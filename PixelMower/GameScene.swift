import SpriteKit

struct WorldPoint {
    var x: CGFloat
    var y: CGFloat
    var z: CGFloat
}

class GameScene: SKScene {
    
    private let isoAngleX: CGFloat = CGFloat(0.45)
    private let isoAngleY: CGFloat = CGFloat(0.25)
    
    private var worldOrigin: CGPoint = .zero
    
    var gold: Int = 0
    var brickCount: Int = 0
    var targetBricks: Int = 100
    var buildingName: String = "小屋"
    
    var workerCount: Int = 1
    var workerSpeed: CGFloat = CGFloat(60)
    
    var workers: [SKSpriteNode] = []
    var buildingBricks: [SKSpriteNode] = []
    var brickPileNode: SKSpriteNode!
    var buildingBaseNode: SKSpriteNode!
    
    var onUpdateUI: ((Int, Int, Double) -> Void)?
    weak var audioManager: AudioManager?
    
    override func didMove(to view: SKView) {
        super.didMove(to: view)
        backgroundColor = UIColor(red:0.3, green:0.6, blue:0.95, alpha:1.0)
        worldOrigin = CGPoint(x:self.size.width / 2.0, y:self.size.height / 2.0)
        
        setupGround()
        setupBrickPile()
        setupBuildingBase()
        spawnWorkers()
    }
    
    private func worldToScreen(_ wp: WorldPoint) -> CGPoint {
        let sx = cos(isoAngleX)
        let sy = cos(isoAngleY)
        let ax = sin(isoAngleX)
        let ay = sin(isoAngleY)
        
        let screenX = worldOrigin.x + wp.x * sx - wp.y * sy
        let screenY = worldOrigin.y + wp.x * ax + wp.y * ay - wp.z
        return CGPoint(x: screenX, y: screenY)
    }
    
    private func setupGround() {
        let ground = SKShapeNode(rectOf: CGSize(width:700, height:420))
        ground.fillColor = UIColor.systemGreen
        ground.strokeColor = UIColor.darkGray
        ground.lineWidth = 2
        ground.position = worldToScreen(WorldPoint(x:0, y:0, z:0))
        ground.zPosition = -10
        addChild(ground)
    }
    
    private func setupBrickPile() {
        brickPileNode = SKSpriteNode(color: .systemBrown, size: CGSize(width:80, height:80))
        brickPileNode.position = worldToScreen(WorldPoint(x:-220, y:-120, z:0))
        brickPileNode.zPosition = 0
        addChild(brickPileNode)
    }
    
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
    
    private func runWorkerAI(worker:SKSpriteNode, startWorld:WorldPoint) {
        guard !worker.isPaused else { return }
        
        let pileWorld = WorldPoint(x:-220, y:-120, z:0)
        let moveToPile = SKAction.move(to: worldToScreen(pileWorld), duration: 1.2 / workerSpeed * 60.0)
        
        let pickBrick = SKAction.run { [weak self] in
            self?.audioManager?.playPickBrick()
        }
        
        let buildWorld = WorldPoint(x:0, y:0, z: CGFloat(self.brickCount)*6.0)
        let moveToBuild = SKAction.move(to: worldToScreen(buildWorld), duration:1.2 / workerSpeed * 60.0)
        
        let placeBrick = SKAction.run { [weak self] in
            guard let self = self else { return }
            self.placeNewBrick(zHeight: CGFloat(self.brickCount)*6.0)
        }
        
        let goBack = SKAction.move(to: worldToScreen(startWorld), duration:1.2 / workerSpeed * 60.0)
        
        let sequence = SKAction.sequence([
            moveToPile, pickBrick,
            moveToBuild, placeBrick,
            goBack
        ])
        let loop = SKAction.repeatForever(sequence)
        worker.run(loop)
    }
    
    private func placeNewBrick(zHeight:CGFloat) {
        brickCount += 1
        let brick = SKSpriteNode(color: UIColor.brown, size: CGSize(width:28, height:28))
        let brickWorld = WorldPoint(x:0, y:0, z: zHeight)
        brick.position = worldToScreen(brickWorld)
        brick.zPosition = zHeight
        addChild(brick)
        buildingBricks.append(brick)
        
        audioManager?.playPlaceBrick()
        
        gold += 1
        let progress = Double(brickCount) / Double(targetBricks)
        onUpdateUI?(gold, brickCount, progress)
        
        if brickCount >= targetBricks {
            audioManager?.playBuildComplete()
        }
    }
    
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
    
    func boostWorkerSpeed() {
        workerSpeed += CGFloat(1.2)
        workers.forEach { $0.removeAllActions() }
        for w in workers {
            let startW = WorldPoint(x:-180, y:-80, z:0)
            runWorkerAI(worker:w, startWorld:startW)
        }
    }
    
    override func didChangeSize(_ oldSize: CGSize) {
        super.didChangeSize(oldSize)
        worldOrigin = CGPoint(x: size.width/2.0, y: size.height/2.0)
    }
}
