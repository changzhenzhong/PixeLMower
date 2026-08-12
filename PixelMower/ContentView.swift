import SwiftUI
import SpriteKit

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

    func updateUIView(_ uiView: SKView, context: Context) { }
}

// MARK: - 主界面
struct ContentView: View {
    @StateObject private var gameState = GameState()   // GameState 定义在 GameScene.swift 中
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
                        newScene.gameState = gameState
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
                    // 升级工人数量
                    Button(action: {
                        if gameState.buyWorker() {
                            scene?.refreshWorkers()   // 让场景重新生成工人
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

                    // 升级移动速度
                    Button(action: {
                        if gameState.buySpeed() {
                            scene?.refreshSpeed()     // 让场景更新速度
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
        .preferredColorScheme(.dark)
    }
}
