import Foundation
import UserNotifications

// MARK: - Auth

enum SocialProvider: String, CaseIterable, Identifiable {
    case kakao, naver, facebook, apple, phone
    var id: String { rawValue }
}

enum AuthError: LocalizedError {
    case invalidCode
    case invalidCredentials
    case duplicateID
    case network

    var errorDescription: String? {
        switch self {
        case .invalidCode: return "인증번호가 올바르지 않아요. 다시 확인해 주세요."
        case .invalidCredentials: return "아이디 또는 비밀번호가 올바르지 않아요."
        case .duplicateID: return "이미 사용 중인 아이디예요."
        case .network: return "네트워크 연결을 확인해 주세요."
        }
    }
}

protocol AuthServicing {
    func sendEmailCode(to email: String) async throws
    func verifyEmailCode(_ code: String) async throws
    func sendPhoneCode(to phone: String) async throws
    func verifyPhoneCode(_ code: String) async throws
    func register(profile: UserProfile, password: String) async throws -> UserProfile
    func login(id: String, password: String) async throws -> UserProfile
    func login(with provider: SocialProvider) async throws -> UserProfile
    func findID(phone: String) async throws -> String
    func changeID(to newID: String) async throws
    func changePassword(current: String, new: String) async throws
    func withdraw(reasons: [WithdrawReason]) async throws
}

struct MockAuthService: AuthServicing {
    static let acceptedCode = "123456"

    func sendEmailCode(to email: String) async throws { try await delay() }
    func verifyEmailCode(_ code: String) async throws {
        try await delay()
        guard code == Self.acceptedCode || code == "000000" else { throw AuthError.invalidCode }
    }
    func sendPhoneCode(to phone: String) async throws { try await delay() }
    func verifyPhoneCode(_ code: String) async throws { try await verifyEmailCode(code) }
    func register(profile: UserProfile, password: String) async throws -> UserProfile {
        try await delay(); return profile
    }
    func login(id: String, password: String) async throws -> UserProfile {
        try await delay()
        guard !id.isEmpty, password.count >= 4 else { throw AuthError.invalidCredentials }
        var user = MockData.user
        user.loginID = id
        return user
    }
    func login(with provider: SocialProvider) async throws -> UserProfile {
        try await delay(); return MockData.user
    }
    func findID(phone: String) async throws -> String { try await delay(); return "hyun****01" }
    func changeID(to newID: String) async throws {
        try await delay()
        if newID.lowercased() == "admin" { throw AuthError.duplicateID }
    }
    func changePassword(current: String, new: String) async throws { try await delay() }
    func withdraw(reasons: [WithdrawReason]) async throws { try await delay() }

    private func delay() async throws { try await Task.sleep(for: .milliseconds(600)) }
}

// MARK: - Notifications

protocol NotificationScheduling {
    func requestAuthorization() async -> Bool
    func scheduleDailyReminder(hour: Int, minute: Int) async
    func cancelAll()
}

struct LocalNotificationScheduler: NotificationScheduling {
    private let center = UNUserNotificationCenter.current()

    func requestAuthorization() async -> Bool {
        (try? await center.requestAuthorization(options: [.alert, .badge, .sound])) ?? false
    }

    func scheduleDailyReminder(hour: Int, minute: Int) async {
        center.removePendingNotificationRequests(withIdentifiers: ["daily-checkin"])
        let content = UNMutableNotificationContent()
        content.title = "똑똑똑"
        content.body = "오늘도 안전하게 시작하세요? 잊지 말고 체크인해 주세요."
        content.sound = .default
        var comps = DateComponents()
        comps.hour = hour
        comps.minute = minute
        let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: true)
        try? await center.add(UNNotificationRequest(identifier: "daily-checkin", content: content, trigger: trigger))
    }

    func cancelAll() { center.removeAllPendingNotificationRequests() }
}

// MARK: - Persistence

enum PersistenceKey: String {
    case hasSeenOnboarding
    case isLoggedIn
    case profile
    case checkInSettings
    case emergencyContacts
    case emergencyMessage
    case lastCheckInDate
    case streakDays
    case healthConnection
    case notifications
    case chat
    case todayMood
}

struct Persistence {
    private let defaults = UserDefaults.standard
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    func bool(_ key: PersistenceKey) -> Bool { defaults.bool(forKey: key.rawValue) }
    func set(_ value: Bool, _ key: PersistenceKey) { defaults.set(value, forKey: key.rawValue) }

    func load<T: Decodable>(_ type: T.Type, _ key: PersistenceKey) -> T? {
        guard let data = defaults.data(forKey: key.rawValue) else { return nil }
        return try? decoder.decode(type, from: data)
    }

    func save<T: Encodable>(_ value: T, _ key: PersistenceKey) {
        guard let data = try? encoder.encode(value) else { return }
        defaults.set(data, forKey: key.rawValue)
    }

    func remove(_ key: PersistenceKey) { defaults.removeObject(forKey: key.rawValue) }
}
