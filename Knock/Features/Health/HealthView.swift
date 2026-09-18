import SwiftUI

enum HealthRoute: Hashable {
    case overview
    case sleep
    case heartRate
    case stress
    case breathing
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
                        case .breathing: BreathingExerciseView(path: $path)
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

                HStack(spacing: 12) {
                    if appState.healthConnection == .connected {
                        LiveHeartBadge()
                            .transition(.scale.combined(with: .opacity))
                    }
                    Button { path.append(.breathing) } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "wind")
                                .font(.system(size: 15, weight: .semibold))
                            Text("호흡 운동 1분")
                                .font(KnockFont.medium(14))
                        }
                        .foregroundStyle(KnockColor.textPrimary)
                        .padding(.horizontal, 16).padding(.vertical, 10)
                        .background(KnockColor.cardTint, in: Capsule())
                        .knockShadow(radius: 8, y: 3)
                    }
                    .buttonStyle(.pressable)
                }
                .animation(.spring(duration: 0.4), value: appState.healthConnection)
                .padding(.top, isGood ? 4 : 0)
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
                    ZStack {
                        Circle().stroke(Color.white.opacity(0.6), lineWidth: 8)
                        Circle()
                            .trim(from: 0, to: scoreProgress)
                            .stroke(overview.condition == .good ? KnockColor.primary : KnockColor.danger,
                                    style: StrokeStyle(lineWidth: 8, lineCap: .round))
                            .rotationEffect(.degrees(-90))
                        Text(String(format: "%.1f", displayedScore))
                            .font(KnockFont.bold(40))
                            .foregroundStyle(KnockColor.textPrimary)
                            .contentTransition(.numericText())
                            .monospacedDigit()
                    }
                    .frame(width: 150, height: 150)
                    .padding(.vertical, 4)
                    PillBadge(text: overview.scoreNote, background: .white, font: KnockFont.medium(11))
                }
                .onAppear { animateScore() }
                .onChange(of: overview.nightingaleScore) { _, _ in animateScore() }
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
                    HealthMetricCard(icon: "heart", title: appState.healthConnection == .connected ? "심박수 · 실시간" : "심박수",
                                     value: "\(appState.healthConnection == .connected ? appState.liveHeartRate : overview.heartRate)회/분",
                                     live: appState.healthConnection == .connected) { path.append(.heartRate) }
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
                    WatchTile(face: .heart) { path.append(.heartRate) }
                    WatchTile(face: .sleep) { path.append(.sleep) }
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
                    WatchTile(face: .relax) { path.append(.stress) }
                    WatchTile(face: .stress) { path.append(.stress) }
                }
                .padding(.horizontal, 16)

                HealthKitConnectCard()
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
            }
        }
    }

    @State private var scoreProgress: CGFloat = 0
    @State private var displayedScore: Double = 0

    private func animateScore() {
        scoreProgress = 0
        displayedScore = 0
        withAnimation(.easeOut(duration: 1.1)) {
            scoreProgress = CGFloat(overview.nightingaleScore / 100)
            displayedScore = overview.nightingaleScore
        }
    }

    private func watchLink(action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Text("에플워치").font(KnockFont.regular(12))
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
    var live: Bool = false
    var action: () -> Void
    @State private var beat = false

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 6) {
                    Image(systemName: live ? "heart.fill" : icon)
                        .font(.system(size: 14))
                        .foregroundStyle(live ? KnockColor.danger : KnockColor.primary)
                        .scaleEffect(live && beat ? 1.25 : 1)
                        .animation(live ? .easeInOut(duration: 0.45).repeatForever(autoreverses: true) : .default, value: beat)
                    Text(title).font(KnockFont.regular(12)).foregroundStyle(KnockColor.textSecondary)
                }
                Text(value).font(KnockFont.medium(18)).foregroundStyle(KnockColor.textPrimary)
                    .contentTransition(.numericText())
                    .animation(.easeInOut(duration: 0.3), value: value)
            }
            .onAppear { beat = live }
            .onChange(of: live) { _, v in beat = v }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.white, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            .knockShadow(radius: 12, y: 4)
        }
        .buttonStyle(.pressable)
    }
}

enum WatchFace { case heart, sleep, relax, stress }

