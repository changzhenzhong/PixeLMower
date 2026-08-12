import SwiftUI
import SpriteKit
import UIKit

struct ContentView: View {
    @StateObject private var gameState = GameState()
    @State private var showUpgradePanel = false
    @State private var upgradeOptions: [UpgradeOption] = []

    var body: some View {
        ZStack {
            SpriteView(scene: createScene())
                .ignoresSafeArea()
                .onAppear { setupGameCallbacks() }

            VStack {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Lv.\(gameState.level)")
                            .font(.system(size: 20, weight: .bold, design: .monospaced))
                            .foregroundColor(.white)
                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                Rectangle().fill(Color.white.opacity(0.2))
                                    .frame(height: 6).cornerRadius(3)
                                Rectangle().fill(Color.green)
                                    .frame(width: geo.size.width * CGFloat(gameState.expProgress), height: 6)
                                    .cornerRadius(3)
                                    .animation(.easeOut(duration: 0.3), value: gameState.expProgress)
                            }
                        }
                        .frame(height: 6)
                    }
                    .frame(width: 120)
                    Spacer()
                    Text("⚔️\(gameState.killCount)")
                        .font(.system(size: 16, weight: .bold, design: .monospaced))
                        .foregroundColor(.orange)
                }
                .padding(.horizontal, 16).padding(.top, 8)
                Spacer()
            }

            if showUpgradePanel {
                upgradePanelView
            }
        }
    }

    private func createScene() -> GameScene {
        let scene = GameScene()
        scene.size = UIScreen.main.bounds.size
        scene.scaleMode = .resizeFill
        scene.gameState = gameState
        return scene
    }

    private func setupGameCallbacks() {
        gameState.onLevelUp = { options in
            upgradeOptions = options
            withAnimation(.spring()) { showUpgradePanel = true }
        }
    }

    private var upgradePanelView: some View {
        VStack(spacing: 12) {
            Text("⬆️ 升级！选择强化")
                .font(.system(size: 22, weight: .bold, design: .monospaced))
                .foregroundColor(.yellow)
            ForEach(upgradeOptions) { option in
                Button(action: {
                    gameState.applyUpgrade(option)
                    withAnimation(.spring()) { showUpgradePanel = false }
                }) {
                    HStack {
                        Text(option.icon).font(.title2)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(option.name)
                                .font(.system(size: 15, weight: .bold, design: .monospaced))
                            Text(option.description)
                                .font(.system(size: 11, design: .monospaced))
                                .foregroundColor(.gray)
                        }
                        Spacer()
                        Text("Lv.\(option.currentLevel+1)")
                            .font(.system(size: 12, design: .monospaced))
                            .foregroundColor(.green)
                    }
                    .padding(12)
                    .background(Color.white.opacity(0.08))
                    .cornerRadius(10)
                    .overlay(RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.yellow.opacity(0.5), lineWidth: 1))
                }
            }
        }
        .padding(20)
        .background(Color(red: 0.05, green: 0.05, blue: 0.12).opacity(0.95))
        .cornerRadius(16)
        .overlay(RoundedRectangle(cornerRadius: 16)
            .stroke(Color.yellow, lineWidth: 2))
        .padding(.horizontal, 30)
        .shadow(radius: 20)
    }
}
