import SpriteKit

// 2.5D世界逻辑坐标结构体
struct WorldPoint {
    var x: CGFloat
    var y: CGFloat
    var z: CGFloat
}

class GameScene: SKScene {
    
    // MARK: 2.5D透视参数【固定斜视角，不可旋转】
    private let isoAngleX: CGFloat = 0.45
    private let isoAngleY: CGFloat = 0.25
    
    // 世界原点映射到屏幕中心点
    private var worldOrigin: CGPoint = .zero
    
    // MARK: 游戏数据
    var gold: Int = 0
    var brickCount: Int = 0
    var targetBricks: Int = 100
    var buildingName: String = "小屋"
    
    var workerCount: Int = 1
    var workerSpeed: CGFloat = 60
    
    var workers: [SKSpriteNode] = []
    var buildingBricks: [SKSpriteNode] = []
    var brickPileNode: SKSpriteNode!
    var buildingBaseNode: SKSpriteNode!
    
    // 回调给SwiftUI UI更新
    var onUpdateUI: ((Int, Int, Double) -> Void)?
    var audioManager: AudioManager?
    
    override func didMove(to view: SKView) {
        super.didMove(to: view)
        backgroundColor = UIColor(red: 0.3, green:0.6, blue:0.95, alpha:1.0)
        
        // ✅ 世界原点 = 画面正中心
        worldOrigin = CGPoint(x: size.width/2, y: size.height/2)
        
        setupGround()
        setupBrickPile()
        setupBuildingBase()
        spawnWorkers()
    }
    
    // MARK: 🔑 核心：世界逻辑坐标 → SpriteKit屏幕坐标投影
    private func worldToScreen(_ wp: WorldPoint) -> CGPoint {
        let screenX = worldOrigin.x + wp.x * cos(isoAngleX) - wp.y * cos(isoAngleY)
        let screenY = worldOrigin.y + wp.x * sin(isoAngleX) + wp.y * sin(isoAngleY) - wp.z
        return CGPoint(x: screenX, y: screenY)
    }
    
    // MARK: 地面（2.5D底座平面）
    private func setupGround() {
        let ground = SKShapeNode(rectOf: CGSize(width:700, height:420))
        ground.fillColor = UIColor.systemGreen
        ground.strokeColor = UIColor.darkGray
        ground.lineWidth = 2
        let groundPos = worldToScreen(WorldPoint(x:0, y:0, z:0))
        ground.position = groundPos
        ground.zPosition = -10
        addChild(ground)
    }
    
    // 砖堆：放在世界坐标(-220, -120, 0)，画面左侧
    private func setupBrickPile() {
        brickPileNode = SKSpriteNode(color: .systemBrown, size: CGSize(width:80, height:80))
        brickPileNode.position = worldToScreen(WorldPoint(x:-220, y:-120, z:0))
        brickPileNode.zPosition = 0
        addChild(brickPileNode)
    }
    
    // ✅【建筑底座强制世界原点(0,0,0)，画面天然居中！】
    private func setupBuildingBase() {
        buildingBaseNode = SKSpriteNode(color: .systemRed, size: CGSize(width:140, height:140))
        buildingBaseNode.position = worldToScreen(WorldPoint(x:0, y:0, z:0))
        buildingBaseNode.zPosition = 1
        addChild(buildingBaseNode)
    }
    
    private func spawnWorkers() {
        for _ in 0..<workerCount {
            let worker = SKSpriteNode(color: .systemBlue, size: CGSize(width:32, height:32))
            let startWorld = WorldPoint(x:-180, y:-80, z:0)
            worker.position = worldToScreen(startWorld)
            worker.zPosition = 5
            addChild(worker)
            workers.append(worker)
            runWorkerAI(worker: worker, startWorld: startWorld)
        }
    }
    
    // 工人AI循环：砖堆取砖 → 走到建筑原点(0,0,0)放下砖块
    private func runWorkerAI(worker:SKSpriteNode, startWorld:WorldPoint) {
        guard !worker.isPaused else { return }
        
        // 1.前往砖堆
        let pileWorld = WorldPoint(x:-220, y:-120, z:0)
        let moveToPile = SKAction.move(to: worldToScreen(pileWorld), duration: 1.2 / workerSpeed * 60)
        
        // 2.拾取砖块音效
        let pickBrick = SKAction.run { [weak self] in
            self?.audioManager?.playPickBrick()
        }
        
        // 3.前往建筑中心点【世界原点】
        let buildWorld = WorldPoint(x:0, y:0, z: CGFloat(self.brickCount)*6)
        let moveToBuild = SKAction.move(to: worldToScreen(buildWorld), duration:1.2 / workerSpeed * 60)
        
        //4.放置砖块
        let placeBrick = SKAction.run { [weak self] in
            guard let self = self else { return }
            self.placeNewBrick(zHeight: CGFloat(self.brickCount)*6)
        }
        
        //5.返回起点
        let goBack = SKAction.move(to: worldToScreen(startWorld), duration:1.2 / workerSpeed * 60)
        
        let sequence = SKAction.sequence([
            moveToPile, pickBrick,
            moveToBuild, placeBrick,
            goBack
        ])
        let loop = SKAction.repeatForever(sequence)
        worker.run(loop)
    }
    
    // 放置新砖块，z高度叠加，2.5D堆叠
    private func placeNewBrick(zHeight:CGFloat) {
        brickCount += 1
        let brick = SKSpriteNode(color: UIColor.brown, size: CGSize(width:28, height:28))
        let brickWorld = WorldPoint(x:0, y:0, z: zHeight)
        brick.position = worldToScreen(brickWorld)
        brick.zPosition = zHeight
        addChild(brick)
        buildingBricks.append(brick)
        
        audioManager?.playPlaceBrick()
        
        // 放砖给金币
        gold += 1
        let progress = Double(brickCount) / Double(targetBricks)
        onUpdateUI?(gold, brickCount, progress)
        
        // 建造完成音效
        if brickCount >= targetBricks {
            audioManager?.playBuildComplete()
        }
    }
    
    // 外部调用：增加工人
    func addWorker() {
        workerCount += 1
        let worker = SKSpriteNode(color: .systemBlue, size: CGSize(width:32, height:32))
        let startWorld = WorldPoint(x:-180, y:-80, z:0)
        worker.position = worldToScreen(startWorld)
        worker.zPosition = 5
        addChild(worker)
        workers.append(worker)
        runWorkerAI(worker: worker, startWorld: startWorld)
    }
    
    // 外部调用：提升工人速度
    func boostWorkerSpeed() {
        workerSpeed += 1.2
        workers.forEach { $0.removeAllActions() }
        for (idx,w) in workers.enumerated() {
            let startW = WorldPoint(x:-180, y:-80, z:0)
            runWorkerAI(worker:w, startWorld:startW)
        }
    }
    
    override func didChangeSize(_ oldSize: CGSize) {
        super.didChangeSize(oldSize)
        // 窗口尺寸变化，重新更新世界原点，自动居中！
        worldOrigin = CGPoint(x: size.width/2, y: size.height/2)
    }
}
