import SpriteKit
import AVFoundation

// MARK: - GameState（唯一定义）
class GameState: ObservableObject {
    @Published var coins: Int = 0
    @Published var workerCount: Int = 1
    @Published var speedLevel: Int = 1
    
    @Published var currentBuildingIndex: Int = 0
    @Published var unlockedBuildings: [Bool] = [true, false, false]
    @Published var currentBuildingName: String = "小屋"
    @Published var currentBrickCount: Int = 0
    @Published var totalBrickCount: Int = 100
    
    private let buildings: [(name: String, cost: Int, totalBricks: Int)] = [
        ("小屋", 0, 100),
        ("住宅楼", 100, 300),
        ("摩天大楼", 500, 500)
    ]
    
    var buildingProgress: Double {
        totalBrickCount > 0 ? Double(currentBrickCount) / Double(totalBrickCount) : 0
    }
    
    var isBuildingComplete: Bool {
        currentBrickCount >= totalBrickCount
    }
    
    var allBuildingsUnlocked: Bool {
        unlockedBuildings.allSatisfy { $0 }
    }
    
    var nextBuildingCost: Int {
        guard let nextIndex = unlockedBuildings.firstIndex(where: { !$0 }) else { return 0 }
        return buildings[nextIndex].cost
    }
    
    var currentBonus: Int {
        return currentBuildingIndex + 1
    }
    
    func unlockNextBuilding() -> Bool {
        guard let index = unlockedBuildings.firstIndex(where: { !$0 }) else { return false }
        let cost = buildings[index].cost
        guard coins >= cost else { return false }
        coins -= cost
        unlockedBuildings[index] = true
        currentBuildingIndex = index
        currentBuildingName = buildings[index].name
        totalBrickCount = buildings[index].totalBricks
        currentBrickCount = 0
        AudioManager.playUnlock()
        return true
    }
    
    func switchToBuilding(index: Int) {
        guard index < unlockedBuildings.count && unlockedBuildings[index] else { return }
        currentBuildingIndex = index
        currentBuildingName = buildings[index].name
        totalBrickCount = buildings[index].totalBricks
        currentBrickCount = 0
    }
    
    func addBrick() {
        guard currentBrickCount < totalBrickCount else { return }
        currentBrickCount += 1
        if isBuildingComplete {
            AudioManager.playUnlock()
        }
    }
    
    var workerCost: Int { 10 + workerCount * 5 }
    var speedCost: Int { 5 + speedLevel * 3 }
    
    func buyWorker() -> Bool {
        guard coins >= workerCost else { return false }
        coins -= workerCost
        workerCount += 1
        return true
    }
    
    func buySpeed() -> Bool {
        guard coins >= speedCost else { return false }
        coins -= speedCost
        speedLevel += 1
        return true
    }
}

// MARK: - 乐高工人（简化）
class LegoWorker: SKNode {
    var moveSpeed: CGFloat = 60
    var isCarryingBrick = false
    
    override init() {
        super.init()
        let body = SKShapeNode(circleOfRadius: 8)
        body.fillColor = .blue
        body.strokeColor = .black
        body.lineWidth = 1
        addChild(body)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

// MARK: - 游戏场景（极简）
class GameScene: SKScene {
    weak var gameState: GameState!
    
    private var buildingNode: SKNode!
    private var brickPile: SKNode!
    private var dropPoint: SKNode!  // 只用一个放置点简化
    private var workers: [LegoWorker] = []
    private var brickCount: Int = 0
    
    private let brickPilePosition = CGPoint(x: 70, y: 70)
    private let dropPosition = CGPoint(x: 200, y: 200) // 临时位置，后面动态设
    
    override func didMove(to view: SKView) {
        backgroundColor = UIColor(red: 0.4, green: 0.7, blue: 1.0, alpha: 1)
        scaleMode = .resizeFill
        
        // 砖堆
        brickPile = SKNode()
        brickPile.position = brickPilePosition
        addChild(brickPile)
        let brickShape = SKShapeNode(rectOf: CGSize(width: 20, height: 10))
        brickShape.fillColor = .red
        brickShape.strokeColor = .black
        brickPile.addChild(brickShape)
        
        // 放置点（在建筑中心上方）
        dropPoint = SKShapeNode(circleOfRadius: 10)
        dropPoint.fillColor = .green
        dropPoint.strokeColor = .black
        dropPoint.position = CGPoint(x: size.width/2, y: size.height/2 + 30)
        addChild(dropPoint)
        
        // 建筑节点（中心）
        buildingNode = SKNode()
        buildingNode.position = CGPoint(x: size.width/2, y: size.height/2)
        addChild(buildingNode)
        
        // 初始显示一个地基
        let base = SKShapeNode(rectOf: CGSize(width: 80, height: 80))
        base.fillColor = .brown
        base.strokeColor = .black
        buildingNode.addChild(base)
        
        // 生成初始工人
        for _ in 0..<gameState.workerCount {
            spawnWorker()
        }
    }
    
    private func spawnWorker() {
        let worker = LegoWorker()
        worker.moveSpeed = 50 + CGFloat(gameState.speedLevel - 1) * 10
        worker.position = brickPilePosition
        addChild(worker)
        workers.append(worker)
    }
    
    func addOneWorker() {
        spawnWorker()
    }
    
    func updateSpeed() {
        for worker in workers {
            worker.moveSpeed = 50 + CGFloat(gameState.speedLevel - 1) * 10
        }
    }
    
    func switchToBuilding(_ index: Int) {
        // 简单重置进度
        gameState.switchToBuilding(index: index)
        brickCount = 0
        // 清除旧建筑外观，新建一个不同颜色的方块
        buildingNode.children.forEach { $0.removeFromParent() }
        let base = SKShapeNode(rectOf: CGSize(width: 80, height: 80))
        base.fillColor = index == 0 ? .brown : (index == 1 ? .yellow : .blue)
        base.strokeColor = .black
        buildingNode.addChild(base)
    }
    
    private var lastUpdate: TimeInterval = 0
    override func update(_ currentTime: TimeInterval) {
        let delta = min(currentTime - lastUpdate, 1/30)
        lastUpdate = currentTime
        
        for worker in workers {
            moveWorker(worker, deltaTime: CGFloat(delta))
        }
    }
    
    private func moveWorker(_ worker: LegoWorker, deltaTime: CGFloat) {
        let target = worker.isCarryingBrick ? dropPoint.position : brickPilePosition
        let dx = target.x - worker.position.x
        let dy = target.y - worker.position.y
        let distance = hypot(dx, dy)
        
        if distance < 3 {
            worker.position = target
            if worker.isCarryingBrick {
                worker.isCarryingBrick = false
                gameState.coins += gameState.currentBonus
                AudioManager.playCoin()
                // 增加建筑砖块
                addBrickToBuilding()
            } else {
                worker.isCarryingBrick = true
                AudioManager.playPickup()
            }
        } else {
            let step = worker.moveSpeed * deltaTime
            let ratio = min(step / distance, 1.0)
            worker.position.x += dx * ratio
            worker.position.y += dy * ratio
        }
    }
    
    private func addBrickToBuilding() {
        // 每次放砖添加一个小方块到建筑上
        let brick = SKShapeNode(rectOf: CGSize(width: 8, height: 8))
        brick.fillColor = .orange
        brick.strokeColor = .black
        let x = CGFloat(brickCount % 10) * 8 - 40
        let y = CGFloat(brickCount / 10) * 8 - 40
        brick.position = CGPoint(x: x, y: y)
        buildingNode.addChild(brick)
        brickCount += 1
        gameState.addBrick()
    }
}
