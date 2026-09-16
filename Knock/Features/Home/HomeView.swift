import SwiftUI
import MapKit

struct HomeView: View {
    @Environment(AppState.self) private var appState
    @Binding var showNotifications: Bool
    @Binding var showSettings: Bool
    @State private var showMap = false
    @State private var showDemoMenu = false

    var body: some View {
        GreenScaffold(headerColor: appState.isDangerMode ? KnockColor.primary : KnockColor.primary) {
            UserHeader(user: appState.user, isOnline: !appState.isDangerMode,
                       trailing: AnyView(HeaderActions(showNotifications: $showNotifications, showSettings: $showSettings)),
                       onAvatarTap: { showSettings = true })
        } content: {
            switch appState.safety {
            case .checkedIn, .resolved:
                CheckedInContent(showMap: $showMap)
            case .idle, .dangerPending:
                CheckPendingContent()
            case .emergencyContacting:
                EmergencyContactingContent()
            }
        }
        .sheet(isPresented: $showMap) { FamilyMapView() }
        .overlay(alignment: .bottomTrailing) {
            // 데모용 시나리오 전환 버튼
            Menu {
                Button("체크 완료 상태 (01)") { appState.checkIn() }
                Button("위험 감지 시나리오 (02·12)") { appState.simulateDangerDetected() }
                Button("비상 연락 진행중 (03)") { appState.startEmergencyContact() }
                Button("초기화 (체크 전)") { appState.resetSafetyDemo() }
            } label: {
                Image(systemName: "wand.and.stars")
                    .font(.system(size: 14))
                    .foregroundStyle(KnockColor.textMuted)
                    .padding(10)
                    .background(.white.opacity(0.9), in: Circle())
                    .knockShadow(radius: 6, y: 2)
            }
            .padding(.trailing, 16)
            .padding(.bottom, 8)
        }
    }
}

// MARK: - 01 체크 완료

private struct CheckedInContent: View {
    @Environment(AppState.self) private var appState
    @Binding var showMap: Bool

    var body: some View {
        VStack(spacing: 20) {
            WeeklyCalendarCard()
                .padding(.horizontal, 16)
                .padding(.top, 16)

            Image("mascot_happy")
                .resizable()
                .scaledToFit()
                .frame(height: 170)

            VStack(spacing: 10) {
                Text("체크 완료")
                    .font(KnockFont.bold(30))
                    .foregroundStyle(KnockColor.textPrimary)
                PillBadge(text: "오늘 상태 : 안전", icon: "checkmark.shield")
            }

            CountdownCard(title: "다음 알람 남은 시간", target: appState.nextReminderDate, showBell: true)
                .padding(.horizontal, 16)

            Text("체크 안 하면 비상연락처 문자 & 전화로 안내")
                .font(KnockFont.regular(12))
                .foregroundStyle(KnockColor.textSecondary)

            FamilyMapCard(region: appState.user.region) { showMap = true }
                .padding(.horizontal, 16)
        }
    }
}

