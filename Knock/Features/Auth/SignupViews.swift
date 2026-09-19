import SwiftUI

enum EmailFlowMode { case signup, findPassword }

/// 이메일로 가입 / 비밀번호 찾기용 이메일 입력
struct EmailSignupView: View {
    @Environment(AppState.self) private var appState
    @Environment(SignupDraft.self) private var draft
    @Binding var path: [AuthRoute]
    var mode: EmailFlowMode = .signup
    @State private var email = ""
    @State private var loading = false

    private var isValid: Bool {
        email.contains("@") && email.contains(".") && email.count > 5
    }

    var body: some View {
        AuthScaffold(title: mode == .signup ? "이메일로 가입" : "비밀번호 찾기",
                     subtitle: mode == .signup ? "이메일 주소를 입력해주세요" : "가입한 이메일 주소를 입력해주세요") {
            VStack(spacing: 16) {
                KnockTextField(placeholder: "이메일 주소 입력", text: $email, keyboard: .emailAddress, contentType: .emailAddress)
                    .multilineTextAlignment(.center)
                PrimaryButton(title: "인증 메일 보내기", isEnabled: isValid, isLoading: loading, style: .filled) {
                    loading = true
                    Task {
                        defer { loading = false }
                        try? await appState.auth.sendEmailCode(to: email)
                        draft.email = email
                        path.append(mode == .signup ? .emailVerify : .findPasswordCode)
                    }
                }
            }
        } footer: {
            if mode == .signup {
                Button("다른 방법으로 가입하기") { path.removeAll() }
                    .font(KnockFont.medium(14))
                    .foregroundStyle(KnockColor.textGray)
                    .padding(.bottom, 12)
            }
        }
    }
}

/// 이메일 인증 코드
struct EmailVerifyView: View {
    @Environment(AppState.self) private var appState
    @Environment(SignupDraft.self) private var draft
    @Binding var path: [AuthRoute]
    var mode: EmailFlowMode = .signup
    @State private var code = ""
    @State private var seconds = 60
    @State private var loading = false
    @State private var error: String?

