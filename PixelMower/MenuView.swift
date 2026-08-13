import SwiftUI

struct MenuView: View {
    let onStart: () -> Void
    let onSettings: () -> Void
    let onAbout: () -> Void
    
    var body: some View {
        ZStack {
            // 像素风格背景
            LinearGradient(gradient: Gradient(colors: [Color(red: 0.2, green: 0.4, blue: 0.6), Color(red: 0.1, green: 0.2, blue: 0.3)]), startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()
            
            // 装饰砖墙（模拟）
            VStack(spacing: 0) {
                ForEach(0..<30) { row in
                    HStack(spacing: 0) {
                        ForEach(0..<20) { col in
                            Rectangle()
                                .fill((row + col) % 2 == 0 ? Color(red: 0.5, green: 0.3, blue: 0.2) : Color(red: 0.6, green: 0.4, blue: 0.25))
                                .frame(width: 30, height: 15)
                        }
                    }
                }
            }
            .opacity(0.2)
            .rotationEffect(.degrees(-3))
            .scaleEffect(1.2)
            
            VStack(spacing: 25) {
                Spacer()
                VStack(spacing: 5) {
                    Text("🏗️")
                        .font(.system(size: 70))
                    Text("搬砖大亨")
                        .font(.system(size: 42, weight: .bold, design: .monospaced))
                        .foregroundColor(.white)
                        .shadow(color: .black, radius: 5, x: 3, y: 3)
                    Text("Build & Earn")
                        .font(.system(size: 20, weight: .medium, design: .monospaced))
                        .foregroundColor(.yellow)
                }
                Spacer()
                VStack(spacing: 18) {
                    MenuButton(title: "🚀 开始游戏", color: .green, action: onStart)
                    MenuButton(title: "⚙️ 设置", color: .blue, action: onSettings)
                    MenuButton(title: "📖 关于", color: .orange, action: onAbout)
                }
                .padding(.horizontal, 40)
                Spacer()
                Text("v1.0.0")
                    .font(.system(size: 14, design: .monospaced))
                    .foregroundColor(.white.opacity(0.4))
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
                    RoundedRectangle(cornerRadius: 14)
                        .fill(color)
                        .shadow(color: .black.opacity(0.4), radius: 6, x: 2, y: 4)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
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
