import SwiftUI

/// [보충 화면] 가족 초대
struct InviteFamilyView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.dismiss) private var dismiss
    @State private var code = ""
    @State private var joinedMember: FamilyMember?
    @State private var errorText: String?
    @State private var shakeOffset: CGFloat = 0
    @State private var copied = false
    private let myCode = "7392-1048"

    var body: some View {
        NavigationStack {
            ZStack {
                KnockColor.background.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 24) {
                        Image("mascot_family").resizable().scaledToFit().frame(height: 120).padding(.top, 20)

                        VStack(spacing: 10) {
                            Text("내 초대 코드").font(KnockFont.medium(14)).foregroundStyle(KnockColor.textSecondary)
                            Button {
                                UIPasteboard.general.string = myCode
                                withAnimation(.spring(duration: 0.3)) { copied = true }
                                Task {
                                    try? await Task.sleep(for: .seconds(1.5))
                                    withAnimation { copied = false }
                                }
                            } label: {
                                HStack(spacing: 8) {
                                    Text(myCode).font(KnockFont.bold(30)).foregroundStyle(KnockColor.textPrimary).tracking(2)
                                    Image(systemName: copied ? "checkmark.circle.fill" : "doc.on.doc")
                                        .font(.system(size: 16))
                                        .foregroundStyle(copied ? KnockColor.primary : KnockColor.textMuted)
                                        .contentTransition(.symbolEffect(.replace))
                                }
                            }
                            .buttonStyle(.plain)
                            if copied {
                                Text("복사되었어요").font(KnockFont.regular(12)).foregroundStyle(KnockColor.primary)
                                    .transition(.opacity.combined(with: .move(edge: .top)))
                            }
                            ShareLink(item: "똑똑똑에서 함께 안전 체크인해요! 초대 코드: \(myCode)") {
                                Label("초대 링크 공유", systemImage: "square.and.arrow.up")
                                    .font(KnockFont.medium(14))
                                    .foregroundStyle(.white)
                                    .padding(.horizontal, 20).padding(.vertical, 12)
                                    .background(KnockColor.primary, in: Capsule())
                            }
                        }
                        .padding(24)
                        .frame(maxWidth: .infinity)
                        .background(.white, in: RoundedRectangle(cornerRadius: 24))
                        .knockShadow()

                        VStack(alignment: .leading, spacing: 12) {
                            FieldLabel(text: "초대 코드로 참여")
                            InviteCodeDisplay(code: code)
                                .accessibilityIdentifier("invite.codeField")
                                .offset(x: shakeOffset)
                                .onChange(of: code) { _, _ in withAnimation { errorText = nil } }
                            if let errorText {
                                Label(errorText, systemImage: "exclamationmark.circle.fill")
                                    .font(KnockFont.regular(13))
                                    .foregroundStyle(KnockColor.dangerText)
                                    .transition(.opacity.combined(with: .move(edge: .top)))
                            }
                            HStack(spacing: 8) {
                                Text("데모 코드").font(KnockFont.regular(12)).foregroundStyle(KnockColor.textMuted)
                                ForEach(MockData.inviteCandidates) { candidate in
                                    Button {
                                        withAnimation { code = candidate.code.filter(\.isNumber) }
                                    } label: {
                                        Text(candidate.code)
                                            .font(KnockFont.medium(12))
                                            .foregroundStyle(KnockColor.primaryDark)
                                            .padding(.horizontal, 10).padding(.vertical, 5)
                                            .background(KnockColor.cardTint, in: Capsule())
                                    }
                                    .buttonStyle(.pressable)
                                    .accessibilityIdentifier("invite.demo.\(candidate.code)")
                                }
                            }
                            PrimaryButton(title: joinedMember == nil ? "참여하기" : "참여 완료",
                                          isEnabled: code.count >= 4 && joinedMember == nil, style: .filled) {
                                join()
                            }
                            .accessibilityIdentifier("invite.join")

                            NumberPad(
                                onDigit: { digit in
                                    guard code.count < 8 else { return }
                                    withAnimation(.spring(duration: 0.25)) { code.append(digit) }
                                },
                                onDelete: {
                                    guard !code.isEmpty else { return }
                                    withAnimation(.spring(duration: 0.25)) { code.removeLast() }
                                }
                            )
                            .disabled(joinedMember != nil)
                        }

                        if let joinedMember {
                            HStack(spacing: 14) {
                                AvatarView(asset: joinedMember.avatarAsset, size: 52, isOnline: joinedMember.isOnline, ring: KnockColor.primary)
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("\(joinedMember.name)님이 가족에 참여했어요")
                                        .font(KnockFont.medium(16)).foregroundStyle(KnockColor.textPrimary)
                                    Text("이제 서로의 안전 체크인을 확인할 수 있어요")
                                        .font(KnockFont.regular(13)).foregroundStyle(KnockColor.textSecondary)
                                }
                                Spacer()
                                Image(systemName: "checkmark.seal.fill").font(.system(size: 26)).foregroundStyle(KnockColor.primary)
                            }
                            .padding(16)
                            .background(KnockColor.cardTint2, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
                            .knockShadow()
                            .transition(.scale(scale: 0.85).combined(with: .opacity))
                        }
                    }
                    .padding(20)
                    .animation(.spring(duration: 0.45, bounce: 0.25), value: joinedMember)
                    .animation(.spring(duration: 0.3), value: errorText)
                }
            }
            .navigationTitle("가족 초대")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .topBarTrailing) { Button("닫기") { dismiss() } } }
        }
    }

    private func join() {
        if let member = appState.joinFamily(code: code) {
            errorText = nil
            joinedMember = member
            appState.showToast("\(member.name)님이 가족에 참여했어요", icon: "person.badge.plus")
            Task {
                try? await Task.sleep(for: .seconds(1.6))
                dismiss()
            }
        } else {
            errorText = "유효하지 않은 초대 코드예요. 다시 확인해 주세요."
            shake()
        }
    }

    private func shake() {
        let steps: [CGFloat] = [-12, 10, -8, 6, -3, 0]
        for (i, x) in steps.enumerated() {
            withAnimation(.easeInOut(duration: 0.06).delay(Double(i) * 0.06)) { shakeOffset = x }
        }
    }
}

