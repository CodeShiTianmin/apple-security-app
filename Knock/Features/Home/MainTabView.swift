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

            if appState.showCelebration {
                CelebrationOverlay(id: appState.celebrationID) { appState.showCelebration = false }
                    .zIndex(9)
            }

            if let toast = appState.toast {
                ToastView(toast: toast)
                    .padding(.bottom, 76)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .zIndex(11)
            }
        }
        .animation(.easeInOut(duration: 0.25), value: appState.showSafetyAlert)
        .sheet(isPresented: $showSettings) { SettingsView() }
        .sheet(isPresented: $appState.showNotifications) { NotificationsView() }
    }
}

/// 하단 토스트
struct ToastView: View {
    var toast: ToastMessage

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: toast.icon)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(KnockColor.yellow)
            Text(toast.text)
                .font(KnockFont.medium(14))
                .foregroundStyle(.white)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 12)
        .background(KnockColor.primaryDark.opacity(0.92), in: Capsule())
        .knockShadow(radius: 14, y: 6, opacity: 0.2)
    }
}

/// 체크인 완료 축하 파티클 (하트·잎 떨어짐)
struct CelebrationOverlay: View {
    var id: UUID
    var onFinish: () -> Void
    @State private var start = Date.now

    private struct Particle: Identifiable {
        let id = UUID()
        let x: CGFloat
        let delay: Double
        let size: CGFloat
        let color: Color
        let symbol: String
        let spin: Double
    }

    private let particles: [Particle] = (0..<18).map { i in
        let palette: [Color] = [KnockColor.primary, KnockColor.yellow, KnockColor.lime, KnockColor.lavender, KnockColor.stressHigh]
        let symbols = ["heart.fill", "leaf.fill", "circle.fill", "star.fill"]
        return Particle(x: CGFloat(i) / 17, delay: Double(i % 6) * 0.06,
                        size: CGFloat(10 + (i * 7) % 12), color: palette[i % palette.count],
                        symbol: symbols[i % symbols.count], spin: Double((i % 2 == 0 ? 1 : -1) * (180 + (i * 37) % 180)))
    }

    private let duration: Double = 1.9

    var body: some View {
        TimelineView(.animation) { context in
            let elapsed = context.date.timeIntervalSince(start)
            GeometryReader { geo in
                ZStack {
                    ForEach(particles) { p in
                        let raw = (elapsed - p.delay) / (duration - p.delay)
                        let t = CGFloat(max(0, min(1, raw)))
                        let eased = t * t
                        Image(systemName: p.symbol)
                            .font(.system(size: p.size))
                            .foregroundStyle(p.color)
                            .rotationEffect(.degrees(p.spin * Double(t)))
                            .opacity(t < 0.1 ? t * 10 : 1 - max(0, t - 0.7) / 0.3)
                            .position(x: geo.size.width * p.x + sin(t * .pi * 2) * 14,
                                      y: -30 + geo.size.height * 0.9 * eased)
                    }
                }
            }
        }
        .allowsHitTesting(false)
        .ignoresSafeArea()
        .id(id)
        .onAppear {
            start = .now
            Task {
                try? await Task.sleep(for: .seconds(duration + 0.1))
                onFinish()
            }
        }
    }
}

/// 헤더 우측 설정 아이콘
struct HeaderActions: View {
    @Binding var showSettings: Bool

    var body: some View {
        HStack(spacing: 16) {
            NotificationBell()
            Button { showSettings = true } label: {
                Image(systemName: "gearshape")
                    .font(.system(size: 20))
                    .foregroundStyle(.white)
                    .frame(width: 24, height: 24)
            }
        }
    }
}
