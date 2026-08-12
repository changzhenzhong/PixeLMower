import SpriteKit
import UIKit
import SwiftUI

// MARK: - 游戏状态（跨场景共享）
class GameState: ObservableObject {
    @Published var level = 1
    @Published var expProgress: Double = 0
    @Published var killCount = 0
    @Published var playerHP: CGFloat = 100
    @Published var maxPlayerHP: CGFloat = 100
    var onLevelUp: (([UpgradeOption]) -> Void)? = nil
    var onPlayerDamaged: (() -> Void)? = nil
    var onPlayerDeath: (() -> Void)? = nil

    // 玩家属性（增量成长）
    var attackDamage: CGFloat = 25
    var attackSpeed: CGFloat = 2.0
    var attackRange: CGFloat = 60
    var moveSpeed: CGFloat = 180
    var bladeCount: Int = 2
    var expMultiplier: CGFloat = 1.0
    var critChance: Double = 0.05
    var critMultiplier: CGFloat = 2.0
    var invincibleDuration: TimeInterval = 0.5

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
        case "hp": maxPlayerHP *= 1.3; playerHP = maxPlayerHP
        default: break
        }
    }

    func takeDamage(_ amount: CGFloat) {
        playerHP = max(0, playerHP - amount)
        onPlayerDamaged?()
        if playerHP <= 0 {
            onPlayerDeath?()
        }
    }

    func heal(_ amount: CGFloat) {
        playerHP = min(maxPlayerHP, playerHP + amount)
    }

    func reset() {
        level = 1
        expProgress = 0
        killCount = 0
        playerHP = maxPlayerHP
        attackDamage = 25
        attackSpeed = 2.0
        attackRange = 60
        moveSpeed = 180
        bladeCount = 2
        expMultiplier = 1.0
        critChance = 0.05
        critMultiplier = 2.0
        totalExp = 0
        expToNext = 50
        upgradeLevels = [:]
    }
}

// MARK: - 游戏场景
class GameScene: SKScene {
    weak var gameState: GameState!
    private var player: SKSpriteNode!
    private var blades: [SKSpriteNode] = []
    private var bladeAngle: CGFloat = 0
    private var lastUpdateTime: TimeInterval = 0
    private var enemySpawnTimer: TimeInterval = 0
    private var spawnInterval: TimeInterval = 0.8
    private var gameTime: TimeInterval = 0
    private var cameraNode: SKCameraNode!
    private var isGamePaused = false

    // 动态摇杆
    private var touchStartPosition: CGPoint?
    private var moveDirection = CGVector.zero
    private var isMoving = false
    private var lastDamageTime: TimeInterval = 0

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

        updateBlades()

        physicsBody = SKPhysicsBody(edgeLoopFrom: frame)
        physicsBody?.friction = 0

