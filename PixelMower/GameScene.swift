import SpriteKit

// MARK: - 游戏状态（可观察）
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

// MARK: - 工人节点
class WorkerNode: SKNode {
    let moveSpeed: CGFloat        // 改名，避免与 SKNode.speed 冲突
    var state: State = .goingToBrick
    enum State {
        case goingToBrick
        case goingToDrop
    }

    init(moveSpeed: CGFloat) {
        self.moveSpeed = moveSpeed
        super.init()
        let size = CGSize(width: 10, height: 10)
        let rect = SKShapeNode(rectOf: size, cornerRadius: 2)
        rect.fillColor = .orange
        rect.strokeColor = .black
        rect.lineWidth = 1
        addChild(rect)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

// MARK: - 游戏场景
class GameScene: SKScene {
    // 注入游戏状态
    weak var gameState: GameState!

    // 场景元素
    private var building: SKShapeNode!
    private var brickPile: SKSpriteNode!
    private var dropPoint: SKSpriteNode!

    // 工人管理
    private var workers: [WorkerNode] = []

    // 建筑相关参数
    private let buildingSize = CGSize(width: 80, height: 80)
    private let orbitRadius: CGFloat = 100

    override func didMove(to view: SKView) {
        backgroundColor = .darkGray

        building = SKShapeNode(rectOf: buildingSize, cornerRadius: 4)
        building.fillColor = .brown
        building.strokeColor = .black
        building.lineWidth = 2
        building.position = CGPoint(x: size.width / 2, y: size.height / 2)
        addChild(building)

        let brickSize = CGSize(width: 30, height: 30)
        brickPile = SKSpriteNode(color: .red, size: brickSize)
        brickPile.position = CGPoint(x: 60, y: 60)
        addChild(brickPile)

        dropPoint = SKSpriteNode(color: .green, size: brickSize)
        dropPoint.position = CGPoint(x: size.width - 60, y: 60)
        addChild(dropPoint)

        spawnWorkers(count: gameState.workerCount)
    }

    // MARK: - 生成工人
    private func spawnWorkers(count: Int) {
        workers.forEach { $0.removeFromParent() }
        workers.removeAll()

        let baseSpeed: CGFloat = 50.0
        let speedMultiplier = 1.0 + CGFloat(gameState.speedLevel - 1) * 0.2

        for i in 0..<count {
            let angle = (CGFloat(i) / CGFloat(count)) * CGFloat.pi * 2
            let x = size.width / 2 + orbitRadius * cos(angle)
            let y = size.height / 2 + orbitRadius * sin(angle)
            let speed = baseSpeed * speedMultiplier
            let worker = WorkerNode(moveSpeed: speed)
            worker.position = CGPoint(x: x, y: y)
            worker.state = Bool.random() ? .goingToBrick : .goingToDrop
            addChild(worker)
            workers.append(worker)
        }
    }

    func refreshWorkers() {
        spawnWorkers(count: gameState.workerCount)
    }

    func refreshSpeed() {
        // 重建所有工人（速度更新）
        spawnWorkers(count: gameState.workerCount)
    }

    // MARK: - 更新循环
    override func update(_ currentTime: TimeInterval) {
        let delta = 1/60.0   // 固定步长，足够简单
        for worker in workers {
            moveWorker(worker, deltaTime: delta)
        }
    }

    private func moveWorker(_ worker: WorkerNode, deltaTime: CGFloat) {
        let step = worker.moveSpeed * deltaTime

        let target: CGPoint
        switch worker.state {
        case .goingToBrick:
            target = brickPile.position
        case .goingToDrop:
            target = dropPoint.position
        }

        let dx = target.x - worker.position.x
        let dy = target.y - worker.position.y
        let distance = hypot(dx, dy)

        if distance < step {
            worker.position = target
            switch worker.state {
            case .goingToBrick:
                worker.state = .goingToDrop
                if let rect = worker.children.first as? SKShapeNode {
                    rect.fillColor = .yellow
                }
            case .goingToDrop:
                worker.state = .goingToBrick
                if let rect = worker.children.first as? SKShapeNode {
                    rect.fillColor = .orange
                }
                gameState.coins += 1
            }
        } else {
            let ratio = step / distance
            worker.position.x += dx * ratio
            worker.position.y += dy * ratio
        }
    }
}
