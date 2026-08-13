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
        view.backgroundColor = .clear
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
                
                VStack {
                    HStack(alignment: .center, spacing: 8) {
                        Button(action: onBack) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(.white)
                                .padding(8)
                                .background(Color.black.opacity(0.4))
                                .clipShape(Circle())
                        }
                        
                        Text("🏢 \(gameState.currentBuildingName)")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white)
                        
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
        .ignoresSafeArea()
    }
}
