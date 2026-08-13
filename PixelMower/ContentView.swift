import SwiftUI
import SpriteKit

struct ContentView: View {
    
    @State private var gold: Int = 0
    @State private var brickCount: Int = 0
    @State private var progress: Double = 0.0
    @State private var goMenu = false
    
    private func makeGameScene() -> GameScene {
        let scene = GameScene()
        scene.audioManager = AudioManager.shared
        return scene
    }
    
    var body: some View {
        if goMenu {
            MenuView()
        } else {
            ZStack {
                SpriteView(scene: makeGameScene())
                    .ignoresSafeArea()
                    .onAppear {
                        let scene = makeGameScene()
                        scene.onUpdateUI = { g,b,p in
                            gold = g
                            brickCount = b
                            progress = p
                        }
                    }
                
                VStack {
                    HStack {
                        Button(action:{ goMenu = true }) {
                            Image(systemName: "arrow.left.circle.fill")
                                .font(.system(size:40))
                                .foregroundColor(.white)
                        }
                        Text("小屋").font(.title).bold().foregroundColor(.white)
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
                    
                    HStack(spacing:16) {
                        Button(action:{
                            // 注意：这里临时注释，下一轮修复按钮调用scene逻辑，当前先保证编译通过
                        }) {
                            HStack {
                                Image(systemName:"person.2.fill")
                                Text("+1工人 15金币")
                            }.padding().background(Color.white.opacity(0.8)).cornerRadius(12)
                        }
                        
                        Button(action:{
                            
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
