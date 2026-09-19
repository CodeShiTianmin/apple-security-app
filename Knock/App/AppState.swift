import Foundation
import Observation
import SwiftUI

enum RootRoute: Equatable {
    case splash
    case onboarding
    case auth
    /// 로그인 직후, 비상 연락처가 아직 등록되지 않은 경우
    case emergencySetup
    case main
}

enum MainTab: Int, CaseIterable, Identifiable {
    case home, stats, health, family
    var id: Int { rawValue }

    var title: String {
        switch self {
        case .home: return "홈"
        case .stats: return "통계"
        case .health: return "건강"
        case .family: return "가족"
        }
    }

    var systemImage: String {
        switch self {
        case .home: return "house.fill"
        case .stats: return "chart.bar.fill"
        case .health: return "heart.fill"
        case .family: return "person.2.fill"
        }
    }
}

/// 오늘의 안전 확인 흐름 상태
enum SafetyFlow: Equatable {
    /// 아직 체크인하지 않음
    case idle
    /// 체크인 완료 (01)
    case checkedIn
    /// 위험 감지 → 사용자 응답 대기, 마감 시각까지 카운트다운 (02 / 12)
    case dangerPending(deadline: Date)
    /// 비상 연락 진행중 (03)
    case emergencyContacting
    /// 비상 연락 종료(가족 응답 확인)
    case resolved(by: String)
}

/// 화면 하단에 잠깐 표시되는 토스트
struct ToastMessage: Identifiable, Equatable {
    var id: UUID = UUID()
    var text: String
    var icon: String = "checkmark.circle.fill"
}

@Observable
@MainActor
final class AppState {
    // Routing
    var route: RootRoute = .splash
    var tab: MainTab = .home
    var showSafetyAlert = false
    var showNotifications = false
    var toast: ToastMessage?

    // Session
    var user: UserProfile = MockData.user
    var isLoggedIn = false

    // Safety
    var safety: SafetyFlow = .idle
    var weekRecords: [CheckInRecord] = MockData.weekRecords()
    var streakDays = 16
    var settings = CheckInSettings()
    var emergencyContacts: [EmergencyContact] = MockData.emergencyContacts
    var emergencyMessage: String = MockData.emergencyMessage
    var hasSetEmergencyContacts = false
    var emergencyTimer: Task<Void, Never>?
    /// 비상 연락 중 다음 연락 시도 예정 시각
    var nextAttemptDate: Date?
    /// 체크인 직후 축하 애니메이션 트리거
    var celebrationID = UUID()
    var showCelebration = false

    // Family
    var members: [FamilyMember] = MockData.members
    var activities: [FamilyActivity] = MockData.activities()
    var chat: [ChatMessage] = MockData.chat()
    var isFamilyTyping = false
    var liveTimer: Task<Void, Never>?
    private var liveEventIndex = 0
    private var replyTask: Task<Void, Never>?

    // Health
    var healthOverview: HealthOverview = MockData.overviewGood
    var healthConnection: HealthConnection = .disconnected
    var liveHeartRate: Int = MockData.overviewGood.heartRate
    var notifications: [AppNotification] = MockData.notifications
    private var heartTask: Task<Void, Never>?
    private var toastTask: Task<Void, Never>?

    // Services
    let auth: AuthServicing
    let scheduler: NotificationScheduling
    let persistence = Persistence()

    init(auth: AuthServicing = MockAuthService(), scheduler: NotificationScheduling = LocalNotificationScheduler()) {
        self.auth = auth
        self.scheduler = scheduler
        if CommandLine.arguments.contains("--demo-reset") { persistence.removeAll() }
        restore()
    }

    // MARK: - Lifecycle

