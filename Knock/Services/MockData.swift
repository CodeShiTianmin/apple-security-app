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
        FamilyMember(name: "엄마", relation: "어머니", phone: "010-4059-1111", avatarAsset: "avatar_family_1", isOnline: true,
                     lastCheckInMinutesAgo: 120, unreadCount: 5,
                     activityTitle: "현재 활동 중",
                     activityDetail: "체크인 정보가 방금\n업데이트되었어요. 지금 확인해 보세요",
                     streakDays: 31, nightingaleScore: 80.1, scoreNote: "오늘은 경도 고혈압",
                     avgSleepHours: 6, sleepQuality: "수면 질량:중", avgHeartRate: 80,
                     latitude: 35.1745, longitude: 126.9120),
        FamilyMember(name: "지웅", relation: "형제", phone: "010-4059-2222", avatarAsset: "avatar_family_2", isOnline: true,
                     lastCheckInMinutesAgo: 30, unreadCount: 0,
                     activityTitle: "현재 활동 중",
                     activityDetail: "체크인 정보가 방금\n업데이트되었어요. 지금 확인해 보세요",
                     streakDays: 12, nightingaleScore: 88.4, scoreNote: "오늘은 정상 범위",
                     avgSleepHours: 7.5, sleepQuality: "수면 질량:상", avgHeartRate: 68,
                     latitude: 35.1790, longitude: 126.9165),
        FamilyMember(name: "성원", relation: "친구", phone: "010-4059-3333", avatarAsset: "avatar_family_3", isOnline: false,
                     lastCheckInMinutesAgo: 23 * 60, unreadCount: 0,
                     activityTitle: "23시간 전에 활동",
                     activityDetail: nil,
                     streakDays: 4, nightingaleScore: 72.3, scoreNote: "오늘은 수면 부족",
                     avgSleepHours: 5.2, sleepQuality: "수면 질량:하", avgHeartRate: 76,
                     latitude: 35.1712, longitude: 126.9068),
    ]

    /// 초대 코드 디렉터리 (코드 → 참여하는 지인)
    static let inviteCandidates: [InviteCandidate] = [
        InviteCandidate(code: "1234-5678", member: FamilyMember(
            name: "아버지", relation: "아버지", phone: "010-4059-4444", avatarAsset: "avatar_mother", isOnline: true,
            lastCheckInMinutesAgo: 12, unreadCount: 0, activityTitle: "현재 활동 중",
            activityDetail: "방금 가족에 참여했어요", streakDays: 1, nightingaleScore: 84.2,
            scoreNote: "오늘은 정상 범위", avgSleepHours: 7, sleepQuality: "수면 질량:중",
            avgHeartRate: 74, latitude: 35.1730, longitude: 126.9150)),
        InviteCandidate(code: "8765-4321", member: FamilyMember(
            name: "할머니", relation: "할머니", phone: "010-4059-5555", avatarAsset: "avatar_family_1", isOnline: false,
            lastCheckInMinutesAgo: 180, unreadCount: 0, activityTitle: "3시간 전에 활동",
            activityDetail: nil, streakDays: 1, nightingaleScore: 69.5,
            scoreNote: "오늘은 혈압 주의", avgSleepHours: 5.8, sleepQuality: "수면 질량:하",
            avgHeartRate: 82, latitude: 35.1698, longitude: 126.9210)),
    ]

    static let emergencyContacts: [EmergencyContact] = [
        EmergencyContact(name: "엄마", phone: "010-4059-1111", relation: "어머니", priority: 1),
        EmergencyContact(name: "지웅", phone: "010-4059-2222", relation: "형제", priority: 2),
        EmergencyContact(name: "성원", phone: "010-4059-3333", relation: "친구", priority: 3),
    ]

    static let emergencyMessage = "저에게 연락이 되지 않아요. 안전 확인을 도와주세요."

    static func weekRecords(reference: Date = .now) -> [CheckInRecord] {
        let start = startOfWeek(reference)
        let moods: [Mood] = [.good, .great, .soso, .good, .tired, .great, .good]
        return (0..<7).map { offset in
            let day = calendar.date(byAdding: .day, value: offset, to: start)!
            let isToday = calendar.isDate(day, inSameDayAs: reference)
            let isFuture = day > reference && !isToday
            let done = !isFuture && !isToday
            return CheckInRecord(date: day, completed: done, status: done ? .safe : .pending,
                                 mood: done ? moods[offset] : nil)
        }
    }

    /// 과거 체크인 이력: 연속 일수만큼 어제부터 거슬러 올라가며 채움
    static func checkedInDays(streak: Int, reference: Date = .now) -> Set<Date> {
        var result = Set<Date>()
        for i in 1...max(streak, 1) {
            if let d = calendar.date(byAdding: .day, value: -i, to: calendar.startOfDay(for: reference)) {
                result.insert(d)
            }
        }
        return result
    }

    /// 가족 채팅 자동 응답 문구
    static let chatReplies: [String] = [
        "응 알게데 오늘도 고생했어~",
        "밥은 꼭 쳐거 밥 사훈누먹거라 😊",
        "오늘 체크 확인했어! 고마워",
        "주말에 같이 식사하자",
        "오늘 날씨 춥다 따뜻하게 입어",
    ]

    /// 모의 가족 실시간 이벤트 (이름, 메시지)
    static let liveFamilyEvents: [(name: String, message: String)] = [
        ("지웅", "오늘 체크인을 완료했어요."),
        ("엄마", "오늘 수면 7시간을 기록했어요."),
        ("성원", "오늘 체크인을 완료했어요."),
        ("엄마", "산책 30분을 마쳤어요."),
    ]

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
            SleepStage(name: "렘 수면", range: "12:30-02 : 33", hours: 3, kind: .rem),
        ]
    )

    static let heartRate = HeartRateSummary(
        date: date(2025, 7, 22), current: 90,
        average: 118, averageRange: "00:00-24:00",
        max: 184, maxRange: "10:30-12 : 35",
        min: 63, minRange: "1:30-09 : 33"
    )

    // MARK: 날짜별 건강 데이터 (결정적 시드 → 같은 날짜는 항상 같은 값)

    /// 날짜 기반 시드 (0...9999)
    static func daySeed(_ day: Date) -> Int {
        let c = calendar.dateComponents([.year, .month, .day], from: day)
        return ((c.year! * 372 + c.month! * 31 + c.day!) * 2654435) % 10_000
    }

    private static func unit(_ seed: Int, _ salt: Int) -> Double {
        Double((seed * (salt * 7919 + 13)) % 1000) / 1000
    }

    private static func clock(_ h: Double) -> String {
        let hh = Int(h) % 24
        let mm = Int((h - Double(Int(h))) * 60)
        return String(format: "%02d:%02d", hh, mm)
    }

    /// 선택 날짜의 수면 요약 (디자인 기준일은 시안 수치 사용)
    static func sleep(for day: Date) -> SleepSummary {
        if calendar.isDate(day, inSameDayAs: sleep.date) { return sleep }
        let seed = daySeed(day)
        let total = 5.0 + unit(seed, 1) * 3.5                       // 5.0 ~ 8.5h
        let deep = (total * (0.30 + unit(seed, 2) * 0.15) * 2).rounded() / 2
        let rem = (total * (0.18 + unit(seed, 3) * 0.1) * 2).rounded() / 2
        let light = max(0.5, ((total - deep - rem) * 2).rounded() / 2)
        let start = 22.5 + unit(seed, 4) * 2.5                      // 22:30 ~ 01:00 취침
        return SleepSummary(
            date: day,
            totalHours: deep + rem + light,
            stages: [
                SleepStage(name: "깊은 수면", range: "\(clock(start))-\(clock(start + deep))", hours: deep, kind: .deep),
                SleepStage(name: "얕은 수면", range: "\(clock(start + deep))-\(clock(start + deep + light))", hours: light, kind: .light),
                SleepStage(name: "렘 수면", range: "\(clock(start + deep + light))-\(clock(start + deep + light + rem))", hours: rem, kind: .rem),
            ]
        )
    }

    /// 시간대별 심박수 24개 샘플
    static func heartRateSamples(for day: Date) -> [Double] {
        if calendar.isDate(day, inSameDayAs: heartRate.date) {
            return [68, 64, 63, 66, 72, 85, 96, 110, 118, 184, 120, 98, 92, 88, 95, 102, 90, 84, 80, 76, 74, 72, 70, 69]
        }
        let seed = daySeed(day)
        let rest = 58.0 + unit(seed, 5) * 12
        let peakHour = 7 + Int(unit(seed, 6) * 12)
        let peak = 120.0 + unit(seed, 7) * 50
        return (0..<24).map { h in
            let daytime = h >= 7 && h <= 22 ? 1.0 : 0.0
            let base = rest + daytime * (14 + unit(seed, 8 + h) * 10)
            let dist = abs(h - peakHour)
            let spike = dist == 0 ? peak - base : (dist == 1 ? (peak - base) * 0.45 : 0)
            return (base + spike).rounded()
        }
    }

    /// 선택 날짜의 심박수 요약
    static func heartRate(for day: Date) -> HeartRateSummary {
        let samples = heartRateSamples(for: day)
        if calendar.isDate(day, inSameDayAs: heartRate.date) {
            var s = heartRate
            s.samples = samples
            return s
        }
        let maxIdx = samples.indices.max { samples[$0] < samples[$1] }!
        let minIdx = samples.indices.min { samples[$0] < samples[$1] }!
        let avg = Int(samples.reduce(0, +) / Double(samples.count))
        return HeartRateSummary(
            date: day, current: Int(samples[min(23, max(0, calendar.component(.hour, from: .now)))]),
            average: avg, averageRange: "00:00-24:00",
            max: Int(samples[maxIdx]), maxRange: "\(clock(Double(maxIdx)))-\(clock(Double(maxIdx) + 1))",
            min: Int(samples[minIdx]), minRange: "\(clock(Double(minIdx)))-\(clock(Double(minIdx) + 1))",
            samples: samples
        )
    }

    /// 시간대별 스트레스 지수(0...1) 24개
    static func stressHours(for day: Date) -> [Double] {
        if calendar.isDate(day, inSameDayAs: heartRate.date) {
            return [0.2, 0.15, 0.1, 0.1, 0.15, 0.3, 0.45, 0.6, 0.7, 0.55, 0.5, 0.65,
                    0.8, 0.75, 0.6, 0.5, 0.4, 0.45, 0.35, 0.3, 0.25, 0.2, 0.2, 0.15]
        }
        let seed = daySeed(day)
        let intensity = 0.35 + unit(seed, 30) * 0.5
        return (0..<24).map { h in
            let curve = h < 6 ? 0.15 : (h < 13 ? 0.3 + Double(h - 6) * 0.08 : (h < 19 ? 0.85 - Double(h - 13) * 0.07 : 0.4 - Double(h - 19) * 0.05))
            return max(0.05, min(1, curve * intensity + unit(seed, 40 + h) * 0.15))
        }
    }

    static func stressLevel(for hours: [Double]) -> StressLevel {
        let avg = hours.reduce(0, +) / Double(max(1, hours.count))
        switch avg {
        case ..<0.3: return .good
        case ..<0.42: return .normal
        case ..<0.55: return .caution
        default: return .high
        }
    }

    static let overviewGood = HealthOverview(nightingaleScore: 90.1, scoreNote: "오늘은 경도 고혈압",
                                             heartRate: 71, sleepHoursPerDay: 6.5, condition: .good)
    static let overviewBad = HealthOverview(nightingaleScore: 58.4, scoreNote: "오늘은 심박 이상 감지",
                                            heartRate: 118, sleepHoursPerDay: 4.1, condition: .bad)

    /// 디자인 시안의 기준 주 (2025-07-21 ~ 27)
    static let designWeekStart = date(2025, 7, 21)

    static func stressWeek(start: Date) -> [StressDay] {
        if calendar.isDate(start, inSameDayAs: designWeekStart) {
            let levels: [StressLevel] = [.good, .normal, .good, .caution, .good, .none, .good]
            let lows: [Double] = [1.0, 0.85, 0.75, 0.5, 0.25, 0.85, 0.95]
            let highs: [Double] = [0.75, 0.3, 0.25, 0.7, 0.45, 0.95, 0.8]
            return (0..<7).map { i in
                StressDay(date: calendar.date(byAdding: .day, value: i, to: start)!,
                          level: levels[i], lowScore: lows[i], highScore: highs[i])
            }
        }
        return (0..<7).map { i in stressDay(for: calendar.date(byAdding: .day, value: i, to: start)!) }
    }

    static func stressDay(for day: Date) -> StressDay {
        let hours = stressHours(for: day)
        let seed = daySeed(day)
        let recorded = seed % 9 != 0 && day <= .now
        let avg = hours.reduce(0, +) / Double(hours.count)
        return StressDay(date: day, level: recorded ? stressLevel(for: hours) : .none,
                         lowScore: min(1, 1.2 - avg), highScore: min(1, avg * 1.4))
    }

    static func stressMonth(monthStart: Date) -> [StressDay] {
        let days = calendar.range(of: .day, in: .month, for: monthStart)!.count
        if calendar.isDate(monthStart, equalTo: designWeekStart, toGranularity: .month) {
            let pattern: [Int: StressLevel] = [2: .high, 6: .good, 7: .good, 8: .good, 14: .good, 15: .good,
                                               16: .high, 26: .good, 27: .good, 28: .good, 31: .good]
            return (0..<days).map { i in
                let d = calendar.date(byAdding: .day, value: i, to: monthStart)!
                return StressDay(date: d, level: pattern[i + 1] ?? .none,
                                 lowScore: Double((i * 7) % 10) / 10, highScore: Double((i * 3) % 10) / 10)
            }
        }
        return (0..<days).map { i in stressDay(for: calendar.date(byAdding: .day, value: i, to: monthStart)!) }
    }

    /// 기간 내 일별 기록을 집계한 요약 (기준 주/월은 디자인 시안 수치 사용)
    static func summary(for days: [StressDay], period: String, fallback: StressPeriodSummary?) -> StressPeriodSummary {
        if let fallback { return fallback }
        let recorded = days.filter { $0.level != .none }
        let good = recorded.filter { $0.level == .good }.count
        let normal = recorded.filter { $0.level == .normal }.count
        let caution = recorded.filter { $0.level == .caution }.count
        let high = recorded.filter { $0.level == .high }.count
        let low = recorded.filter { $0.lowScore >= 0.7 }.count
        let hi = recorded.filter { $0.highScore >= 0.6 }.count
        let total = recorded.count
        let ratio = total == 0 ? 0 : good * 100 / total
        let comment = total == 0
            ? "이 기간에는 기록된 스트레스 데이터가 없어요. 애플워치를 연결하면 자동으로 기록돼요."
            : "\(period) 스트레스 상태는 총 \(total)회 중 \(ratio)%가 좋은 상태예요. " +
              (high > 0 ? "과다 상태가 \(high)회 있었으니 충분한 휴식이 필요해요." : "과다 상태는 없었어요. 지금처럼 유지해 보세요.")
        return StressPeriodSummary(total: total, good: good, normal: normal, caution: caution, high: high,
                                   lowStressDays: low, highStressDays: hi,
                                   lowDelta: low - total / 2, highDelta: hi - total / 3, comment: comment)
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

    static let designYear = 2025

    static func yearMonthlyScores(for year: Int) -> [(low: Double, high: Double)] {
        if year == designYear { return yearMonthlyScores }
        return (0..<12).map { m in
            let seed = Double((year * 31 + m * 17) % 100) / 100
            let low = 0.55 + 0.4 * abs(sin(seed * .pi * 2 + Double(m) * 0.6))
            let high = max(0.1, 0.7 - low * 0.55 + 0.15 * cos(seed * .pi * 3))
            return (min(1, low), min(1, high))
        }
    }

    static func yearSummary(for year: Int) -> StressPeriodSummary {
        if year == designYear { return yearSummary }
        let scores = yearMonthlyScores(for: year)
        let total = 260 + (year % 7) * 9
        let avgLow = scores.map(\.low).reduce(0, +) / Double(scores.count)
        let avgHigh = scores.map(\.high).reduce(0, +) / Double(scores.count)
        let good = Int(Double(total) * avgLow * 0.75)
        let high = Int(Double(total) * avgHigh * 0.12)
        let caution = Int(Double(total) * avgHigh * 0.3)
        let normal = max(0, total - good - high - caution)
        return StressPeriodSummary(
            total: total, good: good, normal: normal, caution: caution, high: high,
            lowStressDays: good, highStressDays: caution + high,
            lowDelta: good - 190, highDelta: (caution + high) - 40,
            comment: "\(year)년 스트레스 상태는 총 \(total)회 중 \(total == 0 ? 0 : good * 100 / total)%가 좋은 상태로 기록되었고, 과다 상태는 \(high)회 나타났어요."
        )
    }

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
