import SwiftUI

/// [보충 화면] 가족 초대
struct InviteFamilyView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.dismiss) private var dismiss
    @State private var code = ""
    @State private var joined = false
    private let myCode = "KNOCK-7F2A"

    var body: some View {
        NavigationStack {
            ZStack {
                KnockColor.background.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 24) {
                        Image("mascot_family").resizable().scaledToFit().frame(height: 120).padding(.top, 20)

                        VStack(spacing: 10) {
                            Text("내 초대 코드").font(KnockFont.medium(14)).foregroundStyle(KnockColor.textSecondary)
                            Text(myCode).font(KnockFont.bold(30)).foregroundStyle(KnockColor.textPrimary).tracking(2)
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
                            KnockTextField(placeholder: "코드 입력 (예: KNOCK-1234)", text: $code)
                            PrimaryButton(title: joined ? "참여 완료" : "참여하기", isEnabled: code.count >= 6 && !joined, style: .filled) {
                                withAnimation {
                                    joined = true
                                    appState.members.append(FamilyMember(
                                        name: "새 가족", relation: "지인", avatarAsset: "avatar_mother", isOnline: true,
                                        lastCheckInMinutesAgo: 5, unreadCount: 0, activityTitle: "현재 활동 중",
                                        activityDetail: "방금 가족에 참여했어요", streakDays: 1, nightingaleScore: 85.0,
                                        scoreNote: "오늘은 정상 범위", avgSleepHours: 7, sleepQuality: "수면 질량:중",
                                        avgHeartRate: 72, latitude: 35.173, longitude: 126.915))
                                }
                            }
                        }
                    }
                    .padding(20)
                }
            }
            .navigationTitle("가족 초대")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .topBarTrailing) { Button("닫기") { dismiss() } } }
        }
    }
}

/// [보충 화면] 가족 채팅
struct FamilyChatView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.dismiss) private var dismiss
    @State private var text = ""

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
                            }
                        }
                        .padding(16)
                    }
                    .background(KnockColor.background)
                    .onChange(of: appState.chat.count) { _, _ in
                        if let last = appState.chat.last { withAnimation { proxy.scrollTo(last.id) } }
                    }
                }
                HStack(spacing: 10) {
                    TextField("메시지 입력", text: $text)
                        .font(KnockFont.regular(15))
                        .padding(.horizontal, 16).frame(height: 44)
                        .background(KnockColor.sheet, in: Capsule())
                    Button {
                        guard !text.trimmingCharacters(in: .whitespaces).isEmpty else { return }
                        appState.chat.append(ChatMessage(senderName: "나", isMine: true, text: text, date: .now))
                        text = ""
                    } label: {
                        Image(systemName: "arrow.up")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(.white)
                            .frame(width: 44, height: 44)
                            .background(KnockColor.primary, in: Circle())
                    }
                }
                .padding(12)
                .background(.white)
            }
            .navigationTitle("가족 채팅")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .topBarTrailing) { Button("닫기") { dismiss() } } }
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

/// [보충 화면] 알림 센터
struct NotificationsView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Group {
                if appState.notifications.isEmpty {
                    EmptyStateView(title: "알림이 없어요", message: "새로운 알림이 오면 여기에서 확인할 수 있어요.")
                } else {
                    List {
                        ForEach(appState.notifications) { n in
                            HStack(alignment: .top, spacing: 12) {
                                Image(systemName: icon(for: n.kind))
                                    .font(.system(size: 18))
                                    .foregroundStyle(n.kind == .danger ? KnockColor.danger : KnockColor.primary)
                                    .frame(width: 36, height: 36)
                                    .background(n.kind == .danger ? KnockColor.dangerSoft : KnockColor.cardTint, in: Circle())
                                VStack(alignment: .leading, spacing: 4) {
                                    HStack {
                                        Text(n.title).font(KnockFont.medium(15)).foregroundStyle(KnockColor.textPrimary)
                                        if !n.isRead { Circle().fill(KnockColor.yellow).frame(width: 7, height: 7) }
                                    }
                                    Text(n.body).font(KnockFont.regular(13)).foregroundStyle(KnockColor.textSecondary).lineSpacing(2)
                                    Text(n.date.relativeDescription).font(KnockFont.regular(11)).foregroundStyle(KnockColor.textMuted)
                                }
                            }
                            .padding(.vertical, 6)
                            .listRowBackground(KnockColor.background)
                        }
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                }
            }
            .background(KnockColor.background)
            .navigationTitle("알림 센터")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) { Button("모두 읽음") { appState.markAllRead() }.font(KnockFont.regular(14)) }
                ToolbarItem(placement: .topBarTrailing) { Button("닫기") { dismiss() } }
            }
        }
    }

    private func icon(for kind: AppNotification.Kind) -> String {
        switch kind {
        case .checkIn: return "checkmark.circle"
        case .danger: return "exclamationmark.triangle.fill"
        case .family: return "person.2"
        case .system: return "sparkles"
        }
    }
}
