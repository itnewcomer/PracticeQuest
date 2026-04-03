import SwiftUI

struct TimerView: View {
    let questName: String
    let questIcon: String
    let targetMinutes: Int
    let starsTotal: Int
    let onComplete: (Int) -> Void  // 実際の分数を返す
    @Environment(\.dismiss) private var dismiss

    @State private var elapsedSeconds = 0
    @State private var isRunning = false
    @State private var timer: Timer?
    @State private var reachedGoal = false
    @State private var showCelebration = false

    private var elapsedMinutes: Int { elapsedSeconds / 60 }
    private var remainingSeconds: Int { max(0, targetMinutes * 60 - elapsedSeconds) }
    private var isOvertime: Bool { elapsedSeconds >= targetMinutes * 60 }
    private var overtimeSeconds: Int { max(0, elapsedSeconds - targetMinutes * 60) }

    // 按分星（5分ごと）
    private var earnedStars: Int {
        let fiveMinBlocks = elapsedMinutes / 5
        let totalBlocks = max(1, targetMinutes / 5)
        return min(starsTotal, max(0, starsTotal * fiveMinBlocks / totalBlocks))
    }

    var body: some View {
        VStack(spacing: 24) {
            // ヘッダー
            HStack {
                Text(questIcon).font(.system(size: 24))
                Text(questName).font(.system(size: 18, weight: .semibold))
                Spacer()
                Button(L10n.current == .ja ? "やめる" : "Stop") {
                    stopTimer()
                    if elapsedSeconds >= 60 {
                        let minutes = elapsedSeconds / 60
                        onComplete(minutes)
                    }
                    dismiss()
                }
                .foregroundColor(AppColors.textSecondary)
            }
            .padding(.horizontal)

            Spacer()

            // タイマー表示
            ZStack {
                // 背景リング
                Circle()
                    .stroke(AppColors.progressEmpty, lineWidth: 12)
                    .frame(width: 220, height: 220)

                // 進捗リング
                Circle()
                    .trim(from: 0, to: min(1.0, Double(elapsedSeconds) / Double(targetMinutes * 60)))
                    .stroke(
                        isOvertime ? AppColors.bonus : AppColors.success,
                        style: StrokeStyle(lineWidth: 12, lineCap: .round)
                    )
                    .frame(width: 220, height: 220)
                    .rotationEffect(.degrees(-90))
                    .animation(.linear(duration: 1), value: elapsedSeconds)

                // 時間表示
                VStack(spacing: 4) {
                    if isOvertime {
                        Text(L10n.current == .ja ? "🎉 目標クリア！" : "🎉 Goal reached!")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(AppColors.bonus)
                        Text("+\(formatTime(overtimeSeconds))")
                            .font(.system(size: 36, weight: .bold, design: .monospaced))
                            .foregroundColor(AppColors.bonus)
                        Text(L10n.current == .ja ? "ボーナスタイム！" : "Bonus time!")
                            .font(.system(size: 12))
                            .foregroundColor(AppColors.textSecondary)
                    } else {
                        Text(formatTime(remainingSeconds))
                            .font(.system(size: 42, weight: .bold, design: .monospaced))
                            .foregroundColor(AppColors.textPrimary)
                        Text(L10n.current == .ja ? "のこり" : "remaining")
                            .font(.system(size: 12))
                            .foregroundColor(AppColors.textSecondary)
                    }
                }
            }

            // 星の進捗
            HStack {
                Text("⭐ \(earnedStars) / \(starsTotal)")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(AppColors.star)
            }

            Spacer()

            // スタート/ポーズボタン
            if !isRunning {
                Button {
                    startTimer()
                } label: {
                    Text(elapsedSeconds == 0
                         ? (L10n.current == .ja ? "▶ スタート" : "▶ Start")
                         : (L10n.current == .ja ? "▶ つづける" : "▶ Resume"))
                        .font(.system(size: 20, weight: .bold))
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(RoundedRectangle(cornerRadius: 16).fill(AppColors.success))
                        .foregroundColor(.white)
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 40)
            } else {
                Button {
                    pauseTimer()
                } label: {
                    Text(L10n.current == .ja ? "⏸ ちょっとまって" : "⏸ Pause")
                        .font(.system(size: 20, weight: .bold))
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(RoundedRectangle(cornerRadius: 16).fill(AppColors.accent))
                        .foregroundColor(.white)
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 40)
            }

            // 完了ボタン（目標達成後に表示）
            if isOvertime {
                Button {
                    stopTimer()
                    let minutes = max(1, (elapsedSeconds + 30) / 60)
                    onComplete(minutes)
                    dismiss()
                } label: {
                    Text(L10n.current == .ja ? "🏆 おわりにする" : "🏆 Finish")
                        .font(.system(size: 18, weight: .bold))
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(RoundedRectangle(cornerRadius: 16).fill(AppColors.bonus))
                        .foregroundColor(.white)
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 40)
            }

            Spacer(minLength: 20)
        }
        .padding(.top)
        .background(AppColors.background)
        .onChange(of: isOvertime) { _, overtime in
            if overtime && !reachedGoal {
                reachedGoal = true
                let generator = UINotificationFeedbackGenerator()
                generator.notificationOccurred(.success)
            }
        }
        .onDisappear {
            stopTimer()
        }
    }

    private func startTimer() {
        isRunning = true
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            elapsedSeconds += 1
        }
    }

    private func pauseTimer() {
        isRunning = false
        timer?.invalidate()
        timer = nil
    }

    private func stopTimer() {
        isRunning = false
        timer?.invalidate()
        timer = nil
    }

    private func formatTime(_ seconds: Int) -> String {
        let m = seconds / 60
        let s = seconds % 60
        return String(format: "%d:%02d", m, s)
    }
}
