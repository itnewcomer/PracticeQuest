import SwiftUI
import SwiftData

struct StopwatchView: View {
    let questName: String
    let questIcon: String
    let starsOnComplete: Int
    let onComplete: (Int) -> Void
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var seconds = 0
    @State private var isRunning = false
    @State private var timer: Timer?

    var body: some View {
        VStack(spacing: 32) {
            HStack {
                Text(questIcon).font(.system(size: 24))
                Text(questName).font(.system(size: 18, weight: .semibold))
                Spacer()
                Button {
                    stop()
                    dismiss()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(AppColors.textSecondary)
                }
            }
            .padding(.horizontal)

            Spacer()

            Text(formatTime(seconds))
                .font(.system(size: 56, weight: .bold, design: .monospaced))
                .foregroundColor(AppColors.textPrimary)

            Spacer()

            if !isRunning && seconds == 0 {
                Button {
                    start()
                } label: {
                    Text(L10n.current == .ja ? "▶ スタート" : "▶ Start")
                        .font(.system(size: 22, weight: .bold))
                        .frame(maxWidth: .infinity).padding()
                        .background(RoundedRectangle(cornerRadius: 16).fill(AppColors.success))
                        .foregroundColor(.white)
                }
                .padding(.horizontal, 40)
            } else if isRunning {
                Button {
                    stop()
                } label: {
                    Text(L10n.current == .ja ? "⏹ ストップ" : "⏹ Stop")
                        .font(.system(size: 22, weight: .bold))
                        .frame(maxWidth: .infinity).padding()
                        .background(RoundedRectangle(cornerRadius: 16).fill(AppColors.bonus))
                        .foregroundColor(.white)
                }
                .padding(.horizontal, 40)
            } else {
                VStack(spacing: 12) {
                    Text(L10n.current == .ja ? "🎉 おつかれさま！" : "🎉 Great job!")
                        .font(.system(size: 20, weight: .bold))
                    Text("⭐ +\(starsOnComplete)")
                        .font(.system(size: 18)).foregroundColor(AppColors.star)

                    Button {
                        let record = StopwatchRecord(questName: questName, seconds: seconds)
                        modelContext.insert(record)
                        try? modelContext.save()
                        onComplete(starsOnComplete)
                        dismiss()
                    } label: {
                        Text(L10n.current == .ja ? "きろくする" : "Save")
                            .font(.system(size: 18, weight: .bold))
                            .frame(maxWidth: .infinity).padding()
                            .background(RoundedRectangle(cornerRadius: 16).fill(AppColors.accent))
                            .foregroundColor(.white)
                    }
                    .padding(.horizontal, 40)

                    Button {
                        seconds = 0
                    } label: {
                        Text(L10n.current == .ja ? "もういちど" : "Retry")
                            .font(.system(size: 14))
                            .foregroundColor(AppColors.textSecondary)
                    }
                }
            }

            Spacer(minLength: 20)
        }
        .padding(.top)
        .background(AppColors.background)
        .buttonStyle(.plain)
        .onDisappear {
            stop()
        }
    }

    private func start() {
        seconds = 0
        isRunning = true
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in seconds += 1 }
    }

    private func stop() {
        isRunning = false
        timer?.invalidate()
        timer = nil
    }

    private func formatTime(_ s: Int) -> String {
        let m = s / 60; let sec = s % 60
        return String(format: "%d:%02d", m, sec)
    }
}