    var body: some View {
        AuthScaffold(title: "이메일 인증", subtitle: "이메일로 발송된 인증 코드를 입력해주세요") {
            VStack(spacing: 40) {
                CodeInputView(code: $code)
                ResendCodeLabel(seconds: seconds) {
                    seconds = 60
                    Task { try? await appState.auth.sendEmailCode(to: draft.email) }
                }
                if let error {
                    Text(error).font(KnockFont.regular(12)).foregroundStyle(KnockColor.warning)
                }
                Text("데모 인증번호: 123456")
                    .font(KnockFont.regular(11))
                    .foregroundStyle(KnockColor.textDisabled)
            }
        } footer: {
            PrimaryButton(title: "다음", isEnabled: code.count == 6, isLoading: loading) {
                loading = true
                error = nil
                Task {
                    defer { loading = false }
                    do {
                        try await appState.auth.verifyEmailCode(code)
                        draft.code = code
                        path.append(mode == .signup ? .userInfo : .resetPassword)
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

/// 사용자 정보 입력
struct UserInfoView: View {
    @Environment(SignupDraft.self) private var draft
    @Binding var path: [AuthRoute]

    var body: some View {
        @Bindable var draft = draft
        AuthScaffold(title: "사용자 정보 입력", subtitle: "기본 정보를 입력해 주세요") {
            VStack(alignment: .leading, spacing: 10) {
                FieldLabel(text: "이름")
                KnockTextField(placeholder: "이름 입력", text: $draft.name, contentType: .name)

                FieldLabel(text: "생년월일").padding(.top, 28)
                KnockTextField(placeholder: "YYYY . MM . DD", text: $draft.birth, keyboard: .numberPad)
                    .onChange(of: draft.birth) { _, new in draft.birth = BirthFormatter.format(new) }

                FieldLabel(text: "성별").padding(.top, 20)
                HStack(spacing: 14) {
                    ForEach(UserProfile.Gender.allCases, id: \.self) { g in
                        ChoiceChip(title: g.rawValue, selected: draft.gender == g) {
                            withAnimation { draft.gender = g }
                        }
                    }
                }
            }
        } footer: {
            PrimaryButton(title: "다음", isEnabled: !draft.name.isEmpty && draft.birth.count >= 10) {
                path.append(.password)
            }
        }
    }
}

enum PasswordMode { case signup, reset }

/// 비밀번호 설정 (+ 약관 동의 시트)
struct PasswordSetupView: View {
    @Environment(AppState.self) private var appState
    @Environment(SignupDraft.self) private var draft
    @Binding var path: [AuthRoute]
    var mode: PasswordMode = .signup
    @State private var showTerms = false
    @State private var loading = false

    private var canContinue: Bool {
        (mode == .reset || !draft.loginID.isEmpty) && draft.isPasswordValid && draft.password == draft.passwordConfirm
    }

    var body: some View {
        @Bindable var draft = draft
        AuthScaffold(title: mode == .signup ? "비밀번호 설정" : "새 비밀번호 설정", subtitle: "안전한 비밀번호를 설정해주세요") {
            VStack(spacing: 14) {
                if mode == .signup {
                    KnockTextField(placeholder: "아이디 입력", text: $draft.loginID, contentType: .username)
                        .padding(.bottom, 26)
                }
                KnockSecureField(placeholder: "비밀번호 입력", text: $draft.password)
                KnockSecureField(placeholder: "비밀번호 확인", text: $draft.passwordConfirm)
                HStack {
                    Text("* 영문,숫자,특수문자 포함 8자 이상")
                        .foregroundStyle(draft.password.isEmpty || draft.isPasswordValid ? KnockColor.textGray : KnockColor.warning)
                    Spacer()
                    if !draft.passwordConfirm.isEmpty {
                        Text(draft.password == draft.passwordConfirm ? "일치" : "불일치")
                            .foregroundStyle(draft.password == draft.passwordConfirm ? KnockColor.primary : KnockColor.warning)
                    }
                }
                .font(KnockFont.regular(12))
                .padding(.horizontal, 20)
            }
        } footer: {
            PrimaryButton(title: "다음", isEnabled: canContinue, isLoading: loading) {
                if mode == .signup {
                    showTerms = true
                } else {
                    loading = true
                    Task {
                        defer { loading = false }
                        try? await appState.auth.changePassword(current: "", new: draft.password)
                        path.append(.resetPasswordDone)
                    }
                }
            }
        }
        .sheet(isPresented: $showTerms) {
            TermsSheet {
                showTerms = false
                path.append(.signupComplete)
            }
            .presentationDetents([.height(400)])
            .presentationCornerRadius(28)
            .presentationDragIndicator(.hidden)
        }
    }
}

/// 약관 동의 바텀시트
struct TermsSheet: View {
    @Environment(SignupDraft.self) private var draft
    var onAgree: () -> Void

    struct Term: Identifiable {
        let id = UUID()
        let title: String
        let required: Bool
    }

    private let terms = [
        Term(title: "개인정보 수집, 이용 동의 (필수)", required: true),
        Term(title: "서비스 이용약관 (필수)", required: true),
        Term(title: "휴대폰 본인 인증 서비스 약관 동의 (필수)", required: true),
        Term(title: "이벤트 및 신규 서비스 알림 수신 동의 (선택)", required: false),
    ]
    @State private var checked: Set<UUID> = []
    @State private var detail: Term?

    private var allChecked: Bool { checked.count == terms.count }
    private var requiredChecked: Bool { terms.filter(\.required).allSatisfy { checked.contains($0.id) } }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Button {
                withAnimation {
                    if allChecked { checked.removeAll() } else { checked = Set(terms.map(\.id)) }
                }
            } label: {
                HStack(spacing: 10) {
                    CheckCircle(checked: allChecked, size: 24)
                    Text("모든 약관에 동의합니다")
                        .font(KnockFont.semibold(18))
                        .foregroundStyle(KnockColor.textNeutral)
                }
            }
            .buttonStyle(.plain)
            .padding(.top, 36)
            .padding(.bottom, 28)

            ForEach(terms) { term in
                HStack(spacing: 10) {
                    Button {
                        withAnimation {
                            if checked.contains(term.id) { checked.remove(term.id) } else { checked.insert(term.id) }
                        }
                    } label: {
                        HStack(spacing: 10) {
                            Image(systemName: "checkmark")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(checked.contains(term.id) ? KnockColor.lime : KnockColor.stroke)
                            Text(term.title)
                                .font(KnockFont.medium(15))
                                .foregroundStyle(KnockColor.textGray)
                        }
                    }
                    .buttonStyle(.plain)
                    Spacer()
                    Button { detail = term } label: {
                        Image(systemName: "chevron.right")
                            .font(.system(size: 14))
                            .foregroundStyle(KnockColor.textDisabled)
                    }
                }
                .padding(.vertical, 10)
            }

            Spacer()
            PrimaryButton(title: "다음", isEnabled: requiredChecked) {
                draft.agreedRequired = true
                draft.agreedMarketing = checked.count == terms.count
                onAgree()
            }
            .padding(.bottom, 8)
        }
        .padding(.horizontal, 24)
        .background(Color.white)
        .sheet(item: $detail) { term in
            TermDetailView(title: term.title)
        }
    }
}

/// [보충 화면] 약관 상세
struct TermDetailView: View {
    var title: String
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                Text(placeholderTerms)
                    .font(KnockFont.regular(14))
                    .foregroundStyle(KnockColor.textGray)
                    .lineSpacing(6)
                    .padding(24)
            }
            .navigationTitle(title.replacingOccurrences(of: " (필수)", with: "").replacingOccurrences(of: " (선택)", with: ""))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .topBarTrailing) { Button("닫기") { dismiss() } } }
        }
    }

    private var placeholderTerms: String {
        """
        제1조 (목적)
        본 약관은 똑똑똑(이하 "서비스")이 제공하는 안전 체크인 서비스의 이용과 관련하여 회사와 회원 간의 권리, 의무 및 책임사항을 규정함을 목적으로 합니다.

        제2조 (수집하는 개인정보)
        서비스는 회원가입, 안전 확인, 비상 연락을 위해 이름, 생년월일, 이메일, 전화번호, 비상 연락처, 위치 정보 및 건강 데이터(심박수·수면·스트레스)를 수집할 수 있습니다.

        제3조 (개인정보의 이용)
        수집한 정보는 체크인 알림 발송, 비상 상황 시 등록된 연락처로의 자동 연락, 건강 통계 제공 목적으로만 이용됩니다.

        제4조 (보관 및 파기)
        회원 탈퇴 시 관련 법령에 따라 보관이 필요한 정보를 제외하고 즉시 파기합니다.
        """
    }
}