/// [보충 화면] 가족 채팅
struct FamilyChatView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.dismiss) private var dismiss
    @State private var text = ""

    private var canSend: Bool { !text.trimmingCharacters(in: .whitespaces).isEmpty }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                ScrollViewReader { proxy in
                    ScrollView {
                        VStack(spacing: 12) {
                            ForEach(appState.chat) { msg in
                                HStack {
                                    if msg.isMine { Spacer(minLength: 60) }
                                    VStack(alignment: msg.isMine ? .trailing : .leading, spacing: 3) {
                                        if !msg.isMine {
                                            Text(msg.senderName).font(KnockFont.regular(11)).foregroundStyle(KnockColor.textMuted)
                                        }
                                        Text(msg.text)
                                            .font(KnockFont.regular(15))
                                            .foregroundStyle(msg.isMine ? .white : KnockColor.textPrimary)
                                            .padding(.horizontal, 14).padding(.vertical, 10)
                                            .background(msg.isMine ? KnockColor.primary : .white,
                                                        in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                                        Text(msg.date.shortTime).font(KnockFont.regular(10)).foregroundStyle(KnockColor.textMuted)
                                    }
                                    if !msg.isMine { Spacer(minLength: 60) }
                                }
                                .id(msg.id)
                                .transition(.asymmetric(
                                    insertion: .move(edge: msg.isMine ? .trailing : .leading)
                                        .combined(with: .opacity)
                                        .combined(with: .scale(scale: 0.9, anchor: msg.isMine ? .bottomTrailing : .bottomLeading)),
                                    removal: .opacity))
                            }
                            if appState.isFamilyTyping {
                                HStack {
                                    TypingBubble()
                                    Spacer(minLength: 60)
                                }
                                .id("typing")
                                .transition(.opacity.combined(with: .move(edge: .leading)))
                            }
                        }
                        .padding(16)
                        .animation(.spring(duration: 0.4, bounce: 0.2), value: appState.chat.count)
                        .animation(.easeInOut(duration: 0.25), value: appState.isFamilyTyping)
                    }
                    .background(KnockColor.background)
                    .onChange(of: appState.chat.count) { _, _ in
                        if let last = appState.chat.last { withAnimation { proxy.scrollTo(last.id) } }
                    }
                    .onChange(of: appState.isFamilyTyping) { _, typing in
                        if typing { withAnimation { proxy.scrollTo("typing") } }
                    }
                    .onAppear {
                        if let last = appState.chat.last { proxy.scrollTo(last.id) }
                    }
                }
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(quickReplies, id: \.self) { reply in
                            Button {
                                appState.sendChat(reply)
                            } label: {
                                Text(reply)
                                    .font(KnockFont.medium(13))
                                    .foregroundStyle(KnockColor.primaryDark)
                                    .padding(.horizontal, 12).padding(.vertical, 7)
                                    .background(KnockColor.cardTint, in: Capsule())
                            }
                            .buttonStyle(.pressable)
                            .accessibilityIdentifier("chat.quick.\(reply)")
                        }
                    }
                    .padding(.horizontal, 12)
                }
                .padding(.top, 10)
                .background(.white)
                HStack(spacing: 10) {
                    TextField("메시지 입력", text: $text)
                        .font(KnockFont.regular(15))
                        .padding(.horizontal, 16).frame(height: 44)
                        .background(KnockColor.sheet, in: Capsule())
                        .onSubmit { send() }
                    Button(action: send) {
                        Image(systemName: "arrow.up")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(.white)
                            .frame(width: 44, height: 44)
                            .background(canSend ? KnockColor.primary : KnockColor.textMuted, in: Circle())
                            .scaleEffect(canSend ? 1 : 0.9)
                            .animation(.spring(duration: 0.3), value: canSend)
                    }
                    .disabled(!canSend)
                }
                .padding(12)
                .background(.white)
            }
            .navigationTitle("가족 채팅")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .topBarTrailing) { Button("닫기") { dismiss() } } }
        }
    }

    private let quickReplies = ["잘 지내고 있어요 😊", "오늘 체크했어요!", "저녁에 전화할게요", "사랑해요 ❤️"]

    private func send() {
        guard canSend else { return }
        appState.sendChat(text)
        text = ""
    }
}

