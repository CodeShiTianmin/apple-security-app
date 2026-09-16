import SwiftUI

/// Figma 设计稿中的颜色令牌 (제목 없음 9.15)
enum KnockColor {
    // Brand
    static let primary = Color(hex: 0x83A94F)        // 헤더 배경 / 主绿色
    static let primaryDeep = Color(hex: 0x7A9F50)    // 헤더 잎사귀 장식
    static let primaryDark = Color(hex: 0x193F2C)    // 기본 진한 텍스트
    static let primaryDark2 = Color(hex: 0x21432F)
    static let lime = Color(hex: 0xB0D978)           // 인증 플로우 버튼
    static let lime2 = Color(hex: 0xBCD98C)
    static let limeLight = Color(hex: 0xD8E86A)      // 카카오 버튼
    static let yellow = Color(hex: 0xFCD45D)         // 체크 버튼 / 경고 배지
    static let sun = Color(hex: 0xFEDA5F)

    // Surfaces
    static let background = Color(hex: 0xFCFCF6)     // 콘텐츠 배경
    static let card = Color.white
    static let cardTint = Color(hex: 0xE7F0D5)       // 연한 초록 카드
    static let cardTint2 = Color(hex: 0xEDF4E2)      // 탭바 선택 배경
    static let cardTint3 = Color(hex: 0xF0F2E8)
    static let divider = Color(hex: 0xE1E8D9)
    static let stroke = Color(hex: 0xD9D9D9)
    static let sheet = Color(hex: 0xF4F4F4)

    // Text
    static let textPrimary = Color(hex: 0x193F2C)
    static let textSecondary = Color(hex: 0x6F7B70)
    static let textMuted = Color(hex: 0x828684)
    static let textDisabled = Color(hex: 0xA7AFA4)
    static let textNeutral = Color(hex: 0x343434)
    static let textGray = Color(hex: 0x777777)
    static let textBlack = Color(hex: 0x262626)

    // Status
    static let online = Color(hex: 0x35B96F)
    static let offline = Color(hex: 0x9A9F99)
    static let danger = Color(hex: 0xA54F56)
    static let dangerText = Color(hex: 0x99494F)
    static let dangerSoft = Color(hex: 0xFCE1DF)
    static let dangerBadge = Color(hex: 0xF5D5D5)
    static let dangerHalo = Color(hex: 0xFBE3E3)
    static let dangerSurface = Color(hex: 0xF8DBD8)
    static let healthGoodPill = Color(hex: 0xF1F7E7)
    static let healthBadPill = Color(hex: 0xFDEAE8)
    static let tabIconActive = Color(hex: 0x648A3F)
    static let tabIconInactive = Color(hex: 0x8B938A)
    static let tabBorder = Color(hex: 0xE5E7E0)
    static let pendingDay = Color(hex: 0xE7E7E3)
    static let waitingBadge = Color(hex: 0xECEEEB)
    static let modalDim = Color(hex: 0x102016)
    static let textRegion = Color(hex: 0x758275)
    static let kakao = Color(hex: 0xDFE686)
    static let authStroke = Color(hex: 0xD2D2D2)
    static let warning = Color(hex: 0xE5484D)
    static let lavender = Color(hex: 0xA4ABBE)       // REM 수면 / 보통 스트레스
    static let link = Color(hex: 0x1370FB)

    // Stress levels
    static let stressGood = primary
    static let stressNormal = yellow
    static let stressCaution = lavender
    static let stressHigh = Color(hex: 0xE8A5A5)
}

extension Color {
    init(hex: UInt32, alpha: Double = 1) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255,
            opacity: alpha
        )
    }
}
