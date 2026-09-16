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
            Spacer()
            HStack(spacing: 14) {
                Button(action: onPrevious) { Image(systemName: "chevron.left").font(.system(size: 12)) }
                Text(date.slashFormatted)
                    .font(KnockFont.medium(20))
                Button(action: onNext) { Image(systemName: "chevron.right").font(.system(size: 12)) }
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

// MARK: - 04 수면 상세

struct SleepDetailView: View {
    @Environment(AppState.self) private var appState
    @Binding var path: [HealthRoute]
    @Binding var showSettings: Bool
    @State private var date = MockData.sleep.date
    private let sleep = MockData.sleep

    var body: some View {
        GreenScaffold {
            UserHeader(user: appState.user, isOnline: true,
                       onAvatarTap: { showSettings = true })
        } content: {
            VStack(spacing: 20) {
                DetailDateBar(date: date, onBack: { path.removeLast() },
                              onPrevious: { date = Calendar.current.date(byAdding: .day, value: -1, to: date)! },
                              onNext: { date = Calendar.current.date(byAdding: .day, value: 1, to: date)! })
                    .padding(.top, 16)

                ZStack {
                    SleepRingView(stages: sleep.stages)
                        .frame(width: 240, height: 240)
                    VStack(spacing: 2) {
                        Text("오늘").font(KnockFont.regular(14)).foregroundStyle(KnockColor.textSecondary)
                        Text("\(Int(sleep.totalHours))").font(KnockFont.bold(44)).foregroundStyle(KnockColor.textPrimary)
                        Text("h").font(KnockFont.regular(14)).foregroundStyle(KnockColor.textSecondary)
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
                            Text("\(Int(sleep.totalHours))h").font(KnockFont.medium(20)).foregroundStyle(KnockColor.textPrimary)
                        }
                        .padding(.bottom, 12)
                        Divider()
                        ForEach(sleep.stages) { stage in
                            HStack(spacing: 10) {
                                Circle().fill(stage.kind.color).frame(width: 10, height: 10)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(stage.name).font(KnockFont.medium(15)).foregroundStyle(KnockColor.textPrimary)
                                    Text(stage.range).font(KnockFont.regular(12)).foregroundStyle(KnockColor.textSecondary)
                                }
                                Spacer()
                                Text("\(Int(stage.hours))h").font(KnockFont.medium(20)).foregroundStyle(KnockColor.textPrimary)
                            }
                            .padding(.vertical, 12)
                            if stage.id != sleep.stages.last?.id { Divider() }
                        }
                    }
                }
                .padding(.horizontal, 16)
            }
        }
    }
}

/// 수면 단계 3중 링
struct SleepRingView: View {
    var stages: [SleepStage]