/// 상대가 입력 중임을 나타내는 말풍선
struct TypingBubble: View {
    @State private var phase = 0

    var body: some View {
        HStack(spacing: 5) {
            ForEach(0..<3, id: \.self) { i in
                Circle()
                    .fill(KnockColor.textMuted)
                    .frame(width: 7, height: 7)
                    .offset(y: phase == i ? -4 : 0)
                    .opacity(phase == i ? 1 : 0.5)
            }
        }
        .padding(.horizontal, 14).padding(.vertical, 12)
        .background(.white, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .task {
            while !Task.isCancelled {
                try? await Task.sleep(for: .milliseconds(260))
                withAnimation(.easeInOut(duration: 0.25)) { phase = (phase + 1) % 3 }
            }
        }
    }
}

/// [보충 화면] 가족 활동 기록
struct FamilyActivityLogView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                ForEach(appState.activities.sorted { $0.date > $1.date }) { a in
                    HStack(spacing: 12) {
                        let member = appState.members.first { $0.name == a.memberName }
                        AvatarView(asset: member?.avatarAsset ?? "avatar_me", size: 40)
                        VStack(alignment: .leading, spacing: 3) {
                            Text("\(a.memberName)님").font(KnockFont.medium(14)).foregroundStyle(KnockColor.textPrimary)
                            Text(a.message).font(KnockFont.regular(13)).foregroundStyle(KnockColor.textSecondary)
                        }
                        Spacer()
                        Text(a.date.relativeDescription).font(KnockFont.regular(11)).foregroundStyle(KnockColor.textMuted)
                    }
                    .listRowBackground(KnockColor.background)
                }
            }
            .listStyle(.plain)
            .background(KnockColor.background)
            .scrollContentBackground(.hidden)
            .navigationTitle("가족 활동")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .topBarTrailing) { Button("닫기") { dismiss() } } }
        }
    }
}

/// 초대 코드 8자리를 `0000-0000` 슬롯으로 보여주는 표시부
struct InviteCodeDisplay: View {
    var code: String

    var body: some View {
        HStack(spacing: 6) {
            ForEach(0..<8, id: \.self) { index in
                if index == 4 {
                    Text("-").font(KnockFont.bold(22)).foregroundStyle(KnockColor.textMuted)
                }
                let digit = index < code.count ? String(code[code.index(code.startIndex, offsetBy: index)]) : ""
                Text(digit.isEmpty ? " " : digit)
                    .font(KnockFont.bold(22))
                    .foregroundStyle(KnockColor.textPrimary)
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .background(.white, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .overlay {
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .stroke(index == code.count ? KnockColor.primary : KnockColor.stroke,
                                    lineWidth: index == code.count ? 2 : 1)
                    }
                    .contentTransition(.numericText())
                    .scaleEffect(index == code.count - 1 ? 1.05 : 1)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityValue(code)
    }
}

/// 시스템 키보드 대신 쓰는 숫자 전용 키패드
struct NumberPad: View {
    var onDigit: (String) -> Void
    var onDelete: () -> Void

    private let rows: [[String]] = [["1", "2", "3"], ["4", "5", "6"], ["7", "8", "9"], ["", "0", "⌫"]]

    var body: some View {
        VStack(spacing: 10) {
            ForEach(rows, id: \.self) { row in
                HStack(spacing: 10) {
                    ForEach(row, id: \.self) { key in
                        if key.isEmpty {
                            Color.clear.frame(height: 50)
                        } else {
                            Button {
                                if key == "⌫" { onDelete() } else { onDigit(key) }
                            } label: {
                                Group {
                                    if key == "⌫" {
                                        Image(systemName: "delete.left").font(.system(size: 20, weight: .medium))
                                    } else {
                                        Text(key).font(KnockFont.medium(22))
                                    }
                                }
                                .foregroundStyle(KnockColor.textPrimary)
                                .frame(maxWidth: .infinity)
                                .frame(height: 50)
                                .background(key == "⌫" ? KnockColor.cardTint3 : .white,
                                            in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                                .knockShadow(radius: 6, y: 2)
                            }
                            .buttonStyle(.pressable)
                            .accessibilityIdentifier(key == "⌫" ? "pad.delete" : "pad.\(key)")
                        }
                    }
                }
            }
        }
        .padding(.top, 4)
    }
}
