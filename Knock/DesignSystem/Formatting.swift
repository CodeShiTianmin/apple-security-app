import Foundation

extension Date {
    /// 2025/07/22
    var slashFormatted: String { Formatters.slash.string(from: self) }
    /// 07/21
    var monthDay: String { Formatters.monthDay.string(from: self) }
    /// 2026년 10월 31일
    var koreanLong: String { Formatters.koreanLong.string(from: self) }
    /// 오후 3:48
    var shortTime: String { Formatters.shortTime.string(from: self) }

    var relativeDescription: String {
        let seconds = Int(Date.now.timeIntervalSince(self))
        switch seconds {
        case ..<60: return "방금"
        case ..<3600: return "\(seconds / 60)분 전"
        case ..<86400: return "\(seconds / 3600)시간 전"
        default: return "\(seconds / 86400)일 전"
        }
    }
}

enum Formatters {
    static let slash: DateFormatter = make("yyyy/MM/dd")
    static let monthDay: DateFormatter = make("MM/dd")
    static let koreanLong: DateFormatter = make("yyyy년 M월 d일")
    static let shortTime: DateFormatter = make("a h:mm")

    private static func make(_ format: String) -> DateFormatter {
        let f = DateFormatter()
        f.locale = Locale(identifier: "ko_KR")
        f.dateFormat = format
        return f
    }
}
