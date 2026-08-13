import SpriteKit
import AVFoundation

// MARK: - GameState（所有游戏数据）
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
    var isBuildingComplete: Bool { currentBrickCount >= totalBrickCount }
    var allBuildingsUnlocked: Bool { unlockedBuildings.allSatisfy { $0 } }
    var nextBuildingCost: Int {
        guard let nextIndex = unlockedBuildings.firstIndex(where: { !$0 }) else { return 0 }
        return buildings[nextIndex].cost
    }
    var currentBonus: Int { currentBuildingIndex + 1 }
    
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
        if isBuildingComplete { AudioManager.playUnlock() }
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

// MARK: - 乐高工人（简单但可爱）
class LegoWorker: SKNode {
    var moveSpeed: CGFloat = 60
    var isCarryingBrick = false
    
    override init() {
        super.init()
        // 身体
        let body = SKShapeNode(circleOfRadius: 8)
        body.fillColor = .blue
        body.strokeColor = .black
        body.lineWidth = 1
        addChild(body)
        // 头
        let head = SKShapeNode(circleOfRadius: 5)
        head.fillColor = .white
        head.strokeColor = .black
        head.lineWidth = 1
        head.position = CGPoint(x: 0, y: 10)
        addChild(head)
        // 砖块（拿在手上）
        let brick = SKShapeNode(rectOf: CGSize(width: 6, height: 6))
        brick.fillColor = .orange
        brick.strokeColor = .black
        brick.position = CGPoint(x: 8, y: 2)
        brick.isHidden = true
        addChild(brick)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setCarrying(_ carrying: Bool) {
        isCarryingBrick = carrying
        if let brick = children.last(where: { $0 is SKShapeNode && $0.position == CGPoint(x: 8, y: 2) }) {
            brick.isHidden = !carrying
        }
    }
}

// MARK: - 游戏场景（竖屏全屏，建筑居中）
class GameScene: SKScene {
    weak var gameState: GameState!
    
    private var buildingNode: SKNode!
    private var brickPile: SKNode!
    private var dropPoint: SKShapeNode!  // 用SKShapeNode
    private var workers: [LegoWorker] = []
    private var brickCount: Int = 0
    
    private let brickPilePosition = CGPoint(x: 70, y: 70) // 左下
    private let dropRadius: CGFloat = 100 // 放置点距离建筑中心的距离
    
    override func didMove(to view: SKView) {
        // 背景色
        backgroundColor = UIColor(red: 0.2, green: 0.5, blue: 0.8, alpha: 1)
        // 确保场景填满
        scaleMode = .resizeFill
        
        // 1. 砖堆（左下）
        brickPile = SKNode()
        brickPile.position = brickPilePosition
        addChild(brickPile)
        let brickShape = SKShapeNode(rectOf: CGSize(width: 30, height: 20))
        brickShape.fillColor = .red
        brickShape.strokeColor = .black
        brickShape.lineWidth = 1
        brickPile.addChild(brickShape)
        // 加一个标签
        let label = SKLabelNode(text: "🧱")
        label.fontSize = 20
        label.position = CGPoint(x: 0, y: -25)
        brickPile.addChild(label)
        
        // 2. 建筑节点（绝对居中）
        buildingNode = SKNode()
        buildingNode.position = CGPoint(x: size.width/2, y: size.height/2)
        addChild(buildingNode)
        // 显示一个地基（褐色方块）
        let base = SKShapeNode(rectOf: CGSize(width: 80, height: 80))
        base.fillColor = .brown
        base.strokeColor = .black
        base.lineWidth = 2
        buildingNode.addChild(base)
        
        // 3. 放置点（在建筑上方）
        dropPoint = SKShapeNode(circleOfRadius: 12)
        dropPoint.fillColor = .green
        dropPoint.strokeColor = .black
        dropPoint.lineWidth = 1
        dropPoint.position = CGPoint(x: size.width/2, y: size.height/2 + dropRadius)
        addChild(dropPoint)
        
        // 4. 初始工人
        for _ in 0..<gameState.workerCount {
            spawnWorker()
        }
        
        // 5. 恢复建筑进度
        restoreBuilding()
    }
    
    private func restoreBuilding() {
        // 显示已放置的砖块（简单用橙色小方块代替）
        let count = gameState.currentBrickCount
        let maxPerRow = 10
        for i in 0..<count {
            let brick = SKShapeNode(rectOf: CGSize(width: 6, height: 6))
            brick.fillColor = .orange
            brick.strokeColor = .black
            let row = i / maxPerRow
            let col = i % maxPerRow
            brick.position = CGPoint(x: -35 + CGFloat(col) * 8, y: -35 + CGFloat(row) * 8)
            buildingNode.addChild(brick)
        }
        brickCount = count
    }
    
    private func spawnWorker() {
        let worker = LegoWorker()
        worker.moveSpeed = 50 + CGFloat(gameState.speedLevel - 1) * 10
        worker.position = brickPilePosition
        worker.setCarrying(false)
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
        gameState.switchToBuilding(index: index)
        // 清除旧建筑砖块
        buildingNode.children.forEach { if $0 is SKShapeNode { $0.removeFromParent() } }
        brickCount = 0
        // 重新显示地基
        let base = SKShapeNode(rectOf: CGSize(width: 80, height: 80))
        base.fillColor = .brown
        base.strokeColor = .black
        base.lineWidth = 2
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
                // 放砖
                worker.setCarrying(false)
                gameState.coins += gameState.currentBonus
                AudioManager.playCoin()
                addBrickToBuilding()
            } else {
                // 取砖
                worker.setCarrying(true)
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
        // 在建筑上添加一块砖（橙色小方块）
        let brick = SKShapeNode(rectOf: CGSize(width: 6, height: 6))
        brick.fillColor = .orange
        brick.strokeColor = .black
        let maxPerRow = 10
        let row = brickCount / maxPerRow
        let col = brickCount % maxPerRow
        brick.position = CGPoint(x: -35 + CGFloat(col) * 8, y: -35 + CGFloat(row) * 8)
        buildingNode.addChild(brick)
        brickCount += 1
        gameState.addBrick()
        // 如果建筑完成，播放音效
        if gameState.isBuildingComplete {
            AudioManager.playUnlock()
        }
    }
}
