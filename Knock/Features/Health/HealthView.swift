import SwiftUI

enum HealthRoute: Hashable {
    case overview
    case sleep
    case heartRate
    case stress
}

struct HealthView: View {
    @Environment(AppState.self) private var appState
    @Binding var showSettings: Bool
    @State private var path: [HealthRoute] = []

    var body: some View {
        NavigationStack(path: $path) {
            HealthStatusView(path: $path, showSettings: $showSettings)
                .navigationDestination(for: HealthRoute.self) { route in
                    Group {
                        switch route {
                        case .overview: HealthOverviewView(path: $path, showSettings: $showSettings)
                        case .sleep: SleepDetailView(path: $path, showSettings: $showSettings)
                        case .heartRate: HeartRateDetailView(path: $path, showSettings: $showSettings)
                        case .stress: StressDetailView(path: $path, showSettings: $showSettings)
                        }
                    }
                    .toolbar(.hidden, for: .navigationBar)
                }
                .toolbar(.hidden, for: .navigationBar)
        }
    }
}

// MARK: - 09 / 11 건강 상태

struct HealthStatusView: View {
    @Environment(AppState.self) private var appState
    @Binding var path: [HealthRoute]
    @Binding var showSettings: Bool
    @State private var pulse = false

    private var isGood: Bool { appState.healthOverview.condition == .good }

    var body: some View {
        GreenScaffold {
            UserHeader(user: appState.user, isOnline: isGood,
                       onAvatarTap: { showSettings = true })
        } content: {
            VStack(spacing: isGood ? 12 : 24) {
                ZStack {
                    if !isGood {
                        Circle()
                            .fill(KnockColor.dangerHalo)
                            .frame(width: 250, height: 250)
                            .scaleEffect(pulse ? 1.08 : 0.96)
                            .animation(.easeInOut(duration: 1.4).repeatForever(autoreverses: true), value: pulse)
                    }
                    Image(isGood ? "mascot_health_good" : "mascot_health_bad")
                        .resizable()
                        .scaledToFit()
                }
                .frame(maxWidth: .infinity)
                .frame(height: isGood ? 340 : 310)
                .padding(.horizontal, 20)
                .padding(.top, isGood ? 100 : 112)

                Button { path.append(.overview) } label: {
                    Text("● 오늘 건강 상태 : \(appState.healthOverview.condition.rawValue)")
                        .font(KnockFont.medium(18))
                        .foregroundStyle(isGood ? KnockColor.textPrimary : KnockColor.danger)
                        .frame(height: 26)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                        .background(isGood ? KnockColor.healthGoodPill : KnockColor.healthBadPill,
                                    in: RoundedRectangle(cornerRadius: 24, style: .continuous))
                        .knockShadow()
                }
                .buttonStyle(.pressable)

                if !isGood {
                    Text("알람 뜨는중.....")
                        .font(KnockFont.medium(20))
                        .foregroundStyle(KnockColor.textPrimary)
                }
            }
            .padding(.bottom, 16)
        }
        .onAppear { pulse = true }
        .overlay(alignment: .bottomTrailing) {
            Button { withAnimation { appState.toggleHealthCondition() } } label: {
                Image(systemName: "arrow.triangle.2.circlepath")
                    .font(.system(size: 14))
                    .foregroundStyle(KnockColor.textMuted)
                    .padding(10)
                    .background(.white.opacity(0.9), in: Circle())
                    .knockShadow(radius: 6, y: 2)
            }
            .accessibilityLabel("건강 상태 데모 전환")
            .padding(.trailing, 16)
            .padding(.bottom, 82)
        }
    }
}

// MARK: - 10 건강 데이터 총람

struct HealthOverviewView: View {
    @Environment(AppState.self) private var appState
    @Binding var path: [HealthRoute]
    @Binding var showSettings: Bool

    private var overview: HealthOverview { appState.healthOverview }

