import SwiftUI

/// 상세 화면 공통 상단 (뒤로 / 날짜 / 더보기)
struct DetailDateBar: View {
    var date: Date
    var onBack: () -> Void
    var onPrevious: () -> Void
    var onNext: () -> Void
    @State private var showMenu = false

    var body: some View {
        HStack {
            CircleIconButton(systemImage: "chevron.left", action: onBack)
                .accessibilityIdentifier("detail.back")
            Spacer()
            HStack(spacing: 14) {
                Button(action: onPrevious) { Image(systemName: "chevron.left").font(.system(size: 12)) }
                    .accessibilityIdentifier("detail.previous")
                Text(date.slashFormatted)
                    .font(KnockFont.medium(20))
                    .contentTransition(.numericText())
                    .animation(.easeInOut(duration: 0.25), value: date)
                Button(action: onNext) { Image(systemName: "chevron.right").font(.system(size: 12)) }
                    .accessibilityIdentifier("detail.next")
            }
            .foregroundStyle(KnockColor.textPrimary)
            Spacer()
            Menu {
                Button("건강 앱에서 열기", systemImage: "heart.text.square") {}
                Button("데이터 공유", systemImage: "square.and.arrow.up") {}
            } label: {
                Image(systemName: "ellipsis")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(KnockColor.primary)
                    .frame(width: 40, height: 40)
                    .background(KnockColor.cardTint, in: Circle())
            }
        }
        .padding(.horizontal, 16)
    }
}

private func format(_ v: Double) -> String {
    v == v.rounded() ? String(Int(v)) : String(format: "%.1f", v)
}

// MARK: - 04 수면 상세

struct SleepDetailView: View {
    @Environment(AppState.self) private var appState
    @Binding var path: [HealthRoute]
    @Binding var showSettings: Bool
    @State private var date = MockData.sleep.date
    @State private var ringProgress: CGFloat = 0

    private var sleep: SleepSummary { MockData.sleep(for: date) }

    var body: some View {
        GreenScaffold {
            UserHeader(user: appState.user, isOnline: true,
                       onAvatarTap: { showSettings = true })
        } content: {
            VStack(spacing: 20) {
                DetailDateBar(date: date, onBack: { path.removeLast() },
                              onPrevious: { shift(-1) },
                              onNext: { shift(1) })
                    .padding(.top, 16)

                ZStack {
                    SleepRingView(stages: sleep.stages, progress: ringProgress)
                        .frame(width: 240, height: 240)
                    VStack(spacing: 2) {
                        Text(Calendar.current.isDateInToday(date) ? "오늘" : "총 수면").font(KnockFont.regular(14)).foregroundStyle(KnockColor.textSecondary)
                        Text(format(sleep.totalHours)).font(KnockFont.bold(44)).foregroundStyle(KnockColor.textPrimary)
                            .contentTransition(.numericText())
                        Text("시간").font(KnockFont.regular(14)).foregroundStyle(KnockColor.textSecondary)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.bottom, 34)
                .overlay(alignment: .bottomLeading) {
                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(sleep.stages) { stage in
                            HStack(spacing: 6) {
                                Circle().fill(stage.kind.color).frame(width: 14, height: 14)
                                Text(stage.name).font(KnockFont.regular(14)).foregroundStyle(KnockColor.textSecondary)
                            }
                        }
                    }
                    .padding(.leading, 24)
                }
                .overlay(alignment: .bottomTrailing) {
                    Image("mascot_sleep").resizable().scaledToFit().frame(width: 96, height: 72)
                        .padding(.trailing, 24)
                }
                .padding(.top, 6)

                SectionCard(padding: 18) {
                    VStack(spacing: 0) {
                        HStack {
                            Image(systemName: "zzz").font(.system(size: 18)).foregroundStyle(KnockColor.textPrimary)
                            Text("수면시간").font(KnockFont.medium(20)).foregroundStyle(KnockColor.textPrimary)
                            Spacer()
                            Text("\(format(sleep.totalHours))시간").font(KnockFont.medium(20)).foregroundStyle(KnockColor.textPrimary)
                                .contentTransition(.numericText())
                        }
                        .padding(.bottom, 12)
                        Divider()
                        ForEach(Array(sleep.stages.enumerated()), id: \.element.id) { i, stage in
                            HStack(spacing: 10) {
                                Circle().fill(stage.kind.color).frame(width: 10, height: 10)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(stage.name).font(KnockFont.medium(15)).foregroundStyle(KnockColor.textPrimary)
                                    Text(stage.range).font(KnockFont.regular(12)).foregroundStyle(KnockColor.textSecondary)
                                }
                                Spacer()
                                Text("\(format(stage.hours))시간").font(KnockFont.medium(20)).foregroundStyle(KnockColor.textPrimary)
                                    .contentTransition(.numericText())
                            }
                            .padding(.vertical, 12)
                            .opacity(ringProgress > 0 ? 1 : 0)
                            .offset(x: ringProgress > 0 ? 0 : 24)
                            .animation(.spring(duration: 0.5).delay(0.1 + Double(i) * 0.08), value: ringProgress > 0)
                            if i != sleep.stages.count - 1 { Divider() }
                        }
                    }
                }
                .padding(.horizontal, 16)
                .animation(.easeInOut(duration: 0.3), value: date)
            }
        }
        .onAppear { animateIn() }
    }

    private func shift(_ days: Int) {
        date = Calendar.current.date(byAdding: .day, value: days, to: date)!
        animateIn()
    }

    private func animateIn() {
        ringProgress = 0
        withAnimation(.easeOut(duration: 0.9)) { ringProgress = 1 }
    }
}

