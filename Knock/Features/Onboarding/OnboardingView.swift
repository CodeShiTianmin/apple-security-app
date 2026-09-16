import SwiftUI

struct OnboardingPage: Identifiable {
    let id = UUID()
    let title: String
    let message: String
    /// 랜드스케이프 일러스트의 어느 부분을 보여줄지 (-1 ... 1)
    let anchorX: CGFloat
}

struct OnboardingView: View {
    @Environment(AppState.self) private var appState
    @State private var index = 0

    private let pages = [
        OnboardingPage(title: "오늘도 안전하게 시작하세요?",
                       message: "똑똑똑은 매일 나의 안전 상태를 확인하고, 소중한 사람들에게 안심을 전하는 안전 체크인 앱입니다.",
                       anchorX: 1),
        OnboardingPage(title: "잊지 않도록 알려드릴게요",
                       message: "정해진 시간에 체크인을 하지 않으면 똑똑똑이 부드럽게 알림을 보내 안전 확인을 도와드립니다.",
                       anchorX: -1),
        OnboardingPage(title: "당신의 하루를 함께 지켜요",
                       message: "간단한 체크인 한 번으로 오늘의 안부를 남기고, 가족과 지인에게 평안한 소식을 전해보세요.",
                       anchorX: 0.4),
    ]

    var body: some View {
        ZStack {
            Color.white.ignoresSafeArea()
            VStack(spacing: 0) {
                HStack {
                    Spacer()
                    Button("건너뛰기") { appState.finishOnboarding() }
                        .font(KnockFont.medium(14))
                        .foregroundStyle(KnockColor.textMuted)
                        .padding(.horizontal, 20)
                }
                .padding(.top, 8)

                TabView(selection: $index) {
                    ForEach(Array(pages.enumerated()), id: \.offset) { i, page in
                        OnboardingPageView(page: page).tag(i)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))

                HStack(spacing: 8) {
                    ForEach(pages.indices, id: \.self) { i in
                        Circle()
                            .fill(i == index ? KnockColor.lime : KnockColor.stroke)
                            .frame(width: 10, height: 10)
                            .animation(.easeInOut, value: index)
                    }
                }
                .padding(.bottom, 20)

                PrimaryButton(title: index == pages.count - 1 ? "시작하기" : "다음") {
                    if index < pages.count - 1 {
                        withAnimation { index += 1 }
                    } else {
                        appState.finishOnboarding()
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 12)
            }
        }
    }
}

private struct OnboardingPageView: View {
    var page: OnboardingPage

    var body: some View {
        VStack(spacing: 0) {
            GeometryReader { geo in
                Image("onboarding_landscape")
                    .resizable()
                    .scaledToFill()
                    .frame(width: geo.size.width * 1.7, height: geo.size.height)
                    .offset(x: -geo.size.width * 0.35 * (page.anchorX + 1))
                    .frame(width: geo.size.width, height: geo.size.height)
                    .clipped()
            }
            .frame(maxHeight: .infinity)

            VStack(spacing: 14) {
                Text(page.title)
                    .font(KnockFont.semibold(24))
                    .foregroundStyle(KnockColor.textNeutral)
                Text(page.message)
                    .font(KnockFont.regular(15))
                    .foregroundStyle(KnockColor.textGray)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .padding(.horizontal, 36)
            }
            .padding(.vertical, 24)
        }
    }
}
