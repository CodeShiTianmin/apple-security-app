import SwiftUI

struct MainTabView: View {
    @Environment(AppState.self) private var appState
    @State private var showSettings = false

    var body: some View {
        @Bindable var appState = appState
        ZStack(alignment: .bottom) {
            Group {
                switch appState.tab {
                case .home: HomeView(showSettings: $showSettings)
                case .stats: StressStatsView(showSettings: $showSettings)
                case .health: HealthView(showSettings: $showSettings)
                case .family: FamilyView(showSettings: $showSettings)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .safeAreaInset(edge: .bottom, spacing: 0) {
                KnockTabBar(selection: $appState.tab)
            }
            .saturation(appState.isDangerMode && appState.showSafetyAlert ? 0.6 : 1)

            if appState.showSafetyAlert {
                SafetyAlertOverlay()
                    .transition(.opacity.combined(with: .scale(scale: 0.95)))
                    .zIndex(10)
            }
        }
        .animation(.easeInOut(duration: 0.25), value: appState.showSafetyAlert)
        .sheet(isPresented: $showSettings) { SettingsView() }
    }
}

/// 헤더 우측 설정 아이콘
struct HeaderActions: View {
    @Binding var showSettings: Bool

    var body: some View {
        Button { showSettings = true } label: {
            Image(systemName: "gearshape")
                .font(.system(size: 20))
                .foregroundStyle(.white)
                .frame(width: 24, height: 24)
        }
    }
}
