import SwiftUI
import SwiftData

struct QuestBoardView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Quest.order) private var quests: [Quest]
    @Query private var logs: [QuestLog]
    @Binding var totalStars: Int

    private let calendar = Calendar.current
    private let today = Calendar.current.startOfDay(for: Date())

    @State private var isMorningBonus = false
    @State private var isPastBedtime = false

    private func logForQuest(_ quest: Quest) -> QuestLog? {
        logs.first { $0.questName == quest.name && calendar.isDate($0.date, inSameDayAs: today) }
    }

    private func updateTimeFlags() {
        let hour = calendar.component(.hour, from: Date())
        let min = calendar.component(.minute, from: Date())
        let now = hour * 60 + min
        let schoolStart = UserDefaults.standard.object(forKey: "schoolStartHour") as? Int ?? 9
        let bedH = UserDefaults.standard.object(forKey: "bedtimeHour") as? Int ?? 20
        let bedM = UserDefaults.standard.object(forKey: "bedtimeMin") as? Int ?? 30
        isMorningBonus = hour >= 5 && hour < schoolStart
        isPastBedtime = now >= bedH * 60 + bedM || hour < 5
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                // 朝ボーナスバナー
                if isMorningBonus {
                    HStack {
                        Text("🌅")
                        Text(L10n.morningBonus)
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(AppColors.morning)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(10)
                    .background(RoundedRectangle(cornerRadius: 12).fill(AppColors.morning.opacity(0.15)))
                }

                if isPastBedtime {
                    HStack {
                        Text("🌙")
                        Text(L10n.current == .ja ? "ねる時間だよ！もらえる⭐がすくなくなるよ" : "It's bedtime! You'll earn fewer stars")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(AppColors.evening)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(10)
                    .background(RoundedRectangle(cornerRadius: 12).fill(AppColors.evening.opacity(0.15)))
                }

                // 今日の進捗
                let completed = quests.reduce(0) { sum, quest in
                    let count = logForQuest(quest)?.completedCount ?? 0
                    if quest.isTimeType { return sum + (count >= quest.targetMinutes ? 1 : 0) }
                    return sum + count
                }
                let total = quests.reduce(0) { sum, quest in
                    if quest.isPageType { return sum + quest.totalPages }
                    if quest.isTimeType { return sum + 1 }
                    return sum + quest.dailyCount
                }
                if total > 0 {
                    VStack(spacing: 6) {
                        Text(L10n.todayQuests)
                            .font(.system(size: 14))
                            .foregroundColor(AppColors.textSecondary)
                        ProgressView(value: Double(completed), total: Double(total))
                            .tint(completed == total ? AppColors.success : AppColors.accent)
                        Text("\(completed) / \(total)")
                            .font(.system(size: 12))
                            .foregroundColor(AppColors.textSecondary)
                    }
                    .card()
                }

                // クエスト一覧
                ForEach(quests) { quest in
                    QuestCardView(
                        quest: quest,
                        log: logForQuest(quest),
                        isMorningBonus: isMorningBonus, isPastBedtime: isPastBedtime,
                        onComplete: { stars, count in
                            completeOne(quest: quest, stars: stars, count: count)
                        },
                        onUndo: {
                            undoOne(quest: quest)
                        }
                    )
                }

                // エクストラクエスト（対象クエストが完了したら表示）
                let allDone = total > 0 && completed >= total
                let extraQuests = quests.filter { quest in
                    guard quest.allowExtra else { return false }
                    let log = logForQuest(quest)
                    let questTarget: Int
                    switch quest.questType {
                    case .page: questTarget = quest.totalPages
                    case .time: questTarget = quest.targetMinutes
                    case .count, .stopwatch: questTarget = quest.dailyCount
                    }
                    return (log?.completedCount ?? 0) >= questTarget
                }

                if !extraQuests.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text(L10n.current == .ja ? "🌟 エクストラクエスト！" : "🌟 Extra Quests!")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(AppColors.bonus)
                            Spacer()
                            if allDone && !isPastBedtime {
                                Text(L10n.current == .ja ? "⭐×3 ボーナス！" : "⭐×3 Bonus!")
                                    .font(.system(size: 12, weight: .bold))
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Capsule().fill(AppColors.bonus.opacity(0.2)))
                                    .foregroundColor(AppColors.bonus)
                            }
                        }
                        ForEach(extraQuests) { quest in
                            QuestCardView(
                                quest: quest,
                                log: logForQuest(quest),
                                isMorningBonus: isMorningBonus, isPastBedtime: isPastBedtime,
                                isExtra: true,
                                extraMultiplier: (allDone && !isPastBedtime) ? 3 : 1,
                                onComplete: { stars, count in completeOne(quest: quest, stars: stars, count: count) },
                                onUndo: { undoOne(quest: quest) }
                            )
                        }
                    }
                }

                // 全クリア
                if allDone {
                    VStack(spacing: 8) {
                        Text("🏆").font(.system(size: 48))
                        Text("ALL CLEAR!")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(AppColors.star)
                        Text(L10n.allClear)
                            .font(.system(size: 14))
                            .foregroundColor(AppColors.textSecondary)
                    }
                    .frame(maxWidth: .infinity)
                    .card()
                }
            }
            .padding(.horizontal)
            .padding(.bottom, 20)
        }
        .onAppear { updateTimeFlags() }
    }

    private func completeOne(quest: Quest, stars: Int, count: Int = 1) {
        let increment = quest.isTimeType ? count : 1
        if let log = logForQuest(quest) {
            if !quest.allowExtra {
                let target = quest.isPageType ? quest.totalPages : (quest.isTimeType ? quest.targetMinutes : quest.dailyCount)
                guard log.completedCount < target else { return }
            }
            log.completedCount += increment
            log.earnedStars += stars
            log.starHistory.append(stars)
        } else {
            let log = QuestLog(questName: quest.name, date: today, completedCount: increment, earnedStars: stars, starHistory: [stars])
            modelContext.insert(log)
        }
        totalStars += stars
        try? modelContext.save()
    }

    private func undoOne(quest: Quest) {
        guard let log = logForQuest(quest), log.completedCount > 0 else { return }
        let starsToRemove = log.starHistory.last ?? 0
        log.completedCount -= 1
        log.earnedStars = max(0, log.earnedStars - starsToRemove)
        if !log.starHistory.isEmpty { log.starHistory.removeLast() }
        totalStars = max(0, totalStars - starsToRemove)
        try? modelContext.save()
    }
}