    var body: some View {
        ZStack {
            ForEach(Array(stages.enumerated()), id: \.element.id) { i, stage in
                let inset = CGFloat(i) * 26
                Circle()
                    .stroke(stage.kind.color.opacity(0.18), lineWidth: 18)
                    .padding(inset)
                Circle()
                    .trim(from: 0, to: min(1, stage.hours / 12))
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
    private let hr = MockData.heartRate

    var body: some View {
        GreenScaffold {
            UserHeader(user: appState.user, isOnline: true,
                       onAvatarTap: { showSettings = true })
        } content: {
            VStack(spacing: 20) {
                SectionCard(padding: 16) {
                    VStack(spacing: 8) {
                        DetailDateBar(date: date, onBack: { path.removeLast() },
                                      onPrevious: { date = Calendar.current.date(byAdding: .day, value: -1, to: date)! },
                                      onNext: { date = Calendar.current.date(byAdding: .day, value: 1, to: date)! })
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
                            Spacer()
                            Text("\(hr.current) bpm").font(KnockFont.medium(20)).foregroundStyle(KnockColor.textPrimary)
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

                HStack(alignment: .bottom, spacing: 12) {
                    HeartRateSparkline()
                        .frame(height: 120)
                }
                .padding(.horizontal, 20)
            }
        }
    }

    private func row(color: Color, title: String, range: String, value: Int) -> some View {
        HStack(spacing: 10) {
            Circle().fill(color).frame(width: 10, height: 10)
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(KnockFont.medium(15)).foregroundStyle(KnockColor.textPrimary)
                Text(range).font(KnockFont.regular(12)).foregroundStyle(KnockColor.textSecondary)
            }
            Spacer()
            Text("\(value) bpm").font(KnockFont.medium(20)).foregroundStyle(KnockColor.textPrimary)
        }
        .padding(.vertical, 12)
    }
}

/// [보충] 24시간 심박수 추이 라인
struct HeartRateSparkline: View {
    private let samples: [Double] = [68, 64, 63, 66, 72, 85, 96, 110, 118, 184, 120, 98, 92, 88, 95, 102, 90, 84, 80, 76, 74, 72, 70, 69]

    var body: some View {
        SectionCard(padding: 14) {
            VStack(alignment: .leading, spacing: 8) {
                Text("24시간 추이").font(KnockFont.medium(13)).foregroundStyle(KnockColor.textSecondary)
                GeometryReader { geo in
                    let maxV = samples.max() ?? 1, minV = samples.min() ?? 0
                    let stepX = geo.size.width / CGFloat(samples.count - 1)
                    Path { p in
                        for (i, v) in samples.enumerated() {
                            let y = geo.size.height * (1 - CGFloat((v - minV) / (maxV - minV)))
                            let pt = CGPoint(x: CGFloat(i) * stepX, y: y)
                            if i == 0 { p.move(to: pt) } else { p.addLine(to: pt) }
                        }
                    }
                    .stroke(KnockColor.primary, style: StrokeStyle(lineWidth: 2.5, lineCap: .round, lineJoin: .round))
                }
                HStack {
                    Text("00:00"); Spacer(); Text("12:00"); Spacer(); Text("24:00")
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
    private let hours: [Double] = [0.2, 0.15, 0.1, 0.1, 0.15, 0.3, 0.45, 0.6, 0.7, 0.55, 0.5, 0.65, 0.8, 0.75, 0.6, 0.5, 0.4, 0.45, 0.35, 0.3, 0.25, 0.2, 0.2, 0.15]

    var body: some View {
        GreenScaffold {
            UserHeader(user: appState.user, isOnline: true,
                       onAvatarTap: { showSettings = true })
        } content: {
            VStack(spacing: 20) {
                DetailDateBar(date: date, onBack: { path.removeLast() },
                              onPrevious: { date = Calendar.current.date(byAdding: .day, value: -1, to: date)! },
                              onNext: { date = Calendar.current.date(byAdding: .day, value: 1, to: date)! })
                    .padding(.top, 16)

                VStack(spacing: 6) {
                    Text("오늘 스트레스").font(KnockFont.regular(13)).foregroundStyle(KnockColor.textSecondary)
                    Text("정상 상태").font(KnockFont.bold(32)).foregroundStyle(KnockColor.textPrimary)
                    PillBadge(text: "HRV 23 ms · 낮은 스트레스", background: .white, font: KnockFont.medium(11))
                }
                .padding(20)
                .frame(maxWidth: .infinity)
                .background(KnockColor.cardTint, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
                .padding(.horizontal, 16)

                SectionCard(padding: 16) {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("시간대별 스트레스").font(KnockFont.medium(16)).foregroundStyle(KnockColor.textPrimary)
                        GeometryReader { geo in
                            HStack(alignment: .bottom, spacing: 3) {
                                ForEach(Array(hours.enumerated()), id: \.offset) { _, v in
                                    Capsule()
                                        .fill(v > 0.7 ? KnockColor.stressHigh : v > 0.5 ? KnockColor.yellow : KnockColor.primary)
                                        .frame(height: max(6, geo.size.height * v))
                                        .frame(maxWidth: .infinity)
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
                        Text("오후 12~14시에 스트레스가 높았어요. 1분 동안 4초 들이쉬고 6초 내쉬는 호흡을 해보세요.")
                            .font(KnockFont.regular(13)).foregroundStyle(KnockColor.textSecondary).lineSpacing(3)
                        Button("주간 통계 보기") { appState.tab = .stats }
                            .font(KnockFont.medium(14)).foregroundStyle(KnockColor.primary)
                    }
                }
                .padding(.horizontal, 16)
            }
        }
    }
}