    private func restore() {
        if let saved = persistence.load(UserProfile.self, .profile) { user = saved }
        if let saved = persistence.load(CheckInSettings.self, .checkInSettings) { settings = saved }
        if let saved = persistence.load([EmergencyContact].self, .emergencyContacts) { emergencyContacts = saved }
        if let saved = persistence.load(String.self, .emergencyMessage) { emergencyMessage = saved }
        hasSetEmergencyContacts = persistence.bool(.hasSetEmergencyContacts)
        if let saved = persistence.load(Int.self, .streakDays) { streakDays = saved }
        if let saved = persistence.load([AppNotification].self, .notifications) { notifications = saved }
        if let saved = persistence.load([ChatMessage].self, .chat) { chat = saved }
        if let saved = persistence.load(HealthConnection.self, .healthConnection), saved == .connected {
            healthConnection = .connected
            startLiveHeartRate()
        }
        isLoggedIn = persistence.bool(.isLoggedIn)
        if let last = persistence.load(Date.self, .lastCheckInDate), Calendar.current.isDateInToday(last) {
            safety = .checkedIn
            markToday(completed: true, status: .safe, mood: persistence.load(Mood.self, .todayMood))
        }
    }

    func finishSplash() {
        if isLoggedIn {
            route = .main
            startLiveFamilyUpdates()
        } else if persistence.bool(.hasSeenOnboarding) {
            route = .auth
        } else {
            route = .onboarding
        }
    }

    func finishOnboarding() {
        persistence.set(true, .hasSeenOnboarding)
        route = .auth
    }

    func completeLogin(_ profile: UserProfile) {
        user = profile
        isLoggedIn = true
        persistence.set(true, .isLoggedIn)
        persistence.save(profile, .profile)
        tab = .home
        if hasSetEmergencyContacts {
            enterMain()
        } else {
            route = .emergencySetup
        }
    }

    /// 로그인 후 비상 연락처 등록 완료
    func completeEmergencySetup(contacts: [EmergencyContact], message: String) {
        if !contacts.isEmpty { emergencyContacts = contacts }
        emergencyMessage = message
        saveEmergency()
        enterMain()
    }

    /// 비상 연락처 등록을 건너뜀 (다음 로그인 시 다시 안내)
    func skipEmergencySetup() {
        enterMain()
    }

    private func enterMain() {
        route = .main
        startLiveFamilyUpdates()
    }

    func logout() {
        isLoggedIn = false
        persistence.set(false, .isLoggedIn)
        persistence.remove(.profile)
        safety = .idle
        emergencyTimer?.cancel()
        liveTimer?.cancel()
        heartTask?.cancel()
        route = .auth
    }

    func withdraw() {
        logout()
        persistence.remove(.hasSeenOnboarding)
        persistence.remove(.checkInSettings)
        persistence.remove(.emergencyContacts)
        persistence.remove(.emergencyMessage)
        persistence.remove(.hasSetEmergencyContacts)
        hasSetEmergencyContacts = false
        emergencyContacts = MockData.emergencyContacts
        emergencyMessage = MockData.emergencyMessage
        persistence.remove(.lastCheckInDate)
        persistence.remove(.streakDays)
        persistence.remove(.notifications)
        persistence.remove(.chat)
        persistence.remove(.healthConnection)
        settings = CheckInSettings()
        route = .auth
    }

    func saveProfile() { persistence.save(user, .profile) }
    func saveSettings() {
        persistence.save(settings, .checkInSettings)
        Task { await scheduler.scheduleDailyReminder(hour: settings.deadlineHour, minute: settings.deadlineMinute) }
    }
    func saveEmergency() {
        persistence.save(emergencyContacts, .emergencyContacts)
        persistence.save(emergencyMessage, .emergencyMessage)
        if !emergencyContacts.isEmpty {
            hasSetEmergencyContacts = true
            persistence.set(true, .hasSetEmergencyContacts)
        }
    }

    // MARK: - Toast

    func showToast(_ text: String, icon: String = "checkmark.circle.fill") {
        toastTask?.cancel()
        withAnimation(.spring(duration: 0.35)) { toast = ToastMessage(text: text, icon: icon) }
        toastTask = Task { [weak self] in
            try? await Task.sleep(for: .seconds(2.2))
            guard !Task.isCancelled else { return }
            withAnimation(.easeOut(duration: 0.3)) { self?.toast = nil }
        }
    }

    // MARK: - Safety flow

    var todayStatus: SafetyStatus {
        switch safety {
        case .checkedIn, .resolved: return .safe
        case .dangerPending, .emergencyContacting: return .danger
        case .idle: return .pending
        }
    }

