import SpriteKit
import UIKit

// MARK: - 游戏状态（跨场景共享）
class GameState: ObservableObject {
    @Published var level = 1
    @Published var expProgress: Double = 0
    @Published var killCount = 0
    var onLevelUp: (([UpgradeOption]) -> Void)? = nil

    // 玩家属性（增量成长）
    var attackDamage: CGFloat = 25
    var attackSpeed: CGFloat = 2.0
    var attackRange: CGFloat = 60
    var moveSpeed: CGFloat = 180
    var bladeCount: Int = 2
    var expMultiplier: CGFloat = 1.0
    var critChance: Double = 0.05
    var critMultiplier: CGFloat = 2.0
    var maxHP: CGFloat = 100
    var currentHP: CGFloat = 100

    private var expToNext: CGFloat = 50
    private var totalExp: CGFloat = 0
    private var upgradeLevels: [String: Int] = [:]

    func addExperience(_ amount: CGFloat) {
        let adjusted = amount * expMultiplier
        totalExp += adjusted
        let required = expToNext
        if totalExp >= required {
            totalExp -= required
            level += 1
            expToNext = CGFloat(50 + (level - 1) * 25)
            expProgress = 0
            let options = UpgradeManager.generateOptions(currentLevels: upgradeLevels, count: 3)
            DispatchQueue.main.async { [weak self] in
                self?.onLevelUp?(options)
            }
        } else {
            expProgress = Double(totalExp / expToNext)
        }
    }

    func applyUpgrade(_ option: UpgradeOption) {
        upgradeLevels[option.id, default: 0] += 1
        switch option.id {
        case "damage": attackDamage *= 1.25
        case "speed": attackSpeed *= 1.2
        case "range": attackRange *= 1.2
        case "move": moveSpeed *= 1.12
        case "blades": bladeCount += 1
        case "exp": expMultiplier *= 1.25
        case "crit": critChance = min(critChance + 0.06, 0.5)
        case "hp": maxHP *= 1.3; currentHP = maxHP
        default: break
        }
    }
}

// MARK: - 游戏场景
class GameScene: SKScene {
    weak var gameState: GameState!
    private var player: SKSpriteNode!
    private var joystickBase: SKShapeNode!
    private var joystickKnob: SKShapeNode!
    private var moveDirection = CGVector.zero
    private var isMoving = false
    private var blades: [SKSpriteNode] = []
    private var bladeAngle: CGFloat = 0
    private var lastUpdateTime: TimeInterval = 0
    private var enemySpawnTimer: TimeInterval = 0
    private var spawnInterval: TimeInterval = 0.8
    private var gameTime: TimeInterval = 0
    private var cameraNode: SKCameraNode!

    override func didMove(to view: SKView) {
        backgroundColor = SKColor(red: 0.08, green: 0.08, blue: 0.15, alpha: 1.0)
        anchorPoint = CGPoint(x: 0.5, y: 0.5)

        cameraNode = SKCameraNode()
        camera = cameraNode
        addChild(cameraNode)

        createPixelBackground()
        player = createPixelPlayer()
        player.position = .zero
        addChild(player)

        setupJoystick()
        updateBlades()

        physicsBody = SKPhysicsBody(edgeLoopFrom: frame)
        physicsBody?.friction = 0
    }

    private func createPixelBackground() {
        let tileSize: CGFloat = 32
        let cols = Int(size.width / tileSize) + 2
        let rows = Int(size.height / tileSize) + 2
        for col in 0..<cols {
            for row in 0..<rows {
                let alpha = CGFloat.random(in: 0.01...0.04)
                let tile = SKSpriteNode(color: SKColor(white: 1.0, alpha: alpha),
                                       size: CGSize(width: tileSize, height: tileSize))
                tile.position = CGPoint(
                    x: (CGFloat(col) - CGFloat(cols)/2) * tileSize,
                    y: (CGFloat(row) - CGFloat(rows)/2) * tileSize
                )
                tile.texture?.filteringMode = .nearest
                addChild(tile)
            }
        }
    }

    private func createPixelPlayer() -> SKSpriteNode {
        let tex = PixelTextureGenerator.generatePlayerTexture(size: 16)
        tex.filteringMode = .nearest
        let node = SKSpriteNode(texture: tex)
        node.setScale(3.0)
        node.name = "player"
        node.zPosition = 10
        node.physicsBody = SKPhysicsBody(circleOfRadius: 20)
        node.physicsBody?.affectedByGravity = false
        node.physicsBody?.categoryBitMask = 0x1
        node.physicsBody?.contactTestBitMask = 0x4
        node.physicsBody?.collisionBitMask = 0
        return node
    }

