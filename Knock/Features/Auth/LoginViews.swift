import SwiftUI

/// 로그인 진입 화면: 로고 + 소셜 로그인
struct LoginLandingView: View {
    @Environment(AppState.self) private var appState
    @Binding var path: [AuthRoute]
    @State private var loading = false
    @State private var error: String?

    var body: some View {
        ZStack {
            Color.white.ignoresSafeArea()
            VStack(spacing: 0) {
                Image("logo_icon")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 129, height: 121)
                    .padding(.top, 199)

                VStack(spacing: 15) {
                    SocialLoginButton(provider: .kakao) { social(.kakao) }
                    SocialLoginButton(provider: .naver) { social(.naver) }
                    SocialLoginButton(provider: .facebook) { social(.facebook) }
                    SocialLoginButton(provider: .apple) { social(.apple) }
                    SocialLoginButton(provider: .phone) { path.append(.phoneLogin) }
                        .padding(.top, 33)
                }
                .padding(.horizontal, 22)
                .padding(.top, 56)

                Spacer(minLength: 16)

                Button {
                    path.append(.idLogin)
                } label: {
                    Text("이메일 또는 아이디로 계속하기 >")
                        .font(KnockFont.semibold(13))
                        .foregroundStyle(KnockColor.textGray)
                }
                .padding(.bottom, 4)
            }
            if loading { LoadingOverlay() }
        }
        .alert("로그인 실패", isPresented: .init(get: { error != nil }, set: { if !$0 { error = nil } })) {
            Button("확인", role: .cancel) {}
        } message: { Text(error ?? "") }
    }

    private func social(_ provider: SocialProvider) {
        loading = true
        Task {
            defer { loading = false }
            do {
                let user = try await appState.auth.login(with: provider)
                appState.completeLogin(user)
            } catch {
                self.error = error.localizedDescription
            }
        }
    }
}

/// [보충 화면] 아이디 / 비밀번호 로그인
struct IDLoginView: View {
    @Environment(AppState.self) private var appState
    @Binding var path: [AuthRoute]
    @State private var id = ""
    @State private var password = ""
    @State private var loading = false
    @State private var error: String?

    var body: some View {
        AuthScaffold(title: "아이디로 로그인", subtitle: "가입한 아이디 또는 이메일과 비밀번호를 입력해주세요") {
            VStack(spacing: 16) {
                KnockTextField(placeholder: "아이디 또는 이메일 입력", text: $id, keyboard: .emailAddress, contentType: .username)
                KnockSecureField(placeholder: "비밀번호 입력", text: $password)
                if let error {
                    Text(error)
                        .font(KnockFont.regular(12))
                        .foregroundStyle(KnockColor.warning)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 12)
                }
                HStack(spacing: 16) {
                    Button("아이디 찾기") { path.append(.findID) }
                    Rectangle().fill(KnockColor.stroke).frame(width: 1, height: 12)
                    Button("비밀번호 찾기") { path.append(.findPasswordEmail) }
                    Rectangle().fill(KnockColor.stroke).frame(width: 1, height: 12)
                    Button("이메일로 가입") { path.append(.emailSignup) }
                }
                .font(KnockFont.medium(13))
                .foregroundStyle(KnockColor.textGray)
                .padding(.top, 8)
            }
        } footer: {
            PrimaryButton(title: "로그인", isEnabled: !id.isEmpty && !password.isEmpty, isLoading: loading) {
                loading = true
                error = nil
                Task {
                    defer { loading = false }
                    do {
                        let user = try await appState.auth.login(id: id, password: password)
                        appState.completeLogin(user)
                    } catch {
                        self.error = error.localizedDescription
                    }
                }
            }
        }
    }
}

enum PhoneFlowMode { case login, findID }

/// 전화번호 입력 (아이디 찾기 / 휴대폰 로그인 공용)
struct PhoneInputView: View {
    @Environment(AppState.self) private var appState
    @Environment(SignupDraft.self) private var draft
    var mode: PhoneFlowMode
    @Binding var path: [AuthRoute]
    @State private var phone = ""
    @State private var loading = false

