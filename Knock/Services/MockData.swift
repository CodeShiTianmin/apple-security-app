import Foundation

/// 设计稿中的示例数据。后端接入后由各 Service 的真实实现替换。
enum MockData {
    static let calendar = Calendar(identifier: .gregorian)

    static let user = UserProfile(
        name: "현진",
        loginID: "hyunjin01",
        email: "hyunjin@knock.app",
        phone: "010-4059-0000",
        birthDate: "1998 . 03 . 14",
        gender: .female,
        region: "광주 · 북구",
        avatarAsset: "avatar_me",
        isOnline: true
    )

    static let members: [FamilyMember] = [
        FamilyMember(name: "엄마", relation: "어머니", avatarAsset: "avatar_family_1", isOnline: true,
                     lastCheckInMinutesAgo: 120, unreadCount: 5,
                     activityTitle: "현재 활동 중",
                     activityDetail: "체크인 정보가 방금\n업데이트되었어요. 지금 확인해 보세요",
                     streakDays: 31, nightingaleScore: 80.1, scoreNote: "오늘은 경도 고혈압",
                     avgSleepHours: 6, sleepQuality: "수면 질량:중", avgHeartRate: 80,
                     latitude: 35.1745, longitude: 126.9120),
        FamilyMember(name: "지웅", relation: "형제", avatarAsset: "avatar_family_2", isOnline: true,
                     lastCheckInMinutesAgo: 30, unreadCount: 0,
                     activityTitle: "현재 활동 중",
                     activityDetail: "체크인 정보가 방금\n업데이트되었어요. 지금 확인해 보세요",
                     streakDays: 12, nightingaleScore: 88.4, scoreNote: "오늘은 정상 범위",
                     avgSleepHours: 7.5, sleepQuality: "수면 질량:상", avgHeartRate: 68,
                     latitude: 35.1790, longitude: 126.9165),
        FamilyMember(name: "성원", relation: "친구", avatarAsset: "avatar_family_3", isOnline: false,
                     lastCheckInMinutesAgo: 23 * 60, unreadCount: 0,
                     activityTitle: "23시간 전에 활동",
                     activityDetail: nil,
                     streakDays: 4, nightingaleScore: 72.3, scoreNote: "오늘은 수면 부족",
                     avgSleepHours: 5.2, sleepQuality: "수면 질량:하", avgHeartRate: 76,
                     latitude: 35.1712, longitude: 126.9068),
    ]

    static let emergencyContacts: [EmergencyContact] = [
        EmergencyContact(name: "엄마", phone: "010-4059-0000", relation: "어머니", priority: 1),
        EmergencyContact(name: "지웅", phone: "010-4059-0000", relation: "형제", priority: 2),
        EmergencyContact(name: "성원", phone: "010-4059-0000", relation: "친구", priority: 3),
    ]

    static let emergencyMessage = "저에게 연락이 되지 않아요. 안전 확인을 도와주세요."

    static func weekRecords(reference: Date = .now) -> [CheckInRecord] {
        let start = startOfWeek(reference)
        return (0..<7).map { offset in
            let day = calendar.date(byAdding: .day, value: offset, to: start)!
            let isFuture = day > reference && !calendar.isDate(day, inSameDayAs: reference)
            return CheckInRecord(date: day, completed: !isFuture, status: isFuture ? .pending : .safe)
        }
    }

    static func startOfWeek(_ date: Date) -> Date {
        var cal = calendar
        cal.firstWeekday = 2
        let comps = cal.dateComponents([.yearForWeekOfYear, .weekOfYear], from: date)
        return cal.date(from: comps)!
    }

    static let sleep = SleepSummary(
        date: date(2025, 7, 22),
        totalHours: 12,
        stages: [
            SleepStage(name: "깊은 수면", range: "02:30-06 : 35", hours: 6, kind: .deep),
            SleepStage(name: "얕은 수면", range: "06:30-09 : 35", hours: 3, kind: .light),
            SleepStage(name: "REM 수면", range: "12:30-02 : 33", hours: 3, kind: .rem),
        ]
    )

    static let heartRate = HeartRateSummary(
        date: date(2025, 7, 22), current: 90,
        average: 118, averageRange: "00:00-24:00",
        max: 184, maxRange: "10:30-12 : 35",
        min: 63, minRange: "1:30-09 : 33"
    )

    static let overviewGood = HealthOverview(nightingaleScore: 90.1, scoreNote: "오늘은 경도 고혈압",
                                             heartRate: 71, sleepHoursPerDay: 6.5, condition: .good)
    static let overviewBad = HealthOverview(nightingaleScore: 58.4, scoreNote: "오늘은 심박 이상 감지",
                                            heartRate: 118, sleepHoursPerDay: 4.1, condition: .bad)

    static func stressWeek(start: Date) -> [StressDay] {
        let levels: [StressLevel] = [.good, .normal, .good, .caution, .good, .none, .good]
        let lows: [Double] = [1.0, 0.85, 0.75, 0.5, 0.25, 0.85, 0.95]
        let highs: [Double] = [0.75, 0.3, 0.25, 0.7, 0.45, 0.95, 0.8]
        return (0..<7).map { i in
            StressDay(date: calendar.date(byAdding: .day, value: i, to: start)!,
                      level: levels[i], lowScore: lows[i], highScore: highs[i])
        }
    }

