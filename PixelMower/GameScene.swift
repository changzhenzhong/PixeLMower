import SpriteKit
import AVFoundation

class LegoWorker: SKNode {
    private let head: SKShapeNode
    private let torso: SKShapeNode
    private let leftArm: SKShapeNode
    private let rightArm: SKShapeNode
    private let leftLeg: SKShapeNode
    private let rightLeg: SKShapeNode
    private let brickNode: SKShapeNode
    
    var isCarryingBrick = false {
        didSet { brickNode.isHidden = !isCarryingBrick }
    }
    var moveSpeed: CGFloat = 60
    
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
        
        brickNode = SKShapeNode(rectOf: CGSize(width: 6, height: 6), cornerRadius: 1)
        brickNode.fillColor = .orange
        brickNode.strokeColor = .black
        brickNode.lineWidth = 1
        brickNode.position = CGPoint(x: 8, y: 6)
        brickNode.isHidden = true
        
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
        addChild(brickNode)
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
    private var brickPile: SKNode!
    private var dropPoints: [SKNode] = []
    private var workers: [LegoWorker] = []
    private var brickNodes: [SKNode] = []
    private var nextBrickIndex: Int = 0
    
    private var foundationRect: CGRect = .zero
    private var foundationPoints: [CGPoint] = []
    
    private let brickPilePosition = CGPoint(x: 70, y: 70)
    private let spawnPoint = CGPoint(x: 90, y: 90)
    private var baseSpeed: CGFloat = 50.0
    private var currentBuildingIndex: Int = 0
    
    override func didMove(to view: SKView) {
        backgroundColor = .white
        setupBackground()
        setupBrickPile()
        setupBuilding(at: currentBuildingIndex)
        setupDropPoints()
        
        baseSpeed = 50.0
        let speedMultiplier = 1.0 + CGFloat(gameState.speedLevel - 1) * 0.2
        let initialSpeed = baseSpeed * speedMultiplier
        for _ in 0..<gameState.workerCount {
            spawnWorker(speed: initialSpeed)
        }
        restoreBricks()
    }
    
    private func setupBackground() {
        let sky = SKShapeNode(rect: CGRect(x: 0, y: size.height * 0.4, width: size.width, height: size.height * 0.6))
        sky.fillColor = UIColor(red: 0.4, green: 0.7, blue: 1.0, alpha: 1)
        sky.strokeColor = .clear
        sky.position = CGPoint(x: 0, y: size.height * 0.4)
        addChild(sky)
        
        let ground = SKShapeNode(rect: CGRect(x: 0, y: 0, width: size.width, height: size.height * 0.4))
        ground.fillColor = UIColor(red: 0.2, green: 0.6, blue: 0.2, alpha: 1)
        ground.strokeColor = .clear
        ground.position = CGPoint(x: 0, y: 0)
        addChild(ground)
        
        let towerPath = UIBezierPath()
        towerPath.move(to: CGPoint(x: 0, y: 0))
        towerPath.addLine(to: CGPoint(x: -20, y: 50))
        towerPath.addLine(to: CGPoint(x: -12, y: 50))
        towerPath.addLine(to: CGPoint(x: -6, y: 90))
        towerPath.addLine(to: CGPoint(x: 6, y: 90))
        towerPath.addLine(to: CGPoint(x: 12, y: 50))
        towerPath.addLine(to: CGPoint(x: 20, y: 50))
        towerPath.close()
        let tower = SKShapeNode(path: towerPath.cgPath)
        tower.fillColor = UIColor(white: 0.5, alpha: 0.8)
        tower.strokeColor = .black
        tower.lineWidth = 1
        tower.position = CGPoint(x: 60, y: size.height * 0.4 + 10)
        addChild(tower)
        
        for i in 0..<3 {
            let cloud = SKShapeNode(circleOfRadius: 25 + CGFloat(i)*10)
            cloud.fillColor = UIColor(white: 0.9, alpha: 0.6)
            cloud.strokeColor = .clear
            cloud.position = CGPoint(x: size.width * 0.2 + CGFloat(i)*120, y: size.height * 0.75 + CGFloat(i)*20)
            addChild(cloud)
        }
        
        let sun = SKShapeNode(circleOfRadius: 30)
        sun.fillColor = .yellow
        sun.strokeColor = .clear
        sun.position = CGPoint(x: size.width - 60, y: size.height - 60)
        addChild(sun)
    }
    