/// 워치 화면 느낌의 타일 (SwiftUI 로 그려서 실시간 데이터와 애니메이션 반영)
struct WatchTile: View {
    @Environment(AppState.self) private var appState
    var face: WatchFace
    var action: () -> Void
    @State private var animate = false

    private var heartRate: Int {
        appState.healthConnection == .connected ? appState.liveHeartRate : appState.healthOverview.heartRate
    }

    var body: some View {
        Button(action: action) {
            ZStack(alignment: .topTrailing) {
                RoundedRectangle(cornerRadius: 16, style: .continuous).fill(.black)
                Text(Date.now.shortTime)
                    .font(KnockFont.medium(11)).foregroundStyle(.white).padding(10)
                content.padding(12)
            }
            .aspectRatio(1, contentMode: .fit)
            .frame(maxWidth: .infinity)
            .padding(8)
            .background(.white, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
            .knockShadow(radius: 18, y: 6)
        }
        .buttonStyle(.pressable)
        .onAppear { animate = true }
    }

    @ViewBuilder private var content: some View {
        switch face {
        case .heart:
            VStack(spacing: 6) {
                Spacer(minLength: 0)
                Image(systemName: "heart.fill")
                    .font(.system(size: 44))
                    .foregroundStyle(Color(red: 1, green: 0.23, blue: 0.19))
                    .shadow(color: .red.opacity(0.7), radius: animate ? 14 : 4)
                    .scaleEffect(animate ? 1.08 : 0.92)
                    .animation(.easeInOut(duration: 0.5).repeatForever(autoreverses: true), value: animate)
                Text("현재").font(KnockFont.regular(11)).foregroundStyle(.white.opacity(0.8))
                HStack(alignment: .firstTextBaseline, spacing: 3) {
                    Text("\(heartRate)").font(KnockFont.bold(26)).foregroundStyle(.white)
                        .contentTransition(.numericText()).monospacedDigit()
                    Text("회/분").font(KnockFont.medium(12)).foregroundStyle(Color(red: 1, green: 0.23, blue: 0.19))
                }
            }
            .frame(maxWidth: .infinity)
        case .sleep:
            VStack(spacing: 6) {
                Spacer(minLength: 0)
                ZStack {
                    Circle().stroke(Color(red: 0.55, green: 0.36, blue: 1).opacity(0.25), lineWidth: 9)
                    Circle().trim(from: 0, to: animate ? 0.9 : 0)
                        .stroke(Color(red: 0.62, green: 0.42, blue: 1), style: StrokeStyle(lineWidth: 9, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                        .animation(.easeOut(duration: 1.2), value: animate)
                    Image(systemName: "moon.zzz.fill").font(.system(size: 20)).foregroundStyle(.white)
                }
                .frame(width: 64, height: 64)
                Text("수면 90%").font(KnockFont.bold(18)).foregroundStyle(.white)
            }
            .frame(maxWidth: .infinity)
        case .relax:
            VStack(alignment: .leading, spacing: 4) {
                ZStack {
                    Circle().stroke(Color(red: 0.2, green: 0.75, blue: 1), lineWidth: 5)
                        .frame(width: 44, height: 44)
                        .scaleEffect(animate ? 1.15 : 0.9)
                        .animation(.easeInOut(duration: 2.4).repeatForever(autoreverses: true), value: animate)
                }
                .frame(height: 54)
                Spacer(minLength: 0)
                Text("호흡 운동").font(KnockFont.bold(17)).foregroundStyle(.white)
                Text("4초 들이쉬고 · 6초 내쉬기").font(KnockFont.regular(10)).foregroundStyle(Color(red: 0.6, green: 0.8, blue: 1))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        case .stress:
            VStack(alignment: .leading, spacing: 6) {
                Spacer(minLength: 0)
                HStack(alignment: .bottom, spacing: 4) {
                    ForEach(Array([0.5, 0.8, 0.35, 0.6, 0.95, 0.45, 0.7].enumerated()), id: \.offset) { i, h in
                        RoundedRectangle(cornerRadius: 2)
                            .fill(h > 0.75 ? Color(red: 1, green: 0.4, blue: 0.3) : Color(red: 0.36, green: 0.85, blue: 0.5))
                            .frame(height: animate ? 46 * h : 4)
                            .animation(.spring(duration: 0.7).delay(Double(i) * 0.06), value: animate)
                    }
                }
                .frame(height: 46)
                Text("스트레스").font(KnockFont.bold(17)).foregroundStyle(.white)
                Text("오늘 대부분 좋은 상태").font(KnockFont.regular(10)).foregroundStyle(.white.opacity(0.7))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

/// [보충 화면] 건강 앱 연동 안내 카드 (연결 중 스피너 → 연결됨)
struct HealthKitConnectCard: View {
    @Environment(AppState.self) private var appState
    @State private var spin = false

    private var state: HealthConnection { appState.healthConnection }

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                if state == .connecting {
                    Circle()
                        .trim(from: 0.15, to: 0.85)
                        .stroke(KnockColor.primary, style: StrokeStyle(lineWidth: 2.5, lineCap: .round))
                        .frame(width: 40, height: 40)
                        .rotationEffect(.degrees(spin ? 360 : 0))
                        .animation(.linear(duration: 0.9).repeatForever(autoreverses: false), value: spin)
                        .onAppear { spin = true }
                        .onDisappear { spin = false }
                }
                Image(systemName: state == .connected ? "checkmark.circle.fill" : "heart.text.square.fill")
                    .font(.system(size: 28))
                    .foregroundStyle(state == .connected ? KnockColor.primary : KnockColor.danger)
                    .contentTransition(.symbolEffect(.replace))
            }
            .frame(width: 40, height: 40)
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(KnockFont.medium(15)).foregroundStyle(KnockColor.textPrimary)
                    .contentTransition(.opacity)
                Text(subtitle)
                    .font(KnockFont.regular(12)).foregroundStyle(KnockColor.textSecondary)
                    .contentTransition(.opacity)
            }
            Spacer()
            Button {
                if state == .connected { appState.disconnectHealth() } else { appState.connectHealth() }
            } label: {
                Text(buttonTitle)
                    .font(KnockFont.medium(13))
                    .foregroundStyle(state == .connected ? KnockColor.textSecondary : .white)
                    .padding(.horizontal, 14).padding(.vertical, 8)
                    .background(state == .connected ? KnockColor.sheet : KnockColor.primary, in: Capsule())
            }
            .disabled(state == .connecting)
        }
        .padding(16)
        .background(.white, in: RoundedRectangle(cornerRadius: 18))
        .overlay {
            RoundedRectangle(cornerRadius: 18)
                .stroke(state == .connected ? KnockColor.primary.opacity(0.5) : .clear, lineWidth: 1.5)
        }
        .knockShadow(radius: 12, y: 4)
        .animation(.spring(duration: 0.4), value: state)
    }

    private var title: String {
        switch state {
        case .disconnected: return "건강 앱 연결하기"
        case .connecting: return "건강 앱에 연결하는 중..."
        case .connected: return "건강 앱과 연결됨"
        }
    }

    private var subtitle: String {
        switch state {
        case .disconnected: return "심박수·수면·스트레스 데이터를 자동으로 가져와요."
        case .connecting: return "에플워치 데이터 권한을 확인하고 있어요."
        case .connected: return "에플워치 데이터를 실시간으로 가져와요."
        }
    }

    private var buttonTitle: String {
        switch state {
        case .disconnected: return "연결"
        case .connecting: return "연결 중"
        case .connected: return "해제"
        }
    }
}

/// 실시간 심박수 배지 (건강 앱 연결 시)
struct LiveHeartBadge: View {
    @Environment(AppState.self) private var appState
    @State private var beat = false

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "heart.fill")
                .font(.system(size: 14))
                .foregroundStyle(KnockColor.danger)
                .scaleEffect(beat ? 1.3 : 1)
                .animation(.easeInOut(duration: 0.45).repeatForever(autoreverses: true), value: beat)
            Text("\(appState.liveHeartRate)")
                .font(KnockFont.bold(16))
                .foregroundStyle(KnockColor.textPrimary)
                .contentTransition(.numericText())
                .monospacedDigit()
            Text("회/분").font(KnockFont.regular(12)).foregroundStyle(KnockColor.textSecondary)
        }
        .padding(.horizontal, 14).padding(.vertical, 10)
        .background(.white, in: Capsule())
        .knockShadow(radius: 8, y: 3)
        .onAppear { beat = true }
    }
}