    var isDangerMode: Bool {
        if case .dangerPending = safety { return true }
        if case .emergencyContacting = safety { return true }
        return false
    }

    var isCheckedInToday: Bool {
        switch safety {
        case .checkedIn, .resolved: return true
        default: return false
        }
    }

    var todayMood: Mood? {
        weekRecords.first { Calendar.current.isDateInToday($0.date) }?.mood
    }

    private func markToday(completed: Bool, status: SafetyStatus, mood: Mood?) {
        guard let idx = weekRecords.firstIndex(where: { Calendar.current.isDateInToday($0.date) }) else { return }
        weekRecords[idx].completed = completed
        weekRecords[idx].status = status
        weekRecords[idx].mood = mood
    }

    func checkIn(mood: Mood? = nil) {
        emergencyTimer?.cancel()
        nextAttemptDate = nil
        let firstTimeToday = !isCheckedInToday
        withAnimation(.spring(duration: 0.4)) { safety = .checkedIn }
        markToday(completed: true, status: .safe, mood: mood ?? todayMood)
        if firstTimeToday {
            streakDays += 1
            persistence.save(streakDays, .streakDays)
            celebrationID = UUID()
            showCelebration = true
            pushNotification(title: "오늘의 체크인 완료", body: "\(streakDays)일 연속 출석 중이에요. 가족에게 안부가 전달됐어요.", kind: .checkIn)
            addActivity(name: user.name, message: "오늘 체크인을 완료했어요.")
        }
        if let mood { persistence.save(mood, .todayMood) }
        persistence.save(Date.now, .lastCheckInDate)
    }

    /// 데모: 위험 감지 시나리오 시작 (02 화면)
    func simulateDangerDetected() {
        let deadline = Date.now.addingTimeInterval(TimeInterval(settings.graceMinutes * 60))
        withAnimation { safety = .dangerPending(deadline: deadline) }
        showSafetyAlert = true
        markToday(completed: false, status: .danger, mood: nil)
        pushNotification(title: "똑똑똑",
                         body: "위험 상황으로 의심되는 상태가 감지되었습니다. \(settings.graceMinutes)분 이내에 응답하지 않으면 긴급 연락처로 자동 연락됩니다.",
                         kind: .danger)
        emergencyTimer?.cancel()
        emergencyTimer = Task { [weak self] in
            try? await Task.sleep(for: .seconds(deadline.timeIntervalSinceNow))
            guard !Task.isCancelled, let self else { return }
            if case .dangerPending = self.safety { self.startEmergencyContact() }
        }
    }

    /// 12 화면: 사용자가 "안전해요" 응답
    func confirmSafe() {
        showSafetyAlert = false
        checkIn()
        showToast("안전 확인이 가족에게 전달됐어요")
    }

    /// 03 화면: 비상 연락 순차 진행 → 가족 응답 시 종료
    func startEmergencyContact() {
        showSafetyAlert = false
        withAnimation { safety = .emergencyContacting }
        for i in emergencyContacts.indices { emergencyContacts[i].state = i == 0 ? .contacting : .waiting }
        let interval: TimeInterval = 6
        nextAttemptDate = Date.now.addingTimeInterval(interval)
        pushNotification(title: "비상 연락 시작", body: "등록된 순서대로 문자와 전화로 안내를 시작했어요.", kind: .danger)
        emergencyTimer?.cancel()
        emergencyTimer = Task { [weak self] in
            guard let self else { return }
            for i in self.emergencyContacts.indices {
                try? await Task.sleep(for: .seconds(interval))
                guard !Task.isCancelled else { return }
                // 첫 번째는 부재중, 두 번째부터 응답하는 시나리오
                let answered = i > 0 || self.emergencyContacts.count == 1
                withAnimation(.spring(duration: 0.4)) {
                    self.emergencyContacts[i].state = answered ? .reached : .failed
                }
                if answered {
                    try? await Task.sleep(for: .seconds(1.5))
                    guard !Task.isCancelled else { return }
                    self.resolveEmergency(by: self.emergencyContacts[i].name)
                    return
                }
                if i + 1 < self.emergencyContacts.count {
                    self.emergencyContacts[i + 1].state = .contacting
                    self.nextAttemptDate = Date.now.addingTimeInterval(interval)
                }
            }
        }
    }

