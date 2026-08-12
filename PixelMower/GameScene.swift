import SpriteKit
import AVFoundation

class GameState: ObservableObject {
    @Published var coins: Int = 0
    @Published var workerCount: Int = 1
    @Published var speedLevel: Int = 1

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
    private let head: SKShapeNode
    private let torso: SKShapeNode
    private let leftArm: SKShapeNode
    private let rightArm: SKShapeNode
    private let leftLeg: SKShapeNode
    private let rightLeg: SKShapeNode
    
    var isCarryingBrick = false
    var walkCycle: CGFloat = 0
    
    override init() {
        head = SKShapeNode(circleOfRadius: 6)
        head.fillColor = .white
        head.strokeColor = .black
        head.lineWidth = 1
        
        torso = SKShapeNode(rectOf: CGSize(width: 10, height: 12), cornerRadius: 2)
        torso.fillColor = .blue
        torso.strokeColor = .black
        torso.lineWidth = 1
        
        leftArm = SKShapeNode(rectOf: CGSize(width: 3, height: 8), cornerRadius: 1)
        leftArm.fillColor = .blue
        leftArm.strokeColor = .black
        leftArm.lineWidth = 1
        
        rightArm = SKShapeNode(rectOf: CGSize(width: 3, height: 8), cornerRadius: 1)
        rightArm.fillColor = .blue
        rightArm.strokeColor = .black
        rightArm.lineWidth = 1
        
        leftLeg = SKShapeNode(rectOf: CGSize(width: 4, height: 6), cornerRadius: 1)
        leftLeg.fillColor = .brown
        leftLeg.strokeColor = .black
        leftLeg.lineWidth = 1
        
        rightLeg = SKShapeNode(rectOf: CGSize(width: 4, height: 6), cornerRadius: 1)
        rightLeg.fillColor = .brown
        rightLeg.strokeColor = .black
        rightLeg.lineWidth = 1
        
        super.init()
        
        head.position = CGPoint(x: 0, y: 14)
        torso.position = CGPoint(x: 0, y: 2)
        leftArm.position = CGPoint(x: -7, y: 4)
        rightArm.position = CGPoint(x: 7, y: 4)
        leftLeg.position = CGPoint(x: -3, y: -6)
        rightLeg.position = CGPoint(x: 3, y: -6)
        
        addChild(head)
        addChild(torso)
        addChild(leftArm)
        addChild(rightArm)
        addChild(leftLeg)
        addChild(rightLeg)
        resetArms()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func resetArms() {
        leftArm.zRotation = 0
        rightArm.zRotation = 0
    }
    
    func setCarrying(_ carrying: Bool) {
        isCarryingBrick = carrying
        if carrying {
            leftArm.zRotation = -CGFloat.pi / 4
            rightArm.zRotation = CGFloat.pi / 4
        } else {
            resetArms()
        }
    }
    
    func animateWalk(progress: CGFloat) {
        let angle = sin(progress * CGFloat.pi * 2) * 0.3
        leftLeg.zRotation = angle
        rightLeg.zRotation = -angle
        leftArm.zRotation = -angle * 0.5
        rightArm.zRotation = angle * 0.5
    }
}

class GameScene: SKScene {
    weak var gameState: GameState!
    
    private var buildingNode: SKNode!
    private var brickPile: SKSpriteNode!
    private var dropPoints: [SKSpriteNode] = []
    private var workers: [LegoWorker] = []
    
    private let buildingSize = CGSize(width: 100, height: 100)
    private let orbitRadius: CGFloat = 120
    private let dropRadius: CGFloat = 70
    private var workerMoveSpeed: CGFloat = 60
    
    override func didMove(to view: SKView) {
        backgroundColor = .black
        setupScene()
        spawnWorkers(count: gameState.workerCount)
    }
    
