import SwiftUI

struct MainTabView: View {
    @Environment(AppState.self) private var appState
    @State private var showSettings = false
    @State private var showNotifications = false

    var body: some View {
        @Bindable var appState = appState
        ZStack(alignment: .bottom) {
            Group {
                switch appState.tab {
                case .home: HomeView(showNotifications: $showNotifications, showSettings: $showSettings)
                case .stats: StressStatsView(showSettings: $showSettings)
                case .health: HealthView(showSettings: $showSettings)
                case .family: FamilyView(showSettings: $showSettings)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .safeAreaInset(edge: .bottom, spacing: 0) {
                KnockTabBar(selection: $appState.tab,
                            badge: [.family: appState.members.reduce(0) { $0 + $1.unreadCount }])
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
        .sheet(isPresented: $showNotifications) { NotificationsView() }
    }
}

/// 헤더 우측 아이콘 묶음 (알림 / 설정)
struct HeaderActions: View {
    @Environment(AppState.self) private var appState
    var showNotifications: Binding<Bool>? = nil
    @Binding var showSettings: Bool

    var body: some View {
        HStack(spacing: 6) {
            if let showNotifications {
                Button { showNotifications.wrappedValue = true } label: {
                    Image(systemName: "bell")
                        .font(.system(size: 20))
                        .foregroundStyle(.white)
                        .frame(width: 40, height: 40)
                        .overlay(alignment: .topTrailing) {
                            if appState.unreadNotifications > 0 {
                                Circle().fill(KnockColor.yellow).frame(width: 9, height: 9).offset(x: -8, y: 8)
                            }
                        }
                }
            }
            Button { showSettings = true } label: {
                Image(systemName: "gearshape")
                    .font(.system(size: 20))
                    .foregroundStyle(.white)
                    .frame(width: 40, height: 40)
            }
        }
    }
}
