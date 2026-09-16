import SwiftUI

enum StatsPeriod: Hashable, CaseIterable {
    case week, month, year
    var title: String {
        switch self {
        case .week: return "주기"
        case .month: return "월기"
        case .year: return "년기"
        }
    }
}

struct StressStatsView: View {
    @Environment(AppState.self) private var appState
    @Binding var showSettings: Bool
    @State private var period: StatsPeriod = .week
    @State private var anchor: Date = MockData.date(2025, 7, 21)

    var body: some View {
        GreenScaffold {
            UserHeader(user: appState.user, isOnline: true,
                       trailing: AnyView(HeaderActions(showSettings: $showSettings)),
                       onAvatarTap: { showSettings = true })
        } content: {
            VStack(spacing: 18) {
                HStack {
                    Text("일별 스트레스 통계")
                        .font(KnockFont.bold(24))
                        .foregroundStyle(KnockColor.textPrimary)
                    Spacer()
                    Image("mascot_stats_small").resizable().scaledToFit().frame(height: 56)
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)

                SegmentedPill(items: StatsPeriod.allCases.map { ($0, $0.title) }, selection: $period)
                    .padding(.horizontal, 16)

                DateNavigator(title: rangeTitle, onPrevious: { shift(-1) }, onNext: { shift(1) })

                switch period {
                case .week: WeekStressSection(start: anchor)
                case .month: MonthStressSection(monthStart: anchor)
                case .year: YearStressSection(year: Calendar.current.component(.year, from: anchor))
                }
            }
            .animation(.easeInOut(duration: 0.25), value: period)
        }
    }

    private var rangeTitle: String {
        let cal = Calendar.current
        switch period {
        case .week:
            let end = cal.date(byAdding: .day, value: 6, to: anchor)!
            return "\(anchor.monthDay)-\(end.monthDay)"
        case .month:
            let end = cal.date(byAdding: .month, value: 1, to: anchor)!
            return "\(anchor.monthDay)-\(end.monthDay)"
        case .year:
            return "\(cal.component(.year, from: anchor))년"
        }
    }

    private func shift(_ direction: Int) {
        let cal = Calendar.current
        withAnimation {
            switch period {
            case .week: anchor = cal.date(byAdding: .day, value: 7 * direction, to: anchor)!
            case .month: anchor = cal.date(byAdding: .month, value: direction, to: anchor)!
            case .year: anchor = cal.date(byAdding: .year, value: direction, to: anchor)!
            }
        }
    }
}

// MARK: - 주기 (05)