/// 비상 연락처 등록 (로그인 직후)
struct EmergencyContactRegisterView: View {
    @Environment(AppState.self) private var appState
    @Environment(SignupDraft.self) private var draft
    @Binding var path: [AuthRoute]
    @State private var contact = ""
    @State private var relation = ""
    @State private var showRelationPicker = false

    private let relations = ["어머니", "아버지", "배우자", "형제·자매", "자녀", "친구", "지인", "기타"]

    var body: some View {
        @Bindable var draft = draft
        AuthScaffold(title: "비상 연락처 등록", subtitle: "위험 상황 시 연락할 가족의 이메일이나 전화번호를 입력해주세요", topSpacing: 40) {
            VStack(alignment: .leading, spacing: 10) {
                FieldLabel(text: "이메일 / 전화번호")
                KnockTextField(placeholder: "입력", text: $contact, keyboard: .emailAddress)

                FieldLabel(text: "관계 선택").padding(.top, 20)
                Button { showRelationPicker = true } label: {
                    HStack {
                        Text(relation.isEmpty ? "관계선택" : relation)
                            .font(KnockFont.medium(16))
                            .foregroundStyle(relation.isEmpty ? KnockColor.textMuted : KnockColor.textNeutral)
                        Spacer()
                        Image(systemName: "chevron.down").foregroundStyle(KnockColor.textMuted)
                    }
                    .padding(.horizontal, 22)
                    .frame(height: 56)
                    .background(.white, in: Capsule())
                    .overlay(Capsule().stroke(KnockColor.stroke, lineWidth: 1))
                }
                .buttonStyle(.plain)

                PrimaryButton(title: "추가", isEnabled: !contact.isEmpty && !relation.isEmpty, style: .outline) {
                    let c = EmergencyContact(name: relation, phone: contact, relation: relation, priority: draft.contacts.count + 1)
                    withAnimation { draft.contacts.append(c) }
                    contact = ""
                    relation = ""
                }
                .padding(.top, 60)

                if !draft.contacts.isEmpty {
                    VStack(spacing: 8) {
                        ForEach(draft.contacts) { c in
                            HStack {
                                Text("\(c.priority)").font(KnockFont.bold(18)).foregroundStyle(KnockColor.textPrimary)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(c.relation).font(KnockFont.medium(15)).foregroundStyle(KnockColor.textNeutral)
                                    Text(c.phone).font(KnockFont.regular(13)).foregroundStyle(KnockColor.textGray)
                                }
                                Spacer()
                                Button {
                                    withAnimation {
                                        draft.contacts.removeAll { $0.id == c.id }
                                        for i in draft.contacts.indices { draft.contacts[i].priority = i + 1 }
                                    }
                                } label: {
                                    Image(systemName: "xmark.circle.fill").foregroundStyle(KnockColor.textDisabled)
                                }
                            }
                            .padding(14)
                            .background(KnockColor.cardTint3, in: RoundedRectangle(cornerRadius: 16))
                        }
                    }
                    .padding(.top, 16)
                }
            }
        } footer: {
            VStack(spacing: 12) {
                PrimaryButton(title: "다음", isEnabled: !draft.contacts.isEmpty) {
                    path.append(.emergencyMessage)
                }
                Button("나중에 등록하기") { appState.skipEmergencySetup() }
                    .font(KnockFont.medium(14))
                    .foregroundStyle(KnockColor.textGray)
            }
        }
        .confirmationDialog("관계 선택", isPresented: $showRelationPicker, titleVisibility: .visible) {
            ForEach(relations, id: \.self) { r in Button(r) { relation = r } }
        }
    }
}

