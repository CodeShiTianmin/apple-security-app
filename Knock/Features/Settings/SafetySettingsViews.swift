import SwiftUI
import UserNotifications
import CoreLocation

/// [보충 화면] 체크인 시간 설정
struct CheckInSettingsView: View {
    @Environment(AppState.self) private var appState
    @State private var time = Date.now
    @State private var reminder = 60
    @State private var grace = 20

    private let reminderOptions = [15, 30, 60, 120]
    private let graceOptions = [10, 20, 30, 60]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                Text("체크인 시간 설정")
                    .font(KnockFont.semibold(24)).foregroundStyle(KnockColor.textNeutral)
                    .padding(.top, 20)

                SectionCard(padding: 16, background: KnockColor.cardTint) {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("매일 체크인 마감 시간").font(KnockFont.medium(15)).foregroundStyle(KnockColor.textPrimary)
                        DatePicker("", selection: $time, displayedComponents: .hourAndMinute)
                            .datePickerStyle(.wheel)
                            .labelsHidden()
                            .frame(maxWidth: .infinity)
                        Text("이 시간까지 체크인하지 않으면 알림을 보내고, 응답이 없으면 비상 연락처로 연락해요.")
                            .font(KnockFont.regular(12)).foregroundStyle(KnockColor.textSecondary)
                    }
                }

                VStack(alignment: .leading, spacing: 10) {
                    Text("마감 전 알림").font(KnockFont.medium(15)).foregroundStyle(KnockColor.textPrimary)
                    HStack(spacing: 8) {
                        ForEach(reminderOptions, id: \.self) { m in
                            ChoiceChip(title: m >= 60 ? "\(m / 60)시간 전" : "\(m)분 전", selected: reminder == m) { reminder = m }
                        }
                    }
                }

                VStack(alignment: .leading, spacing: 10) {
                    Text("미응답 시 비상 연락 대기").font(KnockFont.medium(15)).foregroundStyle(KnockColor.textPrimary)
                    HStack(spacing: 8) {
                        ForEach(graceOptions, id: \.self) { m in
                            ChoiceChip(title: "\(m)분", selected: grace == m) { grace = m }
                        }
                    }
                    Text("위험 감지 알림 후 이 시간 안에 응답하지 않으면 등록된 순서대로 자동 연락됩니다.")
                        .font(KnockFont.regular(12)).foregroundStyle(KnockColor.textSecondary)
                }

                PrimaryButton(title: "저장") {
                    let comps = Calendar.current.dateComponents([.hour, .minute], from: time)
                    appState.settings.deadlineHour = comps.hour ?? 21
                    appState.settings.deadlineMinute = comps.minute ?? 0
                    appState.settings.reminderMinutesBefore = reminder
                    appState.settings.graceMinutes = grace
                    appState.saveSettings()
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 24)
        }
        .background(Color.white)
        .onAppear {
            var comps = DateComponents()
            comps.hour = appState.settings.deadlineHour
            comps.minute = appState.settings.deadlineMinute
            time = Calendar.current.date(from: comps) ?? .now
            reminder = appState.settings.reminderMinutesBefore
            grace = appState.settings.graceMinutes
        }
    }
}

/// [보충 화면] 비상 연락처 관리
struct EmergencyContactsManageView: View {
    @Environment(AppState.self) private var appState
    @State private var showAdd = false
    @State private var name = ""
    @State private var phone = ""
    @State private var relation = "가족"

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("비상 연락처 관리")
                .font(KnockFont.semibold(24)).foregroundStyle(KnockColor.textNeutral)
                .padding(.horizontal, 24).padding(.top, 20)
            Text("위 순서대로 문자와 전화로 연락해요. 길게 눌러 순서를 바꿀 수 있어요.")
                .font(KnockFont.regular(13)).foregroundStyle(KnockColor.textSecondary)
                .padding(.horizontal, 24).padding(.top, 6)

            List {
                ForEach(appState.emergencyContacts) { c in
                    HStack(spacing: 14) {
                        Text("\(c.priority)").font(KnockFont.bold(22)).foregroundStyle(KnockColor.textPrimary).frame(width: 24)
                        VStack(alignment: .leading, spacing: 3) {
                            Text(c.name).font(KnockFont.medium(16)).foregroundStyle(KnockColor.textPrimary)
                            Text("\(c.relation) · \(c.phone)").font(KnockFont.regular(13)).foregroundStyle(KnockColor.textSecondary)
                        }
                        Spacer()
                    }
                    .padding(.vertical, 6)
                    .listRowBackground(Color.white)
                }
                .onMove { from, to in
                    appState.emergencyContacts.move(fromOffsets: from, toOffset: to)
                    renumber()
                }
                .onDelete { idx in
                    appState.emergencyContacts.remove(atOffsets: idx)
                    renumber()
                }
            }
            .listStyle(.plain)
            .environment(\.editMode, .constant(.active))

