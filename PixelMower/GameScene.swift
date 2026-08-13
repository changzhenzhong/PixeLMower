import SpriteKit
import AVFoundation

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
        // 砖块
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

class GameScene: SKScene {
    weak var gameState: GameState!
    
    private var buildingNode: SKNode!
    private var brickPile: SKNode!
    private var dropPoint: SKShapeNode!
    private var workers: [LegoWorker] = []
    private var brickCount: Int = 0
    private var buildingBricks: [SKNode] = []
    
    private let brickPilePos: CGPoint
    private let dropRadius: CGFloat = 120
    
    override init(size: CGSize) {
        self.brickPilePos = CGPoint(x: 60, y: 60)
        super.init(size: size)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func didMove(to view: SKView) {
        // 背景色
        backgroundColor = UIColor(red: 0.3, green: 0.6, blue: 0.9, alpha: 1)
        scaleMode = .resizeFill
        
        drawBackground()
        setupBrickPile()
        setupBuilding()
        setupDropPoint()
        
        for _ in 0..<gameState.workerCount {
            spawnWorker()
        }
        restoreBuilding()
    }
    
    private func drawBackground() {
        // 草地
        let grass = SKShapeNode(rect: CGRect(x: 0, y: 0, width: size.width, height: size.height * 0.35))
        grass.fillColor = UIColor(red: 0.2, green: 0.55, blue: 0.2, alpha: 1)
        grass.strokeColor = .clear
        grass.position = .zero
        addChild(grass)
        
        // 云朵
        for i in 0..<3 {
            let cloud = SKShapeNode(circleOfRadius: 30 + CGFloat(i)*15)
            cloud.fillColor = UIColor(white: 0.95, alpha: 0.7)
            cloud.strokeColor = .clear
            cloud.position = CGPoint(x: size.width * 0.15 + CGFloat(i) * size.width * 0.35, y: size.height * 0.75 + CGFloat(i%2)*20)
            addChild(cloud)
            let cloud2 = SKShapeNode(circleOfRadius: 20 + CGFloat(i)*10)
            cloud2.fillColor = UIColor(white: 0.95, alpha: 0.6)
            cloud2.strokeColor = .clear
            cloud2.position = CGPoint(x: cloud.position.x + 30, y: cloud.position.y - 10)
            addChild(cloud2)
        }
        
        // 太阳
        let sun = SKShapeNode(circleOfRadius: 35)
        sun.fillColor = .yellow
        sun.strokeColor = .clear
        sun.position = CGPoint(x: size.width - 70, y: size.height - 60)
        addChild(sun)
        
        // 埃菲尔铁塔（左侧）
        let towerPath = UIBezierPath()
        towerPath.move(to: CGPoint(x: 0, y: 0))
        towerPath.addLine(to: CGPoint(x: -18, y: 50))
        towerPath.addLine(to: CGPoint(x: -10, y: 50))
        towerPath.addLine(to: CGPoint(x: -5, y: 80))
        towerPath.addLine(to: CGPoint(x: 5, y: 80))
        towerPath.addLine(to: CGPoint(x: 10, y: 50))
        towerPath.addLine(to: CGPoint(x: 18, y: 50))
        towerPath.close()
        let tower = SKShapeNode(path: towerPath.cgPath)
        tower.fillColor = UIColor(white: 0.4, alpha: 0.6)
        tower.strokeColor = UIColor.black
        tower.lineWidth = 1
        tower.position = CGPoint(x: 50, y: size.height * 0.35)
        addChild(tower)
        
        // 故宫亭子（右侧）
        let pavilionBase = SKShapeNode(rectOf: CGSize(width: 35, height: 25), cornerRadius: 2)
        pavilionBase.fillColor = UIColor(red: 0.7, green: 0.2, blue: 0.2, alpha: 0.7)
        pavilionBase.strokeColor = .black
        pavilionBase.lineWidth = 1
        pavilionBase.position = CGPoint(x: size.width - 55, y: size.height * 0.35 + 10)
        addChild(pavilionBase)
        let roofPath = UIBezierPath()
        roofPath.move(to: CGPoint(x: -22, y: 12))
        roofPath.addLine(to: CGPoint(x: 0, y: 30))
        roofPath.addLine(to: CGPoint(x: 22, y: 12))
        roofPath.close()
        let pavilionRoof = SKShapeNode(path: roofPath.cgPath)
        pavilionRoof.fillColor = .yellow
        pavilionRoof.strokeColor = .black
        pavilionRoof.lineWidth = 1
        pavilionRoof.position = pavilionBase.position
        addChild(pavilionRoof)
    }
    
    private func setupBrickPile() {
        brickPile = SKNode()
        brickPile.position = brickPilePos
        addChild(brickPile)
        let pile = SKShapeNode(rectOf: CGSize(width: 30, height: 20), cornerRadius: 2)
        pile.fillColor = .red
        pile.strokeColor = .black
        pile.lineWidth = 1
        brickPile.addChild(pile)
        let label = SKLabelNode(text: "🧱")
        label.fontSize = 18
        label.position = CGPoint(x: 0, y: -22)
        brickPile.addChild(label)
    }
    
    private func setupBuilding() {
        buildingNode = SKNode()
        buildingNode.position = CGPoint(x: size.width/2, y: size.height/2)
        addChild(buildingNode)
        
        // 建筑主体（带屋顶）
        let main = SKShapeNode(rectOf: CGSize(width: 70, height: 70), cornerRadius: 3)
        main.fillColor = UIColor(red: 0.6, green: 0.4, blue: 0.2, alpha: 1)
        main.strokeColor = .black
        main.lineWidth = 2
        buildingNode.addChild(main)
        
        // 屋顶
        let roofPath = UIBezierPath()
        roofPath.move(to: CGPoint(x: -40, y: 35))
        roofPath.addLine(to: CGPoint(x: 0, y: 55))
        roofPath.addLine(to: CGPoint(x: 40, y: 35))
        roofPath.close()
        let roof = SKShapeNode(path: roofPath.cgPath)
        roof.fillColor = .red
        roof.strokeColor = .black
        roof.lineWidth = 2
        buildingNode.addChild(roof)
        
        // 窗户（装饰）
        for i in 0..<2 {
            for j in 0..<2 {
                let win = SKShapeNode(rectOf: CGSize(width: 10, height: 12), cornerRadius: 1)
                win.fillColor = UIColor(red: 0.8, green: 0.8, blue: 0.3, alpha: 1)
                win.strokeColor = .black
                win.lineWidth = 1
                win.position = CGPoint(x: -15 + CGFloat(i)*30, y: -15 + CGFloat(j)*30)
                buildingNode.addChild(win)
            }
        }
    }
    
    private func setupDropPoint() {
        dropPoint = SKShapeNode(circleOfRadius: 12)
        dropPoint.fillColor = .green
        dropPoint.strokeColor = .black
        dropPoint.lineWidth = 1
        dropPoint.position = CGPoint(x: size.width/2, y: size.height/2 + dropRadius)
        addChild(dropPoint)
    }
    
    private func restoreBuilding() {
        let count = gameState.currentBrickCount
        let maxPerRow = 8
        for i in 0..<count {
            let brick = SKShapeNode(rectOf: CGSize(width: 6, height: 6))
            brick.fillColor = .orange
            brick.strokeColor = .black
            brick.lineWidth = 0.5
            let row = i / maxPerRow
            let col = i % maxPerRow
            brick.position = CGPoint(x: -28 + CGFloat(col) * 8, y: -28 + CGFloat(row) * 8)
            buildingNode.addChild(brick)
            buildingBricks.append(brick)
        }
        brickCount = count
    }
    
    private func spawnWorker() {
        let worker = LegoWorker()
        worker.moveSpeed = 50 + CGFloat(gameState.speedLevel - 1) * 10
        worker.position = brickPilePos
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
        buildingBricks.forEach { $0.removeFromParent() }
        buildingBricks.removeAll()
        brickCount = 0
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
        let target = worker.isCarryingBrick ? dropPoint.position : brickPilePos
        let dx = target.x - worker.position.x
        let dy = target.y - worker.position.y
        let distance = hypot(dx, dy)
        
        if distance < 3 {
            worker.position = target
            if worker.isCarryingBrick {
                worker.setCarrying(false)
                gameState.coins += gameState.currentBonus
                AudioManager.playCoin()
                addBrickToBuilding()
            } else {
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
        let brick = SKShapeNode(rectOf: CGSize(width: 6, height: 6))
        brick.fillColor = .orange
        brick.strokeColor = .black
        brick.lineWidth = 0.5
        let maxPerRow = 8
        let row = brickCount / maxPerRow
        let col = brickCount % maxPerRow
        brick.position = CGPoint(x: -28 + CGFloat(col) * 8, y: -28 + CGFloat(row) * 8)
        buildingNode.addChild(brick)
        buildingBricks.append(brick)
        brickCount += 1
        gameState.addBrick()
        if gameState.isBuildingComplete {
            AudioManager.playUnlock()
        }
    }
}
