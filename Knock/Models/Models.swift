import Foundation

// MARK: - User

struct UserProfile: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var name: String
    var loginID: String
    var email: String
    var phone: String
    var birthDate: String
    var gender: Gender?
    var region: String
    var avatarAsset: String
    var isOnline: Bool

    enum Gender: String, Codable, CaseIterable {
        case male = "남"
        case female = "여"
    }
}

// MARK: - Check-in

enum SafetyStatus: String, Codable {
    case safe = "안전"
    case danger = "위험"
    case pending = "대기"
}

struct CheckInRecord: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var date: Date
    var completed: Bool
    var status: SafetyStatus
    var mood: Mood? = nil
}

/// 체크인 시 남기는 오늘의 기분
enum Mood: String, Codable, CaseIterable, Identifiable {
    case great = "아주 좋아요"
    case good = "좋아요"
    case soso = "그냥 그래요"
    case tired = "피곤해요"
    var id: String { rawValue }

    var emoji: String {
        switch self {
        case .great: return "😆"
        case .good: return "🙂"
        case .soso: return "😐"
        case .tired: return "😴"
        }
    }
}

struct CheckInSettings: Codable, Equatable {
    /// 매일 체크인 마감 시간 (시/분)
    var deadlineHour: Int = 21
    var deadlineMinute: Int = 0
    /// 마감 전 알림(분)
    var reminderMinutesBefore: Int = 60
    /// 미응답 시 비상 연락까지 대기 시간(분)
    var graceMinutes: Int = 20
    var pushEnabled: Bool = true
    var smsEnabled: Bool = true
    var callEnabled: Bool = true
    var familyActivityEnabled: Bool = true
    var marketingEnabled: Bool = false
}

// MARK: - Emergency

enum ContactAttemptState: String, Codable {
    case contacting = "연락중..."
    case waiting = "대기중..."
    case reached = "연결됨"
    case failed = "실패"
}

struct EmergencyContact: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var name: String
    var phone: String
    var relation: String
    var priority: Int
    var state: ContactAttemptState = .waiting
}

// MARK: - Family

struct FamilyMember: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var name: String
    var relation: String
    var phone: String = "010-0000-0000"
    var avatarAsset: String
    var isOnline: Bool
    var lastCheckInMinutesAgo: Int
    var unreadCount: Int
    var activityTitle: String
    var activityDetail: String?
    var streakDays: Int
    var nightingaleScore: Double
    var scoreNote: String
    var avgSleepHours: Double
    var sleepQuality: String
    var avgHeartRate: Int
    var latitude: Double
    var longitude: Double
}

struct FamilyActivity: Identifiable, Equatable {
    var id: UUID = UUID()
    var memberName: String
    var message: String
    var date: Date
}

struct ChatMessage: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var senderName: String
    var isMine: Bool
    var text: String
    var date: Date
}

/// 초대 코드로 참여할 수 있는 지인 (백엔드 연동 전 목업)
struct InviteCandidate: Equatable, Identifiable {
    var code: String
    var member: FamilyMember
    var id: String { code }
}

// MARK: - Health

enum HealthCondition: String, Codable {
    case good = "좋음"
    case bad = "나쁨"
    case unknown = "측정중"
}

struct SleepStage: Identifiable, Equatable {
    var id: UUID = UUID()
    var name: String
    var range: String
    var hours: Double
    var kind: Kind

    enum Kind { case deep, light, rem }
}

struct SleepSummary: Equatable {
    var date: Date
    var totalHours: Double
    var stages: [SleepStage]
}

struct HeartRateSummary: Equatable {
    var date: Date
    var current: Int
    var average: Int
    var averageRange: String
    var max: Int
    var maxRange: String
    var min: Int
    var minRange: String
    /// 24시간 시간대별 심박수 샘플
    var samples: [Double] = []
}

/// 건강 앱(HealthKit) 연동 상태
enum HealthConnection: String, Codable, Equatable {
    case disconnected
    case connecting
    case connected
}

struct HealthOverview: Equatable {
    var nightingaleScore: Double
    var scoreNote: String
    var heartRate: Int
    var sleepHoursPerDay: Double
    var condition: HealthCondition
}

// MARK: - Stress

enum StressLevel: String, CaseIterable, Codable {
    case good = "좋은 상태"
    case normal = "정상 상태"
    case caution = "주의 상태"
    case high = "과다 상태"
    case none = "기록 없음"
}

struct StressDay: Identifiable, Equatable {
    var id: UUID = UUID()
    var date: Date
    var level: StressLevel
    var lowScore: Double   // 0...1 낮은 스트레스 막대
    var highScore: Double  // 0...1 높은 스트레스 막대
}

struct StressPeriodSummary: Equatable {
    var total: Int
    var good: Int
    var normal: Int
    var caution: Int
    var high: Int
    var lowStressDays: Int
    var highStressDays: Int
    var lowDelta: Int
    var highDelta: Int
    var comment: String
}

// MARK: - Notifications

struct AppNotification: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var title: String
    var body: String
    var date: Date
    var kind: Kind
    var isRead: Bool

    enum Kind: String, Codable { case checkIn, danger, family, system }
}

// MARK: - Withdrawal

enum WithdrawReason: String, CaseIterable, Identifiable {
    case tooComplex = "서비스 사용법이 복잡하고 어려워요."
    case otherService = "다른 서비스를 사용하고 있어요."
    case deleteData = "개인정보를 삭제하고 싶어요."
    var id: String { rawValue }
}
