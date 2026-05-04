import Foundation

enum AppLanguage: String, CaseIterable {
    case ja = "ja", en = "en"
    var displayName: String { self == .ja ? "日本語" : "English" }
}

struct L10n {
    static var current: AppLanguage {
        AppLanguage(rawValue: UserDefaults.standard.string(forKey: "appLanguage") ?? "ja") ?? .ja
    }
    static func set(_ lang: AppLanguage) { UserDefaults.standard.set(lang.rawValue, forKey: "appLanguage") }

    // タブ
    static var tabQuest: String { current == .ja ? "クエスト" : "Quests" }
    static var tabSchedule: String { current == .ja ? "スケジュール" : "Schedule" }
    static var tabStats: String { current == .ja ? "きろく" : "Stats" }
    static var tabShop: String { current == .ja ? "ショップ" : "Shop" }

    // クエストボード
    static var todayQuests: String { current == .ja ? "きょうのクエスト" : "Today's Quests" }
    static var morningBonus: String { current == .ja ? "朝ボーナスタイム！⭐×2" : "Morning Bonus! ⭐×2" }
    static var allClear: String { current == .ja ? "きょうのクエスト ぜんぶクリア！" : "All quests cleared!" }
    static func remaining(_ n: Int) -> String { current == .ja ? "あと\(n)回" : "\(n) left" }
    static func pages(_ done: Int, _ total: Int) -> String { current == .ja ? "\(done) / \(total) ページ" : "\(done) / \(total) pages" }
    static func minutes(_ done: Int, _ total: Int) -> String { current == .ja ? "\(done) / \(total) 分" : "\(done) / \(total) min" }

    // スケジュール
    static var morningQuest: String { current == .ja ? "朝クエスト ⭐×2" : "Morning Quest ⭐×2" }
    static var school: String { current == .ja ? "学校" : "School" }
    static var homeQuest: String { current == .ja ? "おうちクエスト" : "Home Quest" }
    static var goodnight: String { current == .ja ? "おやすみ" : "Bedtime" }
    static var noLessons: String { current == .ja ? "きょうは習い事なし！" : "No lessons today!" }
    static func freeTime(_ h: Int, _ m: Int) -> String { current == .ja ? "空き時間: \(h)時間\(m)分" : "Free time: \(h)h \(m)m" }
    static var weekdays: [String] { current == .ja ? ["日", "月", "火", "水", "木", "金", "土"] : ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"] }

    // 統計
    static var earnedStars: String { current == .ja ? "もらった星" : "Stars earned" }
    static var clearCount: String { current == .ja ? "クリア数" : "Cleared" }
    static var recordDays: String { current == .ja ? "記録した日" : "Days logged" }
    static var weeklyEffort: String { current == .ja ? "今週のがんばり" : "This week" }
    static func total(_ n: Int) -> String { current == .ja ? "合計 \(n)個" : "Total \(n)" }
    static var milestones: String { current == .ja ? "マイルストーン" : "Milestones" }
    static var achieved: String { current == .ja ? "達成！" : "Done!" }
    static var firstStep: String { current == .ja ? "はじめの一歩" : "First step" }

    // ショップ
    static var usableStars: String { current == .ja ? "つかえる星" : "Stars available" }
    static var noRewards: String { current == .ja ? "ごほうびがまだないよ" : "No rewards yet" }
    static var askParent: String { current == .ja ? "おうちの人にせっていしてもらおう！" : "Ask your parents to set up rewards!" }
    static var use: String { current == .ja ? "つかう" : "Use" }
    static var useReward: String { current == .ja ? "ごほうびをつかう？" : "Use this reward?" }
    static var cancel: String { current == .ja ? "やめる" : "Cancel" }

    // セットアップ
    static var appTitle: String { current == .ja ? "おけいこクエスト" : "PracticeQuest" }
    static var appSubtitle: String { current == .ja ? "まいにちのおけいこを\nたのしいクエストにしよう！" : "Turn daily practice\ninto fun quests!" }
    static var startButton: String { current == .ja ? "はじめる！" : "Let's go!" }
    static var sampleNote: String { current == .ja ? "おうちの人へ：サンプルデータで始めます" : "For parents: Starting with sample data" }

    // 親設定
    static var parentSettings: String { current == .ja ? "おうちの人のせってい" : "Parent Settings" }
    static var close: String { current == .ja ? "とじる" : "Close" }
    static var addQuest: String { current == .ja ? "日課を追加" : "Add Quest" }
    static var addLesson: String { current == .ja ? "習い事を追加" : "Add Lesson" }
    static var addReward: String { current == .ja ? "ごほうびを追加" : "Add Reward" }
    static var add: String { current == .ja ? "追加" : "Add" }
    static var resetData: String { current == .ja ? "データをリセット" : "Reset Data" }
    static var name: String { current == .ja ? "なまえ" : "Name" }
    static var icon: String { current == .ja ? "アイコン" : "Icon" }
    static var pageType: String { current == .ja ? "ページ型（プリントなど）" : "Page type (workbooks etc.)" }
    static var timeType: String { current == .ja ? "時間型（○分勉強）" : "Time type (study for X min)" }
    static func dailyN(_ n: Int) -> String { current == .ja ? "1日 \(n) 回" : "\(n) times/day" }
    static func totalN(_ n: Int, _ unit: String) -> String { current == .ja ? "全 \(n) \(unit)" : "Total \(n) \(unit)" }
    static func starsPerUnit(_ n: Int) -> String { current == .ja ? "⭐ \(n) 個/回" : "⭐ \(n)/time" }
    static func totalStarsN(_ n: Int) -> String { current == .ja ? "全部で ⭐\(n) 個" : "Total ⭐\(n)" }
    static var language: String { current == .ja ? "言語" : "Language" }
    static var weekday: String { current == .ja ? "曜日" : "Day" }
    static func startTime(_ h: Int, _ m: Int) -> String { String(format: "%d:%02d", h, m) + (current == .ja ? " 開始" : " start") }
    static func durationN(_ n: Int) -> String { current == .ja ? "\(n)分間" : "\(n) min" }
    static func starCostN(_ n: Int) -> String { "⭐ \(n)" }

}
