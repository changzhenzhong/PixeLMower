import SwiftUI

// 解决竖屏锁定，替代UIApplication.shared报错
struct OrientationLock: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> UIViewController {
        let vc = UIViewController()
        vc.view.backgroundColor = .clear
        return vc
    }
    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
        // 强制竖屏
        uiViewController.setNeedsUpdateOfSupportedInterfaceOrientations()
    }
}

@main
struct PixelMowerApp: App {
    var body: some Scene {
        WindowGroup {
            ZStack {
                ContentView()
                OrientationLock()
            }
        }
    }
}