            PrimaryButton(title: "연락처 추가", style: .outline) { showAdd = true }
                .padding(.horizontal, 24).padding(.bottom, 12)
        }
        .background(Color.white)
        .sheet(isPresented: $showAdd) {
            NavigationStack {
                Form {
                    TextField("이름", text: $name)
                    TextField("전화번호", text: $phone).keyboardType(.phonePad)
                        .onChange(of: phone) { _, new in phone = PhoneFormatter.format(new) }
                    Picker("관계", selection: $relation) {
                        ForEach(["가족", "어머니", "아버지", "배우자", "형제·자매", "자녀", "친구", "지인"], id: \.self) { Text($0) }
                    }
                }
                .navigationTitle("연락처 추가")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) { Button("취소") { showAdd = false } }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("추가") {
                            appState.emergencyContacts.append(EmergencyContact(name: name, phone: phone, relation: relation,
                                                                                 priority: appState.emergencyContacts.count + 1))
                            appState.saveEmergency()
                            name = ""; phone = ""
                            showAdd = false
                        }
                        .disabled(name.isEmpty || phone.filter(\.isNumber).count < 10)
                    }
                }
            }
            .presentationDetents([.medium])
        }
    }

    private func renumber() {
        for i in appState.emergencyContacts.indices { appState.emergencyContacts[i].priority = i + 1 }
        appState.saveEmergency()
    }
}

/// [보충 화면] 알림 설정
struct NotificationSettingsView: View {
    @Environment(AppState.self) private var appState
    @State private var authorized: Bool?

    var body: some View {
        @Bindable var appState = appState
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("알림 설정")
                    .font(KnockFont.semibold(24)).foregroundStyle(KnockColor.textNeutral)
                    .padding(.top, 20)

                if authorized == false {
                    HStack(spacing: 12) {
                        Image(systemName: "bell.slash.fill").foregroundStyle(KnockColor.danger)
                        VStack(alignment: .leading, spacing: 3) {
                            Text("알림 권한이 꺼져 있어요").font(KnockFont.medium(14)).foregroundStyle(KnockColor.textPrimary)
                            Text("체크인 알림을 받으려면 설정에서 허용해 주세요.").font(KnockFont.regular(12)).foregroundStyle(KnockColor.textSecondary)
                        }
                        Spacer()
                        Button("설정") {
                            if let url = URL(string: UIApplication.openSettingsURLString) { UIApplication.shared.open(url) }
                        }
                        .font(KnockFont.medium(13))
                    }
                    .padding(14)
                    .background(KnockColor.dangerSoft, in: RoundedRectangle(cornerRadius: 16))
                }

                VStack(spacing: 0) {
                    toggle("체크인 리마인드 푸시", $appState.settings.pushEnabled)
                    Divider()
                    toggle("비상 연락 문자 발송", $appState.settings.smsEnabled)
                    Divider()
                    toggle("비상 연락 자동 전화", $appState.settings.callEnabled)
                    Divider()
                    toggle("가족 활동 알림", $appState.settings.familyActivityEnabled)
                    Divider()
                    toggle("이벤트 · 새 소식 (선택)", $appState.settings.marketingEnabled)
                }
                .padding(.horizontal, 16)
                .background(.white, in: RoundedRectangle(cornerRadius: 18))
                .knockShadow()
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 24)
        }
        .background(KnockColor.background)
        .onChange(of: appState.settings) { _, _ in appState.saveSettings() }
        .task {
            let status = await UNUserNotificationCenter.current().notificationSettings().authorizationStatus
            authorized = status == .authorized || status == .provisional
        }
    }

    private func toggle(_ title: String, _ binding: Binding<Bool>) -> some View {
        Toggle(title, isOn: binding)
            .font(KnockFont.medium(15))
            .foregroundStyle(KnockColor.textPrimary)
            .tint(KnockColor.primary)
            .padding(.vertical, 14)
    }
}

