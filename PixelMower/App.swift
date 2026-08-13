import SwiftUI

@main
struct PixelMowerApp: App {
    @State private var isGameActive = false
    @State private var showSettings = false
    @State private var showAbout = false
    
    var body: some Scene {
        WindowGroup {
            if isGameActive {
                ContentView(onBack: {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        isGameActive = false
                    }
                })
                .transition(.opacity)
                .supportedOrientations(.portrait) // 强制竖屏
            } else {
                MenuView(
                    onStart: {
                        withAnimation(.easeIn(duration: 0.3)) {
                            isGameActive = true
                        }
                    },
                    onSettings: {
                        showSettings = true
                    },
                    onAbout: {
                        showAbout = true
                    }
                )
                .sheet(isPresented: $showSettings) {
                    SettingsView()
                }
                .sheet(isPresented: $showAbout) {
                    AboutView()
                }
                .supportedOrientations(.portrait)
            }
        }
    }
}

extension View {
    func supportedOrientations(_ orientations: UIInterfaceOrientationMask) -> some View {
        self.onAppear {
            UIApplication.shared.windows.first?.rootViewController?.setNeedsUpdateOfSupportedInterfaceOrientations()
        }
        .background(SupportedOrientationsView(orientations: orientations))
    }
}

struct SupportedOrientationsView: UIViewControllerRepresentable {
    let orientations: UIInterfaceOrientationMask
    
    func makeUIViewController(context: Context) -> UIViewController {
        let controller = OrientationViewController()
        controller.orientations = orientations
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {}
}

class OrientationViewController: UIViewController {
    var orientations: UIInterfaceOrientationMask = .portrait
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return orientations
    }
    
    override var shouldAutorotate: Bool {
        return false
    }
}
