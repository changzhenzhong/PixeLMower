import SpriteKit
import AVFoundation

// MARK: - GameState（与之前相同）
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

// MARK: - 乐高工人
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
        let head = SKShapeNode(circleOfRadius: 5)
        head.fillColor = .white
        head.strokeColor = .black
        head.lineWidth = 1
        head.position = CGPoint(x: 0, y: 10)
        addChild(head)
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

// MARK: - 游戏场景（含美观建筑）
class GameScene: SKScene {
    weak var gameState: GameState!
    
    private var buildingNode: SKNode!
    private var brickPile: SKNode!
    private var dropPoint: SKShapeNode!
    private var workers: [LegoWorker] = []
    private var brickCount: Int = 0
    private var placedBricks: [SKShapeNode] = []
    
    // 建筑尺寸
    private let buildingWidth: CGFloat = 80
    private let buildingHeight: CGFloat = 90
    private let brickSize: CGFloat = 8
    private let bricksPerRow: Int = 8
    
    private let brickPilePos: CGPoint
    private let dropRadius: CGFloat = 130
    
    override init(size: CGSize) {
        self.brickPilePos = CGPoint(x: 60, y: 60)
        super.init(size: size)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func didMove(to view: SKView) {
        backgroundColor = UIColor(red: 0.3, green: 0.6, blue: 0.9, alpha: 1)
        scaleMode = .resizeFill
        
        drawBackground()
        setupBrickPile()
        setupBuilding()
        setupDropPoint()
        
        for _ in 0..<gameState.workerCount {
            spawnWorker()
        }
        
        // 恢复已放置的砖块
        restoreBricks()
    }
    
    // MARK: - 背景（包含埃菲尔铁塔和故宫亭子）
    private func drawBackground() {
        // 草地
        let grassHeight = size.height * 0.35
        let grass = SKShapeNode(rect: CGRect(x: 0, y: 0, width: size.width, height: grassHeight))
        grass.fillColor = UIColor(red: 0.2, green: 0.55, blue: 0.2, alpha: 1)
        grass.strokeColor = .clear
        grass.position = .zero
        addChild(grass)
        
        // 云朵
        for i in 0..<3 {
            let cloud = SKShapeNode(circleOfRadius: 30 + CGFloat(i)*15)
            cloud.fillColor = UIColor(white: 0.95, alpha: 0.7)
            cloud.strokeColor = .clear
            cloud.position = CGPoint(x: size.width * 0.15 + CGFloat(i) * size.width * 0.35, y: size.height * 0.8 + CGFloat(i%2)*20)
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
        tower.position = CGPoint(x: 50, y: grassHeight + 10)
        addChild(tower)
        
        // 故宫亭子（右侧）
        let pavilionBase = SKShapeNode(rectOf: CGSize(width: 35, height: 25), cornerRadius: 2)
        pavilionBase.fillColor = UIColor(red: 0.7, green: 0.2, blue: 0.2, alpha: 0.7)
        pavilionBase.strokeColor = .black
        pavilionBase.lineWidth = 1
        pavilionBase.position = CGPoint(x: size.width - 55, y: grassHeight + 10)
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
    
    // MARK: - 砖堆
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
    
    // MARK: - 建筑（美观版）
    private func setupBuilding() {
        buildingNode = SKNode()
        buildingNode.position = CGPoint(x: size.width/2, y: size.height/2 + 10)
        addChild(buildingNode)
        
        // 1. 建筑主体（棕色）
        let mainBody = SKShapeNode(rectOf: CGSize(width: buildingWidth, height: buildingHeight), cornerRadius: 4)
        mainBody.fillColor = UIColor(red: 0.6, green: 0.4, blue: 0.2, alpha: 1)
        mainBody.strokeColor = .black
        mainBody.lineWidth = 2
        buildingNode.addChild(mainBody)
        
        // 2. 屋顶（红色三角形）
        let roofPath = UIBezierPath()
        roofPath.move(to: CGPoint(x: -buildingWidth/2 - 5, y: buildingHeight/2))
        roofPath.addLine(to: CGPoint(x: 0, y: buildingHeight/2 + 35))
        roofPath.addLine(to: CGPoint(x: buildingWidth/2 + 5, y: buildingHeight/2))
        roofPath.close()
        let roof = SKShapeNode(path: roofPath.cgPath)
        roof.fillColor = .red
        roof.strokeColor = .black
        roof.lineWidth = 2
        buildingNode.addChild(roof)
        
        // 3. 装饰窗户（初始显示几个，增加美观）
        let windowPositions: [(CGFloat, CGFloat)] = [
            (-20, 20), (20, 20),
            (-20, -5), (20, -5),
            (-20, -30), (20, -30)
        ]
        for (x, y) in windowPositions {
            let win = SKShapeNode(rectOf: CGSize(width: 12, height: 14), cornerRadius: 1)
            win.fillColor = UIColor(red: 0.8, green: 0.8, blue: 0.3, alpha: 1)
            win.strokeColor = .black
            win.lineWidth = 1
            win.position = CGPoint(x: x, y: y)
            buildingNode.addChild(win)
            // 窗户十字框
            let hLine = SKShapeNode(rect: CGRect(x: -6, y: -1, width: 12, height: 2))
            hLine.fillColor = .black
            hLine.strokeColor = .clear
            hLine.position = .zero
            win.addChild(hLine)
            let vLine = SKShapeNode(rect: CGRect(x: -1, y: -7, width: 2, height: 14))
            vLine.fillColor = .black
            vLine.strokeColor = .clear
            vLine.position = .zero
            win.addChild(vLine)
        }
        
        // 4. 门（底部中央）
        let door = SKShapeNode(rectOf: CGSize(width: 16, height: 20), cornerRadius: 2)
        door.fillColor = UIColor(red: 0.3, green: 0.2, blue: 0.1, alpha: 1)
        door.strokeColor = .black
        door.lineWidth = 1
        door.position = CGPoint(x: 0, y: -buildingHeight/2 + 10)
        buildingNode.addChild(door)
        
        // 5. 门把手
        let handle = SKShapeNode(circleOfRadius: 2)
        handle.fillColor = .yellow
        handle.strokeColor = .black
        handle.lineWidth = 0.5
        handle.position = CGPoint(x: 5, y: -buildingHeight/2 + 10)
        buildingNode.addChild(handle)
    }
    
    // MARK: - 放置点
    private func setupDropPoint() {
        dropPoint = SKShapeNode(circleOfRadius: 12)
        dropPoint.fillColor = .green
        dropPoint.strokeColor = .black
        dropPoint.lineWidth = 1
        dropPoint.position = CGPoint(x: size.width/2, y: size.height/2 + dropRadius)
        addChild(dropPoint)
        
        // 添加"放置点"文字
        let label = SKLabelNode(text: "📦")
        label.fontSize = 16
        label.position = CGPoint(x: 0, y: -20)
        dropPoint.addChild(label)
    }
    
    // MARK: - 恢复已放置的砖块
    private func restoreBricks() {
        let count = gameState.currentBrickCount
        for i in 0..<count {
            let brick = createBrick(at: i)
            buildingNode.addChild(brick)
            placedBricks.append(brick)
        }
        brickCount = count
    }
    
    // 创建一块砖
    private func createBrick(at index: Int) -> SKShapeNode {
        let brick = SKShapeNode(rectOf: CGSize(width: brickSize-1, height: brickSize-1))
        brick.fillColor = UIColor(red: 0.8, green: 0.5, blue: 0.2, alpha: 1)
        brick.strokeColor = .black
        brick.lineWidth = 0.5
        
        // 计算位置（从底部开始，逐层向上）
        let row = index / bricksPerRow
        let col = index % bricksPerRow
        // 交错排列（砌墙效果）
        let offset = (row % 2 == 0) ? 0 : brickSize/2
        let totalWidth = CGFloat(bricksPerRow) * brickSize
        let x = -totalWidth/2 + CGFloat(col) * brickSize + brickSize/2 + offset
        let y = -buildingHeight/2 + 10 + CGFloat(row) * brickSize + brickSize/2
        
        brick.position = CGPoint(x: x, y: y)
        return brick
    }
    
    // 生成工人
    private func spawnWorker() {
        let worker = LegoWorker()
        worker.moveSpeed = 50 + CGFloat(gameState.speedLevel - 1) * 10
        worker.position = brickPilePos
        worker.setCarrying(false)
        addChild(worker)
        workers.append(worker)
    }
    
    // MARK: - 对外接口
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
        // 清除旧砖块
        placedBricks.forEach { $0.removeFromParent() }
        placedBricks.removeAll()
        brickCount = 0
        // 更新建筑外观（根据类型变化颜色）
        let colors: [UIColor] = [
            UIColor(red: 0.6, green: 0.4, blue: 0.2, alpha: 1),
            UIColor(red: 0.8, green: 0.7, blue: 0.5, alpha: 1),
            UIColor(red: 0.3, green: 0.5, blue: 0.7, alpha: 1)
        ]
        // 更新主体颜色
        if let mainBody = buildingNode.children.first(where: { $0 is SKShapeNode && $0.position == .zero }) as? SKShapeNode {
            mainBody.fillColor = colors[index % colors.count]
        }
    }
    
    // MARK: - 更新循环
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
        guard brickCount < gameState.totalBrickCount else { return }
        let brick = createBrick(at: brickCount)
        buildingNode.addChild(brick)
        placedBricks.append(brick)
        brickCount += 1
        gameState.addBrick()
        
        // 小动画：砖块出现时弹跳
        brick.setScale(0)
        let scaleUp = SKAction.scale(to: 1.2, duration: 0.1)
        let scaleDown = SKAction.scale(to: 1.0, duration: 0.1)
        brick.run(SKAction.sequence([scaleUp, scaleDown]))
    }
}
