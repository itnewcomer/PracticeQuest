import SwiftUI
import SwiftData

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
            // マイグレーション失敗時: ストアを削除して再作成
            let url = config.url
            try? FileManager.default.removeItem(at: url)
            do {
                return try ModelContainer(for: schema, configurations: [config])
            } catch {
                fatalError("Could not create ModelContainer: \(error)")
            }
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(sharedModelContainer)
    }
}