    private func setupBrickPile() {
        brickPile = SKNode()
        brickPile.position = brickPilePosition
        addChild(brickPile)
        let colors: [UIColor] = [.red, .orange, .brown]
        for i in 0..<3 {
            for j in 0..<2 {
                let brick = SKShapeNode(rectOf: CGSize(width: 20, height: 10), cornerRadius: 1)
                brick.fillColor = colors[(i+j)%3]
                brick.strokeColor = .black
                brick.lineWidth = 1
                brick.position = CGPoint(x: -15 + CGFloat(i)*15, y: -5 + CGFloat(j)*12)
                brickPile.addChild(brick)
            }
        }
        let label = SKLabelNode(text: "🧱")
        label.fontSize = 20
        label.position = CGPoint(x: 0, y: -25)
        brickPile.addChild(label)
    }
    
    private func setupBuilding(at index: Int) {
        buildingNode?.removeFromParent()
        brickNodes.removeAll()
        nextBrickIndex = 0
        
        let (totalBricks, brickSize, layers, perLayer) = gameState.getCurrentBuildingStyle()
        let mainColor = UIColor(red: 0.6, green: 0.4, blue: 0.2, alpha: 1)
        let windowColor = UIColor.yellow
        
        let totalWidth = CGFloat(perLayer) * brickSize
        let totalHeight = CGFloat(layers) * brickSize
        
        buildingNode = SKNode()
        buildingNode.position = CGPoint(x: size.width / 2, y: size.height / 2)
        addChild(buildingNode)
        
        var brickPositions: [CGPoint] = []
        for layer in 0..<layers {
            for col in 0..<perLayer {
                let x = -totalWidth/2 + CGFloat(col) * brickSize + brickSize/2
                let y = -totalHeight/2 + CGFloat(layer) * brickSize + brickSize/2
                let offset = (layer % 2 == 0) ? 0 : brickSize/2
                let finalX = x + offset
                if finalX + brickSize/2 > totalWidth/2 { continue }
                brickPositions.append(CGPoint(x: finalX, y: y))
            }
        }
        if brickPositions.count > totalBricks {
            brickPositions = Array(brickPositions[0..<totalBricks])
        }
        
        for (index, pos) in brickPositions.enumerated() {
            let layer = index / perLayer
            let col = index % perLayer
            let isWindow = (col == perLayer/2 || col == perLayer/2 - 1) && layer > 0 && layer < layers-1
            let color = isWindow ? windowColor : mainColor
            
            let brick = SKShapeNode(rectOf: CGSize(width: brickSize-1, height: brickSize-1), cornerRadius: 1)
            brick.fillColor = color
            brick.strokeColor = UIColor(white: 0.2, alpha: 0.5)
            brick.lineWidth = 0.5
            brick.position = pos
            brick.setScale(0)
            brick.isHidden = true
            buildingNode.addChild(brick)
            brickNodes.append(brick)
        }
        
        let foundationW = totalWidth + 40
        let foundationH = totalHeight + 40
        let center = CGPoint(x: size.width / 2, y: size.height / 2)
        let origin = CGPoint(x: center.x - foundationW/2, y: center.y - foundationH/2)
        foundationRect = CGRect(origin: origin, size: CGSize(width: foundationW, height: foundationH))
        foundationPoints = [
            CGPoint(x: foundationRect.minX, y: foundationRect.minY),
            CGPoint(x: foundationRect.maxX, y: foundationRect.minY),
            CGPoint(x: foundationRect.maxX, y: foundationRect.maxY),
            CGPoint(x: foundationRect.minX, y: foundationRect.maxY)
        ]
        
        let foundationFill = SKShapeNode(rect: foundationRect, cornerRadius: 4)
        foundationFill.fillColor = UIColor(white: 0.9, alpha: 0.2)
        foundationFill.strokeColor = UIColor(white: 0.5, alpha: 0.6)
        foundationFill.lineWidth = 1
        // 移除 lineDashPattern，因为 SKShapeNode 不支持
        // 可以使用实线，或者用其他方法绘制虚线，这里用实线
        buildingNode.addChild(foundationFill)
    }
    
