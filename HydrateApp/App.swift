import SwiftUI
import HydrateKit
import BackgroundTasks

@main
struct HydrateApp: App {
    @Environment(\.scenePhase) private var scenePhase

    init() {
        ReminderScheduler.shared.registerBackgroundTask()
        ReminderScheduler.shared.scheduleBackgroundRefresh()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .onChange(of: scenePhase) { _, newPhase in
                    if newPhase == .background {
                        ReminderScheduler.shared.scheduleBackgroundRefresh()
                    }
                }
        }
    }
}

struct ContentView: View {
    var body: some View {
        TabView {
            HomeView()
                .tabItem {
                    Label("今日", systemImage: "drop.fill")
                }
            HistoryView()
                .tabItem {
                    Label("统计", systemImage: "chart.bar.fill")
                }
            SettingsView()
                .tabItem {
                    Label("设置", systemImage: "gearshape.fill")
                }
        }
    }
}
