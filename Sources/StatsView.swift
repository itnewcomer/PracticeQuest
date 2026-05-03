import SwiftUI
import SwiftData
import Charts

struct StatsView: View {
    @Query private var logs: [QuestLog]
    @Query(sort: \Quest.order) private var quests: [Quest]
    @Query(sort: \StopwatchRecord.date) private var stopwatchRecords: [StopwatchRecord]

    private let calendar = Calendar.current
    private var weekdayNames: [String] { L10n.weekdays }

    // 今週の日別星数
    private var weeklyStars: [(day: String, stars: Int)] {
        let today = calendar.startOfDay(for: Date())
        let weekday = calendar.component(.weekday, from: today)
        let startOfWeek = calendar.date(byAdding: .day, value: -(weekday - 1), to: today)!

        return (0..<7).map { offset in
            let date = calendar.date(byAdding: .day, value: offset, to: startOfWeek)!
            let dayLogs = logs.filter { calendar.isDate($0.date, inSameDayAs: date) }
            let stars = dayLogs.reduce(0) { $0 + $1.earnedStars + $1.bonusStars }
            let dayName = weekdayNames[offset]
            return (day: dayName, stars: stars)
        }
    }

    // 今週の日別完了数
    private var weeklyData: [(day: String, count: Int)] {
        let today = calendar.startOfDay(for: Date())
        let weekday = calendar.component(.weekday, from: today)
        let startOfWeek = calendar.date(byAdding: .day, value: -(weekday - 1), to: today)!

        return (0..<7).map { offset in
            let date = calendar.date(byAdding: .day, value: offset, to: startOfWeek)!
            let dayLogs = logs.filter { calendar.isDate($0.date, inSameDayAs: date) }
            let count = dayLogs.reduce(0) { $0 + $1.completedCount }
            let dayName = weekdayNames[offset]
            return (day: dayName, count: count)
        }
    }

    // 今週の合計
    private var weekTotal: Int {
        weeklyData.reduce(0) { $0 + $1.count }
    }

    // 累計星
    private var totalEarnedStars: Int {
        logs.reduce(0) { $0 + $1.earnedStars + $1.bonusStars }
    }

    // 累計完了数
    private var totalCompleted: Int {
        logs.reduce(0) { $0 + $1.completedCount }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                // 累計
                HStack(spacing: 20) {
                    StatBadge(icon: "⭐", value: "\(totalEarnedStars)", label: "\(L10n.earnedStars)")
                    StatBadge(icon: "✅", value: "\(totalCompleted)", label: "\(L10n.clearCount)")
                    StatBadge(icon: "📅", value: "\(logs.map(\.date).uniqueDays)", label: "\(L10n.recordDays)")
                }
                .card()

                // 今週のグラフ
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("📊 " + L10n.weeklyEffort)
                            .font(.system(size: 14, weight: .semibold))
                        Spacer()
                        Text(L10n.totalCount(weekTotal))
                            .font(.system(size: 12))
                            .foregroundColor(AppColors.textSecondary)
                    }

                    Chart {
                        ForEach(weeklyData, id: \.day) { item in
                            BarMark(
                                x: .value("day", item.day),
                                y: .value("count", item.count)
                            )
                            .foregroundStyle(item.count > 0 ? AppColors.success : AppColors.progressEmpty)
                            .cornerRadius(4)
                        }
                        ForEach(weeklyStars, id: \.day) { item in
                            LineMark(
                                x: .value("day", item.day),
                                y: .value("⭐", item.stars)
                            )
                            .foregroundStyle(AppColors.star)
                            PointMark(
                                x: .value("day", item.day),
                                y: .value("⭐", item.stars)
                            )
                            .foregroundStyle(AppColors.star)
                            .symbolSize(30)
                        }
                    }
                    .chartYAxis {
                        AxisMarks(position: .leading) { value in
                            AxisValueLabel {
                                if let v = value.as(Int.self) {
                                    Text("\(v)").font(.system(size: 10))
                                }
                            }
                        }
                    }
                    .frame(height: 160)
                }
                .card()

                // マイルストーン（挫折しやすいタイミングに配置 — Lally 2010ベース）
                VStack(alignment: .leading, spacing: 8) {
                    Text("🗓️ " + (L10n.current == .ja ? "つづけた日" : "Days practiced"))
                        .font(.system(size: 14, weight: .semibold))

                    let days = logs.map(\.date).uniqueDays
                    MilestoneRow(icon: "🌱", title: L10n.current == .ja ? "はじめの一歩" : "First step", target: 1, current: days)
                    MilestoneRow(icon: "💪", title: L10n.current == .ja ? "3日！" : "3 days!", target: 3, current: days)
                    MilestoneRow(icon: "🔥", title: L10n.current == .ja ? "1週間！" : "1 week!", target: 7, current: days)
                    MilestoneRow(icon: "⭐", title: L10n.current == .ja ? "3週間！" : "3 weeks!", target: 21, current: days)
                    MilestoneRow(icon: "💎", title: L10n.current == .ja ? "66日！習慣化" : "66 days! Habit!", target: 66, current: days)
                    MilestoneRow(icon: "👑", title: L10n.current == .ja ? "1年！" : "1 year!", target: 365, current: days)
                    MilestoneRow(icon: "🌟", title: L10n.current == .ja ? "3年！伝説" : "3 years! Legend!", target: 1095, current: days)
                }
                .card()

                VStack(alignment: .leading, spacing: 8) {
                    Text("🏆 " + (L10n.current == .ja ? "ALL CLEARした日" : "All Clear days"))
                        .font(.system(size: 14, weight: .semibold))

                    let allClearDays = countAllClearDays()
                    MilestoneRow(icon: "🌱", title: L10n.current == .ja ? "はじめてのALL CLEAR" : "First All Clear", target: 1, current: allClearDays)
                    MilestoneRow(icon: "💪", title: L10n.current == .ja ? "3日！" : "3 days!", target: 3, current: allClearDays)
                    MilestoneRow(icon: "🔥", title: L10n.current == .ja ? "1週間！" : "1 week!", target: 7, current: allClearDays)
                    MilestoneRow(icon: "⭐", title: L10n.current == .ja ? "3週間！" : "3 weeks!", target: 21, current: allClearDays)
                    MilestoneRow(icon: "🏆", title: L10n.current == .ja ? "66日！完璧な習慣" : "66 days! Perfect habit!", target: 66, current: allClearDays)
                    MilestoneRow(icon: "👑", title: L10n.current == .ja ? "1年！" : "1 year!", target: 365, current: allClearDays)
                    MilestoneRow(icon: "🌟", title: L10n.current == .ja ? "3年！究極のクエスター" : "3 years! Ultimate!", target: 1095, current: allClearDays)
                }
                .card()

                // ストップウォッチ記録
                let swGroups = Dictionary(grouping: stopwatchRecords, by: \.questName)
                ForEach(Array(swGroups.keys.sorted()), id: \.self) { name in
                    StopwatchChartView(name: name, records: Array(swGroups[name]!.suffix(14)))
                }
            }
            .padding(.horizontal)
            .padding(.bottom, 20)
        }
    }

    private func countAllClearDays() -> Int {
        guard !quests.isEmpty else { return 0 }
        let grouped = Dictionary(grouping: logs, by: { calendar.startOfDay(for: $0.date) })
        var count = 0
        for (_, dayLogs) in grouped {
            let logsByName = Dictionary(uniqueKeysWithValues: dayLogs.map { ($0.questName, $0) })
            let allDone = quests.allSatisfy { quest in
                guard let log = logsByName[quest.name] else { return false }
                let target: Int
                switch quest.questType {
                case .page: target = quest.totalPages
                case .time: target = quest.targetMinutes
                case .count, .stopwatch: target = quest.dailyCount
                }
                return log.completedCount >= target
            }
            if allDone { count += 1 }
        }
        return count
    }
}

