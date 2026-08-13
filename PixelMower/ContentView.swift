import SwiftUI
import SpriteKit

struct ContentView: View {
    @State private var gameScene: GameScene
    
    init() {
        let scene = GameScene()
        scene.audioManager = AudioManager.shared
        _gameScene = State(initialValue: scene)
    }
    
    @State var gold: Int = 0
    @State var brickCount: Int = 0
    @State var progress: Double = 0.0
    @State var goMenu = false
    
    var body: some View {
        if goMenu {
            MenuView()
        } else {
            ZStack {
                SpriteView(scene: gameScene)
                    .ignoresSafeArea() // 全屏消除黑边
                    .onAppear {
                        gameScene.onUpdateUI = { g,b,p in
                            gold = g
                            brickCount = b
                            progress = p
                        }
                    }
                
                // 顶部UI
                VStack {
                    HStack {
                        Button(action:{ goMenu = true }) {
                            Image(systemName: "arrow.left.circle.fill")
                                .font(.system(size:40))
                                .foregroundColor(.white)
                        }
                        Text(gameScene.buildingName).font(.title).bold().foregroundColor(.white)
                        ProgressView(value: progress)
                            .frame(maxWidth: .infinity)
                        Text("\(Int(progress*100))%").foregroundColor(.white)
                        
                        Spacer()
                        VStack {
                            Image(systemName: "bag.fill")
                            Text("\(gold)").font(.title).foregroundColor(.yellow)
                        }
                    }.padding()
                    
                    Spacer()
                    
                    // 底部升级按钮
                    HStack(spacing:16) {
                        Button(action:{
                            gameScene.addWorker()
                        }) {
                            HStack {
                                Image(systemName:"person.2.fill")
                                Text("+1工人 15金币")
                            }.padding().background(Color.white.opacity(0.8)).cornerRadius(12)
                        }
                        
                        Button(action:{
                            gameScene.boostWorkerSpeed()
                        }) {
                            HStack {
                                Image(systemName:"bolt.fill")
                                Text("+1速度 8金币")
                            }.padding().background(Color.white.opacity(0.8)).cornerRadius(12)
                        }
                        
                        Text("建造中").padding().background(Color.brown.opacity(0.7)).foregroundColor(.white).cornerRadius(12)
                    }.padding(.bottom, 30)
                }
            }
        }
    }
}