/// 수면 단계 3중 링 (progress 0→1 로 그려지는 애니메이션)
struct SleepRingView: View {
    var stages: [SleepStage]
    var progress: CGFloat = 1

    var body: some View {
        ZStack {
            ForEach(Array(stages.enumerated()), id: \.element.id) { i, stage in
                let inset = CGFloat(i) * 26
                Circle()
                    .stroke(stage.kind.color.opacity(0.18), lineWidth: 18)
                    .padding(inset)
                Circle()
                    .trim(from: 0, to: min(1, stage.hours / 12) * progress)
                    .stroke(stage.kind.color, style: StrokeStyle(lineWidth: 18, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .padding(inset)
            }
        }
    }
}

extension SleepStage.Kind {
    var color: Color {
        switch self {
        case .deep: return KnockColor.primary
        case .light: return KnockColor.yellow
        case .rem: return KnockColor.lavender
        }
    }
}

// MARK: - 13 심박수 상세

struct HeartRateDetailView: View {
    @Environment(AppState.self) private var appState
    @Binding var path: [HealthRoute]
    @Binding var showSettings: Bool
    @State private var date = MockData.heartRate.date
    @State private var lineProgress: CGFloat = 0

    private var hr: HeartRateSummary { MockData.heartRate(for: date) }
    private var isLive: Bool { appState.healthConnection == .connected && Calendar.current.isDateInToday(date) }

    var body: some View {
        GreenScaffold {
            UserHeader(user: appState.user, isOnline: true,
                       onAvatarTap: { showSettings = true })
        } content: {
            VStack(spacing: 20) {
                SectionCard(padding: 16) {
                    VStack(spacing: 8) {
                        DetailDateBar(date: date, onBack: { path.removeLast() },
                                      onPrevious: { shift(-1) },
                                      onNext: { shift(1) })
                            .padding(.horizontal, -16)
                        Image("illustration_heart_ecg")
                            .resizable()
                            .scaledToFit()
                            .padding(.horizontal, 8)
                            .overlay(alignment: .bottomTrailing) {
                                Image("mascot_heart_small")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 76, height: 76)
                                    .offset(x: 4, y: 8)
                            }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)

                SectionCard(padding: 18) {
                    VStack(spacing: 0) {
                        HStack(spacing: 12) {
                            Image(systemName: "heart")
                                .font(.system(size: 18, weight: .medium))
                                .foregroundStyle(KnockColor.textPrimary)
                                .frame(width: 40, height: 40)
                                .background(KnockColor.cardTint, in: Circle())
                            Text("심박수").font(KnockFont.medium(20)).foregroundStyle(KnockColor.textPrimary)
                            if isLive {
                                PillBadge(text: "실시간", foreground: .white, background: KnockColor.danger, font: KnockFont.medium(10))
                            }
                            Spacer()
                            Text("\(isLive ? appState.liveHeartRate : hr.current)회/분")
                                .font(KnockFont.medium(20)).foregroundStyle(KnockColor.textPrimary)
                                .contentTransition(.numericText())
                                .animation(.easeInOut(duration: 0.3), value: appState.liveHeartRate)
                        }
                        .padding(.bottom, 12)
                        Divider()
                        row(color: KnockColor.primary, title: "평균 심박수", range: hr.averageRange, value: hr.average)
                        Divider()
                        row(color: KnockColor.warning, title: "최고 심박수", range: hr.maxRange, value: hr.max)
                        Divider()
                        row(color: KnockColor.lavender, title: "최저 심박수", range: hr.minRange, value: hr.min)
                    }
                }
                .padding(.horizontal, 20)
                .animation(.easeInOut(duration: 0.3), value: date)

                HStack(alignment: .bottom, spacing: 12) {
                    HeartRateSparkline(samples: hr.samples, progress: lineProgress)
                        .frame(height: 140)
                }
                .padding(.horizontal, 20)
            }
        }
        .onAppear { animateIn() }
    }

    private func shift(_ days: Int) {
        date = Calendar.current.date(byAdding: .day, value: days, to: date)!
        animateIn()
    }

    private func animateIn() {
        lineProgress = 0
        withAnimation(.easeInOut(duration: 1.2)) { lineProgress = 1 }
    }

    private func row(color: Color, title: String, range: String, value: Int) -> some View {
        HStack(spacing: 10) {
            Circle().fill(color).frame(width: 10, height: 10)
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(KnockFont.medium(15)).foregroundStyle(KnockColor.textPrimary)
                Text(range).font(KnockFont.regular(12)).foregroundStyle(KnockColor.textSecondary)
                    .contentTransition(.numericText())
            }
            Spacer()
            Text("\(value)회/분").font(KnockFont.medium(20)).foregroundStyle(KnockColor.textPrimary)
                .contentTransition(.numericText())
        }
        .padding(.vertical, 12)
    }
}

/// [보충] 24시간 심박수 추이 라인 (그려지는 애니메이션 + 최고점 표시)
struct HeartRateSparkline: View {
    var samples: [Double]
    var progress: CGFloat = 1