struct QuestCardView: View {
    let quest: Quest
    let log: QuestLog?
    let isMorningBonus: Bool
    var isPastBedtime: Bool = false
    var isExtra: Bool = false
    var extraMultiplier: Int = 1
    let onComplete: (Int, Int) -> Void  // (stars, count)
    let onUndo: () -> Void
    @State private var showTimer = false
    @State private var showStopwatch = false

    private var completed: Int { log?.completedCount ?? 0 }
    private var target: Int {
        switch quest.questType {
        case .page: return quest.totalPages
        case .time: return quest.targetMinutes
        case .count: return quest.dailyCount
        case .stopwatch: return quest.dailyCount
        }
    }
    private var remaining: Int { max(0, target - completed) }
    private var isDone: Bool { isExtra ? false : completed >= target }

    // ページ型: 完了ページ数に応じた按分星
    private var earnedStarsForPage: Int {
        guard quest.isPageType, quest.totalPages > 0 else { return quest.starsPerComplete }
        return max(1, Int(round(Double(quest.starsPerComplete) / Double(quest.totalPages))))
    }

    var body: some View {
        HStack(spacing: 12) {
            Text(quest.icon).font(.system(size: 32))

            VStack(alignment: .leading, spacing: 4) {
                Text(quest.name)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(isDone ? AppColors.textSecondary : AppColors.textPrimary)
                    .strikethrough(isDone)

                if quest.isPageType {
                    // ページ型: プログレスバー
                    VStack(alignment: .leading, spacing: 2) {
                        ProgressView(value: Double(completed), total: Double(target))
                            .tint(isDone ? AppColors.success : AppColors.accent)
                        Text(L10n.pages(completed, target))
                            .font(.system(size: 10))
                            .foregroundColor(AppColors.textSecondary)
                    }
                } else if quest.isTimeType {
                    // 時間型: プログレスバー + 分表示
                    VStack(alignment: .leading, spacing: 2) {
                        ProgressView(value: Double(completed), total: Double(target))
                            .tint(isDone ? AppColors.success : AppColors.accent)
                        Text(L10n.minutes(completed, target))
                            .font(.system(size: 10))
                            .foregroundColor(AppColors.textSecondary)
                    }
                } else {
                    // 回数型: ドット
                    HStack(spacing: 4) {
                        ForEach(0..<quest.dailyCount, id: \.self) { i in
                            Circle()
                                .fill(i < completed ? AppColors.success : AppColors.progressEmpty)
                                .frame(width: 20, height: 20)
                        }
                        if remaining > 0 {
                            Text(L10n.remaining(remaining))
                                .font(.system(size: 10))
                                .foregroundColor(AppColors.textSecondary)
                        }
                    }
                }
            }

            Spacer()

            // 完了ボタン
            if !isDone {
                if quest.isStopwatch {
                    Button { showStopwatch = true } label: {
                        VStack(spacing: 2) {
                            Image(systemName: "stopwatch").font(.system(size: 28))
                            Text(L10n.current == .ja ? "計測" : "Time")
                                .font(.system(size: 10, weight: .bold))
                        }
                        .foregroundColor(AppColors.bonus)
                    }
                    .buttonStyle(.plain)
                } else if quest.isTimeType {
                    // 時間型: タイマー起動
                    Button {
                        showTimer = true
                    } label: {
                        VStack(spacing: 2) {
                            Image(systemName: "timer")
                                .font(.system(size: 28))
                            Text(L10n.current == .ja ? "スタート" : "Start")
                                .font(.system(size: 10, weight: .bold))
                        }
                        .foregroundColor(AppColors.accent)
                    }
                    .buttonStyle(.plain)
                } else {
                    // 回数型・ページ型: 即完了
                    Button {
                        let baseStars = quest.isPageType ? earnedStarsForPage : quest.starsPerComplete
                        let stars = baseStars * (isMorningBonus ? 2 : 1) * extraMultiplier
                        onComplete(isPastBedtime ? 1 : stars, 1)
                    } label: {
                        VStack(spacing: 2) {
                            Image(systemName: quest.isPageType ? "plus.circle.fill" : "checkmark.circle.fill")
                                .font(.system(size: 28))
                            let baseStars = quest.isPageType ? earnedStarsForPage : quest.starsPerComplete
                            let displayStars = isPastBedtime ? 1 : (baseStars * (isMorningBonus ? 2 : 1) * extraMultiplier)
                            Text("⭐+\(displayStars)")
                                .font(.system(size: 10, weight: .bold))
                        }
                        .foregroundColor(AppColors.success)
                    }
                    .buttonStyle(.plain)
                }
            } else {
                Text("✅")
                    .font(.system(size: 28))
            }
        }
        .card()
        .opacity(isDone ? 0.7 : 1.0)
        .simultaneousGesture(
            LongPressGesture(minimumDuration: 0.5).onEnded { _ in
                if completed > 0 { onUndo() }
            }
        )
        .fullScreenCover(isPresented: $showTimer) {
            TimerView(
                questName: quest.name,
                questIcon: quest.icon,
                targetMinutes: quest.targetMinutes,
                starsTotal: quest.starsPerComplete
            ) { actualMinutes in
                let fiveMinBlocks = actualMinutes / 5
                let totalBlocks = max(1, quest.targetMinutes / 5)
                let stars = min(quest.starsPerComplete, quest.starsPerComplete * fiveMinBlocks / totalBlocks)
                let finalStars = isPastBedtime ? 1 : (stars * (isMorningBonus ? 2 : 1) * extraMultiplier)
                onComplete(finalStars, actualMinutes)
            }
        }
        .fullScreenCover(isPresented: $showStopwatch) {
            StopwatchView(
                questName: quest.name,
                questIcon: quest.icon,
                starsOnComplete: quest.starsPerComplete
            ) { stars in
                let finalStars = isPastBedtime ? 1 : (stars * (isMorningBonus ? 2 : 1) * extraMultiplier)
                onComplete(finalStars, 1)
            }
        }
    }
}
