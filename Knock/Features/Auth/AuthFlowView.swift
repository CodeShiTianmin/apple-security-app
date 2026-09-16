import SwiftUI
import Observation

enum AuthRoute: Hashable {
    case idLogin
    case emailSignup
    case emailVerify
    case userInfo
    case password
    case emergencyContact
    case emergencyMessage
    case signupComplete
    case findID
    case findIDPhone
    case findIDCode
    case findIDResult(String)
    case findPasswordEmail
    case findPasswordCode
    case resetPassword
    case resetPasswordDone
    case phoneLogin
    case phoneLoginCode
}

/// 회원가입 도중 입력값을 모아두는 드래프트
@Observable
final class SignupDraft {
    var email = ""
    var phone = ""
    var code = ""
    var name = ""
    var birth = ""
    var gender: UserProfile.Gender?
    var loginID = ""
    var password = ""
    var passwordConfirm = ""
    var agreedRequired = false
    var agreedMarketing = false
    var contacts: [EmergencyContact] = []
    var emergencyMessage = MockData.emergencyMessage

    var isPasswordValid: Bool {
        password.count >= 8 &&
        password.rangeOfCharacter(from: .letters) != nil &&
        password.rangeOfCharacter(from: .decimalDigits) != nil &&
        password.rangeOfCharacter(from: CharacterSet.alphanumerics.inverted) != nil
    }

    func buildProfile() -> UserProfile {
        UserProfile(name: name.isEmpty ? "회원" : name, loginID: loginID, email: email, phone: phone,
                    birthDate: birth, gender: gender, region: "광주 · 북구", avatarAsset: "avatar_me", isOnline: true)
    }
}

struct AuthFlowView: View {
    @Environment(AppState.self) private var appState
    @State private var path: [AuthRoute] = []
    @State private var draft = SignupDraft()

    var body: some View {
        NavigationStack(path: $path) {
            LoginLandingView(path: $path)
                .navigationDestination(for: AuthRoute.self) { route in
                    destination(for: route)
                        .navigationBarBackButtonHidden()
                        .toolbar {
                            ToolbarItem(placement: .topBarLeading) {
                                Button { path.removeLast() } label: {
                                    Image(systemName: "chevron.left")
                                        .font(.system(size: 18, weight: .medium))
                                        .foregroundStyle(KnockColor.textNeutral)
                                }
                            }
                        }
                }
        }
        .environment(draft)
    }

    @ViewBuilder
    private func destination(for route: AuthRoute) -> some View {
        switch route {
        case .idLogin: IDLoginView(path: $path)
        case .emailSignup: EmailSignupView(path: $path)
        case .emailVerify: EmailVerifyView(path: $path)
        case .userInfo: UserInfoView(path: $path)
        case .password: PasswordSetupView(path: $path)
        case .emergencyContact: EmergencyContactRegisterView(path: $path)
        case .emergencyMessage: EmergencyMessageEditView(mode: .signup, path: $path)
        case .signupComplete: SignupCompleteView(path: $path)
        case .findID: FindIDStartView(path: $path)
        case .findIDPhone: PhoneInputView(mode: .findID, path: $path)
        case .findIDCode: PhoneCodeView(mode: .findID, path: $path)
        case .findIDResult(let id): FindIDResultView(maskedID: id, path: $path)
        case .findPasswordEmail: EmailSignupView(path: $path, mode: .findPassword)
        case .findPasswordCode: EmailVerifyView(path: $path, mode: .findPassword)
        case .resetPassword: PasswordSetupView(path: $path, mode: .reset)
        case .resetPasswordDone: ChangeCompleteView(title: "변경 완료!", subtitle: "새 비밀번호로 로그인 해주세요", buttonTitle: "로그인하기") {
            path.removeAll()
        }
        case .phoneLogin: PhoneInputView(mode: .login, path: $path)
        case .phoneLoginCode: PhoneCodeView(mode: .login, path: $path)
        }
    }
}

/// 인증 화면 공통 레이아웃: 제목 / 부제 / 콘텐츠 / 하단 버튼
struct AuthScaffold<Content: View, Footer: View>: View {
    var title: String
    var subtitle: String? = nil
    var subtitleAccent: Bool = false
    var topSpacing: CGFloat = 80
    @ViewBuilder var content: Content
    @ViewBuilder var footer: Footer

    var body: some View {
        ZStack {
            Color.white.ignoresSafeArea()
            VStack(spacing: 0) {
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 12) {
                        Text(title)
                            .font(KnockFont.authTitle)
                            .foregroundStyle(KnockColor.textNeutral)
                            .multilineTextAlignment(.center)
                        if let subtitle {
                            Text(subtitle)
                                .font(KnockFont.medium(15))
                                .foregroundStyle(subtitleAccent ? KnockColor.lime : KnockColor.textGray)
                                .multilineTextAlignment(.center)
                        }
                        content
                            .padding(.top, 36)
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, topSpacing)
                }
                footer
                    .padding(.horizontal, 24)
                    .padding(.bottom, 12)
            }
        }
        .hideKeyboardOnTap()
    }
}

/// 변경 완료 / 회원가입 완료 등 결과 화면
struct ChangeCompleteView: View {
    var title: String
    var subtitle: String
    var buttonTitle: String
    var action: () -> Void

    var body: some View {
        AuthScaffold(title: title, subtitle: subtitle, topSpacing: 100) {
            ZStack {
                Circle().stroke(KnockColor.lime, lineWidth: 4).frame(width: 220, height: 220)
                Image(systemName: "checkmark")
                    .font(.system(size: 64, weight: .medium))
                    .foregroundStyle(KnockColor.lime)
            }
            .padding(.top, 20)
        } footer: {
            PrimaryButton(title: buttonTitle, action: action)
        }
        .navigationBarBackButtonHidden()
    }
}
