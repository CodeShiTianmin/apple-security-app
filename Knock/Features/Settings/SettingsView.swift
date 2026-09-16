import SwiftUI

enum SettingsRoute: Hashable {
    case editProfile
    case accountMenu
    case changeIDVerify
    case changeIDNew
    case changeIDDone
    case changePassword
    case changePasswordDone
    case withdrawReason
    case withdrawNotice
    case checkInSettings
    case emergencyContacts
    case emergencyMessage
    case notificationSettings
    case permissions
    case about
}

/// 나의 정보관리 (설정 루트)
struct SettingsView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.dismiss) private var dismiss
    @State private var path: [SettingsRoute] = []
    @State private var showLogoutConfirm = false
    @State private var showNotifications = false

    var body: some View {
        NavigationStack(path: $path) {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    Text("나의 정보관리")
                        .font(KnockFont.semibold(24))
                        .foregroundStyle(KnockColor.textNeutral)
                        .padding(.top, 20)
                        .padding(.bottom, 12)

                    HStack(spacing: 14) {
                        AvatarView(asset: appState.user.avatarAsset, size: 56, ring: KnockColor.cardTint)
                        VStack(alignment: .leading, spacing: 3) {
                            Text("\(appState.user.name)님").font(KnockFont.medium(18)).foregroundStyle(KnockColor.textPrimary)
                            Text(appState.user.email).font(KnockFont.regular(13)).foregroundStyle(KnockColor.textSecondary)
                        }
                        Spacer()
                    }
                    .padding(16)
                    .background(KnockColor.cardTint3, in: RoundedRectangle(cornerRadius: 18))
                    .padding(.bottom, 8)

                    Divider()
                    group {
                        NavigationLink(value: SettingsRoute.editProfile) { SettingsRow(title: "개인정보 수정") }
                        Divider()
                        NavigationLink(value: SettingsRoute.accountMenu) { SettingsRow(title: "아이디/비밀번호 변경") }
                        Divider()
                        NavigationLink(value: SettingsRoute.withdrawReason) { SettingsRow(title: "회원탈퇴") }
                    }
                    Divider()

                    sectionTitle("안전 체크인")
                    Divider()
                    group {
                        NavigationLink(value: SettingsRoute.checkInSettings) {
                            SettingsRow(title: "체크인 시간 설정", value: String(format: "%02d:%02d", appState.settings.deadlineHour, appState.settings.deadlineMinute))
                        }
                        Divider()
                        NavigationLink(value: SettingsRoute.emergencyContacts) {
                            SettingsRow(title: "비상 연락처 관리", value: "\(appState.emergencyContacts.count)명")
                        }
                        Divider()
                        NavigationLink(value: SettingsRoute.emergencyMessage) { SettingsRow(title: "비상 연락문자 편집") }
                        Divider()
                        NavigationLink(value: SettingsRoute.notificationSettings) { SettingsRow(title: "알림 설정") }
                        Divider()
                        Button { showNotifications = true } label: {
                            SettingsRow(title: "받은 알림", value: appState.unreadNotifications > 0 ? "\(appState.unreadNotifications)개 안 읽음" : nil)
                        }
                    }
                    Divider()

                    sectionTitle("앱 정보")
                    Divider()
                    group {
                        NavigationLink(value: SettingsRoute.permissions) { SettingsRow(title: "권한 안내") }
                        Divider()
                        NavigationLink(value: SettingsRoute.about) { SettingsRow(title: "앱 정보", value: "v1.0.0") }
                        Divider()
                        Button { showLogoutConfirm = true } label: {
                            SettingsRow(title: "로그아웃", showChevron: false, titleColor: KnockColor.dangerText)
                        }
                    }
                    Divider()
                }
                .padding(.horizontal, 24)
            }
            .background(Color.white)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) { Button("닫기") { dismiss() } }
            }
            .sheet(isPresented: $showNotifications) { NotificationsView() }
            .navigationDestination(for: SettingsRoute.self) { route in
                destination(route)
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
            .confirmationDialog("로그아웃 하시겠어요?", isPresented: $showLogoutConfirm, titleVisibility: .visible) {
                Button("로그아웃", role: .destructive) {
                    dismiss()
                    appState.logout()
                }
                Button("취소", role: .cancel) {}
            }
        }
    }

    private func group<Content: View>(@ViewBuilder _ content: () -> Content) -> some View {
        VStack(spacing: 0) { content() }.buttonStyle(.plain)
    }

    private func sectionTitle(_ text: String) -> some View {
        Text(text)
            .font(KnockFont.semibold(14))
            .foregroundStyle(KnockColor.textMuted)
            .padding(.top, 28)
            .padding(.bottom, 8)
    }

    @ViewBuilder
    private func destination(_ route: SettingsRoute) -> some View {
        switch route {
        case .editProfile: EditProfileView(path: $path)
        case .accountMenu: AccountMenuView(path: $path)
        case .changeIDVerify: ChangeIDVerifyView(path: $path)
        case .changeIDNew: ChangeIDNewView(path: $path)
        case .changeIDDone:
            ChangeCompleteView(title: "변경 완료!", subtitle: "새 아이디로 로그인 해주세요", buttonTitle: "로그인하기") {
                dismiss()
                appState.logout()
            }
        case .changePassword: ChangePasswordView(path: $path)
        case .changePasswordDone:
            ChangeCompleteView(title: "변경 완료!", subtitle: "새 비밀번호로 로그인 해주세요", buttonTitle: "로그인하기") {
                dismiss()
                appState.logout()
            }
        case .withdrawReason: WithdrawReasonView(path: $path)
        case .withdrawNotice: WithdrawNoticeView(path: $path) { dismiss() }
        case .checkInSettings: CheckInSettingsView()
        case .emergencyContacts: EmergencyContactsManageView()
        case .emergencyMessage:
            EmergencyMessageEditView(mode: .settings, path: .constant([]))
                .environment(SignupDraft())
        case .notificationSettings: NotificationSettingsView()
        case .permissions: PermissionsView()
        case .about: AboutView()
        }
    }
}

