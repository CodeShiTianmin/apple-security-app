import SwiftUI

/// 아바타 + 온라인 표시 점
struct AvatarView: View {
    var asset: String
    var size: CGFloat = 44
    var isOnline: Bool? = nil
    var ring: Color = .white

    var body: some View {
        Image(asset)
            .resizable()
            .scaledToFill()
            .frame(width: size, height: size)
            .clipShape(Circle())
            .overlay(Circle().stroke(ring, lineWidth: 2))
            .overlay(alignment: .bottomTrailing) {
                if let isOnline {
                    Circle()
                        .fill(isOnline ? KnockColor.online : KnockColor.offline)
                        .frame(width: size * 0.3, height: size * 0.3)
                        .overlay(Circle().stroke(.white, lineWidth: 2))
                }
            }
    }
}

/// 헤더 우측 잎사귀 장식 배경
struct LeafDecoration: View {
    var body: some View {
        GeometryReader { geo in
            Image("header_leaf")
                .resizable()
                .scaledToFit()
                .frame(width: geo.size.width * 0.55)
                .opacity(0.9)
                .offset(x: geo.size.width * 0.55, y: -geo.size.height * 0.15)
        }
        .allowsHitTesting(false)
    }
}

/// 메인 탭 상단의 초록색 사용자 헤더
struct UserHeader: View {
    @Environment(AppState.self) private var appState
    var user: UserProfile
    var isOnline: Bool
    var trailing: AnyView? = nil
    var onAvatarTap: () -> Void = {}

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                Button(action: onAvatarTap) {
                    AvatarView(asset: user.avatarAsset, size: 40, isOnline: isOnline)
                }
                .buttonStyle(.plain)

                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 8) {
                        Text("\(user.name)님")
                            .font(KnockFont.medium(18))
                            .foregroundStyle(.white)
                        PillBadge(
                            text: isOnline ? "온라인" : "오프라인",
                            foreground: isOnline ? KnockColor.textPrimary : KnockColor.dangerText,
                            background: isOnline ? KnockColor.cardTint : KnockColor.dangerSoft,
                            horizontalPadding: 10,
                            radius: 10
                        )
                    }
                    Text(user.region)
                        .font(KnockFont.regular(12))
                        .foregroundStyle(.white)
                }
                Spacer()
                if let trailing { trailing }
                NotificationBell()
            }
            Text("오늘도 체크하고 화이팅 하자")
                .font(KnockFont.medium(14))
                .foregroundStyle(.white)
        }
        .padding(.horizontal, 24)
        .padding(.top, 12)
        .padding(.bottom, 20)
    }
}

/// 헤더 우측 알림 벨 (안 읽은 개수 배지, 새 알림 시 흔들림)
struct NotificationBell: View {
    @Environment(AppState.self) private var appState
    @State private var ring = false

    var body: some View {
        Button { appState.showNotifications = true } label: {
            Image(systemName: "bell.fill")
                .font(.system(size: 18))
                .foregroundStyle(.white)
                .frame(width: 24, height: 24)
                .rotationEffect(.degrees(ring ? 14 : 0), anchor: .top)
                .overlay(alignment: .topTrailing) {
                    if appState.unreadNotifications > 0 {
                        Text("\(min(appState.unreadNotifications, 9))")
                            .font(KnockFont.bold(10))
                            .foregroundStyle(KnockColor.textPrimary)
                            .frame(minWidth: 16, minHeight: 16)
                            .background(KnockColor.yellow, in: Circle())
                            .overlay(Circle().stroke(KnockColor.primary, lineWidth: 1.5))
                            .offset(x: 7, y: -6)
                            .transition(.scale.combined(with: .opacity))
                    }
                }
        }
        .buttonStyle(.plain)
        .accessibilityLabel("알림 센터")
        .accessibilityIdentifier("header.bell")
        .onChange(of: appState.unreadNotifications) { old, new in
            guard new > old else { return }
            withAnimation(.interpolatingSpring(stiffness: 260, damping: 5)) { ring = true }
            Task {
                try? await Task.sleep(for: .milliseconds(120))
                withAnimation(.interpolatingSpring(stiffness: 260, damping: 6)) { ring = false }
            }
        }
    }
}