    private func setupScene() {
        // 地面
        let ground = SKShapeNode(rect: CGRect(x: 0, y: 0, width: size.width, height: size.height * 0.4))
        ground.fillColor = UIColor(red: 0.2, green: 0.5, blue: 0.2, alpha: 1)
        ground.strokeColor = .clear
        ground.position = CGPoint(x: 0, y: 0)
        addChild(ground)
        
        // 天空
        let sky = SKShapeNode(rect: CGRect(x: 0, y: size.height * 0.4, width: size.width, height: size.height * 0.6))
        sky.fillColor = UIColor(red: 0.4, green: 0.6, blue: 0.9, alpha: 1)
        sky.strokeColor = .clear
        sky.position = CGPoint(x: 0, y: size.height * 0.4)
        addChild(sky)
        
        // 埃菲尔铁塔装饰
        let tower = SKShapeNode()
        let path = UIBezierPath()
        path.move(to: CGPoint(x: 0, y: 0))
        path.addLine(to: CGPoint(x: -15, y: 40))
        path.addLine(to: CGPoint(x: -8, y: 40))
        path.addLine(to: CGPoint(x: -4, y: 70))
        path.addLine(to: CGPoint(x: 4, y: 70))
        path.addLine(to: CGPoint(x: 8, y: 40))
        path.addLine(to: CGPoint(x: 15, y: 40))
        path.close()
        tower.path = path.cgPath
        tower.fillColor = .gray
        tower.strokeColor = .black
        tower.lineWidth = 2
        tower.position = CGPoint(x: 100, y: size.height * 0.3)
        addChild(tower)
        
        // 建筑（中上）
        buildingNode = SKNode()
        buildingNode.position = CGPoint(x: size.width / 2, y: size.height * 0.7)
        addChild(buildingNode)
        
        let base = SKShapeNode(rectOf: buildingSize, cornerRadius: 4)
        base.fillColor = .systemBrown
        base.strokeColor = .black
        base.lineWidth = 2
        buildingNode.addChild(base)
        
        for i in 0..<3 {
            for j in 0..<3 {
                let win = SKShapeNode(rectOf: CGSize(width: 8, height: 10), cornerRadius: 1)
                win.fillColor = .yellow
                win.strokeColor = .black
                win.lineWidth = 1
                win.position = CGPoint(x: -20 + CGFloat(i)*20, y: -20 + CGFloat(j)*20)
                buildingNode.addChild(win)
            }
        }
        
        let roof = SKShapeNode(path: {
            let p = UIBezierPath()
            p.move(to: CGPoint(x: -buildingSize.width/2 - 10, y: buildingSize.height/2))
            p.addLine(to: CGPoint(x: 0, y: buildingSize.height/2 + 30))
            p.addLine(to: CGPoint(x: buildingSize.width/2 + 10, y: buildingSize.height/2))
            p.close()
            return p.cgPath
        }())
        roof.fillColor = .red
        roof.strokeColor = .black
        roof.lineWidth = 2
        buildingNode.addChild(roof)
        
        // 砖堆（左下）
        brickPile = SKSpriteNode(color: .systemRed, size: CGSize(width: 30, height: 20))
        brickPile.position = CGPoint(x: 50, y: 50)
        addChild(brickPile)
        for i in 0..<2 {
            let line = SKShapeNode(rect: CGRect(x: -15, y: -8 + CGFloat(i)*16, width: 30, height: 2))
            line.fillColor = .black
            line.strokeColor = .clear
            brickPile.addChild(line)
        }
        
        // 放置点（围绕建筑）
        let angles: [CGFloat] = [0, CGFloat.pi/2, CGFloat.pi, 3*CGFloat.pi/2]
        for angle in angles {
            let x = size.width / 2 + dropRadius * cos(angle)
            let y = size.height * 0.7 + dropRadius * sin(angle)
            let dot = SKSpriteNode(color: .green, size: CGSize(width: 12, height: 12))
            dot.position = CGPoint(x: x, y: y)
            addChild(dot)
            dropPoints.append(dot)
        }
    }
    
    private func spawnWorkers(count: Int) {
        workers.forEach { $0.removeFromParent() }
        workers.removeAll()
        
        let baseSpeed: CGFloat = 50.0
        let speedMultiplier = 1.0 + CGFloat(gameState.speedLevel - 1) * 0.2
        workerMoveSpeed = baseSpeed * speedMultiplier
        
        for i in 0..<count {
            let angle = (CGFloat(i) / CGFloat(count)) * CGFloat.pi * 2
            let x = size.width / 2 + orbitRadius * cos(angle)
            let y = size.height * 0.7 + orbitRadius * sin(angle)
            let worker = LegoWorker()
            worker.position = CGPoint(x: x, y: y)
            worker.setCarrying(Bool.random())
            addChild(worker)
            workers.append(worker)
        }
    }
    
    func refreshWorkers() {
        spawnWorkers(count: gameState.workerCount)
    }
    
    func refreshSpeed() {
        spawnWorkers(count: gameState.workerCount)
    }
    
    private var lastUpdate: TimeInterval = 0
    override func update(_ currentTime: TimeInterval) {
        let delta = min(currentTime - lastUpdate, 1/30)
        lastUpdate = currentTime
        let deltaCGFloat = CGFloat(delta)
        for worker in workers {
            moveWorker(worker, deltaTime: deltaCGFloat)
        }
    }
    
    private func moveWorker(_ worker: LegoWorker, deltaTime: CGFloat) {
        let target: CGPoint
        if worker.isCarryingBrick {
            var nearest = dropPoints[0]
            var minDist = CGFloat.greatestFiniteMagnitude
            for point in dropPoints {
                let dist = hypot(point.position.x - worker.position.x, point.position.y - worker.position.y)
                if dist < minDist {
                    minDist = dist
                    nearest = point
                }
            }
            target = nearest.position
        } else {
            target = brickPile.position
        }
        
        let dx = target.x - worker.position.x
        let dy = target.y - worker.position.y
        let distance = hypot(dx, dy)
        
        if distance < 1 {
            worker.position = target
            if worker.isCarryingBrick {
                worker.setCarrying(false)
                gameState.coins += 1
                AudioManager.playCoin()
                if let dot = dropPoints.first(where: { $0.position == target }) {
                    let flash = SKAction.sequence([
                        SKAction.colorize(with: .white, colorBlendFactor: 1, duration: 0.1),
                        SKAction.colorize(with: .green, colorBlendFactor: 1, duration: 0.1)
                    ])
                    dot.run(flash)
                }
            } else {
                worker.setCarrying(true)
                AudioManager.playPickup()
            }
        } else {
            let step = workerMoveSpeed * deltaTime
            let ratio = min(step / distance, 1.0)
            worker.position.x += dx * ratio
            worker.position.y += dy * ratio
            worker.animateWalk(progress: CGFloat(CFAbsoluteTimeGetCurrent()) * 2)
        }
    }
}