// MARK: - 개인정보 수정 (보충 화면)

struct EditProfileView: View {
    @Environment(AppState.self) private var appState
    @Binding var path: [SettingsRoute]
    @State private var name = ""
    @State private var birth = ""
    @State private var gender: UserProfile.Gender?
    @State private var region = ""
    @State private var phone = ""

    var body: some View {
        AuthScaffold(title: "개인정보 수정", subtitle: "변경할 정보를 입력해 주세요", topSpacing: 24) {
            VStack(alignment: .leading, spacing: 10) {
                FieldLabel(text: "이름")
                KnockTextField(placeholder: "이름 입력", text: $name)
                FieldLabel(text: "생년월일").padding(.top, 16)
                KnockTextField(placeholder: "YYYY . MM . DD", text: $birth, keyboard: .numberPad)
                    .onChange(of: birth) { _, new in birth = BirthFormatter.format(new) }
                FieldLabel(text: "성별").padding(.top, 16)
                HStack(spacing: 14) {
                    ForEach(UserProfile.Gender.allCases, id: \.self) { g in
                        ChoiceChip(title: g.rawValue, selected: gender == g) { gender = g }
                    }
                }
                FieldLabel(text: "전화번호").padding(.top, 16)
                KnockTextField(placeholder: "전화번호 입력", text: $phone, keyboard: .phonePad)
                    .onChange(of: phone) { _, new in phone = PhoneFormatter.format(new) }
                FieldLabel(text: "지역").padding(.top, 16)
                KnockTextField(placeholder: "예: 광주 · 북구", text: $region)
            }
        } footer: {
            PrimaryButton(title: "저장", isEnabled: !name.isEmpty) {
                appState.user.name = name
                appState.user.birthDate = birth
                appState.user.gender = gender
                appState.user.region = region
                appState.user.phone = phone
                appState.saveProfile()
                path.removeLast()
            }
        }
        .onAppear {
            name = appState.user.name
            birth = appState.user.birthDate
            gender = appState.user.gender
            region = appState.user.region
            phone = appState.user.phone
        }
    }
}

// MARK: - 아이디 / 비밀번호 변경

struct AccountMenuView: View {
    @Environment(AppState.self) private var appState
    @Binding var path: [SettingsRoute]

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("아이디/비밀번호 변경")
                .font(KnockFont.semibold(24)).foregroundStyle(KnockColor.textNeutral)
                .padding(.top, 20).padding(.bottom, 12)
            Divider()
            NavigationLink(value: SettingsRoute.changeIDVerify) { SettingsRow(title: "아이디 수정하기", value: appState.user.loginID) }
            Divider()
            NavigationLink(value: SettingsRoute.changePassword) { SettingsRow(title: "비밀번호 변경") }
            Divider()
            Spacer()
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 24)
        .background(Color.white)
    }
}