    var body: some View {
        SectionCard(padding: 14) {
            VStack(alignment: .leading, spacing: 8) {
                Text("24시간 추이").font(KnockFont.medium(13)).foregroundStyle(KnockColor.textSecondary)
                GeometryReader { geo in
                    let maxV = samples.max() ?? 1, minV = samples.min() ?? 0
                    let span = max(1, maxV - minV)
                    let stepX = geo.size.width / CGFloat(max(1, samples.count - 1))
                    let points = samples.enumerated().map { i, v in
                        CGPoint(x: CGFloat(i) * stepX, y: geo.size.height * (1 - CGFloat((v - minV) / span)))
                    }
                    let line = Path { p in
                        for (i, pt) in points.enumerated() {
                            if i == 0 { p.move(to: pt) } else { p.addLine(to: pt) }
                        }
                    }
                    ZStack(alignment: .topLeading) {
                        Path { p in
                            p.addPath(line)
                            if let last = points.last, let first = points.first {
                                p.addLine(to: CGPoint(x: last.x, y: geo.size.height))
                                p.addLine(to: CGPoint(x: first.x, y: geo.size.height))
                                p.closeSubpath()
                            }
                        }
                        .fill(LinearGradient(colors: [KnockColor.primary.opacity(0.25), .clear], startPoint: .top, endPoint: .bottom))
                        .opacity(Double(progress))
                        line
                            .trim(from: 0, to: progress)
                            .stroke(KnockColor.primary, style: StrokeStyle(lineWidth: 2.5, lineCap: .round, lineJoin: .round))
                        if progress >= 1, let maxIdx = samples.indices.max(by: { samples[$0] < samples[$1] }) {
                            let pt = points[maxIdx]
                            Circle().fill(KnockColor.danger).frame(width: 8, height: 8)
                                .position(pt)
                                .transition(.scale)
                            Text("\(Int(samples[maxIdx]))")
                                .font(KnockFont.bold(11)).foregroundStyle(KnockColor.danger)
                                .position(x: min(max(pt.x, 14), geo.size.width - 14), y: max(8, pt.y - 14))
                                .transition(.opacity)
                        }
                    }
                }
                HStack {
                    Text("0시"); Spacer(); Text("12시"); Spacer(); Text("24시")
                }
                .font(KnockFont.regular(10)).foregroundStyle(KnockColor.textMuted)
            }
        }
    }
}

// MARK: - [보충] 스트레스 상세 (오늘)

struct StressDetailView: View {
    @Environment(AppState.self) private var appState
    @Binding var path: [HealthRoute]
    @Binding var showSettings: Bool
    @State private var date = Date.now
    @State private var barProgress: CGFloat = 0