    /// 가족이 응답해 비상 상황 종료
    func resolveEmergency(by name: String) {
        emergencyTimer?.cancel()
        nextAttemptDate = nil
        withAnimation(.spring(duration: 0.5)) { safety = .resolved(by: name) }
        markToday(completed: true, status: .safe, mood: todayMood)
        persistence.save(Date.now, .lastCheckInDate)
        pushNotification(title: "\(name)님이 응답했어요", body: "\(name)님이 안전 확인 요청에 응답해 비상 연락이 종료되었어요.", kind: .family)
        addActivity(name: name, message: "안전 확인 요청에 응답했어요.")
        if let idx = members.firstIndex(where: { $0.name == name }) {
            members[idx].isOnline = true
            members[idx].lastCheckInMinutesAgo = 0
            members[idx].activityTitle = "현재 활동 중"
        }
    }

    func cancelEmergency() {
        emergencyTimer?.cancel()
        nextAttemptDate = nil
        for i in emergencyContacts.indices { emergencyContacts[i].state = .waiting }
        checkIn()
        showToast("비상 연락을 중단했어요")
    }

    func resetSafetyDemo() {
        emergencyTimer?.cancel()
        nextAttemptDate = nil
        withAnimation { safety = .idle }
        for i in emergencyContacts.indices { emergencyContacts[i].state = .waiting }
        markToday(completed: false, status: .pending, mood: nil)
        persistence.remove(.lastCheckInDate)
        persistence.remove(.todayMood)
    }

    // MARK: - Family

    func addActivity(name: String, message: String) {
        withAnimation { activities.insert(FamilyActivity(memberName: name, message: message, date: .now), at: 0) }
    }

    /// 초대 코드로 가족 참여. 성공 시 참여한 구성원 반환.
    func joinFamily(code: String) -> FamilyMember? {
        let normalized = code.filter(\.isNumber)
        guard let candidate = MockData.inviteCandidates.first(where: { $0.code.filter(\.isNumber) == normalized }) else { return nil }
        guard !members.contains(where: { $0.name == candidate.member.name }) else { return candidate.member }
        withAnimation(.spring(duration: 0.5)) { members.append(candidate.member) }
        addActivity(name: candidate.member.name, message: "가족에 참여했어요.")
        pushNotification(title: "\(candidate.member.name)님이 가족에 참여했어요",
                         body: "이제 서로의 안전 체크인을 확인할 수 있어요.", kind: .family)
        return candidate.member
    }

    func removeMember(_ member: FamilyMember) {
        withAnimation { members.removeAll { $0.id == member.id } }
    }

