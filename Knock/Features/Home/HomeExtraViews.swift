import SwiftUI

// MARK: - 오늘 기분 선택 (체크인)

/// 체크인 시 오늘 기분을 함께 기록하는 시트
struct MoodPickerSheet: View {
    var onConfirm: (Mood) -> Void
    @State private var selected: Mood?
    @State private var appeared = false

    var body: some View {
        VStack(spacing: 20) {
            VStack(spacing: 6) {
                Text("오늘 기분은 어떠세요?")
                    .font(KnockFont.bold(22))
                    .foregroundStyle(KnockColor.textPrimary)
                Text("체크인과 함께 가족에게 오늘 기분을 알려드려요")
                    .font(KnockFont.regular(13))
                    .foregroundStyle(KnockColor.textSecondary)
            }
            .padding(.top, 28)

            HStack(spacing: 12) {
                ForEach(Array(Mood.allCases.enumerated()), id: \.element.id) { i, mood in
                    let isSelected = selected == mood
                    Button {
                        withAnimation(.spring(duration: 0.35, bounce: 0.4)) { selected = mood }
                    } label: {
                        VStack(spacing: 8) {
                            Text(mood.emoji)
                                .font(.system(size: 34))
                                .scaleEffect(isSelected ? 1.25 : 1)
                            Text(mood.rawValue)
                                .font(KnockFont.medium(12))
                                .foregroundStyle(isSelected ? .white : KnockColor.textPrimary)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 96)
                        .background(isSelected ? KnockColor.primary : .white,
                                    in: RoundedRectangle(cornerRadius: 20, style: .continuous))
                        .overlay {
                            RoundedRectangle(cornerRadius: 20, style: .continuous)
                                .stroke(isSelected ? KnockColor.primary : KnockColor.cardTint, lineWidth: 1.5)
                        }
                        .knockShadow(radius: isSelected ? 14 : 6, y: isSelected ? 6 : 2)
                    }
                    .buttonStyle(.pressable)
                    .accessibilityIdentifier("mood.\(mood.rawValue)")
                    .offset(y: appeared ? 0 : 40)
                    .opacity(appeared ? 1 : 0)
                    .animation(.spring(duration: 0.5, bounce: 0.3).delay(Double(i) * 0.06), value: appeared)
                }
            }
            .padding(.horizontal, 20)

            PrimaryButton(title: selected == nil ? "기분을 선택해 주세요" : "오늘 체크 완료",
                          isEnabled: selected != nil, style: .filled) {
                if let selected { onConfirm(selected) }
            }
            .accessibilityIdentifier("mood.confirm")
            .padding(.horizontal, 20)

            Spacer(minLength: 0)
        }
        .onAppear { appeared = true }
    }
}

// MARK: - 나의 체크인 캘린더

