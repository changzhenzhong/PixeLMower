import SwiftUI
import SpriteKit

struct GameView: UIViewRepresentable {
    let scene: GameScene
    func makeUIView(context: Context) -> SKView {
        let view = SKView()
        view.presentScene(scene)
        view.ignoresSiblingOrder = true
        view.showsFPS = false
        view.showsNodeCount = false
        return view
    }
    func updateUIView(_ uiView: SKView, context: Context) { }
}

struct ContentView: View {
    let onBack: () -> Void
    @StateObject private var gameState = GameState()
    @State private var scene: GameScene?
    
    var body: some View {
        GeometryReader { geometry in
            let safeArea = geometry.safeAreaInsets
            ZStack {
                if let scene = scene {
                    GameView(scene: scene)
                        .ignoresSafeArea()
                        .onAppear {
                            scene.scaleMode = .resizeFill
                        }
                } else {
                    Color.black
                        .ignoresSafeArea()
                        .onAppear {
                            let size = UIScreen.main.bounds.size
                            let newScene = GameScene(size: size)
                            newScene.scaleMode = .resizeFill
                            newScene.gameState = gameState
                            scene = newScene
                        }
                }
                
                // UI 覆盖层
                VStack {
                    // 顶部栏：返回按钮 + 建筑信息 + 金币
                    HStack(alignment: .center, spacing: 8) {
                        // 返回主菜单按钮
                        Button(action: onBack) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(.white)
                                .padding(8)
                                .background(Color.black.opacity(0.4))
                                .clipShape(Circle())
                        }
                        .padding(.leading, 4)
                        
                        Text("🏢 \(gameState.currentBuildingName)")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white)
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                        
                        GeometryReader { proxy in
                            let progress = gameState.buildingProgress
                            ZStack(alignment: .leading) {
                                Rectangle()
                                    .fill(Color.white.opacity(0.3))
                                    .frame(height: 10)
                                    .cornerRadius(5)
                                Rectangle()
                                    .fill(Color.green)
                                    .frame(width: max(0, proxy.size.width * progress), height: 10)
                                    .cornerRadius(5)
                                    .animation(.easeInOut, value: progress)
                            }
                        }
                        .frame(width: 80, height: 10)
                        
                        Text("\(Int(gameState.buildingProgress * 100))%")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.white)
                            .frame(minWidth: 30)
                        
                        Spacer()
                        
                        Text("💰 \(gameState.coins)")
                            .font(.system(size: 18, weight: .bold, design: .monospaced))
                            .foregroundColor(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.black.opacity(0.5))
                            .cornerRadius(8)
                    }
                    .padding(.horizontal, 8)
                    .padding(.top, safeArea.top + 6)
                    .background(Color.black.opacity(0.3))
                    .cornerRadius(12)
                    .padding(.horizontal, 6)
                    
                    Spacer()
                    
                    // 底部按钮行
                    HStack(spacing: 10) {
                        Button(action: {
                            if gameState.buyWorker() {
                                scene?.addOneWorker()
                            }
                        }) {
                            VStack(spacing: 2) {
                                Text("👷 +1")
                                    .font(.system(size: 14, weight: .bold))
                                Text("💰\(gameState.workerCost)")
                                    .font(.system(size: 10))
                            }
                            .padding(6)
                            .frame(width: 60)
                            .background(gameState.coins >= gameState.workerCost ? Color.blue.opacity(0.7) : Color.gray.opacity(0.5))
                            .foregroundColor(.white)
                            .cornerRadius(8)
                        }
                        .disabled(gameState.coins < gameState.workerCost)
                        
                        Button(action: {
                            if gameState.buySpeed() {
                                scene?.updateSpeed()
                            }
                        }) {
                            VStack(spacing: 2) {
                                Text("⚡ +1")
                                    .font(.system(size: 14, weight: .bold))
                                Text("💰\(gameState.speedCost)")
                                    .font(.system(size: 10))
                            }
                            .padding(6)
                            .frame(width: 60)
                            .background(gameState.coins >= gameState.speedCost ? Color.green.opacity(0.7) : Color.gray.opacity(0.5))
                            .foregroundColor(.white)
                            .cornerRadius(8)
                        }
                        .disabled(gameState.coins < gameState.speedCost)
                        
                        if gameState.isBuildingComplete {
                            if !gameState.allBuildingsUnlocked {
                                Button(action: {
                                    if gameState.unlockNextBuilding() {
                                        scene?.switchToBuilding(gameState.currentBuildingIndex)
                                    }
                                }) {
                                    VStack(spacing: 2) {
                                        Text("🚀 下一关")
                                            .font(.system(size: 14, weight: .bold))
                                        Text("💰\(gameState.nextBuildingCost)")
                                            .font(.system(size: 10))
                                    }
                                    .padding(6)
                                    .frame(width: 70)
                                    .background(gameState.coins >= gameState.nextBuildingCost ? Color.purple.opacity(0.7) : Color.gray.opacity(0.5))
                                    .foregroundColor(.white)
                                    .cornerRadius(8)
                                }
                                .disabled(gameState.coins < gameState.nextBuildingCost)
                            } else {
                                Text("🏆 全解锁")
                                    .font(.system(size: 12, weight: .bold))
                                    .padding(6)
                                    .frame(width: 70)
                                    .background(Color.yellow.opacity(0.5))
                                    .foregroundColor(.white)
                                    .cornerRadius(8)
                            }
                        } else {
                            Text("🔨 建造中")
                                .font(.system(size: 12, weight: .bold))
                                .padding(6)
                                .frame(width: 70)
                                .background(Color.orange.opacity(0.5))
                                .foregroundColor(.white)
                                .cornerRadius(8)
                        }
                    }
                    .padding(.bottom, safeArea.bottom + 12)
                    .padding(.horizontal, 6)
                    .background(Color.black.opacity(0.3))
                    .cornerRadius(12)
                }
            }
        }
        .preferredColorScheme(.dark)
    }
}

