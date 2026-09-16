import SwiftUI

/// 스플래시: "똑똑똑과 함께! 시작해요!" + 지구 일러스트
struct SplashView: View {
    @Environment(AppState.self) private var appState
    @State private var appeared = false

    var body: some View {
        ZStack {
            Color.white.ignoresSafeArea()
            VStack(spacing: 0) {
                Spacer()
                VStack(alignment: .trailing, spacing: 4) {
                    Text("똑똑똑과 함께 !")
                        .frame(maxWidth: .infinity, alignment: .leading)
                    Text("시작해요 !")
                        .frame(maxWidth: .infinity, alignment: .trailing)
                }
                .font(KnockFont.heavy(40))
                .foregroundStyle(KnockColor.textGray)
                .padding(.horizontal, 24)
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 16)

                Image("splash_globe")
                    .resizable()
                    .scaledToFit()
                    .padding(.horizontal, 32)
                    .padding(.top, 24)
                    .scaleEffect(appeared ? 1 : 0.9)
                    .opacity(appeared ? 1 : 0)
                Spacer()
                Spacer()
            }
        }
        .task {
            withAnimation(.easeOut(duration: 0.6)) { appeared = true }
            try? await Task.sleep(for: .seconds(1.8))
            appState.finishSplash()
        }
    }
}
