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
            }
        }
    }
}