    private var hours: [Double] { MockData.stressHours(for: date) }
    private var level: StressLevel { MockData.stressLevel(for: hours) }
    private var peakHour: Int { hours.indices.max { hours[$0] < hours[$1] } ?? 12 }
    private var hrv: Int { Int(70 - (hours.reduce(0, +) / Double(hours.count)) * 50) }

    var body: some View {
        GreenScaffold {
            UserHeader(user: appState.user, isOnline: true,
                       onAvatarTap: { showSettings = true })
        } content: {
            VStack(spacing: 20) {
                DetailDateBar(date: date, onBack: { path.removeLast() },
                              onPrevious: { shift(-1) },
                              onNext: { shift(1) })
                    .padding(.top, 16)

                VStack(spacing: 6) {
                    Text(Calendar.current.isDateInToday(date) ? "오늘 스트레스" : "하루 스트레스")
                        .font(KnockFont.regular(13)).foregroundStyle(KnockColor.textSecondary)
                    Text(level.rawValue).font(KnockFont.bold(32)).foregroundStyle(KnockColor.textPrimary)
                        .contentTransition(.opacity)
                    PillBadge(text: "심박 변이 \(hrv) · \(level == .good || level == .normal ? "낮은" : "높은") 스트레스",
                              background: .white, font: KnockFont.medium(11))
                }
                .padding(20)
                .frame(maxWidth: .infinity)
                .background(level.color.opacity(0.28), in: RoundedRectangle(cornerRadius: 24, style: .continuous))
                .padding(.horizontal, 16)
                .animation(.easeInOut(duration: 0.3), value: date)

                SectionCard(padding: 16) {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("시간대별 스트레스").font(KnockFont.medium(16)).foregroundStyle(KnockColor.textPrimary)
                        GeometryReader { geo in
                            HStack(alignment: .bottom, spacing: 3) {
                                ForEach(Array(hours.enumerated()), id: \.offset) { i, v in
                                    Capsule()
                                        .fill(v > 0.7 ? KnockColor.stressHigh : v > 0.5 ? KnockColor.yellow : KnockColor.primary)
                                        .frame(height: max(6, geo.size.height * v * barProgress))
                                        .frame(maxWidth: .infinity)
                                        .animation(.spring(duration: 0.6, bounce: 0.2).delay(Double(i) * 0.02), value: barProgress)
                                }
                            }
                            .frame(height: geo.size.height, alignment: .bottom)
                        }
                        .frame(height: 120)
                        HStack { Text("0시"); Spacer(); Text("12시"); Spacer(); Text("24시") }
                            .font(KnockFont.regular(10)).foregroundStyle(KnockColor.textMuted)
                        StressLegend()
                    }
                }
                .padding(.horizontal, 16)

                SectionCard(padding: 16) {
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Image(systemName: "wind").foregroundStyle(KnockColor.primary)
                            Text("추천 호흡 운동").font(KnockFont.medium(16)).foregroundStyle(KnockColor.textPrimary)
                        }
                        Text("\(peakHour)시~\(peakHour + 2)시에 스트레스가 가장 높았어요. 1분 동안 4초 들이쉬고 6초 내쉬는 호흡을 해보세요.")
                            .font(KnockFont.regular(13)).foregroundStyle(KnockColor.textSecondary).lineSpacing(3)
                        HStack(spacing: 12) {
                            PrimaryButton(title: "호흡 운동 시작", style: .green) { path.append(.breathing) }
                                .accessibilityIdentifier("stress.startBreathing")
                            Button("주간 통계 보기") { appState.tab = .stats }
                                .font(KnockFont.medium(14)).foregroundStyle(KnockColor.primary)
                        }
                    }
                }
                .padding(.horizontal, 16)
            }
        }
        .onAppear { animateIn() }
    }

    private func shift(_ days: Int) {
        date = Calendar.current.date(byAdding: .day, value: days, to: date)!
        animateIn()
    }

    private func animateIn() {
        barProgress = 0
        withAnimation { barProgress = 1 }
    }
}
