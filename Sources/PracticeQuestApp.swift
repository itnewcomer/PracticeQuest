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
                .task {
                    UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { _, _ in }
                }
        }
        .modelContainer(sharedModelContainer)
    }
}
