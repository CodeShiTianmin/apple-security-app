import SwiftUI

struct FamilyView: View {
    @Environment(AppState.self) private var appState
    @Binding var showSettings: Bool
    @State private var selectedMember: FamilyMember?
    @State private var showInvite = false
    @State private var showChat = false
    @State private var showActivities = false

    var body: some View {
        GreenScaffold {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    Text("똑똑똑").font(KnockFont.bold(28)).foregroundStyle(.white)
                    Spacer()
                    HeaderActions(showSettings: $showSettings)
                }
                Text("나의 가족 생존 기록").font(KnockFont.medium(18)).foregroundStyle(.white)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 14) {
                        Button { showInvite = true } label: {
                            AvatarView(asset: appState.user.avatarAsset, size: 58, ring: .white)
                                .overlay(alignment: .bottomTrailing) {
                                    Image(systemName: "plus")
                                        .font(.system(size: 11, weight: .bold))
                                        .foregroundStyle(.white)
                                        .frame(width: 20, height: 20)
                                        .background(KnockColor.primaryDark, in: Circle())
                                }
                        }
                        .buttonStyle(.plain)
                        ForEach(appState.members) { m in
                            Button { selectedMember = m } label: {
                                AvatarView(asset: m.avatarAsset, size: 58, isOnline: m.isOnline, ring: .white)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
            .padding(.bottom, 20)
        } content: {
            VStack(spacing: 0) {
                if appState.members.isEmpty {
                    EmptyStateView(image: "mascot_family", title: "아직 가족이 없어요",
                                   message: "가족이나 지인을 초대하면 서로의 안전 체크인을\n확인할 수 있어요.",
                                   actionTitle: "가족 초대하기") { showInvite = true }
                        .padding(.top, 40)
                } else {
                    ForEach(appState.members) { m in
                        Button { selectedMember = m } label: {
                            FamilyMemberRow(member: m)
                        }
                        .buttonStyle(.plain)
                        Divider().padding(.horizontal, 20)
                    }
                }

                Image("mascot_family")
                    .resizable()
                    .scaledToFit()
                    .frame(height: 110)
                    .padding(.top, 24)

                HStack(spacing: 0) {
                    Button { showChat = true } label: {
                        Image(systemName: "ellipsis.message")
                            .font(.system(size: 22))
                            .frame(width: 60, height: 44)
                    }
                    Rectangle().fill(KnockColor.primary.opacity(0.3)).frame(width: 1, height: 24)
                    Button { showActivities = true } label: {
                        Image(systemName: "person.2")
                            .font(.system(size: 22))
                            .frame(width: 60, height: 44)
                    }
                }
                .foregroundStyle(KnockColor.primaryDark)
                .background(KnockColor.cardTint, in: Capsule())
                .padding(.top, 12)
            }
            .padding(.top, 8)
        }
        .sheet(item: $selectedMember) { m in FamilyMemberDetailView(member: m) }
        .sheet(isPresented: $showInvite) { InviteFamilyView() }
        .sheet(isPresented: $showChat) { FamilyChatView() }
        .sheet(isPresented: $showActivities) { FamilyActivityLogView() }
    }
}

struct FamilyMemberRow: View {
    var member: FamilyMember

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            AvatarView(asset: member.avatarAsset, size: 56, isOnline: member.isOnline, ring: KnockColor.cardTint)
            VStack(alignment: .leading, spacing: 4) {
                Text(member.name).font(KnockFont.medium(20)).foregroundStyle(KnockColor.textPrimary)
                Text(member.activityTitle).font(KnockFont.regular(14)).foregroundStyle(KnockColor.textSecondary)
                if let detail = member.activityDetail {
                    Text(detail).font(KnockFont.regular(14)).foregroundStyle(KnockColor.textMuted).lineSpacing(2)
                }
            }
            Spacer()
            if member.unreadCount > 0 {
                Text("\(member.unreadCount)")
                    .font(KnockFont.medium(13))
                    .foregroundStyle(KnockColor.dangerText)
                    .frame(width: 32, height: 32)
                    .background(KnockColor.dangerBadge, in: Circle())
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 18)
        .contentShape(Rectangle())
    }
}

// MARK: - 08 가족 구성원 상세

