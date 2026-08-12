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
    let speed: CGFloat
    var state: State = .goingToBrick
    enum State {
        case goingToBrick
        case goingToDrop
    }

    init(speed: CGFloat) {
        self.speed = speed
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
    private var brickPile: SKSpriteNode!   // 砖堆位置
    private var dropPoint: SKSpriteNode!   // 放置点位置

    // 工人管理
    private var workers: [WorkerNode] = []
    private var lastSpawnTime: TimeInterval = 0

    // 建筑相关参数（固定）
    private let buildingSize = CGSize(width: 80, height: 80)
    private let orbitRadius: CGFloat = 100   // 工人绕建筑转圈的半径

    override func didMove(to view: SKView) {
        backgroundColor = .darkGray

        // 1. 绘制建筑（中心）
        building = SKShapeNode(rectOf: buildingSize, cornerRadius: 4)
        building.fillColor = .brown
        building.strokeColor = .black
        building.lineWidth = 2
        building.position = CGPoint(x: size.width / 2, y: size.height / 2)
        addChild(building)

        // 2. 砖堆（左下角）
        let brickSize = CGSize(width: 30, height: 30)
        brickPile = SKSpriteNode(color: .red, size: brickSize)
        brickPile.position = CGPoint(x: 60, y: 60)
        addChild(brickPile)

        // 3. 放置点（右下角）
        dropPoint = SKSpriteNode(color: .green, size: brickSize)
        dropPoint.position = CGPoint(x: size.width - 60, y: 60)
        addChild(dropPoint)

        // 初始化工人
        spawnWorkers(count: gameState.workerCount)
    }

    // MARK: - 生成工人
    private func spawnWorkers(count: Int) {
        // 清除旧工人
        workers.forEach { $0.removeFromParent() }
        workers.removeAll()

        let baseSpeed: CGFloat = 50.0   // 基础速度
        let speedMultiplier = 1.0 + CGFloat(gameState.speedLevel - 1) * 0.2

        for i in 0..<count {
            let angle = (CGFloat(i) / CGFloat(count)) * CGFloat.pi * 2
            let x = size.width / 2 + orbitRadius * cos(angle)
            let y = size.height / 2 + orbitRadius * sin(angle)
            let speed = baseSpeed * speedMultiplier
            let worker = WorkerNode(speed: speed)
            worker.position = CGPoint(x: x, y: y)
            // 随机初始状态
            worker.state = Bool.random() ? .goingToBrick : .goingToDrop
            addChild(worker)
            workers.append(worker)
        }
    }

    // 对外接口：刷新工人（升级数量时调用）
    func refreshWorkers() {
        spawnWorkers(count: gameState.workerCount)
    }

    // 对外接口：刷新速度（升级速度时调用）
    func refreshSpeed() {
        // 只需更新每个工人的速度属性
        let baseSpeed: CGFloat = 50.0
        let speedMultiplier = 1.0 + CGFloat(gameState.speedLevel - 1) * 0.2
        for worker in workers {
            // 由于 WorkerNode 的 speed 是 let，我们重新创建工人会更简单
            // 这里直接重建所有工人（保持数量不变）
            spawnWorkers(count: gameState.workerCount)
        }
    }

    // MARK: - 更新循环
    override func update(_ currentTime: TimeInterval) {
        // 让每个工人执行任务
        for worker in workers {
            moveWorker(worker, deltaTime: 1/60)   // 假设固定时间步长，实际可用帧间隔，为简单用固定值
        }
    }

    // 简化移动：每帧移动一小步，并检测是否到达目标点，切换状态
    private func moveWorker(_ worker: WorkerNode, deltaTime: CGFloat) {
        let step = worker.speed * deltaTime

        // 获取当前目标位置
        let target: CGPoint
        switch worker.state {
        case .goingToBrick:
            target = brickPile.position
        case .goingToDrop:
            target = dropPoint.position
        }

        // 朝向目标移动
        let dx = target.x - worker.position.x
        let dy = target.y - worker.position.y
        let distance = hypot(dx, dy)

        if distance < step {
            // 到达目标
            worker.position = target
            // 切换状态并触发事件
            switch worker.state {
            case .goingToBrick:
                worker.state = .goingToDrop
                // 拿起砖（显示效果，这里只是简单改变颜色）
                if let rect = worker.children.first as? SKShapeNode {
                    rect.fillColor = .yellow   // 表示拿着砖
                }
            case .goingToDrop:
                worker.state = .goingToBrick
                // 放下砖 -> 获得金币
                if let rect = worker.children.first as? SKShapeNode {
                    rect.fillColor = .orange   // 恢复原色
                }
                // 加金币
                gameState.coins += 1
                // 可选：播放一个小动画或粒子效果
            }
        } else {
            // 继续移动
            let ratio = step / distance
            worker.position.x += dx * ratio
            worker.position.y += dy * ratio
        }
    }

    // 为了更平滑，可以重写 didSimulatePhysics 或使用固定时间步长，但以上简化足够。
}