    private func setupDropPoints() {
        dropPoints.forEach { $0.removeFromParent() }
        dropPoints.removeAll()
        
        let offset: CGFloat = 30
        for point in foundationPoints {
            let dx = point.x - size.width/2
            let dy = point.y - size.height/2
            let dist = hypot(dx, dy)
            guard dist > 0 else { continue }
            let ratio = (dist + offset) / dist
            let pos = CGPoint(
                x: size.width/2 + dx * ratio,
                y: size.height/2 + dy * ratio
            )
            let dot = SKShapeNode(circleOfRadius: 8)
            dot.fillColor = .green
            dot.strokeColor = .black
            dot.lineWidth = 1
            dot.position = pos
            addChild(dot)
            dropPoints.append(dot)
        }
    }
    
    private func restoreBricks() {
        let count = min(gameState.currentBrickCount, brickNodes.count)
        for i in 0..<count {
            let brick = brickNodes[i]
            brick.isHidden = false
            brick.setScale(1)
        }
        nextBrickIndex = count
    }
    
    func addBrick() {
        guard nextBrickIndex < brickNodes.count else { return }
        let brick = brickNodes[nextBrickIndex]
        brick.isHidden = false
        brick.setScale(0)
        // 修正：使用正确的动画方式
        let scaleAction = SKAction.scale(to: 1, duration: 0.2)
        scaleAction.timingMode = .easeOut
        brick.run(scaleAction)
        AudioManager.playBuild()
        nextBrickIndex += 1
        gameState.addBrick()
    }
    
    private func spawnWorker(speed: CGFloat) {
        let worker = LegoWorker()
        worker.moveSpeed = speed
        worker.position = spawnPoint
        worker.setCarrying(false)
        addChild(worker)
        workers.append(worker)
    }
    
    func addOneWorker() {
        let speedMultiplier = 1.0 + CGFloat(gameState.speedLevel - 1) * 0.2
        let speed = baseSpeed * speedMultiplier
        spawnWorker(speed: speed)
    }
    
    func updateSpeed() {
        let speedMultiplier = 1.0 + CGFloat(gameState.speedLevel - 1) * 0.2
        let newSpeed = baseSpeed * speedMultiplier
        for worker in workers {
            worker.moveSpeed = newSpeed
        }
    }
    
    func switchToBuilding(_ index: Int) {
        currentBuildingIndex = index
        setupBuilding(at: index)
        setupDropPoints()
        nextBrickIndex = 0
        restoreBricks()
        repositionWorkersOnFoundation()
    }
    
    private func repositionWorkersOnFoundation() {
        let count = workers.count
        guard count > 0 else { return }
        for (i, worker) in workers.enumerated() {
            let t = CGFloat(i) / CGFloat(count)
            let pointIndex = Int(t * 4) % 4
            let nextIndex = (pointIndex + 1) % 4
            let localT = (t * 4).truncatingRemainder(dividingBy: 1)
            let p1 = foundationPoints[pointIndex]
            let p2 = foundationPoints[nextIndex]
            let x = p1.x + (p2.x - p1.x) * localT
            let y = p1.y + (p2.y - p1.y) * localT
            let dx = x - size.width/2
            let dy = y - size.height/2
            let dist = hypot(dx, dy)
            let offset: CGFloat = 20
            let ratio = (dist + offset) / dist
            worker.position = CGPoint(
                x: size.width/2 + dx * ratio,
                y: size.height/2 + dy * ratio
            )
        }
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
        let brickTarget = brickPilePosition
        let dropTarget = nearestDropPoint(from: worker.position)
        let target: CGPoint
        if worker.isCarryingBrick {
            target = dropTarget
        } else {
            target = brickTarget
        }
        
        let dx = target.x - worker.position.x
        let dy = target.y - worker.position.y
        let distance = hypot(dx, dy)
        
        if distance < 3 {
            worker.position = target
            if worker.isCarryingBrick {
                worker.setCarrying(false)
                let bonus = gameState?.currentBonus ?? 1
                gameState.coins += bonus
                AudioManager.playCoin()
                addBrick()
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
            let step = worker.moveSpeed * deltaTime
            let ratio = min(step / distance, 1.0)
            worker.position.x += dx * ratio
            worker.position.y += dy * ratio
            worker.animateWalk(progress: CGFloat(CFAbsoluteTimeGetCurrent()) * 2)
        }
    }
    
    private func nearestDropPoint(from pos: CGPoint) -> CGPoint {
        var nearest = dropPoints[0]
        var minDist = CGFloat.greatestFiniteMagnitude
        for point in dropPoints {
            let dist = hypot(pos.x - point.position.x, pos.y - point.position.y)
            if dist < minDist {
                minDist = dist
                nearest = point
            }
        }
        return nearest.position
    }
}