/// [보충 화면] 권한 안내 (알림 / 위치 / 건강)
struct PermissionsView: View {
    @Environment(AppState.self) private var appState
    @State private var notificationsGranted: Bool?
    @State private var locationManager = CLLocationManager()

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("권한 안내")
                    .font(KnockFont.semibold(24)).foregroundStyle(KnockColor.textNeutral)
                    .padding(.top, 20)
                Text("똑똑똑이 안전 확인을 위해 사용하는 권한이에요. 필요할 때만 사용하고, 언제든 설정에서 변경할 수 있어요.")
                    .font(KnockFont.regular(13)).foregroundStyle(KnockColor.textSecondary).lineSpacing(3)

                permission(icon: "bell.badge.fill", color: KnockColor.yellow, title: "알림",
                           detail: "체크인 리마인드와 위험 감지 알림을 보내요.",
                           status: notificationsGranted.map { $0 ? "허용됨" : "허용 안 됨" } ?? "확인 중") {
                    Task {
                        notificationsGranted = await appState.scheduler.requestAuthorization()
                        if notificationsGranted == true {
                            await appState.scheduler.scheduleDailyReminder(hour: appState.settings.deadlineHour, minute: appState.settings.deadlineMinute)
                        }
                    }
                }
                permission(icon: "location.fill", color: KnockColor.primary, title: "위치 (사용 중에만)",
                           detail: "우리 가족 위치 지도에 내 위치를 표시해요.",
                           status: locationStatus) {
                    locationManager.requestWhenInUseAuthorization()
                }
                permission(icon: "heart.text.square.fill", color: KnockColor.danger, title: "건강 데이터",
                           detail: "심박수·수면·스트레스를 읽어 건강 상태를 보여줘요. (Apple Watch 연동)",
                           status: "건강 탭에서 연결") {
                    appState.tab = .health
                }

                Button {
                    if let url = URL(string: UIApplication.openSettingsURLString) { UIApplication.shared.open(url) }
                } label: {
                    Label("iOS 설정에서 권한 변경", systemImage: "gearshape")
                        .font(KnockFont.medium(14)).foregroundStyle(KnockColor.primary)
                }
                .padding(.top, 8)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 24)
        }
        .background(Color.white)
        .task {
            let status = await UNUserNotificationCenter.current().notificationSettings().authorizationStatus
            notificationsGranted = status == .authorized || status == .provisional
        }
    }

    private var locationStatus: String {
        switch locationManager.authorizationStatus {
        case .authorizedAlways, .authorizedWhenInUse: return "허용됨"
        case .denied, .restricted: return "허용 안 됨"
        default: return "요청 전"
        }
    }

    private func permission(icon: String, color: Color, title: String, detail: String, status: String, action: @escaping () -> Void) -> some View {
        HStack(spacing: 14) {
            Image(systemName: icon).font(.system(size: 20)).foregroundStyle(color)
                .frame(width: 44, height: 44).background(color.opacity(0.15), in: RoundedRectangle(cornerRadius: 12))
            VStack(alignment: .leading, spacing: 3) {
                Text(title).font(KnockFont.medium(15)).foregroundStyle(KnockColor.textPrimary)
                Text(detail).font(KnockFont.regular(12)).foregroundStyle(KnockColor.textSecondary)
                Text(status).font(KnockFont.regular(11)).foregroundStyle(KnockColor.textMuted)
            }
            Spacer()
            Button("요청", action: action)
                .font(KnockFont.medium(13)).foregroundStyle(KnockColor.primary)
        }
        .padding(14)
        .background(KnockColor.cardTint3, in: RoundedRectangle(cornerRadius: 18))
    }
}

/// [보충 화면] 앱 정보
struct AboutView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image("logo_full").resizable().scaledToFit().frame(width: 180).padding(.top, 60)
            Text("똑똑똑 · Knock").font(KnockFont.semibold(20)).foregroundStyle(KnockColor.textPrimary)
            Text("매일 한 번의 체크인으로 나와 가족의 안전을 지켜요.")
                .font(KnockFont.regular(14)).foregroundStyle(KnockColor.textSecondary)
            VStack(spacing: 0) {
                SettingsRow(title: "버전", value: "1.0.0 (1)", showChevron: false)
                Divider()
                Link(destination: URL(string: "https://example.com/terms")!) { SettingsRow(title: "서비스 이용약관") }
                Divider()
                Link(destination: URL(string: "https://example.com/privacy")!) { SettingsRow(title: "개인정보 처리방침") }
                Divider()
                Link(destination: URL(string: "mailto:help@knock.app")!) { SettingsRow(title: "문의하기", value: "help@knock.app") }
            }
            .padding(.horizontal, 24)
            Spacer()
        }
        .background(Color.white)
    }
}
