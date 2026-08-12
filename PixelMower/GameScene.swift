import SpriteKit
import AVFoundation

// MARK: - 乐高工人（保留原有结构，稍后可以再细化）
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

// MARK: - 游戏场景（完全修正）
class GameScene: SKScene {
    weak var gameState: GameState!
    
    // 场景元素
    private var buildingNode: SKNode!
    private var brickPile: SKNode!
    private var dropPoints: [SKNode] = []
    private var workers: [LegoWorker] = []
    private var brickNodes: [SKNode] = []
    private var nextBrickIndex: Int = 0
    
    private var foundationRect: CGRect = .zero
    private var foundationPoints: [CGPoint] = []
    
    private let brickPilePosition = CGPoint(x: 70, y: 70) // 左下固定
    private let spawnPoint = CGPoint(x: 90, y: 90)
    private var baseSpeed: CGFloat = 50.0
    private var currentBuildingIndex: Int = 0
    
    // 存储当前建筑数据
    private var currentBrickSize: CGFloat = 10
    private var currentLayers: Int = 10
    private var currentPerLayer: Int = 10
    
    override func didMove(to view: SKView) {
        // 关键：强制背景色，并设定场景大小与视图一致
        backgroundColor = UIColor(red: 0.4, green: 0.7, blue: 1.0, alpha: 1)
        // 设置缩放模式（已在外部设为 .resizeFill，但再确保一次）
        self.scaleMode = .resizeFill
        
        setupBackground()
        setupBrickPile()
        setupBuilding(at: currentBuildingIndex)
        setupDropPoints()
        
        // 初始化工人
        baseSpeed = 50.0
        let speedMultiplier = 1.0 + CGFloat(gameState.speedLevel - 1) * 0.2
        let initialSpeed = baseSpeed * speedMultiplier
        for _ in 0..<gameState.workerCount {
            spawnWorker(speed: initialSpeed)
        }
        restoreBricks()
    }
    
    // MARK: - 背景绘制（含主题元素）
    private func setupBackground() {
        // 天空覆盖整个背景（不再分上下部分，用渐变色）
        let skyGradient = SKShapeNode(rect: CGRect(x: 0, y: 0, width: size.width, height: size.height))
        // 为了简单，用纯色背景，但添加装饰云朵和远山
        skyGradient.fillColor = UIColor(red: 0.4, green: 0.7, blue: 1.0, alpha: 1)
        skyGradient.strokeColor = .clear
        skyGradient.position = .zero
        addChild(skyGradient)
        
        // 地面（底部 30% 区域）
        let groundHeight = size.height * 0.3
        let ground = SKShapeNode(rect: CGRect(x: 0, y: 0, width: size.width, height: groundHeight))
        ground.fillColor = UIColor(red: 0.2, green: 0.6, blue: 0.2, alpha: 1)
        ground.strokeColor = .clear
        ground.position = .zero
        addChild(ground)
        
        // 添加一些简单的装饰：云朵（纯装饰）
        for i in 0..<3 {
            let cloud = SKShapeNode(circleOfRadius: 25 + CGFloat(i)*10)
            cloud.fillColor = UIColor(white: 0.9, alpha: 0.7)
            cloud.strokeColor = .clear
            cloud.position = CGPoint(x: size.width * 0.2 + CGFloat(i)*150, y: size.height * 0.8 + CGFloat(i%2)*20)
            addChild(cloud)
        }
        
        // 太阳
        let sun = SKShapeNode(circleOfRadius: 35)
        sun.fillColor = .yellow
        sun.strokeColor = .clear
        sun.position = CGPoint(x: size.width - 70, y: size.height - 70)
        addChild(sun)
        
        // 远山（三角形）
        let mountainPath = UIBezierPath()
        mountainPath.move(to: CGPoint(x: 0, y: groundHeight))
        mountainPath.addLine(to: CGPoint(x: size.width * 0.2, y: groundHeight + 50))
        mountainPath.addLine(to: CGPoint(x: size.width * 0.3, y: groundHeight))
        mountainPath.close()
        let mountain = SKShapeNode(path: mountainPath.cgPath)
        mountain.fillColor = UIColor(white: 0.3, alpha: 0.5)
        mountain.strokeColor = .clear
        addChild(mountain)
        
        // 埃菲尔铁塔轮廓（左侧装饰）
        let towerPath = UIBezierPath()
        towerPath.move(to: CGPoint(x: 0, y: 0))
        towerPath.addLine(to: CGPoint(x: -25, y: 60))
        towerPath.addLine(to: CGPoint(x: -15, y: 60))
        towerPath.addLine(to: CGPoint(x: -8, y: 100))
        towerPath.addLine(to: CGPoint(x: 8, y: 100))
        towerPath.addLine(to: CGPoint(x: 15, y: 60))
        towerPath.addLine(to: CGPoint(x: 25, y: 60))
        towerPath.close()
        let tower = SKShapeNode(path: towerPath.cgPath)
        tower.fillColor = UIColor(white: 0.5, alpha: 0.6)
        tower.strokeColor = UIColor.black
        tower.lineWidth = 1
        tower.position = CGPoint(x: 50, y: groundHeight)
        addChild(tower)
        
        // 故宫风格的小亭子（右侧装饰）
        let pavilion = SKShapeNode(rectOf: CGSize(width: 40, height: 30), cornerRadius: 2)
        pavilion.fillColor = UIColor(red: 0.8, green: 0.2, blue: 0.2, alpha: 0.7)
        pavilion.strokeColor = .black
        pavilion.lineWidth = 1
        pavilion.position = CGPoint(x: size.width - 60, y: groundHeight + 15)
        addChild(pavilion)
        let roofPath = UIBezierPath()
        roofPath.move(to: CGPoint(x: -25, y: 15))
        roofPath.addLine(to: CGPoint(x: 0, y: 35))
        roofPath.addLine(to: CGPoint(x: 25, y: 15))
        roofPath.close()
        let roof = SKShapeNode(path: roofPath.cgPath)
        roof.fillColor = UIColor.yellow
        roof.strokeColor = .black
        roof.lineWidth = 1
        roof.position = pavilion.position
        addChild(roof)
    }
    
