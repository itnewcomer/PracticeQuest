import SwiftUI
import SwiftData

struct ShopView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Reward.starCost) private var rewards: [Reward]
    @Binding var totalStars: Int
    @State private var showConfirm = false
    @State private var selectedReward: Reward?
    @State private var timerReward: Reward?

    private var stockedRewards: [Reward] { rewards.filter { $0.stockCount > 0 || $0.hasTimeLeft } }

    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                // 持っている星
                VStack(spacing: 4) {
                    Text("⭐").font(.system(size: 36))
                    Text("\(totalStars)")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(AppColors.star)
                    Text(L10n.usableStars)
                        .font(.system(size: 12))
                        .foregroundColor(AppColors.textSecondary)
                }
                .card()

                // ストック（持っているごほうび）
                if !stockedRewards.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(L10n.current == .ja ? "🎒 もっているごほうび" : "🎒 My Rewards")
                            .font(.system(size: 14, weight: .semibold))

                        ForEach(stockedRewards) { reward in
                            HStack(spacing: 12) {
                                Text(reward.icon).font(.system(size: 24))
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(reward.name)
                                        .font(.system(size: 14, weight: .medium))
                                    if reward.isTimeBased {
                                        Text(L10n.current == .ja ? "のこり \(reward.remainingMinutes)分" : "\(reward.remainingMinutes)min left")
                                            .font(.system(size: 11))
                                            .foregroundColor(AppColors.textSecondary)
                                    } else {
                                        Text(L10n.current == .ja ? "\(reward.stockCount)個" : "×\(reward.stockCount)")
                                            .font(.system(size: 11))
                                            .foregroundColor(AppColors.textSecondary)
                                    }
                                }
                                Spacer()

                                if reward.isTimeBased && reward.hasTimeLeft {
                                    // 時間系: タイマーで消費
                                    Button {
                                        timerReward = reward
                                    } label: {
                                        Text(L10n.current == .ja ? "▶ つかう" : "▶ Use")
                                            .font(.system(size: 12, weight: .bold))
                                            .padding(.horizontal, 12)
                                            .padding(.vertical, 6)
                                            .background(Capsule().fill(AppColors.accent))
                                            .foregroundColor(.white)
                                    }
                                    .buttonStyle(.plain)
                                } else {
                                    // 非時間系: タップで消費
                                    Button {
                                        reward.stockCount -= 1
                                        try? modelContext.save()
                                    } label: {
                                        Text(L10n.current == .ja ? "つかう" : "Use")
                                            .font(.system(size: 12, weight: .bold))
                                            .padding(.horizontal, 12)
                                            .padding(.vertical, 6)
                                            .background(Capsule().fill(AppColors.success))
                                            .foregroundColor(.white)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .padding(12)
                            .background(RoundedRectangle(cornerRadius: 12).fill(AppColors.bonus.opacity(0.08)))
                        }
                    }
                    .card()
                }

                // 購入可能なごほうび
                VStack(alignment: .leading, spacing: 8) {
                    Text(L10n.current == .ja ? "🛒 ごほうびショップ" : "🛒 Reward Shop")
                        .font(.system(size: 14, weight: .semibold))

                    if rewards.isEmpty {
                        VStack(spacing: 8) {
                            Text("🎁").font(.system(size: 40))
                            Text(L10n.noRewards).font(.system(size: 14)).foregroundColor(AppColors.textSecondary)
                            Text(L10n.askParent).font(.system(size: 12)).foregroundColor(AppColors.textSecondary)
                        }
                        .frame(maxWidth: .infinity)
                    } else {
                        ForEach(rewards) { reward in
                            let canAfford = totalStars >= reward.starCost
                            HStack(spacing: 12) {
                                Text(reward.icon).font(.system(size: 28))
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(reward.name)
                                        .font(.system(size: 15, weight: .medium))
                                    HStack(spacing: 4) {
                                        Text("⭐\(reward.starCost)").font(.system(size: 12)).foregroundColor(AppColors.star)
                                        if reward.isTimeBased {
                                            Text("(\(reward.durationMinutes)\(L10n.current == .ja ? "分" : "min"))")
                                                .font(.system(size: 10)).foregroundColor(AppColors.textSecondary)
                                        }
                                    }
                                }
                                Spacer()
                                Button {
                                    selectedReward = reward
                                    showConfirm = true
                                } label: {
                                    Text(L10n.current == .ja ? "かう" : "Buy")
                                        .font(.system(size: 13, weight: .bold))
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 8)
                                        .background(Capsule().fill(canAfford ? AppColors.accent : AppColors.progressEmpty))
                                        .foregroundColor(canAfford ? .white : AppColors.textSecondary)
                                }
                                .buttonStyle(.plain)
                                .disabled(!canAfford)
                            }
                        }
                    }
                }
                .card()
            }
            .padding(.horizontal)
            .padding(.bottom, 20)
        }
        .alert(L10n.current == .ja ? "ごほうびをかう？" : "Buy this reward?", isPresented: $showConfirm) {
            Button(L10n.current == .ja ? "かう！" : "Buy!") {
                if let reward = selectedReward {
                    totalStars -= reward.starCost
                    if reward.isTimeBased {
                        reward.purchase()
                    } else {
                        reward.stockCount += 1
                    }
                    try? modelContext.save()
                }
            }
            Button(L10n.cancel, role: .cancel) {}
        } message: {
            if let reward = selectedReward {
                Text("\(reward.icon) \(reward.name)\n⭐\(reward.starCost)")
            }
        }
        .fullScreenCover(item: $timerReward) { reward in
            RewardTimerView(reward: reward) {
                try? modelContext.save()
            }
        }
    }
}

