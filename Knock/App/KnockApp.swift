import SwiftUI

@main
struct KnockApp: App {
    @State private var appState = AppState()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(appState)
                .preferredColorScheme(.light)
                .tint(KnockColor.primaryDark)
        }
    }
}

struct RootView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        ZStack {
            switch appState.route {
            case .splash:
                SplashView()
                    .transition(.opacity)
            case .onboarding:
                OnboardingView()
                    .transition(.move(edge: .trailing).combined(with: .opacity))
            case .auth:
                AuthFlowView()
                    .transition(.move(edge: .trailing).combined(with: .opacity))
            case .main:
                MainTabView()
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.35), value: appState.route)
    }
}