/// 초록 헤더 + 크림색 콘텐츠 영역 스캐폴드
struct GreenScaffold<Header: View, Content: View>: View {
    var headerColor: Color = KnockColor.primary
    var contentBackground: Color = KnockColor.background
    var scrollable: Bool = true
    @ViewBuilder var header: Header
    @ViewBuilder var content: Content

    var body: some View {
        ZStack(alignment: .top) {
            headerColor.ignoresSafeArea()
            LeafDecoration().frame(height: 160).ignoresSafeArea(edges: .top)

            VStack(spacing: 0) {
                header
                Group {
                    if scrollable {
                        ScrollView(showsIndicators: false) {
                            content.padding(.bottom, 24)
                        }
                    } else {
                        content
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(
                    contentBackground,
                    in: UnevenRoundedRectangle(topLeadingRadius: 28, topTrailingRadius: 28, style: .continuous)
                )
                .ignoresSafeArea(edges: .bottom)
            }
        }
    }
}

/// 하단 4탭 커스텀 탭바
struct KnockTabBar: View {
    @Binding var selection: MainTab

    var body: some View {
        HStack(spacing: 0) {
            ForEach(MainTab.allCases) { tab in
                Button {
                    withAnimation(.spring(duration: 0.3)) { selection = tab }
                } label: {
                    TabIcon(tab: tab, color: selection == tab ? KnockColor.tabIconActive : KnockColor.tabIconInactive)
                        .frame(width: 24, height: 24)
                        .frame(width: 60, height: 44)
                        .background {
                            if selection == tab {
                                RoundedRectangle(cornerRadius: 22, style: .continuous)
                                    .fill(KnockColor.cardTint2)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: alignment(for: tab))
                        .accessibilityLabel(tab.title)
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("tab.\(tab.title)")
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 8)
        .padding(.bottom, 10)
        .background(KnockColor.background)
        .overlay(alignment: .top) { Rectangle().fill(KnockColor.tabBorder).frame(height: 1) }
    }

    private func alignment(for tab: MainTab) -> Alignment {
        switch tab {
        case .home: return .leading
        case .family: return .trailing
        default: return .center
        }
    }
}

/// 탭바 아이콘 (디자인 벡터 재현: 24×24)
struct TabIcon: View {
    var tab: MainTab
    var color: Color

    var body: some View {
        switch tab {
        case .home:
            VStack(spacing: 4) {
                HStack(spacing: 4) { square; square }
                HStack(spacing: 4) { square; square }
            }
        case .stats:
            HStack(alignment: .bottom, spacing: 3) {
                bar(10); bar(20); bar(14)
            }
        case .health:
            Image(systemName: "heart")
                .font(.system(size: 20, weight: .medium))
                .foregroundStyle(color)
        case .family:
            VStack(spacing: 1) {
                Circle().stroke(color, lineWidth: 2).frame(width: 8, height: 8)
                UnevenRoundedRectangle(topLeadingRadius: 8, bottomLeadingRadius: 3,
                                       bottomTrailingRadius: 3, topTrailingRadius: 8)
                    .stroke(color, lineWidth: 2)
                    .frame(width: 16, height: 10)
            }
        }
    }

    private var square: some View {
        RoundedRectangle(cornerRadius: 2).fill(color).frame(width: 8, height: 8)
    }

    private func bar(_ height: CGFloat) -> some View {
        Capsule().fill(color).frame(width: 4, height: height)
    }
}

/// 빈 상태 뷰 (기록 없음 / 가족 없음 등)
struct EmptyStateView: View {
    var image: String = "mascot_worried"
    var title: String
    var message: String
    var actionTitle: String? = nil
    var action: (() -> Void)? = nil

    var body: some View {
        VStack(spacing: 16) {
            Image(image).resizable().scaledToFit().frame(height: 140)
            Text(title).font(KnockFont.semibold(18)).foregroundStyle(KnockColor.textPrimary)
            Text(message)
                .font(KnockFont.regular(14))
                .foregroundStyle(KnockColor.textSecondary)
                .multilineTextAlignment(.center)
            if let actionTitle, let action {
                Button(actionTitle, action: action)
                    .font(KnockFont.medium(15))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 24).padding(.vertical, 12)
                    .background(KnockColor.primary, in: Capsule())
            }
        }
        .padding(32)
        .frame(maxWidth: .infinity)
    }
}