/// 아이디 수정하기 — 현재 아이디/비밀번호 확인
struct ChangeIDVerifyView: View {
    @Environment(AppState.self) private var appState
    @Binding var path: [SettingsRoute]
    @State private var id = ""
    @State private var password = ""
    @State private var confirm = ""
    @State private var loading = false
    @State private var error: String?

    var body: some View {
        AuthScaffold(title: "아이디 수정하기", subtitle: "현재 아이디와 비밀번호를 입력해주세요", subtitleAccent: true) {
            VStack(spacing: 14) {
                KnockTextField(placeholder: "아이디 입력", text: $id, accent: true).padding(.bottom, 26)
                KnockSecureField(placeholder: "비밀번호 입력", text: $password, accent: true)
                KnockSecureField(placeholder: "비밀번호 확인", text: $confirm, accent: true)
                Text("* 영문,숫자,특수문자 포함 8자 이상")
                    .font(KnockFont.regular(12)).foregroundStyle(KnockColor.lime)
                    .frame(maxWidth: .infinity, alignment: .leading).padding(.horizontal, 20)
                if let error { Text(error).font(KnockFont.regular(12)).foregroundStyle(KnockColor.warning) }
            }
        } footer: {
            PrimaryButton(title: "다음", isEnabled: !id.isEmpty && password.count >= 4 && password == confirm, isLoading: loading) {
                loading = true
                error = nil
                Task {
                    defer { loading = false }
                    do {
                        _ = try await appState.auth.login(id: id, password: password)
                        path.append(.changeIDNew)
                    } catch { self.error = error.localizedDescription }
                }
            }
        }
    }
}

/// 새 아이디를 입력해주세요
struct ChangeIDNewView: View {
    @Environment(AppState.self) private var appState
    @Binding var path: [SettingsRoute]
    @State private var newID = ""
    @State private var loading = false
    @State private var availability: Availability = .unknown

    enum Availability { case unknown, checking, available, taken }

    var body: some View {
        AuthScaffold(title: "새 아이디를 입력해주세요") {
            VStack(alignment: .trailing, spacing: 8) {
                KnockTextField(placeholder: "아이디 입력", text: $newID, accent: true)
                HStack(spacing: 4) {
                    switch availability {
                    case .unknown: EmptyView()
                    case .checking: ProgressView().controlSize(.mini)
                    case .available:
                        Text("사용 가능").foregroundStyle(KnockColor.textGray)
                        Image(systemName: "checkmark").foregroundStyle(KnockColor.stressHigh)
                    case .taken:
                        Text("이미 사용 중인 아이디").foregroundStyle(KnockColor.warning)
                    }
                }
                .font(KnockFont.regular(12))
                .padding(.trailing, 12)
                .frame(height: 16)
            }
            .onChange(of: newID) { _, _ in availability = .unknown }
        } footer: {
            PrimaryButton(title: "다음", isEnabled: newID.count >= 4, isLoading: loading) {
                loading = true
                availability = .checking
                Task {
                    defer { loading = false }
                    do {
                        try await appState.auth.changeID(to: newID)
                        availability = .available
                        appState.user.loginID = newID
                        appState.saveProfile()
                        path.append(.changeIDDone)
                    } catch { availability = .taken }
                }
            }
        }
    }
}

/// [보충 화면] 비밀번호 변경
struct ChangePasswordView: View {
    @Environment(AppState.self) private var appState
    @Binding var path: [SettingsRoute]
    @State private var current = ""
    @State private var new = ""
    @State private var confirm = ""
    @State private var loading = false

    private var valid: Bool {
        new.count >= 8 && new == confirm && !current.isEmpty &&
        new.rangeOfCharacter(from: .letters) != nil && new.rangeOfCharacter(from: .decimalDigits) != nil
    }

    var body: some View {
        AuthScaffold(title: "비밀번호 변경", subtitle: "현재 비밀번호와 새 비밀번호를 입력해주세요") {
            VStack(spacing: 14) {
                KnockSecureField(placeholder: "현재 비밀번호", text: $current).padding(.bottom, 20)
                KnockSecureField(placeholder: "새 비밀번호 입력", text: $new)
                KnockSecureField(placeholder: "새 비밀번호 확인", text: $confirm)
                Text("* 영문,숫자,특수문자 포함 8자 이상")
                    .font(KnockFont.regular(12)).foregroundStyle(KnockColor.textGray)
                    .frame(maxWidth: .infinity, alignment: .leading).padding(.horizontal, 20)
            }
        } footer: {
            PrimaryButton(title: "변경하기", isEnabled: valid, isLoading: loading) {
                loading = true
                Task {
                    defer { loading = false }
                    try? await appState.auth.changePassword(current: current, new: new)
                    path.append(.changePasswordDone)
                }
            }
        }
    }
}