struct FamilyMemberDetailView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.dismiss) private var dismiss
    var member: FamilyMember
    @State private var segment: Segment = .calendar
    @State private var month = MockData.date(2026, 10, 1)

    enum Segment: Hashable { case calendar, log }

    var body: some View {
        GreenScaffold {
            VStack(spacing: 8) {
                HStack {
                    Text("똑똑똑").font(KnockFont.medium(14)).foregroundStyle(.white)
                    Spacer()
                    Button { dismiss() } label: {
                        Image(systemName: "xmark").font(.system(size: 16, weight: .semibold)).foregroundStyle(.white)
                    }
                }
                .padding(.horizontal, 20)
                AvatarView(asset: member.avatarAsset, size: 72, ring: .white)
                Text(member.name).font(KnockFont.medium(16)).foregroundStyle(.white)
                Text("최근 체크 \(member.lastCheckInMinutesAgo >= 60 ? "\(member.lastCheckInMinutesAgo / 60)시간" : "\(member.lastCheckInMinutesAgo)분") 전")
                    .font(KnockFont.regular(11)).foregroundStyle(.white.opacity(0.9))
            }
            .padding(.top, 8)
            .padding(.bottom, 16)
        } content: {
            VStack(spacing: 16) {
                SegmentedPill(items: [(Segment.calendar, "캘린더"), (Segment.log, "기록 목록")], selection: $segment)
                    .padding(.horizontal, 16)
                    .padding(.top, 16)

                if segment == .calendar {
                    SectionCard(padding: 16) {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Button { month = Calendar.current.date(byAdding: .month, value: -1, to: month)! } label: {
                                    Image(systemName: "chevron.left").font(.system(size: 12))
                                }
                                Text(month.koreanLong.replacingOccurrences(of: " 1일", with: ""))
                                    .font(KnockFont.medium(14)).foregroundStyle(KnockColor.textPrimary)
                                Button { month = Calendar.current.date(byAdding: .month, value: 1, to: month)! } label: {
                                    Image(systemName: "chevron.right").font(.system(size: 12))
                                }
                                Spacer()
                            }
                            .foregroundStyle(KnockColor.textPrimary)
                            CheckInCalendarGrid(monthStart: month, streakDays: member.streakDays)
                            Text("\(member.streakDays)일 연속 출석 중")
                                .font(KnockFont.medium(13)).foregroundStyle(KnockColor.textPrimary)
                        }
                    }
                    .padding(.horizontal, 16)
                } else {
                    VStack(spacing: 0) {
                        ForEach(appState.activities.filter { $0.memberName == member.name }) { a in
                            HStack(alignment: .top, spacing: 12) {
                                Circle().fill(KnockColor.primary).frame(width: 8, height: 8).padding(.top, 6)
                                VStack(alignment: .leading, spacing: 3) {
                                    Text(a.message).font(KnockFont.medium(14)).foregroundStyle(KnockColor.textPrimary)
                                    Text(a.date.relativeDescription).font(KnockFont.regular(12)).foregroundStyle(KnockColor.textMuted)
                                }
                                Spacer()
                            }
                            .padding(.vertical, 12)
                            Divider()
                        }
                        if appState.activities.filter({ $0.memberName == member.name }).isEmpty {
                            Text("아직 기록이 없어요").font(KnockFont.regular(13)).foregroundStyle(KnockColor.textMuted).padding(.vertical, 24)
                        }
                    }
                    .padding(16)
                    .background(.white, in: RoundedRectangle(cornerRadius: 20))
                    .knockShadow()
                    .padding(.horizontal, 16)
                }

                Text("\(member.name)님 건강 상태")
                    .font(KnockFont.medium(14)).foregroundStyle(KnockColor.textPrimary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 20)

                HStack(spacing: 10) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("나이팅게일 점수").font(KnockFont.regular(11)).foregroundStyle(KnockColor.textSecondary)
                        Text(String(format: "%.1f", member.nightingaleScore)).font(KnockFont.bold(34)).foregroundStyle(KnockColor.textPrimary)
                        Text(member.scoreNote).font(KnockFont.regular(11)).foregroundStyle(KnockColor.textSecondary)
                    }
                    .padding(16)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
                    .background(KnockColor.cardTint, in: RoundedRectangle(cornerRadius: 18))

                    VStack(spacing: 10) {
                        miniCard(title: "평균 수면 시간", value: "\(format(member.avgSleepHours))h", note: member.sleepQuality)
                        miniCard(title: "평균 심박수", value: "\(member.avgHeartRate) bpm", note: nil)
                    }
                }
                .frame(height: 150)
                .padding(.horizontal, 16)

                StressDistributionCard(title: "월별 스트레스 상태 추이", summary: MockData.monthSummary)
                    .padding(.horizontal, 16)

                Text("이번 달 스트레스 상태는 전반적으로 안정적이에요.\n총 86회 중 65%가 좋은 상태로 기록되었고, 과다 상태는 3회만 나타났어요.\n다만 주의 상태가 일부 확인되어 충분한 휴식과 수면 관리가 필요해요.")
                    .font(KnockFont.regular(12)).foregroundStyle(KnockColor.textSecondary).lineSpacing(4)
                    .padding(16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(KnockColor.cardTint3, in: RoundedRectangle(cornerRadius: 16))
                    .padding(.horizontal, 16)

                HStack(spacing: 12) {
                    Button {
                        if let url = URL(string: "tel://\(appState.emergencyContacts.first?.phone.filter(\.isNumber) ?? "")") {
                            UIApplication.shared.open(url)
                        }
                    } label: {
                        Label("전화하기", systemImage: "phone.fill")
                    }
                    .buttonStyle(.borderedProminent).tint(KnockColor.primary)
                    Button {
                        appState.chat.append(ChatMessage(senderName: "나", isMine: true, text: "\(member.name), 오늘 체크인 잊지 마세요 👋", date: .now))
                    } label: {
                        Label("안부 보내기", systemImage: "hand.wave.fill")
                    }
                    .buttonStyle(.bordered).tint(KnockColor.primaryDark)
                }
                .font(KnockFont.medium(14))
                .padding(.horizontal, 16)
            }
        }
    }

    private func miniCard(title: String, value: String, note: String?) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title).font(KnockFont.regular(10)).foregroundStyle(KnockColor.textSecondary)
            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text(value).font(KnockFont.medium(18)).foregroundStyle(KnockColor.textPrimary)
                if let note { Text(note).font(KnockFont.regular(9)).foregroundStyle(KnockColor.textMuted) }
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .background(.white, in: RoundedRectangle(cornerRadius: 14))
        .knockShadow(radius: 8, y: 2)
    }

    private func format(_ v: Double) -> String {
        v == v.rounded() ? String(Int(v)) : String(format: "%.1f", v)
    }
}

