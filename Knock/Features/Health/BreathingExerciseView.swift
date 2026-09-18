import SwiftUI

/// [보충 화면] 1분 호흡 운동 — 4초 들이쉬고 6초 내쉬기
struct BreathingExerciseView: View {
    @Environment(AppState.self) private var appState
    @Binding var path: [HealthRoute]

    private enum Phase: Equatable {
        case ready, inhale, exhale, done

        var title: String {
            switch self {
            case .ready: return "준비되면 시작을 눌러요"
            case .inhale: return "천천히 들이쉬어요"
            case .exhale: return "천천히 내쉬어요"
            case .done: return "잘했어요!"
            }
        }
    }

    private let totalSeconds = 60
    private let inhale = 4.0
    private let exhale = 6.0

    @State private var phase: Phase = .ready
    @State private var scale: CGFloat = 0.6
    @State private var remaining = 60
    @State private var cycles = 0
    @State private var runner: Task<Void, Never>?
    @State private var ripple = false

    var body: some View {
        GreenScaffold {
            HStack {
                Button { stop(); path.removeLast() } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(width: 36, height: 36)
                        .background(.white.opacity(0.18), in: Circle())
                }
                Spacer()
                Text("호흡 운동").font(KnockFont.medium(18)).foregroundStyle(.white)
                Spacer()
                Color.clear.frame(width: 36, height: 36)
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
            .padding(.bottom, 16)
        } content: {
            VStack(spacing: 28) {
                VStack(spacing: 6) {
                    Text(phase.title)
                        .font(KnockFont.medium(22))
                        .foregroundStyle(KnockColor.textPrimary)
                        .contentTransition(.opacity)
                        .animation(.easeInOut(duration: 0.3), value: phase)
                    Text(phase == .done ? "\(cycles)회 호흡을 마쳤어요" : "4초 들이쉬고 · 6초 내쉬기")
                        .font(KnockFont.regular(14))
                        .foregroundStyle(KnockColor.textSecondary)
                }
                .padding(.top, 28)

                ZStack {
                    ForEach(0..<3, id: \.self) { i in
                        Circle()
                            .stroke(KnockColor.primary.opacity(0.18 - Double(i) * 0.05), lineWidth: 2)
                            .frame(width: 220 + CGFloat(i) * 40, height: 220 + CGFloat(i) * 40)
                            .scaleEffect(ripple ? 1.08 : 0.96)
                            .animation(.easeInOut(duration: 3).repeatForever(autoreverses: true).delay(Double(i) * 0.4), value: ripple)
                    }
                    Circle()
                        .fill(
                            RadialGradient(colors: [KnockColor.lime, KnockColor.primary],
                                           center: .center, startRadius: 10, endRadius: 130)
                        )
                        .frame(width: 220, height: 220)
                        .scaleEffect(scale)
                        .shadow(color: KnockColor.primary.opacity(0.35), radius: 30, y: 10)
                    VStack(spacing: 4) {
                        Text(phase == .done ? "완료" : "\(remaining)")
                            .font(KnockFont.bold(48))
                            .foregroundStyle(.white)
                            .contentTransition(.numericText(countsDown: true))
                            .animation(.easeInOut(duration: 0.3), value: remaining)
                            .monospacedDigit()
                        if phase != .done {
                            Text("초 남음").font(KnockFont.regular(13)).foregroundStyle(.white.opacity(0.9))
                        }
                    }
                }
                .frame(height: 320)
                .onAppear { ripple = true }

                HStack(spacing: 10) {
                    ForEach(0..<6, id: \.self) { i in
                        Capsule()
                            .fill(i < cycles ? KnockColor.primary : KnockColor.cardTint)
                            .frame(width: i < cycles ? 26 : 14, height: 8)
                            .animation(.spring(duration: 0.4), value: cycles)
                    }
                }

                VStack(spacing: 12) {
                    switch phase {
                    case .ready:
                        PrimaryButton(title: "시작하기", style: .filled) { start() }
                    case .inhale, .exhale:
                        PrimaryButton(title: "그만하기", style: .outline) { stop() }
                    case .done:
                        PrimaryButton(title: "다시 하기", style: .filled) { start() }
                        Button("건강 화면으로") { path.removeAll() }
                            .font(KnockFont.medium(14)).foregroundStyle(KnockColor.primary)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 24)
            }
        }
        .onDisappear { runner?.cancel() }
    }

    private func start() {
        runner?.cancel()
        remaining = totalSeconds
        cycles = 0
        runner = Task { @MainActor in
            let started = Date.now
            while !Task.isCancelled {
                phase = .inhale
                withAnimation(.easeInOut(duration: inhale)) { scale = 1.0 }
                if await tick(seconds: inhale, started: started) { break }
                phase = .exhale
                withAnimation(.easeInOut(duration: exhale)) { scale = 0.6 }
                if await tick(seconds: exhale, started: started) { break }
                cycles += 1
            }
            guard !Task.isCancelled else { return }
            remaining = 0
            withAnimation(.spring(duration: 0.6, bounce: 0.35)) {
                phase = .done
                scale = 0.85
            }
            appState.showToast("호흡 운동 1분 완료 · 스트레스가 낮아졌어요", icon: "wind")
            appState.pushNotification(title: "호흡 운동 완료", body: "1분 호흡 운동을 \(cycles)회 마쳤어요.", kind: .system)
        }
    }

    /// 1초 단위로 카운트다운. 60초가 끝나면 true 반환.
    private func tick(seconds: Double, started: Date) async -> Bool {
        var elapsed = 0.0
        while elapsed < seconds {
            try? await Task.sleep(for: .seconds(1))
            if Task.isCancelled { return true }
            elapsed += 1
            remaining = max(0, totalSeconds - Int(Date.now.timeIntervalSince(started)))
            if remaining <= 0 { return true }
        }
        return false
    }

    private func stop() {
        runner?.cancel()
        runner = nil
        withAnimation(.easeInOut(duration: 0.4)) {
            phase = .ready
            scale = 0.6
        }
        remaining = totalSeconds
        cycles = 0
    }
}