// MARK: - 회원 탈퇴

struct WithdrawReasonView: View {
    @Environment(AppState.self) private var appState
    @Binding var path: [SettingsRoute]
    @State private var selected: Set<WithdrawReason> = []
    @State private var other = ""

    var body: some View {
        ZStack {
            Color.white.ignoresSafeArea()
            VStack(alignment: .leading, spacing: 0) {
                Text("똑똑똑을 탈퇴하시나요?\n탈퇴하시는 이유를 알려주세요.")
                    .font(KnockFont.semibold(20))
                    .foregroundStyle(KnockColor.textNeutral)
                    .lineSpacing(4)
                    .padding(.top, 60)
                    .padding(.bottom, 40)

                ForEach(WithdrawReason.allCases) { reason in
                    Button {
                        withAnimation { if selected.contains(reason) { selected.remove(reason) } else { selected.insert(reason) } }
                    } label: {
                        HStack {
                            Text(reason.rawValue).font(KnockFont.medium(15)).foregroundStyle(KnockColor.textGray)
                            Spacer()
                            CheckCircle(checked: selected.contains(reason), size: 20)
                        }
                        .padding(.vertical, 14)
                    }
                    .buttonStyle(.plain)
                }

                TextField("기타 의견을 남겨주세요 (선택)", text: $other)
                    .font(KnockFont.regular(14))
                    .padding(.horizontal, 16).frame(height: 48)
                    .background(KnockColor.sheet, in: RoundedRectangle(cornerRadius: 14))
                    .padding(.top, 12)

                Spacer()

                HStack(spacing: 16) {
                    PrimaryButton(title: "돌아가기", style: .outline) { path.removeLast() }
                    PrimaryButton(title: "다음", isEnabled: !selected.isEmpty || !other.isEmpty) { path.append(.withdrawNotice) }
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 12)
        }
        .hideKeyboardOnTap()
    }
}

struct WithdrawNoticeView: View {
    @Environment(AppState.self) private var appState
    @Binding var path: [SettingsRoute]
    var onWithdrawn: () -> Void
    @State private var confirmed = false
    @State private var loading = false
    @State private var showFinal = false

    var body: some View {
        ZStack {
            Color.white.ignoresSafeArea()
            VStack(alignment: .leading, spacing: 0) {
                Text("유의사항을 확인해 주세요.")
                    .font(KnockFont.semibold(20)).foregroundStyle(KnockColor.textNeutral)
                    .padding(.top, 60).padding(.bottom, 16)

                VStack(alignment: .leading, spacing: 14) {
                    (Text("탈퇴 시작부터 ") + Text("30일동안 똑똑똑 재가입이 불가").foregroundColor(KnockColor.warning) + Text("하며,\n탈퇴는 철회할 수 없습니다."))
                    (Text("탈퇴 시 계정 정보, 혜택, 충전 내역 등 모든 정보가 삭제").foregroundColor(KnockColor.warning) + Text("되며\n복구할 수 없습니다."))
                }
                .font(KnockFont.regular(13))
                .foregroundStyle(KnockColor.textGray)
                .lineSpacing(4)
                .padding(20)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(KnockColor.stroke.opacity(0.6), in: RoundedRectangle(cornerRadius: 24))

                Button { withAnimation { confirmed.toggle() } } label: {
                    HStack(spacing: 8) {
                        CheckCircle(checked: confirmed, size: 20)
                        Text("유의사항을 모두 확인했어요.").font(KnockFont.medium(15)).foregroundStyle(KnockColor.textNeutral)
                    }
                }
                .buttonStyle(.plain)
                .padding(.top, 20)

                Spacer()

                HStack(spacing: 16) {
                    PrimaryButton(title: "돌아가기", style: .outline) { path.removeLast() }
                    PrimaryButton(title: "탈퇴하기", isEnabled: confirmed, isLoading: loading) { showFinal = true }
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 12)
        }
        .alert("정말 탈퇴하시겠어요?", isPresented: $showFinal) {
            Button("탈퇴", role: .destructive) {
                loading = true
                Task {
                    defer { loading = false }
                    try? await appState.auth.withdraw(reasons: [])
                    onWithdrawn()
                    appState.withdraw()
                }
            }
            Button("취소", role: .cancel) {}
        } message: {
            Text("모든 데이터가 삭제되며 복구할 수 없습니다.")
        }
    }
}