    /// 채팅 전송 후 가족 자동 응답 (타이핑 표시 → 답장)
    func sendChat(_ text: String) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        chat.append(ChatMessage(senderName: "나", isMine: true, text: trimmed, date: .now))
        persistence.save(chat, .chat)
        scheduleReply()
    }

    /// 특정 가족에게 안부 보내기
    func sendGreeting(to member: FamilyMember) {
        chat.append(ChatMessage(senderName: "나", isMine: true, text: "\(member.name), 오늘 체크인 잊지 마세요 👋", date: .now))
        persistence.save(chat, .chat)
        showToast("\(member.name)님에게 안부를 보냈어요", icon: "hand.wave.fill")
        scheduleReply(from: member.name)
    }

    private func scheduleReply(from name: String? = nil) {
        replyTask?.cancel()
        replyTask = Task { [weak self] in
            guard let self else { return }
            try? await Task.sleep(for: .seconds(1.2))
            guard !Task.isCancelled else { return }
            withAnimation { self.isFamilyTyping = true }
            try? await Task.sleep(for: .seconds(1.8))
            guard !Task.isCancelled else { return }
            let sender = name ?? self.members.filter(\.isOnline).randomElement()?.name ?? "엄마"
            let reply = MockData.chatReplies.randomElement() ?? "응 알겠어!"
            withAnimation(.spring(duration: 0.35)) {
                self.isFamilyTyping = false
                self.chat.append(ChatMessage(senderName: sender, isMine: false, text: reply, date: .now))
            }
            self.persistence.save(self.chat, .chat)
            if let idx = self.members.firstIndex(where: { $0.name == sender }) {
                self.members[idx].unreadCount += 1
            }
        }
    }

    func clearUnread(for member: FamilyMember) {
        if let idx = members.firstIndex(where: { $0.id == member.id }) { members[idx].unreadCount = 0 }
    }

    /// 가족 실시간 업데이트 모의: 주기적으로 구성원 활동을 반영
    func startLiveFamilyUpdates() {
        liveTimer?.cancel()
        liveTimer = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(25))
                guard !Task.isCancelled, let self else { return }
                self.applyLiveEvent()
            }
        }
    }

    func applyLiveEvent() {
        let events = MockData.liveFamilyEvents
        guard !events.isEmpty else { return }
        let event = events[liveEventIndex % events.count]
        liveEventIndex += 1
        guard let idx = members.firstIndex(where: { $0.name == event.name }) else { return }
        withAnimation(.spring(duration: 0.4)) {
            members[idx].isOnline = true
            members[idx].lastCheckInMinutesAgo = 0
            members[idx].activityTitle = "현재 활동 중"
            members[idx].activityDetail = event.message
        }
        addActivity(name: event.name, message: event.message)
        if settings.familyActivityEnabled {
            pushNotification(title: "\(event.name)님의 새 소식", body: event.message, kind: .family)
        }
    }

    // MARK: - Health

    func toggleHealthCondition() {
        healthOverview = healthOverview.condition == .good ? MockData.overviewBad : MockData.overviewGood
        liveHeartRate = healthOverview.heartRate
        if healthOverview.condition == .bad {
            pushNotification(title: "건강 이상 감지", body: "심박수가 평소보다 높아요. 잠시 휴식을 취해 주세요.", kind: .danger)
        }
    }

    /// 건강 앱 연동 (연결 중 → 연결됨). 연결되면 실시간 심박수 갱신 시작.
    func connectHealth() {
        guard healthConnection == .disconnected else { return }
        withAnimation { healthConnection = .connecting }
        Task { [weak self] in
            try? await Task.sleep(for: .seconds(2.2))
            guard let self else { return }
            withAnimation(.spring(duration: 0.4)) { self.healthConnection = .connected }
            self.persistence.save(HealthConnection.connected, .healthConnection)
            self.startLiveHeartRate()
            self.showToast("건강 앱과 연결됐어요", icon: "heart.text.square.fill")
            self.pushNotification(title: "건강 앱 연결 완료", body: "애플워치 심박수·수면 데이터를 자동으로 가져와요.", kind: .system)
        }
    }

    func disconnectHealth() {
        heartTask?.cancel()
        withAnimation { healthConnection = .disconnected }
        persistence.remove(.healthConnection)
        liveHeartRate = healthOverview.heartRate
    }

    private func startLiveHeartRate() {
        heartTask?.cancel()
        heartTask = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(1.6))
                guard !Task.isCancelled, let self else { return }
                let base = self.healthOverview.heartRate
                withAnimation(.easeInOut(duration: 0.4)) {
                    self.liveHeartRate = max(48, min(190, base + Int.random(in: -4...4)))
                }
            }
        }
    }

    // MARK: - Notifications

    var unreadNotifications: Int { notifications.filter { !$0.isRead }.count }

    func pushNotification(title: String, body: String, kind: AppNotification.Kind) {
        withAnimation(.spring(duration: 0.4)) {
            notifications.insert(AppNotification(title: title, body: body, date: .now, kind: kind, isRead: false), at: 0)
        }
        if notifications.count > 30 { notifications.removeLast(notifications.count - 30) }
        persistence.save(notifications, .notifications)
    }

    func markRead(_ notification: AppNotification) {
        guard let idx = notifications.firstIndex(where: { $0.id == notification.id }) else { return }
        notifications[idx].isRead = true
        persistence.save(notifications, .notifications)
    }

    func markAllRead() {
        withAnimation { for i in notifications.indices { notifications[i].isRead = true } }
        persistence.save(notifications, .notifications)
    }

    func removeNotification(_ notification: AppNotification) {
        withAnimation { notifications.removeAll { $0.id == notification.id } }
        persistence.save(notifications, .notifications)
    }
}
