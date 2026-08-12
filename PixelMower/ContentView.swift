import SwiftUI
import SpriteKit

// MARK: - 游戏状态（可观察，自动刷新 UI）
class GameState: ObservableObject {
    @Published var coins: Int = 0
    @Published var workerCount: Int = 1
    @Published var speedLevel: Int = 1

    // 升级成本（可根据需要调整公式）
    var workerCost: Int { 10 + workerCount * 5 }
    var speedCost: Int { 5 + speedLevel * 3 }

    /// 购买一名新工人
    func buyWorker() -> Bool {
        guard coins >= workerCost else { return false }
        coins -= workerCost
        workerCount += 1
        return true
    }

    /// 升级移动速度
    func buySpeed() -> Bool {
        guard coins >= speedCost else { return false }
        coins -= speedCost
        speedLevel += 1
        return true
    }
}

// MARK: - SpriteKit 容器
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

    func updateUIView(_ uiView: SKView, context: Context) {
        // 无需更新
    }
}

// MARK: - 主界面
struct ContentView: View {
    @StateObject private var gameState = GameState()
    @State private var scene: GameScene?

    var body: some View {
        ZStack {
            // 游戏场景
            if let scene = scene {
                GameView(scene: scene)
                    .ignoresSafeArea()
            } else {
                Color.black
                    .ignoresSafeArea()
                    .onAppear {
                        let size = UIScreen.main.bounds.size
                        let newScene = GameScene(size: size)
                        newScene.gameState = gameState   // 注入状态
                        scene = newScene
                    }
            }

            // UI 覆盖层
            VStack {
                HStack {
                    Text("💰 \(gameState.coins)")
                        .font(.system(size: 28, weight: .bold, design: .monospaced))
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color.black.opacity(0.6))
                        .cornerRadius(12)
                        .padding(.top, 40)
                    Spacer()
                }

                Spacer()

                HStack(spacing: 16) {
                    // 升级工人按钮
                    Button(action: {
                        if gameState.buyWorker() {
                            // 若场景需要即时刷新，可调用相应方法（以下为预留）
                            // scene?.refreshWorkers()
                        }
                    }) {
                        VStack {
                            Text("👷 升级工人")
                            Text("\(gameState.workerCount) → \(gameState.workerCount+1)")
                                .font(.caption)
                            Text("💰 \(gameState.workerCost)")
                                .font(.caption2)
                        }
                        .padding()
                        .frame(minWidth: 100)
                        .background(gameState.coins >= gameState.workerCost ? Color.blue : Color.gray)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }
                    .disabled(gameState.coins < gameState.workerCost)

                    // 升级速度按钮
                    Button(action: {
                        if gameState.buySpeed() {
                            // scene?.refreshSpeed()
                        }
                    }) {
                        VStack {
                            Text("⚡ 升级速度")
                            Text("Lv.\(gameState.speedLevel) → Lv.\(gameState.speedLevel+1)")
                                .font(.caption)
                            Text("💰 \(gameState.speedCost)")
                                .font(.caption2)
                        }
                        .padding()
                        .frame(minWidth: 100)
                        .background(gameState.coins >= gameState.speedCost ? Color.green : Color.gray)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }
                    .disabled(gameState.coins < gameState.speedCost)
                }
                .padding(.bottom, 40)
            }
        }
        .preferredColorScheme(.dark) // 强制深色，更配像素风
    }
}