        lastDamageTime = 0
    }

    func pauseGame() {
        isGamePaused = true
    }

    func resumeGame() {
        isGamePaused = false
        lastUpdateTime = 0
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

    private func updateBlades() {
        for blade in blades { blade.removeFromParent() }
        blades.removeAll()
        let count = gameState.bladeCount
        for _ in 0..<count {
            let bladeTex = PixelTextureGenerator.generateBladeTexture(size: 8)
            bladeTex.filteringMode = .nearest
            let blade = SKSpriteNode(texture: bladeTex)
            blade.setScale(2.5)
            blade.name = "blade"
            blade.zPosition = 9
            blade.physicsBody = SKPhysicsBody(rectangleOf: CGSize(width: 24, height: 8))
            blade.physicsBody?.affectedByGravity = false
            blade.physicsBody?.categoryBitMask = 0x2
            blade.physicsBody?.contactTestBitMask = 0x4
            blade.physicsBody?.collisionBitMask = 0
            addChild(blade)
            blades.append(blade)
        }
    }

    private func spawnEnemy() {
        let tex = PixelTextureGenerator.generateEnemyTexture(size: 12)
        tex.filteringMode = .nearest
        let enemy = SKSpriteNode(texture: tex)
        enemy.setScale(2.5)
        enemy.name = "enemy"
        enemy.zPosition = 5

        let margin: CGFloat = 40
        let side = Int.random(in: 0...3)
        var pos = CGPoint.zero
        switch side {
        case 0: pos = CGPoint(x: CGFloat.random(in: -size.width/2...size.width/2), y: size.height/2 + margin)
        case 1: pos = CGPoint(x: CGFloat.random(in: -size.width/2...size.width/2), y: -size.height/2 - margin)
        case 2: pos = CGPoint(x: -size.width/2 - margin, y: CGFloat.random(in: -size.height/2...size.height/2))
        default: pos = CGPoint(x: size.width/2 + margin, y: CGFloat.random(in: -size.height/2...size.height/2))
        }
        enemy.position = pos

        let hp: CGFloat = 20 + CGFloat(gameTime / 10) * 8
        enemy.userData = ["hp": hp, "maxHp": hp, "speed": CGFloat.random(in: 40...90)]
        enemy.physicsBody = SKPhysicsBody(circleOfRadius: 14)
        enemy.physicsBody?.affectedByGravity = false
        enemy.physicsBody?.categoryBitMask = 0x4
        enemy.physicsBody?.contactTestBitMask = 0x1 | 0x2
        enemy.physicsBody?.collisionBitMask = 0
        addChild(enemy)
    }

    private func spawnExpOrb(at position: CGPoint) {
        let orb = SKShapeNode(circleOfRadius: 5)
        orb.fillColor = SKColor(red: 0.2, green: 1.0, blue: 0.5, alpha: 0.9)
        orb.strokeColor = .clear
        orb.position = position
        orb.zPosition = 4
        orb.name = "expOrb"
        orb.physicsBody = SKPhysicsBody(circleOfRadius: 5)
        orb.physicsBody?.affectedByGravity = false
        orb.physicsBody?.categoryBitMask = 0x8
        orb.physicsBody?.contactTestBitMask = 0x1
        orb.physicsBody?.collisionBitMask = 0
        addChild(orb)

        let moveAction = SKAction.move(to: player.position, duration: 1.5)
        let fadeAction = SKAction.fadeOut(withDuration: 4)
        let removeAction = SKAction.removeFromParent()
        orb.run(SKAction.sequence([SKAction.group([moveAction, fadeAction]), removeAction]))
    }

    private func spawnPixelParticles(at position: CGPoint, color: SKColor) {
        for _ in 0..<6 {
            let particle = SKSpriteNode(color: color, size: CGSize(width: 4, height: 4))
            particle.position = position
            particle.zPosition = 15
            addChild(particle)
            let dx = CGFloat.random(in: -50...50)
            let dy = CGFloat.random(in: -50...50)
            let move = SKAction.moveBy(x: dx, y: dy, duration: 0.4)
            let fade = SKAction.fadeOut(withDuration: 0.4)
            let remove = SKAction.removeFromParent()
            particle.run(SKAction.sequence([SKAction.group([move, fade]), remove]))
        }
    }

    override func update(_ currentTime: TimeInterval) {
        if isGamePaused {
            lastUpdateTime = 0
            return
        }
        if lastUpdateTime == 0 { lastUpdateTime = currentTime; return }
        let dt = currentTime - lastUpdateTime
        lastUpdateTime = currentTime
        gameTime += dt

        // 移动玩家
        if isMoving {
            let speed = gameState.moveSpeed
            let dx = moveDirection.dx * speed * CGFloat(dt)
            let dy = moveDirection.dy * speed * CGFloat(dt)
            player.position.x += dx
            player.position.y += dy
            let halfW = size.width / 2 - 30
            let halfH = size.height / 2 - 30
            player.position.x = max(-halfW, min(halfW, player.position.x))
            player.position.y = max(-halfH, min(halfH, player.position.y))
        }

        // 旋转剑
        bladeAngle += gameState.attackSpeed * CGFloat(dt) * 6
        let range = gameState.attackRange
        for (i, blade) in blades.enumerated() {
            let angleOffset = CGFloat(i) * (2 * .pi / CGFloat(blades.count))
            let angle = bladeAngle + angleOffset
            blade.position = CGPoint(
                x: player.position.x + cos(angle) * range,
                y: player.position.y + sin(angle) * range
            )
            blade.zRotation = angle + .pi / 2
        }

        // 敌人生成
        enemySpawnTimer += dt
        if enemySpawnTimer >= spawnInterval {
            enemySpawnTimer = 0
            spawnEnemy()
            if Int(gameTime) % 15 == 0 && spawnInterval > 0.2 {
                spawnInterval -= 0.05
            }
        }

        // 敌人AI + 碰撞伤害
        for node in children where node.name == "enemy" {
            guard let data = node.userData,
                  let speed = data["speed"] as? CGFloat else { continue }
            let dx = player.position.x - node.position.x
            let dy = player.position.y - node.position.y
            let dist = hypot(dx, dy)
            if dist > 1 {
                node.position.x += (dx / dist) * speed * CGFloat(dt)
                node.position.y += (dy / dist) * speed * CGFloat(dt)
            }

            // 敌人碰到玩家造成伤害
            if dist < 35 && currentTime - lastDamageTime > gameState.invincibleDuration {
                gameState.takeDamage(15)
                lastDamageTime = currentTime
                spawnPixelParticles(at: player.position, color: .orange)
            }
        }

        // 剑与敌人碰撞检测
        var enemiesToRemove: [SKNode] = []
        for blade in blades {
            for enemy in children where enemy.name == "enemy" {
                let dist = hypot(blade.position.x - enemy.position.x, blade.position.y - enemy.position.y)
                if dist < 30 {
                    var damage = gameState.attackDamage
                    let isCrit = Double.random(in: 0...1) < gameState.critChance
                    if isCrit { damage *= gameState.critMultiplier }
                    var hp = (enemy.userData?["hp"] as? CGFloat) ?? 0
                    hp -= damage * CGFloat(dt) * 3
                    enemy.userData?["hp"] = hp
                    if hp <= 0 && !enemiesToRemove.contains(enemy) {
                        enemiesToRemove.append(enemy)
                    }
                }
            }
        }

        for enemy in enemiesToRemove {
            spawnExpOrb(at: enemy.position)
            spawnPixelParticles(at: enemy.position, color: .red)
            enemy.removeFromParent()
            gameState.killCount += 1
        }

        // 经验球收集
        for orb in children where orb.name == "expOrb" {
            let dist = hypot(orb.position.x - player.position.x, orb.position.y - player.position.y)
            if dist < 30 {
                gameState.addExperience(10)
                gameState.heal(2)
                orb.removeFromParent()
            }
        }

        // 清理离屏敌人
        for enemy in children where enemy.name == "enemy" {
            if abs(enemy.position.x) > size.width + 200 || abs(enemy.position.y) > size.height + 200 {
                enemy.removeFromParent()
            }
        }

        // 更新刀片数量
        if blades.count != gameState.bladeCount {
            updateBlades()
        }
    }

    // MARK: - 动态摇杆触摸处理
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        touchStartPosition = location
        isMoving = true
        moveDirection = .zero
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard isMoving, let touch = touches.first, let start = touchStartPosition else { return }
        let location = touch.location(in: self)
        let dx = location.x - start.x
        let dy = location.y - start.y
        let dist = hypot(dx, dy)
        let maxDist: CGFloat = 50
        if dist > 5 {
            let clampedDx = dx / maxDist
            let clampedDy = dy / maxDist
            let mag = hypot(clampedDx, clampedDy)
            if mag > 1 {
                moveDirection = CGVector(dx: clampedDx/mag, dy: clampedDy/mag)
            } else {
                moveDirection = CGVector(dx: clampedDx, dy: clampedDy)
            }
        } else {
            moveDirection = .zero
        }
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        isMoving = false
        moveDirection = .zero
        touchStartPosition = nil
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        isMoving = false
        moveDirection = .zero
        touchStartPosition = nil
    }
}
