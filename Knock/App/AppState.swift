import Foundation
import Observation
import SwiftUI

enum RootRoute: Equatable {
    case splash
    case onboarding
    case auth
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
    case resolved
}

@Observable
@MainActor
final class AppState {
    // Routing
    var route: RootRoute = .splash
    var tab: MainTab = .home
    var showSafetyAlert = false

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
    var emergencyTimer: Task<Void, Never>?

    // Family
    var members: [FamilyMember] = MockData.members
    var activities: [FamilyActivity] = MockData.activities()
    var chat: [ChatMessage] = MockData.chat()

    // Health
    var healthOverview: HealthOverview = MockData.overviewGood
    var notifications: [AppNotification] = MockData.notifications

    // Services
    let auth: AuthServicing
    let scheduler: NotificationScheduling
    let persistence = Persistence()

    init(auth: AuthServicing = MockAuthService(), scheduler: NotificationScheduling = LocalNotificationScheduler()) {
        self.auth = auth
        self.scheduler = scheduler
        restore()
    }

    // MARK: - Lifecycle

    private func restore() {
        if let saved = persistence.load(UserProfile.self, .profile) { user = saved }
        if let saved = persistence.load(CheckInSettings.self, .checkInSettings) { settings = saved }
        if let saved = persistence.load([EmergencyContact].self, .emergencyContacts) { emergencyContacts = saved }
        if let saved = persistence.load(String.self, .emergencyMessage) { emergencyMessage = saved }
        isLoggedIn = persistence.bool(.isLoggedIn)
        if let last = persistence.load(Date.self, .lastCheckInDate), Calendar.current.isDateInToday(last) {
            safety = .checkedIn
        }
    }

    func finishSplash() {
        if isLoggedIn {
            route = .main
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
        route = .main
        tab = .home
    }

    func logout() {
        isLoggedIn = false
        persistence.set(false, .isLoggedIn)
        persistence.remove(.profile)
        safety = .idle
        emergencyTimer?.cancel()
        route = .auth
    }

    func withdraw() {
        logout()
        persistence.remove(.hasSeenOnboarding)
        persistence.remove(.checkInSettings)
        persistence.remove(.emergencyContacts)
        persistence.remove(.lastCheckInDate)
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

    func checkIn() {
        emergencyTimer?.cancel()
        withAnimation(.spring(duration: 0.4)) { safety = .checkedIn }
        if let idx = weekRecords.firstIndex(where: { Calendar.current.isDateInToday($0.date) }) {
            weekRecords[idx].completed = true
            weekRecords[idx].status = .safe
        }
        persistence.save(Date.now, .lastCheckInDate)
    }

    /// 데모: 위험 감지 시나리오 시작 (02 화면)
    func simulateDangerDetected() {
        let deadline = Date.now.addingTimeInterval(TimeInterval(settings.graceMinutes * 60))
        withAnimation { safety = .dangerPending(deadline: deadline) }
        showSafetyAlert = true
        if let idx = weekRecords.firstIndex(where: { Calendar.current.isDateInToday($0.date) }) {
            weekRecords[idx].status = .danger
        }
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
    }

    /// 03 화면: 비상 연락 순차 진행
    func startEmergencyContact() {
        showSafetyAlert = false
        withAnimation { safety = .emergencyContacting }
        for i in emergencyContacts.indices { emergencyContacts[i].state = i == 0 ? .contacting : .waiting }
        emergencyTimer?.cancel()
        emergencyTimer = Task { [weak self] in
            guard let self else { return }
            for i in self.emergencyContacts.indices {
                try? await Task.sleep(for: .seconds(4))
                guard !Task.isCancelled else { return }
                self.emergencyContacts[i].state = .reached
                if i + 1 < self.emergencyContacts.count { self.emergencyContacts[i + 1].state = .contacting }
            }
        }
    }

    func cancelEmergency() {
        emergencyTimer?.cancel()
        for i in emergencyContacts.indices { emergencyContacts[i].state = .waiting }
        checkIn()
    }

    func resetSafetyDemo() {
        emergencyTimer?.cancel()
        withAnimation { safety = .idle }
        for i in emergencyContacts.indices { emergencyContacts[i].state = .waiting }
        if let idx = weekRecords.firstIndex(where: { Calendar.current.isDateInToday($0.date) }) {
            weekRecords[idx].completed = false
            weekRecords[idx].status = .pending
        }
        persistence.remove(.lastCheckInDate)
    }

    // MARK: - Health demo toggles

    func toggleHealthCondition() {
        healthOverview = healthOverview.condition == .good ? MockData.overviewBad : MockData.overviewGood
    }

    var unreadNotifications: Int { notifications.filter { !$0.isRead }.count }
    func markAllRead() { for i in notifications.indices { notifications[i].isRead = true } }
}
