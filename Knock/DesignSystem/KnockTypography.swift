import SwiftUI

/// 设计稿使用 Noto Sans KR / Pretendard。未打包字体时回退到系统字体(Apple SD Gothic Neo 渲染韩文)。
enum KnockFont {
    static func regular(_ size: CGFloat) -> Font { .system(size: size, weight: .regular) }
    static func medium(_ size: CGFloat) -> Font { .system(size: size, weight: .medium) }
    static func semibold(_ size: CGFloat) -> Font { .system(size: size, weight: .semibold) }
    static func bold(_ size: CGFloat) -> Font { .system(size: size, weight: .bold) }
    static func heavy(_ size: CGFloat) -> Font { .system(size: size, weight: .heavy) }

    // Semantic styles
    static let display = bold(38)
    static let title = medium(22)
    static let headline = medium(18)
    static let body = medium(14)
    static let caption = medium(12)
    static let footnote = regular(12)

    // Auth flow (Pretendard 600)
    static let authTitle = semibold(24)
    static let authSubtitle = semibold(16)
    static let authButton = semibold(20)
}

struct KnockShadow: ViewModifier {
    var radius: CGFloat = 18
    var y: CGFloat = 6
    var opacity: Double = 0.08
    func body(content: Content) -> some View {
        content.shadow(color: KnockColor.primaryDark.opacity(opacity), radius: radius, x: 0, y: y)
    }
}

extension View {
    func knockShadow(radius: CGFloat = 18, y: CGFloat = 6, opacity: Double = 0.08) -> some View {
        modifier(KnockShadow(radius: radius, y: y, opacity: opacity))
    }

    func hideKeyboardOnTap() -> some View {
        onTapGesture {
            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        }
    }
}