    // MARK: - 砖堆（不变）
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
    
    // MARK: - 建造建筑（居中 + 美观）
    private func setupBuilding(at index: Int) {
        buildingNode?.removeFromParent()
        brickNodes.removeAll()
        nextBrickIndex = 0
        
        // 获取建筑数据
        let (totalBricks, brickSize, layers, perLayer) = gameState.getCurrentBuildingStyle()
        currentBrickSize = brickSize
        currentLayers = layers
        currentPerLayer = perLayer
        
        // 建筑主色（根据建筑类型改变）
        let mainColors: [UIColor] = [
            UIColor(red: 0.6, green: 0.4, blue: 0.2, alpha: 1), // 小屋
            UIColor(red: 0.8, green: 0.7, blue: 0.5, alpha: 1), // 住宅楼
            UIColor(red: 0.3, green: 0.5, blue: 0.7, alpha: 1)  // 摩天大楼
        ]
        let mainColor = mainColors[index % mainColors.count]
        let windowColor = UIColor.yellow
        
        // 计算网格尺寸
        let totalWidth = CGFloat(perLayer) * brickSize
        let totalHeight = CGFloat(layers) * brickSize
        
        // 建筑节点置于屏幕中心
        buildingNode = SKNode()
        buildingNode.position = CGPoint(x: size.width / 2, y: size.height / 2)
        addChild(buildingNode)
        
        // 生成砖块位置（交错排列）
        var brickPositions: [CGPoint] = []
        for layer in 0..<layers {
            let offset = (layer % 2 == 0) ? 0 : brickSize/2
            let cols = (layer % 2 == 0) ? perLayer : perLayer - 1
            for col in 0..<cols {
                let x = -totalWidth/2 + CGFloat(col) * brickSize + brickSize/2 + offset
                let y = -totalHeight/2 + CGFloat(layer) * brickSize + brickSize/2
                brickPositions.append(CGPoint(x: x, y: y))
            }
        }
        // 只取前 totalBricks 个
        if brickPositions.count > totalBricks {
            brickPositions = Array(brickPositions[0..<totalBricks])
        }
        
        // 创建砖块节点（窗户随机放置）
        for (idx, pos) in brickPositions.enumerated() {
            let isWindow = (idx % 7 == 0 || idx % 11 == 0) && idx > 10 // 简单窗户分布
            let color = isWindow ? windowColor : mainColor
            let brick = SKShapeNode(rectOf: CGSize(width: brickSize-1, height: brickSize-1), cornerRadius: 1)
            brick.fillColor = color
            brick.strokeColor = UIColor(white: 0.2, alpha: 0.3)
            brick.lineWidth = 0.5
            brick.position = pos
            brick.setScale(0)
            brick.isHidden = true
            buildingNode.addChild(brick)
            brickNodes.append(brick)
        }
        
        // 绘制地基（半透明边框，方便视觉对齐）
        let foundationW = totalWidth + 30
        let foundationH = totalHeight + 30
        let origin = CGPoint(x: -foundationW/2, y: -foundationH/2)
        foundationRect = CGRect(origin: origin, size: CGSize(width: foundationW, height: foundationH))
        // 计算四个角（相对于建筑节点）
        foundationPoints = [
            CGPoint(x: origin.minX, y: origin.minY),
            CGPoint(x: origin.maxX, y: origin.minY),
            CGPoint(x: origin.maxX, y: origin.maxY),
            CGPoint(x: origin.minX, y: origin.maxY)
        ]
        // 绘制地基虚线（用多个小线段模拟）
        let foundationFill = SKShapeNode(rect: foundationRect, cornerRadius: 4)
        foundationFill.fillColor = UIColor(white: 0.9, alpha: 0.15)
        foundationFill.strokeColor = UIColor(white: 0.5, alpha: 0.3)
        foundationFill.lineWidth = 1
        buildingNode.addChild(foundationFill)
    }
    
