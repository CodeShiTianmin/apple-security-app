import SwiftUI

/// 인증 플로우의 캡슐형 입력 필드
struct KnockTextField: View {
    var placeholder: String
    @Binding var text: String
    var keyboard: UIKeyboardType = .default
    var contentType: UITextContentType? = nil
    var accent: Bool = false
    var trailing: AnyView? = nil

    var body: some View {
        HStack {
            TextField(placeholder, text: $text, prompt: Text(placeholder).foregroundStyle(accent ? KnockColor.lime : KnockColor.textMuted))
                .keyboardType(keyboard)
                .textContentType(contentType)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .font(KnockFont.medium(16))
                .foregroundStyle(KnockColor.textNeutral)
            if let trailing { trailing }
        }
        .padding(.horizontal, 22)
        .frame(height: 56)
        .background(.white, in: Capsule())
        .overlay(Capsule().stroke(KnockColor.stroke, lineWidth: 1))
    }
}

struct KnockSecureField: View {
    var placeholder: String
    @Binding var text: String
    var accent: Bool = false
    @State private var reveal = false

    var body: some View {
        HStack {
            Group {
                if reveal {
                    TextField(placeholder, text: $text, prompt: prompt)
                } else {
                    SecureField(placeholder, text: $text, prompt: prompt)
                }
            }
            .textContentType(.password)
            .textInputAutocapitalization(.never)
            .autocorrectionDisabled()
            .font(KnockFont.medium(16))
            .foregroundStyle(KnockColor.textNeutral)

            Button { reveal.toggle() } label: {
                Image(systemName: reveal ? "eye" : "eye.slash")
                    .foregroundStyle(accent ? KnockColor.lime : KnockColor.textMuted)
            }
        }
        .padding(.horizontal, 22)
        .frame(height: 56)
        .background(.white, in: Capsule())
        .overlay(Capsule().stroke(KnockColor.stroke, lineWidth: 1))
    }

    private var prompt: Text {
        Text(placeholder).foregroundStyle(accent ? KnockColor.lime : KnockColor.textMuted)
    }
}

/// 6자리 인증번호 입력 (원형 6개)
struct CodeInputView: View {
    @Binding var code: String
    var length: Int = 6
    var accent: Bool = false
    @FocusState private var focused: Bool

    var body: some View {
        ZStack {
            HStack(spacing: 8) {
                ForEach(0..<length, id: \.self) { i in
                    ZStack {
                        Circle()
                            .stroke(i == code.count && focused ? KnockColor.lime : KnockColor.stroke, lineWidth: 1.5)
                            .background(Circle().fill(.white))
                        if i < code.count {
                            Text(String(code[code.index(code.startIndex, offsetBy: i)]))
                                .font(KnockFont.semibold(22))
                                .foregroundStyle(accent ? KnockColor.primary : KnockColor.textNeutral)
                        }
                    }
                    .frame(width: 50, height: 50)
                }
            }
            TextField("", text: $code)
                .keyboardType(.numberPad)
                .textContentType(.oneTimeCode)
                .focused($focused)
                .opacity(0.02)
                .onChange(of: code) { _, new in
                    let digits = new.filter(\.isNumber)
                    code = String(digits.prefix(length))
                }
        }
        .contentShape(Rectangle())
        .onTapGesture { focused = true }
        .onAppear { focused = true }
    }
}

/// 재발송 카운트다운 라벨 (인증 번호 재발송  00:56)
struct ResendCodeLabel: View {
    var seconds: Int
    var accent: Bool = false
    var onResend: () -> Void

    var body: some View {
        HStack(spacing: 8) {
            Button("인증 번호 재발송", action: onResend)
                .font(KnockFont.semibold(16))
                .foregroundStyle(KnockColor.textNeutral)
                .disabled(seconds > 0)
            Text(String(format: "%02d:%02d", seconds / 60, seconds % 60))
                .font(KnockFont.medium(16))
                .foregroundStyle(accent ? KnockColor.primary : KnockColor.textGray)
                .monospacedDigit()
        }
    }
}

struct FieldLabel: View {
    var text: String
    var body: some View {
        Text(text)
            .font(KnockFont.semibold(16))
            .foregroundStyle(KnockColor.textNeutral)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}

/// 성별 선택 등의 선택 칩
struct ChoiceChip: View {
    var title: String
    var selected: Bool
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(KnockFont.medium(16))
                .foregroundStyle(selected ? .white : KnockColor.textNeutral)
                .frame(maxWidth: .infinity)
                .frame(height: 40)
                .background(selected ? KnockColor.primary : .white, in: Capsule())
                .overlay(Capsule().stroke(selected ? KnockColor.primary : KnockColor.stroke, lineWidth: 1))
        }
        .buttonStyle(.pressable)
    }
}

/// 체크 아이콘 (원형 체크)
struct CheckCircle: View {
    var checked: Bool
    var size: CGFloat = 22
    var body: some View {
        Image(systemName: checked ? "checkmark.circle.fill" : "checkmark.circle")
            .font(.system(size: size, weight: .regular))
            .foregroundStyle(checked ? KnockColor.lime : KnockColor.stroke)
            .contentTransition(.symbolEffect(.replace))
    }
}

/// 설정 리스트 행
struct SettingsRow: View {
    var title: String
    var value: String? = nil
    var showChevron: Bool = true
    var titleColor: Color = KnockColor.textGray

    var body: some View {
        HStack {
            Text(title).font(KnockFont.medium(16)).foregroundStyle(titleColor)
            Spacer()
            if let value { Text(value).font(KnockFont.regular(14)).foregroundStyle(KnockColor.textMuted) }
            if showChevron {
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(KnockColor.lime)
            }
        }
        .padding(.vertical, 20)
        .contentShape(Rectangle())
    }
}
