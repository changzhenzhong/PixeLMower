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
    @StateObject private var gameState = GameState()
    @State private var scene: GameScene?
    
    var body: some View {
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
                HStack {
                    Text("💰 \(gameState.coins)")
                        .font(.system(size: 24, weight: .bold, design: .monospaced))
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.black.opacity(0.5))
                        .cornerRadius(10)
                        .padding(.top, 20)
                        .padding(.leading, 20)
                    Spacer()
                }
                
                Spacer()
                
                HStack(spacing: 20) {
                    Button(action: {
                        if gameState.buyWorker() {
                            scene?.refreshWorkers()
                        }
                    }) {
                        VStack(spacing: 2) {
                            Text("👷 +1")
                                .font(.system(size: 16, weight: .bold))
                            Text("💰\(gameState.workerCost)")
                                .font(.system(size: 12))
                        }
                        .padding(8)
                        .frame(width: 80)
                        .background(gameState.coins >= gameState.workerCost ? Color.blue.opacity(0.7) : Color.gray.opacity(0.5))
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }
                    .disabled(gameState.coins < gameState.workerCost)
                    
                    Button(action: {
                        if gameState.buySpeed() {
                            scene?.refreshSpeed()
                        }
                    }) {
                        VStack(spacing: 2) {
                            Text("⚡ +1")
                                .font(.system(size: 16, weight: .bold))
                            Text("💰\(gameState.speedCost)")
                                .font(.system(size: 12))
                        }
                        .padding(8)
                        .frame(width: 80)
                        .background(gameState.coins >= gameState.speedCost ? Color.green.opacity(0.7) : Color.gray.opacity(0.5))
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }
                    .disabled(gameState.coins < gameState.speedCost)
                }
                .padding(.bottom, 30)
                .padding(.horizontal, 20)
                .background(Color.black.opacity(0.3))
                .cornerRadius(15)
            }
        }
        .preferredColorScheme(.dark)
    }
}