    var body: some View {
        AuthScaffold(title: "전화번호 입력",
                     subtitle: mode == .findID ? "가입한 전화번호를 입력해주세요" : "인증번호를 받을 휴대폰 번호를 입력해주세요") {
            KnockTextField(placeholder: "전화번호 입력", text: $phone, keyboard: .phonePad, contentType: .telephoneNumber, accent: true)
                .onChange(of: phone) { _, new in phone = PhoneFormatter.format(new) }
        } footer: {
            PrimaryButton(title: "다음", isEnabled: phone.filter(\.isNumber).count >= 10, isLoading: loading) {
                loading = true
                Task {
                    defer { loading = false }
                    try? await appState.auth.sendPhoneCode(to: phone)
                    draft.phone = phone
                    path.append(mode == .findID ? .findIDCode : .phoneLoginCode)
                }
            }
        }
    }
}

/// 문자 인증번호 입력
struct PhoneCodeView: View {
    @Environment(AppState.self) private var appState
    @Environment(SignupDraft.self) private var draft
    var mode: PhoneFlowMode
    @Binding var path: [AuthRoute]
    @State private var code = ""
    @State private var seconds = 60
    @State private var loading = false
    @State private var error: String?

    var body: some View {
        AuthScaffold(title: "인증번호 입력", subtitle: "문자로 전송된 인증번호를 입력해주세요", subtitleAccent: true) {
            VStack(spacing: 40) {
                CodeInputView(code: $code, accent: true)
                ResendCodeLabel(seconds: seconds, accent: true) {
                    seconds = 60
                    Task { try? await appState.auth.sendPhoneCode(to: draft.phone) }
                }
                if let error {
                    Text(error).font(KnockFont.regular(12)).foregroundStyle(KnockColor.warning)
                }
            }
        } footer: {
            PrimaryButton(title: "인증완료", isEnabled: code.count == 6, isLoading: loading) {
                loading = true
                error = nil
                Task {
                    defer { loading = false }
                    do {
                        try await appState.auth.verifyPhoneCode(code)
                        switch mode {
                        case .findID:
                            let id = try await appState.auth.findID(phone: draft.phone)
                            path.append(.findIDResult(id))
                        case .login:
                            var user = MockData.user
                            user.phone = draft.phone
                            appState.completeLogin(user)
                        }
                    } catch {
                        self.error = error.localizedDescription
                    }
                }
            }
        }
        .task(id: seconds) {
            guard seconds > 0 else { return }
            try? await Task.sleep(for: .seconds(1))
            seconds -= 1
        }
    }
}

/// 아이디를 잊으셨나요?
struct FindIDStartView: View {
    @Binding var path: [AuthRoute]

    var body: some View {
        AuthScaffold(title: "아이디를 잊으셨나요?", subtitle: "가입 시 입력한 번호로 아이디 찾기") {
            EmptyView()
        } footer: {
            VStack(spacing: 12) {
                PrimaryButton(title: "전화번호 인증하기") { path.append(.findIDPhone) }
                PrimaryButton(title: "이메일 인증하기") { path.append(.findPasswordEmail) }
            }
        }
    }
}

/// [보충 화면] 아이디 찾기 결과
struct FindIDResultView: View {
    var maskedID: String
    @Binding var path: [AuthRoute]

    var body: some View {
        AuthScaffold(title: "아이디를 찾았어요", subtitle: "가입하신 아이디는 아래와 같아요") {
            VStack(spacing: 12) {
                Text(maskedID)
                    .font(KnockFont.bold(28))
                    .foregroundStyle(KnockColor.textPrimary)
                    .frame(maxWidth: .infinity)
                    .frame(height: 90)
                    .background(KnockColor.cardTint, in: RoundedRectangle(cornerRadius: 20))
                Text("개인정보 보호를 위해 일부는 * 로 표시됩니다.")
                    .font(KnockFont.regular(12))
                    .foregroundStyle(KnockColor.textMuted)
            }
        } footer: {
            VStack(spacing: 12) {
                PrimaryButton(title: "로그인하기") { path = [.idLogin] }
                PrimaryButton(title: "비밀번호 찾기", style: .outline) { path = [.findPasswordEmail] }
            }
        }
    }
}

enum PhoneFormatter {
    static func format(_ raw: String) -> String {
        let digits = String(raw.filter(\.isNumber).prefix(11))
        switch digits.count {
        case 0...3: return digits
        case 4...7: return "\(digits.prefix(3))-\(digits.dropFirst(3))"
        default: return "\(digits.prefix(3))-\(digits.dropFirst(3).prefix(4))-\(digits.dropFirst(7))"
        }
    }
}