/// 월 단위 체크인 기록 화면 (연속 출석·이번 달 달성률)
struct MyCheckInCalendarView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.dismiss) private var dismiss
    @State private var monthStart = MockData.calendar.date(
        from: MockData.calendar.dateComponents([.year, .month], from: .now))!
    @State private var progress: CGFloat = 0
    @State private var selectedDay: Date?

    private let cal = MockData.calendar
    private let weekdays = ["월", "화", "수", "목", "금", "토", "일"]

    private var checked: Set<Date> {
        var set = MockData.checkedInDays(streak: appState.streakDays)
        if appState.isCheckedInToday { set.insert(cal.startOfDay(for: .now)) }
        return set
    }

    private var daysInMonth: [Date] {
        let count = cal.range(of: .day, in: .month, for: monthStart)!.count
        return (0..<count).map { cal.date(byAdding: .day, value: $0, to: monthStart)! }
    }

    private var monthRate: Double {
        let today = cal.startOfDay(for: .now)
        let elapsed = daysInMonth.filter { $0 <= today }
        guard !elapsed.isEmpty else { return 0 }
        let done = elapsed.filter { checked.contains($0) }.count
        return Double(done) / Double(elapsed.count)
    }

    private var leadingBlanks: Int {
        let weekday = cal.component(.weekday, from: monthStart) // 1 = 일요일
        return (weekday + 5) % 7
    }

    private var monthTitle: String {
        let c = cal.dateComponents([.year, .month], from: monthStart)
        return "\(c.year!)년 \(c.month!)월"
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    summaryCard
                    calendarCard
                    if let selectedDay { dayDetail(selectedDay) }
                }
                .padding(20)
            }
            .background(KnockColor.background)
            .navigationTitle("나의 체크인 캘린더")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .topBarTrailing) { Button("닫기") { dismiss() } } }
            .onAppear { withAnimation(.easeOut(duration: 1.0).delay(0.15)) { progress = monthRate } }
            .onChange(of: monthStart) { _, _ in
                progress = 0
                withAnimation(.easeOut(duration: 0.8)) { progress = monthRate }
            }
        }
    }

    private var summaryCard: some View {
        SectionCard(background: KnockColor.primary) {
            HStack(spacing: 16) {
                ZStack {
                    Circle().stroke(Color.white.opacity(0.25), lineWidth: 10)
                    Circle()
                        .trim(from: 0, to: progress)
                        .stroke(KnockColor.yellow, style: StrokeStyle(lineWidth: 10, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                    VStack(spacing: 0) {
                        Text("\(Int(progress * 100))%")
                            .font(KnockFont.bold(20))
                            .foregroundStyle(.white)
                            .contentTransition(.numericText())
                        Text("이번 달")
                            .font(KnockFont.regular(11))
                            .foregroundStyle(.white.opacity(0.85))
                    }
                }
                .frame(width: 96, height: 96)

                VStack(alignment: .leading, spacing: 10) {
                    HStack(spacing: 6) {
                        Image(systemName: "flame.fill").foregroundStyle(KnockColor.yellow)
                        Text("\(appState.streakDays)일 연속 출석 중")
                            .font(KnockFont.bold(18))
                            .foregroundStyle(.white)
                    }
                    Text(appState.isCheckedInToday ? "오늘 체크인을 완료했어요 👍" : "오늘 체크인이 아직 남아 있어요")
                        .font(KnockFont.regular(13))
                        .foregroundStyle(.white.opacity(0.9))
                    if let mood = appState.todayMood {
                        PillBadge(text: "\(mood.emoji) \(mood.rawValue)", foreground: KnockColor.textPrimary, background: KnockColor.yellow)
                    }
                }
                Spacer(minLength: 0)
            }
        }
    }

    private var calendarCard: some View {
        SectionCard {
            VStack(spacing: 12) {
                DateNavigator(title: monthTitle) {
                    withAnimation(.spring(duration: 0.4)) { monthStart = cal.date(byAdding: .month, value: -1, to: monthStart)! }
                } onNext: {
                    withAnimation(.spring(duration: 0.4)) { monthStart = cal.date(byAdding: .month, value: 1, to: monthStart)! }
                }
                .padding(.horizontal, -24)

                HStack(spacing: 0) {
                    ForEach(weekdays, id: \.self) { d in
                        Text(d).font(KnockFont.medium(12)).foregroundStyle(KnockColor.textSecondary)
                            .frame(maxWidth: .infinity)
                    }
                }

                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 6), count: 7), spacing: 8) {
                    ForEach(0..<leadingBlanks, id: \.self) { _ in Color.clear.frame(height: 36) }
                    ForEach(Array(daysInMonth.enumerated()), id: \.element) { i, day in
                        dayCell(day, index: i)
                    }
                }
                .id(monthStart)
                .transition(.opacity.combined(with: .scale(scale: 0.97)))
            }
        }
    }

    private func dayCell(_ day: Date, index: Int) -> some View {
        let isToday = cal.isDateInToday(day)
        let done = checked.contains(day)
        let isFuture = day > .now && !isToday
        let isSelected = selectedDay.map { cal.isDate($0, inSameDayAs: day) } ?? false
        return Button {
            withAnimation(.spring(duration: 0.3)) { selectedDay = isSelected ? nil : day }
        } label: {
            ZStack {
                Circle()
                    .fill(done ? KnockColor.primary : (isFuture ? Color.clear : KnockColor.pendingDay))
                if isToday {
                    Circle().stroke(KnockColor.yellow, lineWidth: 2)
                }
                if isSelected {
                    Circle().stroke(KnockColor.primaryDark, lineWidth: 2).padding(-2)
                }
                if done {
                    Image(systemName: "checkmark")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(.white)
                } else {
                    Text("\(cal.component(.day, from: day))")
                        .font(KnockFont.medium(12))
                        .foregroundStyle(isFuture ? KnockColor.textMuted : KnockColor.textPrimary)
                }
            }
            .frame(height: 36)
            .scaleEffect(progress > 0 ? 1 : 0.6)
            .opacity(progress > 0 ? 1 : 0)
            .animation(.spring(duration: 0.45, bounce: 0.3).delay(Double(index) * 0.012), value: progress > 0)
        }
        .buttonStyle(.plain)
    }

    private func dayDetail(_ day: Date) -> some View {
        let done = checked.contains(day)
        let mood = cal.isDateInToday(day) ? appState.todayMood
            : appState.weekRecords.first { cal.isDate($0.date, inSameDayAs: day) }?.mood
        return SectionCard(background: KnockColor.cardTint2) {
            HStack(spacing: 12) {
                Image(systemName: done ? "checkmark.seal.fill" : "moon.zzz.fill")
                    .font(.system(size: 26))
                    .foregroundStyle(done ? KnockColor.primary : KnockColor.textMuted)
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(cal.component(.month, from: day))월 \(cal.component(.day, from: day))일")
                        .font(KnockFont.medium(15))
                        .foregroundStyle(KnockColor.textPrimary)
                    Text(done ? "체크인 완료 \(mood.map { "· 기분 \($0.emoji) \($0.rawValue)" } ?? "")" : (day > .now ? "예정된 날이에요" : "체크인 기록이 없어요"))
                        .font(KnockFont.regular(13))
                        .foregroundStyle(KnockColor.textSecondary)
                }
                Spacer()
            }
        }
        .transition(.move(edge: .bottom).combined(with: .opacity))
    }
}