enum EmergencyMessageMode { case setup, settings }

/// 비상 연락문자 편집
struct EmergencyMessageEditView: View {
    @Environment(AppState.self) private var appState
    @Environment(SignupDraft.self) private var draft
    @Environment(\.dismiss) private var dismiss
    var mode: EmergencyMessageMode
    @Binding var path: [AuthRoute]
    @State private var text = ""
    @State private var saved = false

    var body: some View {
        AuthScaffold(title: "비상 연락문자 편집", subtitle: "전달하고싶은말을 적어주세요") {
            VStack(alignment: .leading, spacing: 10) {
                FieldLabel(text: "비상 문자")
                TextEditor(text: $text)
                    .font(KnockFont.medium(15))
                    .foregroundStyle(KnockColor.textNeutral)
                    .scrollContentBackground(.hidden)
                    .padding(14)
                    .frame(height: 150)
                    .background(.white, in: RoundedRectangle(cornerRadius: 24))
                    .overlay(RoundedRectangle(cornerRadius: 24).stroke(KnockColor.stroke, lineWidth: 1))
                    .overlay(alignment: .topLeading) {
                        if text.isEmpty {
                            Text("입력").font(KnockFont.medium(15)).foregroundStyle(KnockColor.textMuted)
                                .padding(22).allowsHitTesting(false)
                        }
                    }
                Text("\(text.count) / 120")
                    .font(KnockFont.regular(12))
                    .foregroundStyle(KnockColor.textMuted)
                    .frame(maxWidth: .infinity, alignment: .trailing)

                PrimaryButton(title: saved ? "저장됨" : "저장", style: .outline) {
                    if mode == .setup { draft.emergencyMessage = text } else {
                        appState.emergencyMessage = text
                        appState.saveEmergency()
                    }
                    withAnimation { saved = true }
                }
                .padding(.top, 60)
            }
        } footer: {
            PrimaryButton(title: "완료") {
                if mode == .setup {
                    draft.emergencyMessage = text
                    appState.completeEmergencySetup(contacts: draft.contacts, message: text)
                } else {
                    appState.emergencyMessage = text
                    appState.saveEmergency()
                    dismiss()
                }
            }
        }
        .onAppear {
            text = mode == .setup ? draft.emergencyMessage : appState.emergencyMessage
        }
        .onChange(of: text) { _, new in
            if new.count > 120 { text = String(new.prefix(120)) }
            saved = false
        }
    }
}

/// 회원가입 완료
struct SignupCompleteView: View {
    @Environment(AppState.self) private var appState
    @Environment(SignupDraft.self) private var draft
    @Binding var path: [AuthRoute]
    @State private var loading = false

    var body: some View {
        AuthScaffold(title: "", topSpacing: 140) {
            VStack(spacing: 20) {
                Image("icon_user_check").resizable().scaledToFit().frame(width: 130)
                Text("회원가입 완료 !")
                    .font(KnockFont.authTitle)
                    .foregroundStyle(KnockColor.textNeutral)
            }
        } footer: {
            PrimaryButton(title: "다음", isLoading: loading) {
                loading = true
                Task {
                    defer { loading = false }
                    let profile = draft.buildProfile()
                    let user = (try? await appState.auth.register(profile: profile, password: draft.password)) ?? profile
                    appState.completeLogin(user)
                }
            }
        }
        .navigationBarBackButtonHidden()
        .toolbar(.hidden, for: .navigationBar)
    }
}

enum BirthFormatter {
    static func format(_ raw: String) -> String {
        let digits = String(raw.filter(\.isNumber).prefix(8))
        switch digits.count {
        case 0...4: return digits
        case 5...6: return "\(digits.prefix(4)) . \(digits.dropFirst(4))"
        default: return "\(digits.prefix(4)) . \(digits.dropFirst(4).prefix(2)) . \(digits.dropFirst(6))"
        }
    }
}
