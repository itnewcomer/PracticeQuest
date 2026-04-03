import Foundation
import SwiftData

// 日課（親が設定）
@Model
class Quest {
    var name: String
    var icon: String
    var dailyCount: Int       // 1日の目標回数（回数型）
    var totalPages: Int       // 総ページ数（ページ型、0なら非ページ型）
    var targetMinutes: Int    // 目標分数（時間型、0なら非時間型）
    var isStopwatch: Bool     // ストップウォッチ型（タイム計測）
    var allowExtra: Bool      // エクストラクエスト可能
    var starsPerComplete: Int
    var order: Int

    var isPageType: Bool { totalPages > 0 }
    var isTimeType: Bool { targetMinutes > 0 && !isStopwatch }
    var questType: QuestType {
        if isStopwatch { return .stopwatch }
        if totalPages > 0 { return .page }
        if targetMinutes > 0 { return .time }
        return .count
    }

    enum QuestType { case count, page, time, stopwatch }

    init(name: String, icon: String = "⭐", dailyCount: Int = 1, totalPages: Int = 0, targetMinutes: Int = 0, isStopwatch: Bool = false, allowExtra: Bool = false, starsPerComplete: Int = 1, order: Int = 0) {
        self.name = name
        self.icon = icon
        self.dailyCount = dailyCount
        self.totalPages = totalPages
        self.targetMinutes = targetMinutes
        self.isStopwatch = isStopwatch
        self.allowExtra = allowExtra
        self.starsPerComplete = starsPerComplete
        self.order = order
    }
}

// 日次の完了記録
@Model
class QuestLog {
    var questName: String
    var date: Date
    var completedCount: Int
    var earnedStars: Int
    var bonusStars: Int  // 後方互換のため残す（常に0）
    var starHistory: [Int]  // 完了ごとの獲得星数履歴（UNDOに使用）

    init(questName: String, date: Date, completedCount: Int = 0, earnedStars: Int = 0, bonusStars: Int = 0, starHistory: [Int] = []) {
        self.questName = questName
        self.date = date
        self.completedCount = completedCount
        self.earnedStars = earnedStars
        self.bonusStars = bonusStars
        self.starHistory = starHistory
    }
}

// 習い事スケジュール
@Model
class Lesson {
    var name: String
    var icon: String
    var weekday: Int      // 1=日, 2=月, ... 7=土
    var startHour: Int
    var startMinute: Int
    var durationMinutes: Int

    init(name: String, icon: String = "📚", weekday: Int, startHour: Int, startMinute: Int = 0, durationMinutes: Int = 60) {
        self.name = name
        self.icon = icon
        self.weekday = weekday
        self.startHour = startHour
        self.startMinute = startMinute
        self.durationMinutes = durationMinutes
    }

    var timeString: String {
        String(format: "%d:%02d", startHour, startMinute)
    }
}

// ストップウォッチ記録
@Model
class StopwatchRecord {
    var questName: String
    var date: Date
    var seconds: Int  // かかった秒数

    init(questName: String, date: Date = Date(), seconds: Int) {
        self.questName = questName
        self.date = date
        self.seconds = seconds
    }
}

// ごほうび
@Model
class Reward {
    var name: String
    var icon: String
    var starCost: Int
    var isTimeBased: Bool
    var durationMinutes: Int
    var stockCount: Int
    var remainingSeconds: Int  // 時間系: 残り秒数（途中停止対応）

    init(name: String, icon: String = "🎁", starCost: Int, isTimeBased: Bool = false, durationMinutes: Int = 0, stockCount: Int = 0, remainingSeconds: Int = 0) {
        self.name = name
        self.icon = icon
        self.starCost = starCost
        self.isTimeBased = isTimeBased
        self.durationMinutes = durationMinutes
        self.stockCount = stockCount
        self.remainingSeconds = remainingSeconds
    }

    // 購入時: 残り時間を加算
    func purchase() {
        remainingSeconds += durationMinutes * 60
    }

    // 使用後: 残り時間を更新
    func consumeTime(_ usedSeconds: Int) {
        remainingSeconds = max(0, remainingSeconds - usedSeconds)
    }

    var remainingMinutes: Int { remainingSeconds / 60 }
    var hasTimeLeft: Bool { remainingSeconds > 0 }
}
