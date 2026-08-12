import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) var dismiss
    
    @AppStorage("soundEnabled") private var soundEnabled = true
    @AppStorage("musicEnabled") private var musicEnabled = true
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("音效")) {
                    Toggle("音效开关", isOn: $soundEnabled)
                    Toggle("背景音乐", isOn: $musicEnabled)
                }
                Section(header: Text("关于")) {
                    HStack {
                        Text("版本")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.secondary)
                    }
                }
                Section {
                    Button("恢复默认设置") {
                        soundEnabled = true
                        musicEnabled = true
                    }
                    .foregroundColor(.red)
                }
            }
            .navigationTitle("设置")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("关闭") {
                        dismiss()
                    }
                }
            }
        }
    }
}