/// 나의 주간 캘린더
struct WeeklyCalendarCard: View {
    @Environment(AppState.self) private var appState
    private let symbols = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]

    var body: some View {
        SectionCard(padding: 16) {
            VStack(spacing: 14) {
                HStack {
                    Text("나의 주간 캘린더")
                        .font(KnockFont.medium(16))
                        .foregroundStyle(KnockColor.textPrimary)
                    Spacer()
                    PillBadge(text: "\(appState.streakDays)일 연속 출석 중", font: KnockFont.medium(11))
                }
                HStack(spacing: 0) {
                    ForEach(Array(appState.weekRecords.enumerated()), id: \.element.id) { i, record in
                        VStack(spacing: 6) {
                            Text(symbols[i % symbols.count])
                                .font(KnockFont.regular(11))
                                .foregroundStyle(KnockColor.textSecondary)
                            ZStack {
                                Circle()
                                    .fill(record.completed ? KnockColor.primary : KnockColor.sheet)
                                    .frame(width: 26, height: 26)
                                if record.completed {
                                    Image(systemName: record.status == .danger ? "exclamationmark" : "checkmark")
                                        .font(.system(size: 12, weight: .bold))
                                        .foregroundStyle(.white)
                                }
                            }
                            Text("\(Calendar.current.component(.day, from: record.date))")
                                .font(KnockFont.regular(11))
                                .foregroundStyle(record.completed ? KnockColor.textPrimary : KnockColor.textDisabled)
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
            }
        }
    }
}

/// 다음 알람 카운트다운 카드
struct CountdownCard: View {
    var title: String
    var target: Date?
    var showBell: Bool = false
    var accent: Color = KnockColor.textPrimary

    var body: some View {
        TimelineView(.periodic(from: .now, by: 1)) { context in
            VStack(spacing: 6) {
                Text(title)
                    .font(KnockFont.medium(14))
                    .foregroundStyle(KnockColor.textPrimary)
                HStack(spacing: 10) {
                    Text(formatted(now: context.date))
                        .font(KnockFont.bold(38))
                        .monospacedDigit()
                        .foregroundStyle(accent)
                    if showBell {
                        Image(systemName: "bell")
                            .font(.system(size: 22))
                            .foregroundStyle(KnockColor.primary)
                    }
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(KnockColor.cardTint, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        }
    }

    private func formatted(now: Date) -> String {
        guard let target else { return "00 : 00" }
        let remaining = max(0, Int(target.timeIntervalSince(now)))
        if remaining >= 3600 {
            return String(format: "%02d : %02d", remaining / 3600, (remaining % 3600) / 60)
        }
        return String(format: "%02d : %02d", remaining / 60, remaining % 60)
    }
}

/// 우리 가족 위치 카드
struct FamilyMapCard: View {
    var region: String
    var action: () -> Void

    var body: some View {
        SectionCard(padding: 14) {
            VStack(spacing: 10) {
                HStack {
                    Text("우리 가족 위치").font(KnockFont.medium(14)).foregroundStyle(KnockColor.textPrimary)
                    Spacer()
                    Text(region).font(KnockFont.regular(12)).foregroundStyle(KnockColor.textSecondary)
                }
                Button(action: action) {
                    Image("map_preview")
                        .resizable()
                        .scaledToFill()
                        .frame(height: 120)
                        .frame(maxWidth: .infinity)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                        .overlay(alignment: .bottomTrailing) {
                            Text("지도 열기")
                                .font(KnockFont.medium(10))
                                .foregroundStyle(KnockColor.link)
                                .padding(.horizontal, 8).padding(.vertical, 4)
                                .background(.white, in: Capsule())
                                .padding(8)
                        }
                }
                .buttonStyle(.pressable)
            }
        }
    }
}

// MARK: - 02 오늘 체크 (대기 / 위험)

private struct CheckPendingContent: View {
    @Environment(AppState.self) private var appState

    private var deadline: Date? {
        if case .dangerPending(let d) = appState.safety { return d }
        return nil
    }

    var body: some View {
        VStack(spacing: 18) {
            Image(appState.isDangerMode ? "mascot_worried" : "mascot_happy")
                .resizable()
                .scaledToFit()
                .frame(height: 230)
                .padding(.top, 24)

            Text("오늘 체크")
                .font(KnockFont.bold(30))
                .foregroundStyle(KnockColor.textPrimary)

            Button {
                appState.checkIn()
            } label: {
                Text("오늘 체크")
                    .font(KnockFont.medium(18))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 62)
                    .background(KnockColor.yellow, in: Capsule())
            }
            .buttonStyle(.pressable)
            .padding(.horizontal, 16)

            PillBadge(
                text: appState.isDangerMode ? "오늘 상태 : 위험" : "오늘 상태 : 확인 전",
                foreground: appState.isDangerMode ? KnockColor.textPrimary : KnockColor.textSecondary,
                background: appState.isDangerMode ? KnockColor.yellow : KnockColor.cardTint
            )

            CountdownCard(title: appState.isDangerMode ? "비상 연락까지 남은 시간" : "다음 알람 남은 시간",
                          target: deadline ?? appState.nextReminderDate)
                .padding(.horizontal, 16)

            Text("체크 안 하면 비상연락처 문자 & 전화로 안내")
                .font(KnockFont.regular(12))
                .foregroundStyle(KnockColor.textSecondary)
        }
    }
}

// MARK: - 03 비상 연락 진행중

private struct EmergencyContactingContent: View {
    @Environment(AppState.self) private var appState
    @State private var showCancelConfirm = false

    var body: some View {
        VStack(spacing: 16) {
            HStack(alignment: .top) {
                Text("비상 연락 진행중")
                    .font(KnockFont.bold(24))
                    .foregroundStyle(KnockColor.textPrimary)
                Spacer()
                Image("mascot_alert_small").resizable().scaledToFit().frame(height: 80)
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)

            ForEach(appState.emergencyContacts) { contact in
                EmergencyContactRow(contact: contact)
                    .padding(.horizontal, 16)
            }

            CountdownCard(title: "다음 연락 시도 까지",
                          target: Date.now.addingTimeInterval(59))
                .padding(.horizontal, 16)

            PrimaryButton(title: "저는 안전해요 · 연락 중단", style: .green) { showCancelConfirm = true }
                .padding(.horizontal, 16)
                .padding(.top, 8)

            Text("등록된 순서대로 문자와 전화로 안내하고 있어요.\n연결되면 자동으로 다음 연락처로 넘어가지 않아요.")
                .font(KnockFont.regular(12))
                .foregroundStyle(KnockColor.textSecondary)
                .multilineTextAlignment(.center)
        }
        .confirmationDialog("안전 상태를 확인할까요?", isPresented: $showCancelConfirm, titleVisibility: .visible) {
            Button("네, 안전해요") { appState.cancelEmergency() }
            Button("취소", role: .cancel) {}
        } message: {
            Text("비상 연락을 중단하고 오늘 체크인을 완료합니다.")
        }
    }
}

struct EmergencyContactRow: View {
    var contact: EmergencyContact

    var body: some View {
        SectionCard(padding: 16) {
            HStack(spacing: 14) {
                Text("\(contact.priority)")
                    .font(KnockFont.bold(26))
                    .foregroundStyle(KnockColor.textPrimary)
                VStack(alignment: .leading, spacing: 4) {
                    Text(contact.name).font(KnockFont.medium(16)).foregroundStyle(KnockColor.textPrimary)
                    Text(contact.phone).font(KnockFont.regular(13)).foregroundStyle(KnockColor.textSecondary)
                }
                Spacer()
                stateBadge
            }
        }
    }

    @ViewBuilder private var stateBadge: some View {
        switch contact.state {
        case .contacting:
            PillBadge(text: "연락중...", foreground: KnockColor.textPrimary, background: KnockColor.yellow)
        case .waiting:
            PillBadge(text: "대기중...", foreground: KnockColor.textSecondary, background: KnockColor.sheet)
        case .reached:
            PillBadge(text: "연결됨", foreground: .white, background: KnockColor.primary, icon: "checkmark")
        case .failed:
            PillBadge(text: "실패", foreground: .white, background: KnockColor.danger)
        }
    }
}

// MARK: - 12 안전 확인 모달

struct SafetyAlertOverlay: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        ZStack {
            Color.black.opacity(0.45).ignoresSafeArea()
                .onTapGesture {}

            VStack(spacing: 0) {
                VStack(spacing: 16) {
                    Image("mascot_modal")
                        .resizable()
                        .scaledToFit()
                        .frame(height: 130)
                        .padding(.top, 8)

                    Text("위험 상황으로 의심되는 상태가 감지되었습니다.\n지금 바로 안전 상태를 확인해 주세요.")
                        .font(KnockFont.medium(15))
                        .foregroundStyle(KnockColor.textPrimary)
                        .multilineTextAlignment(.center)
                        .lineSpacing(3)

                    Text("\(appState.settings.graceMinutes)분 이내에 응답하지 않으면\n긴급 연락처로 자동 연락됩니다")
                        .font(KnockFont.regular(13))
                        .foregroundStyle(KnockColor.textSecondary)
                        .multilineTextAlignment(.center)

                    PrimaryButton(title: "안전 확인", style: .green) { appState.confirmSafe() }
                        .frame(height: 52)

                    Button("도움이 필요해요 · 지금 비상 연락") { appState.startEmergencyContact() }
                        .font(KnockFont.medium(13))
                        .foregroundStyle(KnockColor.dangerText)
                }
                .padding(24)
                .background(KnockColor.background, in: RoundedRectangle(cornerRadius: 28, style: .continuous))
                .padding(.horizontal, 28)

                Text("알람 뜨는중.....")
                    .font(KnockFont.medium(18))
                    .foregroundStyle(.white)
                    .padding(.top, 24)
            }
        }
    }
}

// MARK: - 가족 위치 지도 (보충 화면)

struct FamilyMapView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.dismiss) private var dismiss
    @State private var position: MapCameraPosition = .region(
        MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: 35.175, longitude: 126.912),
                           span: MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02))
    )
    @State private var selected: FamilyMember?

    var body: some View {
        NavigationStack {
            Map(position: $position) {
                Annotation("나", coordinate: CLLocationCoordinate2D(latitude: 35.1760, longitude: 126.9105)) {
                    AvatarView(asset: appState.user.avatarAsset, size: 40, ring: KnockColor.yellow)
                }
                ForEach(appState.members) { m in
                    Annotation(m.name, coordinate: CLLocationCoordinate2D(latitude: m.latitude, longitude: m.longitude)) {
                        Button { selected = m } label: {
                            AvatarView(asset: m.avatarAsset, size: 40, isOnline: m.isOnline, ring: KnockColor.primary)
                        }
                    }
                }
            }
            .mapStyle(.standard(pointsOfInterest: .excludingAll))
            .navigationTitle("우리 가족 위치")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .topBarTrailing) { Button("닫기") { dismiss() } } }
            .sheet(item: $selected) { m in
                FamilyMemberDetailView(member: m)
            }
        }
    }
}

extension AppState {
    /// 다음 체크인 알림 시각
    var nextReminderDate: Date {
        let cal = Calendar.current
        var comps = cal.dateComponents([.year, .month, .day], from: .now)
        comps.hour = settings.deadlineHour
        comps.minute = settings.deadlineMinute
        var date = cal.date(from: comps) ?? .now
        if date <= .now { date = cal.date(byAdding: .day, value: 1, to: date) ?? date }
        return date
    }
}