// MARK: - 알림 센터

struct NotificationsView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Group {
                if appState.notifications.isEmpty {
                    EmptyStateView(title: "알림이 없어요", message: "체크인·가족 소식이 도착하면 여기에 표시돼요")
                } else {
                    ScrollView {
                        LazyVStack(spacing: 10) {
                            ForEach(appState.notifications) { n in
                                NotificationRow(notification: n)
                                    .onTapGesture { withAnimation { appState.markRead(n) } }
                                    .transition(.move(edge: .top).combined(with: .opacity))
                            }
                        }
                        .padding(20)
                        .animation(.spring(duration: 0.4), value: appState.notifications)
                    }
                }
            }
            .background(KnockColor.background)
            .navigationTitle("알림")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("모두 읽음") { appState.markAllRead() }
                        .accessibilityIdentifier("notifications.readAll")
                        .disabled(appState.unreadNotifications == 0)
                }
                ToolbarItem(placement: .topBarTrailing) { Button("닫기") { dismiss() } }
            }
        }
    }
}

struct NotificationRow: View {
    @Environment(AppState.self) private var appState
    var notification: AppNotification

    private var icon: (name: String, color: Color) {
        switch notification.kind {
        case .checkIn: return ("checkmark.circle.fill", KnockColor.primary)
        case .danger: return ("exclamationmark.triangle.fill", KnockColor.danger)
        case .family: return ("person.2.fill", KnockColor.lavender)
        case .system: return ("gearshape.fill", KnockColor.textMuted)
        }
    }

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon.name)
                .font(.system(size: 18))
                .foregroundStyle(icon.color)
                .frame(width: 38, height: 38)
                .background(icon.color.opacity(0.12), in: Circle())
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(notification.title)
                        .font(KnockFont.medium(15))
                        .foregroundStyle(KnockColor.textPrimary)
                    Spacer()
                    Text(notification.date.relativeDescription)
                        .font(KnockFont.regular(11))
                        .foregroundStyle(KnockColor.textMuted)
                }
                Text(notification.body)
                    .font(KnockFont.regular(13))
                    .foregroundStyle(KnockColor.textSecondary)
                    .lineLimit(3)
            }
            if !notification.isRead {
                Circle().fill(KnockColor.yellow).frame(width: 8, height: 8).padding(.top, 6)
            }
        }
        .padding(14)
        .background(notification.isRead ? .white : KnockColor.cardTint2,
                    in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .knockShadow()
        .contextMenu {
            Button(role: .destructive) { appState.removeNotification(notification) } label: {
                Label("삭제", systemImage: "trash")
            }
        }
    }
}