    var body: some View {
        GreenScaffold {
            UserHeader(user: appState.user, isOnline: true,
                       onAvatarTap: { showSettings = true })
        } content: {
            VStack(alignment: .leading, spacing: 18) {
                // 나이팅게일 점수
                VStack(spacing: 10) {
                    HStack {
                        CircleIconButton(systemImage: "chevron.left", size: 36) { path.removeLast() }
                        Spacer()
                        Text("나이팅게일 점수").font(KnockFont.medium(14)).foregroundStyle(KnockColor.textPrimary)
                        Spacer()
                        CircleIconButton(systemImage: "ellipsis", size: 36) {}
                    }
                    Text(String(format: "%.1f", overview.nightingaleScore))
                        .font(KnockFont.bold(44))
                        .foregroundStyle(KnockColor.textPrimary)
                    PillBadge(text: overview.scoreNote, background: .white, font: KnockFont.medium(11))
                }
                .padding(16)
                .frame(maxWidth: .infinity)
                .background(
                    LinearGradient(colors: [KnockColor.cardTint2, KnockColor.cardTint3],
                                   startPoint: .top, endPoint: .bottom),
                    in: RoundedRectangle(cornerRadius: 24, style: .continuous)
                )
                .knockShadow(radius: 18, y: 6)
                .padding(.horizontal, 20)
                .padding(.top, 16)

                Text("나의 건강 상태")
                    .font(KnockFont.medium(16))
                    .foregroundStyle(KnockColor.textPrimary)
                    .padding(.horizontal, 20)

                HStack(spacing: 12) {
                    HealthMetricCard(icon: "heart", title: "심박수", value: "\(overview.heartRate) bpm") { path.append(.heartRate) }
                    HealthMetricCard(icon: "moon", title: "수면", value: "\(format(overview.sleepHoursPerDay)) 시간/하루") { path.append(.sleep) }
                }
                .padding(.horizontal, 16)

                HStack {
                    watchLink { path.append(.heartRate) }
                    Spacer()
                    watchLink { path.append(.sleep) }
                }
                .padding(.horizontal, 20)

                HStack(spacing: 12) {
                    WatchTile(asset: "watch_heart") { path.append(.heartRate) }
                    WatchTile(asset: "watch_sleep") { path.append(.sleep) }
                }
                .padding(.horizontal, 16)

                HStack(spacing: 8) {
                    Image(systemName: "figure.mind.and.body").foregroundStyle(KnockColor.primary)
                    Text("나의 스트레스").font(KnockFont.medium(16)).foregroundStyle(KnockColor.textPrimary)
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .overlay(alignment: .bottom) { Rectangle().fill(KnockColor.divider).frame(height: 1).padding(.horizontal, 16) }

                watchLink { path.append(.stress) }.padding(.horizontal, 20)

                HStack(spacing: 12) {
                    WatchTile(asset: "watch_relax") { path.append(.stress) }
                    WatchTile(asset: "watch_stress") { path.append(.stress) }
                }
                .padding(.horizontal, 16)

                HealthKitConnectCard()
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
            }
        }
    }

    private func watchLink(action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Text("AppleWatch").font(KnockFont.regular(12))
                Image(systemName: "chevron.right").font(.system(size: 9, weight: .semibold))
            }
            .foregroundStyle(KnockColor.textSecondary)
        }
    }

    private func format(_ v: Double) -> String {
        v == v.rounded() ? String(Int(v)) : String(format: "%.1f", v)
    }
}

struct HealthMetricCard: View {
    var icon: String
    var title: String
    var value: String
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 6) {
                    Image(systemName: icon).font(.system(size: 14)).foregroundStyle(KnockColor.primary)
                    Text(title).font(KnockFont.regular(12)).foregroundStyle(KnockColor.textSecondary)
                }
                Text(value).font(KnockFont.medium(18)).foregroundStyle(KnockColor.textPrimary)
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.white, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            .knockShadow(radius: 12, y: 4)
        }
        .buttonStyle(.pressable)
    }
}

struct WatchTile: View {
    var asset: String
    var action: () -> Void
    var body: some View {
        Button(action: action) {
            Image(asset)
                .resizable()
                .scaledToFit()
                .frame(maxWidth: .infinity)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .padding(8)
                .background(.white, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
                .knockShadow(radius: 18, y: 6)
        }
        .buttonStyle(.pressable)
    }
}

/// [보충 화면] 건강 앱 연동 안내 카드
struct HealthKitConnectCard: View {
    @State private var connected = false
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "heart.text.square.fill")
                .font(.system(size: 28))
                .foregroundStyle(KnockColor.danger)
            VStack(alignment: .leading, spacing: 4) {
                Text(connected ? "건강 앱과 연결됨" : "건강 앱 연결하기")
                    .font(KnockFont.medium(15)).foregroundStyle(KnockColor.textPrimary)
                Text(connected ? "Apple Watch 데이터를 자동으로 가져와요." : "심박수·수면·스트레스 데이터를 자동으로 가져와요.")
                    .font(KnockFont.regular(12)).foregroundStyle(KnockColor.textSecondary)
            }
            Spacer()
            Button(connected ? "해제" : "연결") { withAnimation { connected.toggle() } }
                .font(KnockFont.medium(13))
                .foregroundStyle(connected ? KnockColor.textSecondary : .white)
                .padding(.horizontal, 14).padding(.vertical, 8)
                .background(connected ? KnockColor.sheet : KnockColor.primary, in: Capsule())
        }
        .padding(16)
        .background(.white, in: RoundedRectangle(cornerRadius: 18))
        .knockShadow(radius: 12, y: 4)
    }
}