    static func stressMonth(monthStart: Date) -> [StressDay] {
        let days = calendar.range(of: .day, in: .month, for: monthStart)!.count
        let pattern: [Int: StressLevel] = [2: .high, 6: .good, 7: .good, 8: .good, 14: .good, 15: .good,
                                           16: .high, 26: .good, 27: .good, 28: .good, 31: .good]
        return (0..<days).map { i in
            let d = calendar.date(byAdding: .day, value: i, to: monthStart)!
            return StressDay(date: d, level: pattern[i + 1] ?? .none,
                             lowScore: Double((i * 7) % 10) / 10, highScore: Double((i * 3) % 10) / 10)
        }
    }

    static let weekSummary = StressPeriodSummary(
        total: 7, good: 4, normal: 1, caution: 1, high: 0,
        lowStressDays: 3, highStressDays: 3, lowDelta: 3, highDelta: -3,
        comment: "이번 주 스트레스 상태는 전반적으로 양호해요. 주중 목요일에 주의가 필요한 시간대가 있었어요."
    )

    static let monthSummary = StressPeriodSummary(
        total: 86, good: 56, normal: 19, caution: 8, high: 3,
        lowStressDays: 18, highStressDays: 5, lowDelta: 4, highDelta: -2,
        comment: "이번 달 스트레스 상태는 전반적으로 양호하며, 좋은 상태의 비율이 가장 높게 나타났지만 일부 날짜에는 주의가 필요한 스트레스 시간대도 확인된다"
    )

    static let yearSummary = StressPeriodSummary(
        total: 312, good: 201, normal: 74, caution: 28, high: 9,
        lowStressDays: 201, highStressDays: 37, lowDelta: 22, highDelta: -11,
        comment: "올해 스트레스 상태는 전반적으로 안정적이에요. 총 312회 중 64%가 좋은 상태로 기록되었고, 과다 상태는 9회 나타났어요."
    )

    /// 년기: 월별 좋은/높은 스트레스 비율
    static let yearMonthlyScores: [(low: Double, high: Double)] = [
        (0.8, 0.3), (0.7, 0.4), (0.9, 0.2), (0.6, 0.5), (0.75, 0.35), (0.85, 0.3),
        (0.95, 0.15), (0.65, 0.45), (0.7, 0.4), (0.8, 0.3), (0.9, 0.2), (0.85, 0.25),
    ]

    static let notifications: [AppNotification] = [
        AppNotification(title: "똑똑똑", body: "위험 상황으로 의심되는 상태가 감지되었습니다. 지금 바로 안전 상태를 확인해 주세요. 20분 이내에 응답하지 않으면 긴급 연락처로 자동 연락됩니다",
                        date: .now.addingTimeInterval(-600), kind: .danger, isRead: false),
        AppNotification(title: "오늘의 체크인", body: "아직 오늘 체크인을 하지 않았어요. 잊지 말고 안부를 남겨주세요.",
                        date: .now.addingTimeInterval(-3600 * 3), kind: .checkIn, isRead: false),
        AppNotification(title: "엄마님이 체크인했어요", body: "엄마님의 오늘 상태는 안전이에요.",
                        date: .now.addingTimeInterval(-3600 * 5), kind: .family, isRead: true),
        AppNotification(title: "16일 연속 출석 달성!", body: "꾸준히 체크인하고 있어요. 계속 화이팅!",
                        date: .now.addingTimeInterval(-86400), kind: .system, isRead: true),
    ]

    static func activities() -> [FamilyActivity] {
        [
            FamilyActivity(memberName: "엄마", message: "오늘 체크인을 완료했어요.", date: .now.addingTimeInterval(-7200)),
            FamilyActivity(memberName: "지웅", message: "오늘 체크인을 완료했어요.", date: .now.addingTimeInterval(-1800)),
            FamilyActivity(memberName: "엄마", message: "심박수가 정상 범위로 돌아왔어요.", date: .now.addingTimeInterval(-86400)),
            FamilyActivity(memberName: "성원", message: "23시간 전에 마지막으로 활동했어요.", date: .now.addingTimeInterval(-82800)),
        ]
    }

    static func chat() -> [ChatMessage] {
        [
            ChatMessage(senderName: "엄마", isMine: false, text: "오늘도 체크 잊지 말고~", date: .now.addingTimeInterval(-7000)),
            ChatMessage(senderName: "나", isMine: true, text: "네! 방금 체크했어요 😊", date: .now.addingTimeInterval(-6900)),
            ChatMessage(senderName: "지웅", isMine: false, text: "누나 이번 주말에 집에 와?", date: .now.addingTimeInterval(-3000)),
        ]
    }

    static func date(_ y: Int, _ m: Int, _ d: Int) -> Date {
        calendar.date(from: DateComponents(year: y, month: m, day: d))!
    }
}