// ごほうびタイマー
struct RewardTimerView: View {
    @Bindable var reward: Reward
    let onFinish: () -> Void
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var remainingSeconds: Int = 0
    @State private var initialSeconds: Int = 0
    @State private var timer: Timer?
    @State private var isRunning = false
    @State private var usedSeconds = 0

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            Text(reward.icon).font(.system(size: 60))
            Text(reward.name).font(.system(size: 24, weight: .bold))

            // カウントダウン
            ZStack {
                Circle()
                    .stroke(AppColors.progressEmpty, lineWidth: 10)
                    .frame(width: 200, height: 200)
                Circle()
                    .trim(from: 0, to: max(0, Double(remainingSeconds) / Double(max(1, initialSeconds))))
                    .stroke(remainingSeconds > 60 ? AppColors.success : AppColors.bonus,
                            style: StrokeStyle(lineWidth: 10, lineCap: .round))
                    .frame(width: 200, height: 200)
                    .rotationEffect(.degrees(-90))

                VStack {
                    Text(formatTime(remainingSeconds))
                        .font(.system(size: 40, weight: .bold, design: .monospaced))
                    Text(L10n.current == .ja ? "のこり" : "remaining")
                        .font(.system(size: 12))
                        .foregroundColor(AppColors.textSecondary)
                }
            }

            Spacer()

            if remainingSeconds <= 0 {
                Text(L10n.current == .ja ? "⏰ じかんだよ！" : "⏰ Time's up!")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(AppColors.bonus)
                Button {
                    saveAndDismiss()
                } label: {
                    Text(L10n.current == .ja ? "おしまい" : "Done")
                        .font(.system(size: 18, weight: .bold))
                        .frame(maxWidth: .infinity).padding()
                        .background(RoundedRectangle(cornerRadius: 16).fill(AppColors.accent))
                        .foregroundColor(.white)
                }
                .padding(.horizontal, 40)
            } else if isRunning {
                Button {
                    pauseTimer()
                } label: {
                    Text(L10n.current == .ja ? "⏸ いったんとめる" : "⏸ Pause")
                        .font(.system(size: 18, weight: .bold))
                        .frame(maxWidth: .infinity).padding()
                        .background(RoundedRectangle(cornerRadius: 16).fill(AppColors.accent))
                        .foregroundColor(.white)
                }
                .padding(.horizontal, 40)
            } else {
                Button {
                    startTimer()
                } label: {
                    Text(usedSeconds == 0
                         ? (L10n.current == .ja ? "▶ スタート" : "▶ Start")
                         : (L10n.current == .ja ? "▶ つづける" : "▶ Resume"))
                        .font(.system(size: 18, weight: .bold))
                        .frame(maxWidth: .infinity).padding()
                        .background(RoundedRectangle(cornerRadius: 16).fill(AppColors.success))
                        .foregroundColor(.white)
                }
                .padding(.horizontal, 40)

                // 途中でやめる
                if usedSeconds > 0 {
                    Button {
                        saveAndDismiss()
                    } label: {
                        Text(L10n.current == .ja ? "ここまでにする（\(usedSeconds / 60)分つかった）" : "Stop here (\(usedSeconds / 60)min used)")
                            .font(.system(size: 14))
                            .foregroundColor(AppColors.textSecondary)
                    }
                }
            }

            // まだ始めてない時だけキャンセル可能
            if usedSeconds == 0 && !isRunning {
                Button {
                    dismiss()
                } label: {
                    Text(L10n.current == .ja ? "あとでつかう" : "Use later")
                        .font(.system(size: 14))
                        .foregroundColor(AppColors.textSecondary)
                }
            }

            Spacer(minLength: 20)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AppColors.background.ignoresSafeArea())
        .buttonStyle(.plain)
        .onAppear {
            remainingSeconds = reward.remainingSeconds
            initialSeconds = reward.remainingSeconds
        }
        .onDisappear {
            pauseTimer()
        }
    }

    private func startTimer() {
        isRunning = true
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            if remainingSeconds > 0 {
                remainingSeconds -= 1
                usedSeconds += 1
            } else {
                pauseTimer()
            }
        }
    }

    private func pauseTimer() {
        isRunning = false
        timer?.invalidate()
        timer = nil
    }

    private func saveAndDismiss() {
        pauseTimer()
        reward.consumeTime(usedSeconds)
        try? modelContext.save()
        if reward.remainingSeconds <= 0 {
            onFinish()
        }
        dismiss()
    }

    private func formatTime(_ s: Int) -> String {
        String(format: "%d:%02d", s / 60, s % 60)
    }
}
