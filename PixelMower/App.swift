import SwiftUI

@main
struct PixelMowerApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .statusBar(hidden: true)
                .persistentSystemOverlays(.hidden)
        }
    }
}