    private func setupJoystick() {
        let baseRadius: CGFloat = 50
        joystickBase = SKShapeNode(circleOfRadius: baseRadius)
        joystickBase.fillColor = SKColor(white: 1.0, alpha: 0.1)
        joystickBase.strokeColor = SKColor(white: 1.0, alpha: 0.3)
        joystickBase.lineWidth = 2
        joystickBase.zPosition = 100
        joystickBase.position = CGPoint(x: -size.width/2 + 80, y: -size.height/2 + 100)
        cameraNode.addChild(joystickBase)

        joystickKnob = SKShapeNode(circleOfRadius: 22)
        joystickKnob.fillColor = SKColor(white: 1.0, alpha: 0.5)
        joystickKnob.simport SpriteKit
import UIKit

// MARK: - 游戏状态（跨场景共享）
class GameState: ObservableObject {
    @Published var level = 1
    @Published var expProgress: Double = 0
    @Published var killCount = 0
    var onLevelUp: (([UpgradeOption]) -> Void)? = nil

    // 玩家属性（增量成长）
    var attackDamage: CGFloat = 25
    var attackSpeed: CGFloat = 2.0
    var attackRange: CGFloat = 60
    var moveSpeed: CGFloat = 180
    var bladeCount: Int = 2
    var expMultiplier: CGFloat = 1.0
    var critChance: Double = 0.05
    var critMultiplier: CGFloat = 2.0
    var maxHP: CGFloat = 100
    var currentHP: CGFloat = 100

    private var expToNext: CGFloat = 50
    private var totalExp: CGFloat = 0
    private var upgradeLevels: [String: Int] = [:]

    func addExperience(_ amount: CGFloat) {
        let adjusted = amount * expMultiplier
        totalExp += adjusted
        let required = expToNext
        if totalExp >= required {
            totalExp -= required
            level += 1
            expToNext = CGFloat(50 + (level - 1) * 25)
            expProgress = 0
            let options = UpgradeManager.generateOptions(currentLevels: upgradeLevels, count: 3)
            DispatchQueue.main.async { [weak self] in
                self?.onLevelUp?(options)
            }
        } else {
            expProgress = Double(totalExp / expToNext)
        }
    }

    func applyUpgrade(_ option: UpgradeOption) {
        upgradeLevels[option.id, default: 0] += 1
        switch option.id {
        case "damage": attackDamage *= 1.25
        case "speed": attackSpeed *= 1.2
        case "range": attackRange *= 1.2
        case "move": moveSpeed *= 1.12
        case "blades": bladeCount += 1
        case "exp": expMultiplier *= 1.25
        case "crit": critChance = min(critChance + 0.06, 0.5)
        case "hp": maxHP *= 1.3; currentHP = maxHP
        default: break
        }
    }
}

// MARK: - 游戏场景
class GameScene: SKScene {
    weak var gameState: GameState!
    private var player: SKSpriteNode!
    private var joystickBase: SKShapeNode!
    private var joystickKnob: SKShapeNode!
    private var moveDirection = CGVector.zero
    private var isMoving = false
    private var blades: [SKSpriteNode] = []
    private var bladeAngle: CGFloat = 0
    private var lastUpdateTime: TimeInterval = 0
    private var enemySpawnTimer: TimeInterval = 0
    private var spawnInterval: TimeInterval = 0.8
    private var gameTime: TimeInterval = 0
    private var cameraNode: SKCameraNode!

    override func didMove(to view: SKView) {
        backgroundColor = SKColor(red: 0.08, green: 0.08, blue: 0.15, alpha: 1.0)
        anchorPoint = CGPoint(x: 0.5, y: 0.5)

        cameraNode = SKCameraNode()
        camera = cameraNode
        addChild(cameraNode)

        createPixelBackground()
        player = createPixelPlayer()
        player.position = .zero
        addChild(player)

        setupJoystick()
        updateBlades()

        physicsBody = SKPhysicsBody(edgeLoopFrom: frame)
        physicsBody?.friction = 0
    }

    private func createPixelBackground() {
        let tileSize: CGFloat = 32
        let cols = Int(size.width / tileSize) + 2
        let rows = Int(size.height / tileSize) + 2
        for col in 0..<cols {
            for row in 0..<rows {
                let alpha = CGFloat.random(in: 0.01...0.04)
                let tile = SKSpriteNode(color: SKColor(white: 1.0, alpha: alpha),
                                       size: CGSize(width: tileSize, height: tileSize))
                tile.position = CGPoint(
                    x: (CGFloat(col) - CGFloat(cols)/2) * tileSize,
                    y: (CGFloat(row) - CGFloat(rows)/2) * tileSize
                )
                tile.texture?.filteringMode = .nearest
                addChild(tile)
            }
        }
    }

    private func createPixelPlayer() -> SKSpriteNode {
        let tex = PixelTextureGenerator.generatePlayerTexture(size: 16)
        tex.filteringMode = .nearest
        let node = SKSpriteNode(texture: tex)
        node.setScale(3.0)
        node.name = "player"
        node.zPosition = 10
        node.physicsBody = SKPhysicsBody(circleOfRadius: 20)
        node.physicsBody?.affectedByGravity = false
        node.physicsBody?.categoryBitMask = 0x1
        node.physicsBody?.contactTestBitMask = 0x4
        node.physicsBody?.collisionBitMask = 0
        return node
    }

    private func setupJoystick() {
        let baseRadius: CGFloat = 50
        joystickBase = SKShapeNode(circleOfRadius: baseRadius)
        joystickBase.fillColor = SKColor(white: 1.0, alpha: 0.1)
        joystickBase.strokeColor = SKColor(white: 1.0, alpha: 0.3)
        joystickBase.lineWidth = 2
        joystickBase.zPosition = 100
        joystickBase.position = CGPoint(x: -size.width/2 + 80, y: -size.height/2 + 100)
        cameraNode.addChild(joystickBase)

        joystickKnob = SKShapeNode(circleOfRadius: 22)
        joystickKnob.fillColor = SKColor(white: 1.0, alpha: 0.5)
        joystickKnob.s