/// 체크인 캘린더 (연속 출석 표시)
struct CheckInCalendarGrid: View {
    var monthStart: Date
    var streakDays: Int
    private let symbols = ["M", "T", "W", "T", "F", "S", "S"]

    var body: some View {
        let cal = Calendar.current
        let days = cal.range(of: .day, in: .month, for: monthStart)!.count
        let leading = (cal.component(.weekday, from: monthStart) + 5) % 7
        let prevEnd = cal.component(.day, from: cal.date(byAdding: .day, value: -1, to: monthStart)!)
        let total = Int(ceil(Double(leading + days) / 7)) * 7

        VStack(spacing: 8) {
            HStack {
                ForEach(Array(symbols.enumerated()), id: \.offset) { _, s in
                    Text(s).font(KnockFont.medium(11)).foregroundStyle(KnockColor.textSecondary).frame(maxWidth: .infinity)
                }
            }
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 4), count: 7), spacing: 8) {
                ForEach(0..<total, id: \.self) { cell in
                    let dayIndex = cell - leading
                    if dayIndex < 0 {
                        cellView(prevEnd + dayIndex + 1, checked: false, muted: true)
                    } else if dayIndex < days {
                        cellView(dayIndex + 1, checked: dayIndex + 1 <= streakDays, muted: false)
                    } else {
                        cellView(dayIndex - days + 1, checked: false, muted: true)
                    }
                }
            }
        }
    }

    private func cellView(_ n: Int, checked: Bool, muted: Bool) -> some View {
        Text("\(n)")
            .font(KnockFont.medium(12))
            .foregroundStyle(muted ? KnockColor.textDisabled : KnockColor.textPrimary)
            .frame(width: 30, height: 22)
            .background { if checked { Capsule().fill(KnockColor.lime2) } }
    }
}
