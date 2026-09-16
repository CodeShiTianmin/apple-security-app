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
                        .frame(width: size * 0.26, height: size * 0.26)
                        .overlay(Circle().stroke(.white, lineWidth: 1.5))
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
    var user: UserProfile
    var isOnline: Bool
    var trailing: AnyView? = nil
    var onAvatarTap: () -> Void = {}

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                Button(action: onAvatarTap) {
                    AvatarView(asset: user.avatarAsset, size: 46, isOnline: isOnline)
                }
                .buttonStyle(.plain)

                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 8) {
                        Text("\(user.name)님")
                            .font(KnockFont.medium(18))
                            .foregroundStyle(.white)
                        PillBadge(
                            text: isOnline ? "ONLINE" : "OFFLINE",
                            foreground: isOnline ? KnockColor.textPrimary : KnockColor.dangerText,
                            background: isOnline ? KnockColor.cardTint : KnockColor.dangerBadge,
                            font: KnockFont.medium(11)
                        )
                    }
                    Text(user.region)
                        .font(KnockFont.regular(12))
                        .foregroundStyle(.white.opacity(0.9))
                }
                Spacer()
                if let trailing { trailing }
            }
            Text("오늘도 체크하고 화이팅 하자")
                .font(KnockFont.medium(14))
                .foregroundStyle(.white)
        }
        .padding(.horizontal, 20)
        .padding(.top, 8)
        .padding(.bottom, 20)
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
    var badge: [MainTab: Int] = [:]

    var body: some View {
        HStack {
            ForEach(MainTab.allCases) { tab in
                Button {
                    withAnimation(.spring(duration: 0.3)) { selection = tab }
                } label: {
                    ZStack(alignment: .topTrailing) {
                        Image(systemName: icon(for: tab))
                            .font(.system(size: 22, weight: .regular))
                            .foregroundStyle(selection == tab ? KnockColor.primary : KnockColor.textMuted)
                            .frame(width: 64, height: 48)
                            .background {
                                if selection == tab {
                                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                                        .fill(KnockColor.cardTint2)
                                }
                            }
                        if let count = badge[tab], count > 0 {
                            Text("\(count)")
                                .font(KnockFont.semibold(10))
                                .foregroundStyle(.white)
                                .padding(.horizontal, 5).padding(.vertical, 2)
                                .background(KnockColor.warning, in: Capsule())
                                .offset(x: -6, y: 4)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .accessibilityLabel(tab.title)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 12)
        .padding(.top, 10)
        .padding(.bottom, 4)
        .background(KnockColor.background)
    }

    private func icon(for tab: MainTab) -> String {
        switch tab {
        case .home: return "square.grid.2x2.fill"
        case .stats: return "chart.bar.fill"
        case .health: return "heart"
        case .family: return "person"
        }
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