private struct StatBadge: View {
    let icon: String
    let value: String
    let label: String

    var body: some View {
        VStack(spacing: 4) {
            Text(icon).font(.system(size: 20))
            Text(value).font(.system(size: 18, weight: .bold)).foregroundColor(AppColors.textPrimary)
            Text(label).font(.system(size: 10)).foregroundColor(AppColors.textSecondary)
        }
        .frame(maxWidth: .infinity)
    }
}

private struct MilestoneRow: View {
    let icon: String
    let title: String
    let target: Int
    let current: Int

    private var achieved: Bool { current >= target }

    var body: some View {
        HStack {
            Text(icon)
            Text(title).font(.system(size: 13))
                .foregroundColor(achieved ? AppColors.textPrimary : AppColors.textSecondary)
            Spacer()
            if achieved {
                Text(L10n.achieved).font(.system(size: 11, weight: .bold)).foregroundColor(AppColors.success)
            } else {
                Text("\(current)/\(target)").font(.system(size: 11)).foregroundColor(AppColors.textSecondary)
            }
        }
    }
}

private struct StopwatchChartView: View {
    let name: String
    let records: [StopwatchRecord]
    @State private var selectedX: Int? = nil

    private var selectedRecord: StopwatchRecord? {
        guard let x = selectedX, x >= 1, x <= records.count else { return nil }
        return records[x - 1]
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top) {
                Text("⏱ \(name)")
                    .font(.system(size: 14, weight: .semibold))
                Spacer()
                if let r = selectedRecord {
                    VStack(alignment: .trailing, spacing: 1) {
                        Text(formatSW(r.seconds))
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(AppColors.accent)
                        Text(r.date, style: .date)
                            .font(.system(size: 10))
                            .foregroundColor(AppColors.textSecondary)
                    }
                } else if let best = records.min(by: { $0.seconds < $1.seconds }) {
                    Text(L10n.current == .ja ? "ベスト: \(formatSW(best.seconds))" : "Best: \(formatSW(best.seconds))")
                        .font(.system(size: 12))
                        .foregroundColor(AppColors.bonus)
                }
            }

            Chart(Array(records.enumerated()), id: \.offset) { idx, record in
                LineMark(x: .value("#", idx + 1), y: .value("sec", record.seconds))
                    .foregroundStyle(AppColors.accent)
                PointMark(x: .value("#", idx + 1), y: .value("sec", record.seconds))
                    .foregroundStyle(selectedX == idx + 1 ? AppColors.bonus : AppColors.accent)
                    .symbolSize(selectedX == idx + 1 ? 80 : 30)
            }
            .chartXSelection(value: $selectedX)
            .chartYAxis {
                AxisMarks(position: .leading) { value in
                    AxisValueLabel {
                        if let v = value.as(Int.self) { Text(formatSW(v)).font(.system(size: 9)) }
                    }
                }
            }
            .frame(height: 120)
        }
        .card()
    }

    private func formatSW(_ s: Int) -> String {
        String(format: "%d:%02d", s / 60, s % 60)
    }
}

extension Array where Element == Date {
    var uniqueDays: Int {
        Set(self.map { Calendar.current.startOfDay(for: $0) }).count
    }
}
