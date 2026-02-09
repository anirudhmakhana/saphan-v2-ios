import SwiftUI
import SaphanCore

struct MainTabView: View {
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            VoiceTranslationView()
                .tabItem {
                    Label("Translate", systemImage: "waveform")
                }
                .tag(0)

            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gearshape")
                }
                .tag(1)
        }
        .tint(Color.blue)
    }
}

#Preview {
    MainTabView()
        .environmentObject(AuthViewModel())
        .environmentObject(NetworkMonitor.shared)
}
