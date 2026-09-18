import SwiftUI
import MapKit

struct HomeView: View {
    @Environment(AppState.self) private var appState
    @Binding var showSettings: Bool
    @State private var showMap = false
    @State private var showMoodPicker = false
    @State private var showCalendar = false

    var body: some View {
        GreenScaffold {
            UserHeader(user: appState.user, isOnline: !appState.isDangerMode,
                       onAvatarTap: { showSettings = true })
        } content: {
            Group {
                switch appState.safety {
                case .checkedIn:
                    CheckedInContent(showMap: $showMap, showCalendar: $showCalendar)
                        .transition(.opacity.combined(with: .move(edge: .bottom)))
                case .resolved(let name):
                    EmergencyResolvedContent(responder: name, showMap: $showMap)
                        .transition(.opacity.combined(with: .scale(scale: 0.96)))
                case .idle, .dangerPending:
                    CheckPendingContent(showMoodPicker: $showMoodPicker)
                        .transition(.opacity)
                case .emergencyContacting:
                    EmergencyContactingContent()
                        .transition(.opacity.combined(with: .move(edge: .trailing)))
                }
            }
            .animation(.spring(duration: 0.45), value: appState.safety)
        }
        .sheet(isPresented: $showMap) { FamilyMapView() }
        .sheet(isPresented: $showCalendar) { MyCheckInCalendarView() }
        .sheet(isPresented: $showMoodPicker) {
            MoodPickerSheet { mood in
                showMoodPicker = false
                appState.checkIn(mood: mood)
            }
            .presentationDetents([.height(380)])
            .presentationDragIndicator(.visible)
            .presentationBackground(KnockColor.background)
        }
        .overlay(alignment: .bottomTrailing) {
            // 데모용 시나리오 전환 버튼
            Menu {
                Button("체크 완료 상태 (01)") { appState.checkIn() }
                Button("위험 감지 시나리오 (02·12)") { appState.simulateDangerDetected() }
                Button("비상 연락 진행중 (03)") { appState.startEmergencyContact() }
                Button("가족 응답 완료 (종료)") { appState.resolveEmergency(by: appState.emergencyContacts.first?.name ?? "엄마") }
                Button("가족 실시간 이벤트 발생") { appState.applyLiveEvent() }
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
    @Binding var showCalendar: Bool
    @State private var bounce = false

    var body: some View {
        VStack(spacing: 12) {
            Button { showCalendar = true } label: {
                WeeklyCalendarCard()
            }
            .buttonStyle(.pressable)
            .padding(.horizontal, 20)
            .padding(.top, 20)

            Image("mascot_happy")
                .resizable()
                .scaledToFit()
                .frame(height: 200)
                .scaleEffect(bounce ? 1.0 : 0.94)
                .offset(y: bounce ? 0 : 6)
                .animation(.easeInOut(duration: 1.6).repeatForever(autoreverses: true), value: bounce)
                .onAppear { bounce = true }

            VStack(spacing: 4) {
                Text("체크 완료")
                    .font(KnockFont.bold(38))
                    .foregroundStyle(KnockColor.textPrimary)
                HStack(spacing: 8) {
                    PillBadge(text: "오늘 상태 : 안전", icon: "checkmark.shield",
                              font: KnockFont.medium(14), radius: 16, iconSize: 15)
                    if let mood = appState.todayMood {
                        PillBadge(text: "\(mood.emoji) \(mood.rawValue)", foreground: KnockColor.textPrimary,
                                  background: KnockColor.yellow, font: KnockFont.medium(14), radius: 16)
                            .transition(.scale.combined(with: .opacity))
                    }
                }
            }
            .padding(.vertical, 4)

            CountdownCard(title: "다음 알람 남은 시간", target: appState.nextReminderDate, showBell: true)
                .padding(.horizontal, 20)

            Text("체크 안 하면 비상연락처 문자 & 전화로 안내")
                .font(KnockFont.regular(14))
                .foregroundStyle(KnockColor.textSecondary)

            FamilyMapCard(region: appState.user.region) { showMap = true }
                .padding(.horizontal, 20)
        }
        .padding(.bottom, 12)
    }
}

/// 나의 주간 캘린더
struct WeeklyCalendarCard: View {
    @Environment(AppState.self) private var appState
    private let symbols = ["월", "화", "수", "목", "금", "토", "일"]

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Text("나의 주간 캘린더")
                    .font(KnockFont.medium(18))
                    .foregroundStyle(KnockColor.textPrimary)
                Spacer()
                PillBadge(text: "\(appState.streakDays)일 연속 출석 중")
                    .contentTransition(.numericText())
                    .animation(.spring(duration: 0.5), value: appState.streakDays)
            }
            .padding(.vertical, 2)
            HStack(spacing: 0) {
                ForEach(Array(appState.weekRecords.enumerated()), id: \.element.id) { i, record in
                    let isToday = Calendar.current.isDateInToday(record.date)
                    VStack(spacing: 4) {
                        Text(symbols[i % symbols.count])
                            .font(KnockFont.medium(12))
                            .foregroundStyle(KnockColor.textSecondary)
                        ZStack {
                            Circle()
                                .fill(record.completed ? KnockColor.primary : KnockColor.pendingDay)
                                .frame(width: 28, height: 28)
                                .overlay {
                                    if isToday {
                                        Circle().stroke(KnockColor.yellow, lineWidth: 2).padding(-2)
                                    }
                                }
                            if record.completed {
                                if let mood = record.mood {
                                    Text(mood.emoji).font(.system(size: 15))
                                        .transition(.scale)
                                } else {
                                    Image(systemName: record.status == .danger ? "exclamationmark" : "checkmark")
                                        .font(.system(size: 13, weight: .bold))
                                        .foregroundStyle(.white)
                                }
                            }
                        }
                        .animation(.spring(duration: 0.45), value: record.completed)
                        Text("\(Calendar.current.component(.day, from: record.date))")
                            .font(KnockFont.medium(12))
                            .foregroundStyle(record.completed ? KnockColor.textPrimary : KnockColor.textMuted)
                    }
                    .padding(.vertical, 4)
                    .frame(maxWidth: .infinity)
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
            VStack(spacing: 4) {
                Text(title)
                    .font(KnockFont.medium(14))
                    .foregroundStyle(KnockColor.textPrimary)
                HStack(spacing: 16) {
                    Text(formatted(now: context.date))
                        .font(KnockFont.bold(38))
                        .monospacedDigit()
                        .foregroundStyle(accent)
                    if showBell {
                        Image(systemName: "bell")
                            .font(.system(size: 20, weight: .medium))
                            .foregroundStyle(KnockColor.textPrimary)
                            .frame(width: 24, height: 24)
                    }
                }
                .frame(height: 50)
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 16)
            .padding(.vertical, verticalPadding)
            .background(KnockColor.cardTint2, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
            .knockShadow()
        }
    }

    var verticalPadding: CGFloat = 8

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
        VStack(spacing: 10) {
            HStack {
                Text("우리 가족 위치").font(KnockFont.medium(14)).foregroundStyle(KnockColor.primaryDark2)
                Spacer()
                Text(region).font(KnockFont.regular(12)).foregroundStyle(KnockColor.textRegion)
            }
            .frame(height: 22)
            Button(action: action) {
                Image("map_preview")
                    .resizable()
                    .scaledToFill()
                    .frame(height: 132)
                    .frame(maxWidth: .infinity)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(alignment: .bottomTrailing) {
                        Text("지도 열기")
                            .font(KnockFont.bold(8))
                            .foregroundStyle(KnockColor.link)
                            .padding(.horizontal, 6).padding(.vertical, 3)
                            .background(.white, in: Capsule())
                            .padding(8)
                    }
            }
            .buttonStyle(.pressable)
        }
        .padding(12)
        .padding(.bottom, 4)
        .background(.white, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
    }
}

// MARK: - 02 오늘 체크 (대기 / 위험)

private struct CheckPendingContent: View {
    @Environment(AppState.self) private var appState
    @Binding var showMoodPicker: Bool
    @State private var glow = false

    private var deadline: Date? {
        if case .dangerPending(let d) = appState.safety { return d }
        return nil
    }

    var body: some View {
        VStack(spacing: 12) {
            Image(appState.isDangerMode ? "mascot_worried" : "mascot_happy")
                .resizable()
                .scaledToFit()
                .frame(maxWidth: .infinity)
                .frame(height: 266)
                .padding(.top, 20)

            Text("오늘 체크")
                .font(KnockFont.bold(32))
                .foregroundStyle(KnockColor.textPrimary)
                .frame(height: 40)

            Button {
                if appState.isDangerMode { appState.confirmSafe() } else { showMoodPicker = true }
            } label: {
                Text("오늘 체크")
                    .font(KnockFont.medium(20))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(KnockColor.yellow, in: RoundedRectangle(cornerRadius: 26, style: .continuous))
                    .overlay {
                        RoundedRectangle(cornerRadius: 26, style: .continuous)
                            .stroke(KnockColor.yellow.opacity(glow ? 0 : 0.7), lineWidth: 3)
                            .scaleEffect(glow ? 1.12 : 1.0)
                            .animation(.easeOut(duration: 1.4).repeatForever(autoreverses: false), value: glow)
                    }
            }
            .buttonStyle(.pressable)
            .padding(.horizontal, 20)
            .onAppear { glow = true }

            PillBadge(
                text: appState.isDangerMode ? "오늘 상태 : 위험" : "오늘 상태 : 확인 전",
                foreground: appState.isDangerMode ? KnockColor.textPrimary : KnockColor.textSecondary,
                background: appState.isDangerMode ? KnockColor.yellow : KnockColor.cardTint
            )

            CountdownCard(title: appState.isDangerMode ? "비상 연락까지 남은 시간" : "다음 알람 남은 시간",
                          target: deadline ?? appState.nextReminderDate)
                .padding(.horizontal, 20)

            Text("체크 안 하면 비상연락처 문자 & 전화로 안내")
                .font(KnockFont.regular(14))
                .foregroundStyle(KnockColor.textSecondary)
        }
        .padding(.bottom, 16)
    }
}

// MARK: - 03 비상 연락 진행중

private struct EmergencyContactingContent: View {
    @Environment(AppState.self) private var appState
    @State private var showCancelConfirm = false

    var body: some View {
        VStack(spacing: 12) {
            HStack(alignment: .center) {
                Text("비상 연락 진행중")
                    .font(KnockFont.medium(22))
                    .foregroundStyle(KnockColor.textPrimary)
                Spacer()
                Image("mascot_alert_small").resizable().scaledToFit().frame(width: 96, height: 80)
            }
            .frame(height: 96)
            .padding(.horizontal, 20)
            .padding(.top, 20)

            ForEach(appState.emergencyContacts) { contact in
                EmergencyContactRow(contact: contact)
                    .padding(.horizontal, 20)
            }

            CountdownCard(title: "다음 연락 시도 까지",
                          target: appState.nextAttemptDate, verticalPadding: 12)
                .padding(.horizontal, 20)

            PrimaryButton(title: "저는 안전해요 · 연락 중단", style: .green) { showCancelConfirm = true }
                .padding(.horizontal, 20)
                .padding(.top, 8)

            Text("등록된 순서대로 문자와 전화로 안내하고 있어요.\n연결되면 자동으로 다음 연락처로 넘어가지 않아요.")
                .font(KnockFont.regular(14))
                .foregroundStyle(KnockColor.textSecondary)
                .multilineTextAlignment(.center)
        }
        .padding(.bottom, 16)
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
        HStack(spacing: 12) {
            Text("\(contact.priority)")
                .font(KnockFont.bold(28))
                .foregroundStyle(KnockColor.textPrimary)
                .frame(minWidth: 17)
            VStack(alignment: .leading, spacing: 4) {
                Text(contact.name).font(KnockFont.medium(16)).foregroundStyle(KnockColor.textPrimary)
                Text(contact.phone).font(KnockFont.regular(14)).foregroundStyle(KnockColor.textSecondary)
            }
            Spacer()
            stateBadge
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 16)
        .frame(height: 76)
        .background(.white, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .knockShadow()
    }

    @ViewBuilder private var stateBadge: some View {
        switch contact.state {
        case .contacting:
            HStack(spacing: 6) {
                CallingDots()
                PillBadge(text: "연락중...", foreground: KnockColor.textPrimary, background: KnockColor.yellow)
            }
        case .waiting:
            PillBadge(text: "대기중...", foreground: KnockColor.textMuted, background: KnockColor.waitingBadge)
        case .reached:
            PillBadge(text: "연결됨", foreground: .white, background: KnockColor.primary, icon: "checkmark")
        case .failed:
            PillBadge(text: "실패", foreground: .white, background: KnockColor.danger)
        }
    }
}

/// 통화 연결 중 점 세 개 애니메이션
struct CallingDots: View {
    var color: Color = KnockColor.primary
    @State private var phase = 0

    var body: some View {
        HStack(spacing: 3) {
            ForEach(0..<3, id: \.self) { i in
                Circle()
                    .fill(color)
                    .frame(width: 5, height: 5)
                    .scaleEffect(phase == i ? 1.3 : 0.7)
                    .opacity(phase == i ? 1 : 0.4)
            }
        }
        .task {
            while !Task.isCancelled {
                try? await Task.sleep(for: .milliseconds(320))
                withAnimation(.easeInOut(duration: 0.3)) { phase = (phase + 1) % 3 }
            }
        }
    }
}

// MARK: - 비상 연락 종료 (가족 응답)

private struct EmergencyResolvedContent: View {
    @Environment(AppState.self) private var appState
    var responder: String
    @Binding var showMap: Bool
    @State private var ringScale: CGFloat = 0.6
    @State private var checkShown = false

    var body: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle().fill(KnockColor.cardTint).frame(width: 190, height: 190)
                    .scaleEffect(ringScale)
                Circle().stroke(KnockColor.primary.opacity(0.35), lineWidth: 2).frame(width: 220, height: 220)
                    .scaleEffect(ringScale)
                Image("mascot_happy").resizable().scaledToFit().frame(height: 150)
                Image(systemName: "checkmark.seal.fill")
                    .font(.system(size: 40))
                    .foregroundStyle(KnockColor.primary)
                    .background(Circle().fill(.white).padding(6))
                    .scaleEffect(checkShown ? 1 : 0.2)
                    .opacity(checkShown ? 1 : 0)
                    .offset(x: 70, y: -60)
            }
            .frame(height: 230)
            .padding(.top, 12)
            .onAppear {
                withAnimation(.spring(duration: 0.8, bounce: 0.35)) { ringScale = 1 }
                withAnimation(.spring(duration: 0.6, bounce: 0.5).delay(0.35)) { checkShown = true }
            }

            VStack(spacing: 6) {
                Text("\(responder)님이 응답했어요")
                    .font(KnockFont.bold(28))
                    .foregroundStyle(KnockColor.textPrimary)
                PillBadge(text: "비상 연락 종료 · 오늘 상태 : 안전", icon: "checkmark.shield",
                          font: KnockFont.medium(14), radius: 16, iconSize: 15)
            }

            SectionCard {
                VStack(spacing: 10) {
                    ForEach(appState.emergencyContacts) { c in
                        HStack(spacing: 10) {
                            Image(systemName: c.state == .reached ? "phone.fill.checkmark" : (c.state == .failed ? "phone.down.fill" : "phone"))
                                .foregroundStyle(c.state == .reached ? KnockColor.primary : (c.state == .failed ? KnockColor.danger : KnockColor.textMuted))
                                .frame(width: 22)
                            Text(c.name).font(KnockFont.medium(15)).foregroundStyle(KnockColor.textPrimary)
                            Spacer()
                            Text(c.state == .reached ? "응답" : (c.state == .failed ? "부재중" : "대기"))
                                .font(KnockFont.regular(13))
                                .foregroundStyle(KnockColor.textSecondary)
                        }
                    }
                }
            }
            .padding(.horizontal, 20)

            PrimaryButton(title: "오늘 체크 완료로 돌아가기", style: .green) {
                appState.checkIn()
            }
            .padding(.horizontal, 20)

            FamilyMapCard(region: appState.user.region) { showMap = true }
                .padding(.horizontal, 20)
        }
        .padding(.bottom, 12)
    }
}

// MARK: - 12 안전 확인 모달

struct SafetyAlertOverlay: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        ZStack {
            KnockColor.modalDim.opacity(0.62).ignoresSafeArea()
                .onTapGesture {}

            VStack(spacing: 12) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 22, weight: .medium))
                    .foregroundStyle(KnockColor.danger)
                    .frame(width: 28, height: 28)
                    .padding(10)
                    .background(KnockColor.dangerSurface, in: Circle())

                Image("mascot_modal")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 128, height: 104)

                Text("위험 상황으로 의심되는 상태가\n감지되었습니다.\n지금 바로 안전 상태를 확인해 주세요.")
                    .font(KnockFont.medium(16))
                    .foregroundStyle(KnockColor.primaryDark2)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .frame(maxWidth: .infinity)

                Text("\(appState.settings.graceMinutes)분 이내에 응답하지 않으면\n긴급 연락처로 자동 연락됩니다")
                    .font(KnockFont.regular(14))
                    .foregroundStyle(KnockColor.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)

                Button { appState.confirmSafe() } label: {
                    Text("안전 확인")
                        .font(KnockFont.medium(18))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 44)
                        .background(KnockColor.primary, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
                }
                .buttonStyle(.pressable)
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 20)
            .background(KnockColor.background, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
            .knockShadow(radius: 24, y: 8, opacity: 0.18)
            .padding(.horizontal, 36)
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