// MARK: - GameState（不变）
class GameState: ObservableObject {
    @Published var coins: Int = 0
    @Published var workerCount: Int = 1
    @Published var speedLevel: Int = 1
    
    @Published var currentBuildingIndex: Int = 0
    @Published var unlockedBuildings: [Bool] = [true, false, false]
    @Published var currentBuildingName: String = "小屋"
    @Published var currentBrickCount: Int = 0
    @Published var totalBrickCount: Int = 100
    
    private let buildings: [(name: String, cost: Int, totalBricks: Int, brickSize: CGFloat, layers: Int, perLayer: Int)] = [
        ("小屋", 0, 100, 10, 10, 10),
        ("住宅楼", 100, 300, 8, 15, 20),
        ("摩天大楼", 500, 500, 6, 20, 25)
    ]
    
    var buildingProgress: Double {
        totalBrickCount > 0 ? Double(currentBrickCount) / Double(totalBrickCount) : 0
    }
    
    var isBuildingComplete: Bool {
        currentBrickCount >= totalBrickCount
    }
    
    var allBuildingsUnlocked: Bool {
        unlockedBuildings.allSatisfy { $0 }
    }
    
    var nextBuildingCost: Int {
        guard let nextIndex = unlockedBuildings.firstIndex(where: { !$0 }) else { return 0 }
        return buildings[nextIndex].cost
    }
    
    var currentBonus: Int {
        return currentBuildingIndex + 1
    }
    
    func getCurrentBuildingStyle() -> (totalBricks: Int, brickSize: CGFloat, layers: Int, perLayer: Int) {
        let data = buildings[currentBuildingIndex]
        return (data.totalBricks, data.brickSize, data.layers, data.perLayer)
    }
    
    func unlockNextBuilding() -> Bool {
        guard let index = unlockedBuildings.firstIndex(where: { !$0 }) else { return false }
        let cost = buildings[index].cost
        guard coins >= cost else { return false }
        coins -= cost
        unlockedBuildings[index] = true
        currentBuildingIndex = index
        currentBuildingName = buildings[index].name
        let style = getCurrentBuildingStyle()
        totalBrickCount = style.totalBricks
        currentBrickCount = 0
        AudioManager.playUnlock()
        return true
    }
    
    func switchToBuilding(index: Int) {
        guard index < unlockedBuildings.count && unlockedBuildings[index] else { return }
        currentBuildingIndex = index
        currentBuildingName = buildings[index].name
        let style = getCurrentBuildingStyle()
        totalBrickCount = style.totalBricks
        currentBrickCount = 0
    }
    
    func addBrick() {
        guard currentBrickCount < totalBrickCount else { return }
        currentBrickCount += 1
        if isBuildingComplete {
            AudioManager.playUnlock()
        }
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
