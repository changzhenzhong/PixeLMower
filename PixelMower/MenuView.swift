import SwiftUI

struct MenuView: View {
    let onStart: () -> Void
    let onSettings: () -> Void
    let onAbout: () -> Void
    
    var body: some View {
        ZStack {
            Color(red: 0.2, green: 0.3, blue: 0.4)
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                ForEach(0..<20) { row in
                    HStack(spacing: 0) {
                        ForEach(0..<15) { col in
                            Rectangle()
                                .fill((row + col) % 2 == 0 ? Color(red: 0.5, green: 0.3, blue: 0.2) : Color(red: 0.6, green: 0.4, blue: 0.25))
                                .frame(width: 30, height: 15)
                        }
                    }
                }
            }
            .opacity(0.3)
            .rotationEffect(.degrees(-5))
            .scaleEffect(1.5)
            .offset(y: -50)
            
            VStack(spacing: 30) {
                Spacer()
                
                VStack(spacing: 8) {
                    Text("🏗️")
                        .font(.system(size: 60))
                    Text("搬砖大亨")
                        .font(.system(size: 40, weight: .bold, design: .monospaced))
                        .foregroundColor(.white)
                        .shadow(color: .black, radius: 4, x: 2, y: 2)
                    Text("Build & Earn")
                        .font(.system(size: 18, weight: .medium, design: .monospaced))
                        .foregroundColor(.yellow)
                }
                
                Spacer()
                
                VStack(spacing: 20) {
                    MenuButton(title: "🚀 开始游戏", color: .green) {
                        onStart()
                    }
                    MenuButton(title: "⚙️ 设置", color: .blue) {
                        onSettings()
                    }
                    MenuButton(title: "📖 关于", color: .orange) {
                        onAbout()
                    }
                }
                .padding(.horizontal, 40)
                
                Spacer()
                
                Text("v1.0.0")
                    .font(.system(size: 14, design: .monospaced))
                    .foregroundColor(.white.opacity(0.5))
                    .padding(.bottom, 20)
            }
        }
    }
}

struct MenuButton: View {
    let title: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 22, weight: .bold, design: .monospaced))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(color)
                        .shadow(color: .black.opacity(0.3), radius: 4, x: 2, y: 4)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.white.opacity(0.3), lineWidth: 2)
                )
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeOut(duration: 0.1), value: configuration.isPressed)
    }
}
