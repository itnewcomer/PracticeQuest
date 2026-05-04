import SwiftUI
import SwiftData
import UserNotifications

@main
struct PracticeQuestApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Quest.self,
            QuestLog.self,
            Lesson.self,
            Reward.self,
            StopwatchRecord.self,
        ])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        do {
            return try ModelContainer(for: schema, configurations: [config])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(sharedModelContainer)
    }
}

// 通知許可を必要なタイミング（タイマー初回起動時など）でリクエストするヘルパ。
// 起動直後にダイアログを出さず、ユーザーが通知の必要性を理解できる文脈で求める。
enum NotificationPermission {
    static func requestIfNeeded() {
        let center = UNUserNotificationCenter.current()
        center.getNotificationSettings { settings in
            guard settings.authorizationStatus == .notDetermined else { return }
            center.requestAuthorization(options: [.alert, .sound, .badge]) { _, _ in }
        }
    }
}