    // MARK: - 放置点（在地基四角外侧）
    private func setupDropPoints() {
        dropPoints.forEach { $0.removeFromParent() }
        dropPoints.removeAll()
        
        let offset: CGFloat = 35
        for point in foundationPoints {
            // 将地基角转换为世界坐标（相对于建筑节点）
            let worldPos = buildingNode.convert(point, to: self)
            let dx = worldPos.x - size.width/2
            let dy = worldPos.y - size.height/2
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
    
    // MARK: - 恢复砖块进度
    private func restoreBricks() {
        let count = min(gameState.currentBrickCount, brickNodes.count)
        for i in 0..<count {
            let brick = brickNodes[i]
            brick.isHidden = false
            brick.setScale(1)
        }
        nextBrickIndex = count
    }
    
    // MARK: - 添加一块砖（动画）
    func addBrick() {
        guard nextBrickIndex < brickNodes.count else { return }
        let brick = brickNodes[nextBrickIndex]
        brick.isHidden = false
        brick.setScale(0)
        let scaleAction = SKAction.scale(to: 1, duration: 0.15)
        scaleAction.timingMode = .easeOut
        brick.run(scaleAction)
        AudioManager.playBuild()
        nextBrickIndex += 1
        gameState.addBrick()
    }
    
    // MARK: - 工人管理
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
            // 转换到世界坐标
            let worldPos = buildingNode.convert(CGPoint(x: x, y: y), to: self)
            let dx = worldPos.x - size.width/2
            let dy = worldPos.y - size.height/2
            let dist = hypot(dx, dy)
            let offset: CGFloat = 25
            let ratio = (dist + offset) / dist
            worker.position = CGPoint(
                x: size.width/2 + dx * ratio,
                y: size.height/2 + dy * ratio
            )
        }
    }
    
    // MARK: - 更新循环
    private var lastUpdate: TimeInterval = 0
    override func update(_ currentTime: TimeInterval) {
        let delta = min(currentTime - lastUpdate, 1/30)
        lastUpdate = currentTime
        let deltaCGFloat = CGFloat(delta)
        for worker in workers {
            moveWorker(worker, deltaTime: deltaCGFloat)
        }
    }
    
    // MARK: - 工人移动
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
