import SwiftUI

/// 인증 플로우의 큰 라임색 버튼 (높이 62, 라디우스 31)
struct PrimaryButton: View {
    var title: String
    var isEnabled: Bool = true
    var isLoading: Bool = false
    var style: Style = .filled
    var action: () -> Void

    enum Style { case filled, outline, yellow, green, danger }

    var body: some View {
        Button(action: action) {
            ZStack {
                if isLoading {
                    ProgressView().tint(foreground)
                } else {
                    Text(title)
                        .font(KnockFont.authButton)
                        .foregroundStyle(foreground)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 62)
            .background(background, in: Capsule())
            .overlay {
                if style == .outline {
                    Capsule().stroke(KnockColor.stroke, lineWidth: 1)
                }
            }
            .opacity(isEnabled ? 1 : 0.5)
        }
        .buttonStyle(.pressable)
        .disabled(!isEnabled || isLoading)
    }

    private var background: Color {
        switch style {
        case .filled: return KnockColor.lime
        case .outline: return .white
        case .yellow: return KnockColor.yellow
        case .green: return KnockColor.primary
        case .danger: return KnockColor.danger
        }
    }

    private var foreground: Color {
        switch style {
        case .filled, .outline: return KnockColor.textBlack
        case .yellow: return KnockColor.textPrimary
        case .green, .danger: return .white
        }
    }
}

struct PressableButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .opacity(configuration.isPressed ? 0.9 : 1)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}

extension ButtonStyle where Self == PressableButtonStyle {
    static var pressable: PressableButtonStyle { PressableButtonStyle() }
}

/// 소셜 로그인 버튼
struct SocialLoginButton: View {
    var provider: SocialProvider
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                icon
                Text(title)
                    .font(KnockFont.medium(16))
                    .foregroundStyle(KnockColor.textNeutral)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(background, in: Capsule())
            .overlay {
                if provider == .facebook || provider == .apple || provider == .phone {
                    Capsule().stroke(KnockColor.stroke, lineWidth: 1)
                }
            }
        }
        .buttonStyle(.pressable)
    }

    private var title: String {
        switch provider {
        case .kakao: return "카카오로 계속하기"
        case .naver: return "네이버로 계속하기"
        case .facebook: return "페이스북으로 계속하기"
        case .apple: return "Apple로 계속하기"
        case .phone: return "휴대폰번호로 계속하기"
        }
    }

    private var background: Color {
        switch provider {
        case .kakao: return KnockColor.limeLight
        case .naver: return KnockColor.lime
        default: return .white
        }
    }

    @ViewBuilder private var icon: some View {
        switch provider {
        case .kakao: Image(systemName: "message.fill").font(.system(size: 15))
        case .naver: Text("N").font(.system(size: 15, weight: .black))
        case .facebook: Image(systemName: "f.circle.fill").font(.system(size: 16))
        case .apple: Image(systemName: "apple.logo").font(.system(size: 16))
        case .phone: Image(systemName: "iphone").font(.system(size: 16))
        }
    }
}

/// 상단 둥근 아이콘 버튼 (뒤로가기 / 더보기)
struct CircleIconButton: View {
    var systemImage: String
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(KnockColor.primary)
                .frame(width: 40, height: 40)
                .background(KnockColor.cardTint, in: Circle())
        }
        .buttonStyle(.pressable)
    }
}

/// 라운드 캡슐 배지 (ONLINE / 오늘 상태)
struct PillBadge: View {
    var text: String
    var foreground: Color = KnockColor.textPrimary
    var background: Color = KnockColor.cardTint
    var icon: String? = nil
    var dot: Color? = nil
    var font: Font = KnockFont.medium(12)

    var body: some View {
        HStack(spacing: 5) {
            if let icon { Image(systemName: icon).font(.system(size: 11, weight: .semibold)) }
            if let dot { Circle().fill(dot).frame(width: 8, height: 8) }
            Text(text).font(font)
        }
        .foregroundStyle(foreground)
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(background, in: Capsule())
    }
}

struct SectionCard<Content: View>: View {
    var padding: CGFloat = 16
    var background: Color = .white
    var radius: CGFloat = 20
    @ViewBuilder var content: Content

    var body: some View {
        content
            .padding(padding)
            .background(background, in: RoundedRectangle(cornerRadius: radius, style: .continuous))
            .knockShadow()
    }
}

/// 통계 상단 세그먼트 (주기 / 월기 / 년기)
struct SegmentedPill<T: Hashable>: View {
    var items: [(T, String)]
    @Binding var selection: T
    @Namespace private var ns

    var body: some View {
        HStack(spacing: 0) {
            ForEach(items, id: \.0) { item in
                Button {
                    withAnimation(.spring(duration: 0.3)) { selection = item.0 }
                } label: {
                    Text(item.1)
                        .font(KnockFont.medium(16))
                        .foregroundStyle(selection == item.0 ? KnockColor.textPrimary : KnockColor.textSecondary)
                        .frame(maxWidth: .infinity)
                        .frame(height: 40)
                        .background {
                            if selection == item.0 {
                                Capsule().fill(.white)
                                    .matchedGeometryEffect(id: "pill", in: ns)
                            }
                        }
                }
                .buttonStyle(.plain)
            }
        }
        .padding(4)
        .background(KnockColor.cardTint2, in: Capsule())
    }
}

/// 날짜 이동 네비게이터 ( < 07/21-07/27 > )
struct DateNavigator: View {
    var title: String
    var onPrevious: () -> Void
    var onNext: () -> Void

    var body: some View {
        HStack {
            Button(action: onPrevious) {
                Image(systemName: "chevron.left").font(.system(size: 16, weight: .medium))
            }
            Spacer()
            Text(title).font(KnockFont.medium(18))
            Spacer()
            Button(action: onNext) {
                Image(systemName: "chevron.right").font(.system(size: 16, weight: .medium))
            }
        }
        .foregroundStyle(KnockColor.textPrimary)
        .padding(.horizontal, 20)
    }
}

/// 흐릿한 배경 로딩 오버레이
struct LoadingOverlay: View {
    var body: some View {
        ZStack {
            Color.black.opacity(0.15).ignoresSafeArea()
            ProgressView()
                .tint(KnockColor.primaryDark)
                .padding(24)
                .background(.white, in: RoundedRectangle(cornerRadius: 16))
        }
    }
}