struct WeekStressSection: View {
    var start: Date
    private let symbols = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]
    private var days: [StressDay] { MockData.stressWeek(start: start) }
    private let summary = MockData.weekSummary

    var body: some View {
        VStack(spacing: 20) {
            VStack(spacing: 14) {
                HStack {
                    Text("일별 스트레스 상태 추이").font(KnockFont.medium(16)).foregroundStyle(KnockColor.textPrimary)
                    Spacer()
                    Text("주간 캘린더").font(KnockFont.regular(12)).foregroundStyle(KnockColor.textSecondary)
                }
                HStack(spacing: 0) {
                    ForEach(Array(days.enumerated()), id: \.element.id) { i, day in
                        VStack(spacing: 8) {
                            Text(symbols[i % symbols.count]).font(KnockFont.regular(12)).foregroundStyle(KnockColor.textSecondary)
                            RoundedRectangle(cornerRadius: 6)
                                .fill(day.level.color)
                                .frame(width: 34, height: 34)
                                .overlay {
                                    if day.level == .none {
                                        Text("\(Calendar.current.component(.day, from: day.date))")
                                            .font(KnockFont.medium(12))
                                            .foregroundStyle(KnockColor.textSecondary)
                                    }
                                }
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
            }
            .padding(16)
            .background(KnockColor.cardTint, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
            .padding(.horizontal, 16)

            HStack(spacing: 16) {
                StressCountBlock(title: "스트레스 낮음", days: summary.lowStressDays, delta: summary.lowDelta)
                StressCountBlock(title: "스트레스 높음", days: summary.highStressDays, delta: summary.highDelta)
            }
            .padding(.horizontal, 20)

            StressBarChart(days: days)
                .frame(height: 170)
                .padding(.horizontal, 20)

            StressLegend()
                .padding(.horizontal, 20)

            Text(summary.comment)
                .font(KnockFont.regular(13))
                .foregroundStyle(KnockColor.textSecondary)
                .lineSpacing(4)
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(KnockColor.cardTint3, in: RoundedRectangle(cornerRadius: 16))
                .padding(.horizontal, 16)
        }
    }
}

struct StressCountBlock: View {
    var title: String
    var days: Int
    var delta: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title).font(KnockFont.medium(14)).foregroundStyle(KnockColor.textPrimary)
            Text("\(days)일").font(KnockFont.bold(30)).foregroundStyle(KnockColor.textPrimary)
            Text("\(delta >= 0 ? "▲" : "▼") 지난주보다 \(abs(delta))일 \(delta >= 0 ? "많음" : "적음")")
                .font(KnockFont.regular(12))
                .foregroundStyle(KnockColor.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

/// 요일별 낮음/높음 스트레스 막대 그래프
struct StressBarChart: View {
    var days: [StressDay]

    var body: some View {
        GeometryReader { geo in
            let h = geo.size.height
            HStack(alignment: .bottom, spacing: 0) {
                ForEach(days) { day in
                    HStack(alignment: .bottom, spacing: 4) {
                        Capsule().fill(KnockColor.primary).frame(width: 14, height: max(8, h * day.lowScore))
                        Capsule().fill(day.highScore > 0.6 ? KnockColor.yellow : KnockColor.lavender)
                            .frame(width: 14, height: max(8, h * day.highScore))
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .frame(height: h, alignment: .bottom)
        }
    }
}

struct StressLegend: View {
    var body: some View {
        HStack(spacing: 14) {
            legend(KnockColor.stressGood, "좋음")
            legend(KnockColor.stressNormal, "정상")
            legend(KnockColor.stressCaution, "주의")
            legend(KnockColor.stressHigh, "과다")
            Spacer()
        }
    }
    private func legend(_ color: Color, _ text: String) -> some View {
        HStack(spacing: 5) {
            Circle().fill(color).frame(width: 8, height: 8)
            Text(text).font(KnockFont.regular(11)).foregroundStyle(KnockColor.textSecondary)
        }
    }
}

// MARK: - 월기 (07)

struct MonthStressSection: View {
    var monthStart: Date
    private var days: [StressDay] { MockData.stressMonth(monthStart: monthStart) }
    private let summary = MockData.monthSummary
    @State private var selected: StressDay?

    var body: some View {
        VStack(spacing: 18) {
            StressDistributionCard(title: "월별 스트레스 상태 추이", summary: summary)
                .padding(.horizontal, 16)

            SectionCard(padding: 16) {
                VStack(spacing: 12) {
                    Text("스트레스 시간대")
                        .font(KnockFont.medium(16))
                        .foregroundStyle(KnockColor.textPrimary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    StressCalendarGrid(monthStart: monthStart, days: days, selected: $selected)
                }
            }
            .padding(.horizontal, 16)

            if let selected {
                HStack {
                    Circle().fill(selected.level.color).frame(width: 10, height: 10)
                    Text("\(selected.date.formatted(.dateTime.month().day())) · \(selected.level.rawValue)")
                        .font(KnockFont.medium(14))
                        .foregroundStyle(KnockColor.textPrimary)
                    Spacer()
                }
                .padding(.horizontal, 24)
                .transition(.opacity)
            }

            Text(summary.comment)
                .font(KnockFont.regular(13))
                .foregroundStyle(KnockColor.textSecondary)
                .lineSpacing(4)
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(KnockColor.cardTint3, in: RoundedRectangle(cornerRadius: 16))
                .padding(.horizontal, 16)
        }
    }
}

/// 총횟수 + 4개 상태 비율 + 세로 막대
struct StressDistributionCard: View {
    var title: String
    var summary: StressPeriodSummary
    var caption: String = "월간 캘린더"

    var body: some View {
        SectionCard(padding: 18) {
            VStack(alignment: .leading, spacing: 14) {
                Text(title).font(KnockFont.medium(16)).foregroundStyle(KnockColor.textPrimary)
                HStack(alignment: .top, spacing: 12) {
                    VStack(alignment: .leading, spacing: 14) {
                        HStack(alignment: .firstTextBaseline, spacing: 8) {
                            Text("총횟수").font(KnockFont.regular(13)).foregroundStyle(KnockColor.textSecondary)
                            Text("\(summary.total)").font(KnockFont.bold(28)).foregroundStyle(KnockColor.textPrimary)
                        }
                        Grid(alignment: .leading, horizontalSpacing: 20, verticalSpacing: 12) {
                            GridRow {
                                stat(KnockColor.stressGood, "좋은 상태", summary.good)
                                stat(KnockColor.stressCaution, "정상 상태", summary.normal)
                            }
                            GridRow {
                                stat(KnockColor.stressHigh, "주의 상태", summary.caution)
                                stat(KnockColor.danger, "과다 상태", summary.high)
                            }
                        }
                    }
                    Spacer()
                    VStack(spacing: 6) {
                        Text(caption).font(KnockFont.regular(11)).foregroundStyle(KnockColor.textSecondary)
                        StackedBar(summary: summary).frame(width: 30, height: 130)
                    }
                }
            }
        }
    }

    private func stat(_ color: Color, _ label: String, _ value: Int) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            HStack(spacing: 5) {
                Circle().fill(color).frame(width: 6, height: 6)
                Text(label).font(KnockFont.regular(11)).foregroundStyle(KnockColor.textSecondary)
            }
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text("\(value)").font(KnockFont.bold(22)).foregroundStyle(KnockColor.textPrimary)
                Text("\(summary.total == 0 ? 0 : value * 100 / summary.total)%")
                    .font(KnockFont.regular(11)).foregroundStyle(KnockColor.textSecondary)
            }
        }
    }
}

struct StackedBar: View {
    var summary: StressPeriodSummary
    var body: some View {
        GeometryReader { geo in
            let total = CGFloat(max(summary.total, 1))
            VStack(spacing: 0) {
                Rectangle().fill(KnockColor.stressGood).frame(height: geo.size.height * CGFloat(summary.good) / total)
                Rectangle().fill(KnockColor.stressCaution).frame(height: geo.size.height * CGFloat(summary.normal) / total)
                Rectangle().fill(KnockColor.stressHigh).frame(height: geo.size.height * CGFloat(summary.caution) / total)
                Rectangle().fill(KnockColor.danger).frame(height: geo.size.height * CGFloat(summary.high) / total)
            }
            .clipShape(Capsule())
        }
    }
}

/// 월간 캘린더 그리드 (상태별 색상 칩)
struct StressCalendarGrid: View {
    var monthStart: Date
    var days: [StressDay]
    @Binding var selected: StressDay?
    private let symbols = ["M", "T", "W", "T", "F", "S", "S"]

    private var leadingBlanks: Int {
        let weekday = Calendar.current.component(.weekday, from: monthStart) // 1 = Sun
        return (weekday + 5) % 7
    }

    var body: some View {
        let cal = Calendar.current
        let prevMonthEnd = cal.date(byAdding: .day, value: -1, to: monthStart)!
        let prevDays = cal.component(.day, from: prevMonthEnd)
        let totalCells = Int(ceil(Double(leadingBlanks + days.count) / 7)) * 7

        VStack(spacing: 10) {
            HStack {
                ForEach(Array(symbols.enumerated()), id: \.offset) { _, s in
                    Text(s).font(KnockFont.medium(12)).foregroundStyle(KnockColor.textSecondary).frame(maxWidth: .infinity)
                }
            }
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 4), count: 7), spacing: 10) {
                ForEach(0..<totalCells, id: \.self) { cell in
                    if cell < leadingBlanks {
                        dayCell(prevDays - leadingBlanks + cell + 1, level: nil, muted: true)
                    } else if cell - leadingBlanks < days.count {
                        let day = days[cell - leadingBlanks]
                        Button { withAnimation { selected = day } } label: {
                            dayCell(cell - leadingBlanks + 1, level: day.level, muted: false,
                                    highlighted: selected?.id == day.id)
                        }
                        .buttonStyle(.plain)
                    } else {
                        dayCell(cell - leadingBlanks - days.count + 1, level: nil, muted: true)
                    }
                }
            }
        }
    }

    private func dayCell(_ number: Int, level: StressLevel?, muted: Bool, highlighted: Bool = false) -> some View {
        Text("\(number)")
            .font(KnockFont.medium(13))
            .foregroundStyle(muted ? KnockColor.textDisabled : KnockColor.textPrimary)
            .frame(width: 34, height: 24)
            .background {
                if let level, level != .none {
                    Capsule().fill(level.color.opacity(0.7))
                }
            }
            .overlay {
                if highlighted { Capsule().stroke(KnockColor.primaryDark, lineWidth: 1.5) }
            }
    }
}

// MARK: - 년기 (보충 화면)

struct YearStressSection: View {
    var year: Int
    private let summary = MockData.yearSummary
    private let months = ["1", "2", "3", "4", "5", "6", "7", "8", "9", "10", "11", "12"]

    var body: some View {
        VStack(spacing: 18) {
            StressDistributionCard(title: "연간 스트레스 상태 추이", summary: summary, caption: "연간 분포")
                .padding(.horizontal, 16)

            SectionCard(padding: 16) {
                VStack(alignment: .leading, spacing: 14) {
                    Text("월별 스트레스 추이").font(KnockFont.medium(16)).foregroundStyle(KnockColor.textPrimary)
                    GeometryReader { geo in
                        HStack(alignment: .bottom, spacing: 4) {
                            ForEach(Array(MockData.yearMonthlyScores.enumerated()), id: \.offset) { i, s in
                                VStack(spacing: 4) {
                                    ZStack(alignment: .bottom) {
                                        Capsule().fill(KnockColor.cardTint).frame(height: geo.size.height - 18)
                                        Capsule().fill(KnockColor.primary).frame(height: (geo.size.height - 18) * s.low)
                                        Capsule().fill(KnockColor.stressHigh).frame(width: 6, height: (geo.size.height - 18) * s.high)
                                    }
                                    Text(months[i % months.count]).font(KnockFont.regular(10)).foregroundStyle(KnockColor.textSecondary)
                                }
                                .frame(maxWidth: .infinity)
                            }
                        }
                    }
                    .frame(height: 150)
                    StressLegend()
                }
            }
            .padding(.horizontal, 16)

            Text(summary.comment)
                .font(KnockFont.regular(13))
                .foregroundStyle(KnockColor.textSecondary)
                .lineSpacing(4)
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(KnockColor.cardTint3, in: RoundedRectangle(cornerRadius: 16))
                .padding(.horizontal, 16)
        }
    }
}

extension StressLevel {
    var color: Color {
        switch self {
        case .good: return KnockColor.stressGood
        case .normal: return KnockColor.stressNormal
        case .caution: return KnockColor.stressCaution
        case .high: return KnockColor.stressHigh
        case .none: return .white
        }
    }
}
