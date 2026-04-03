import SwiftUI
import SwiftData

struct SetupView: View {
    @Environment(\.modelContext) private var modelContext
    @Binding var isSetupDone: Bool

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                Text("🗡️").font(.system(size: 60))
                Text("おけいこクエスト")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(AppColors.textPrimary)
                Text("まいにちのおけいこを\nたのしいクエストにしよう！")
                    .font(.system(size: 16))
                    .foregroundColor(AppColors.textSecondary)
                    .multilineTextAlignment(.center)

                Divider()

                Text("おうちの人へ：サンプルデータで始めます")
                    .font(.system(size: 13))
                    .foregroundColor(AppColors.textSecondary)

                Button {
                    setupSampleData()
                    isSetupDone = true
                } label: {
                    Text("はじめる！")
                        .font(.system(size: 18, weight: .bold))
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(RoundedRectangle(cornerRadius: 16).fill(AppColors.accent))
                        .foregroundColor(.white)
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 40)
            }
            .padding(32)
        }
        .background(AppColors.background)
    }

    private func setupSampleData() {
        let ja = L10n.current == .ja
        let quests = ja ? [
            Quest(name: "読書", icon: "📖", dailyCount: 1, targetMinutes: 15, starsPerComplete: 20, order: 0),
            Quest(name: "プリント", icon: "📝", dailyCount: 1, totalPages: 15, allowExtra: true, starsPerComplete: 30, order: 1),
            Quest(name: "ピアノ", icon: "🎹", dailyCount: 5, starsPerComplete: 6, order: 2),
            Quest(name: "英単語", icon: "📖", dailyCount: 1, starsPerComplete: 10, order: 3),
            Quest(name: "100ます計算", icon: "🧮", dailyCount: 1, isStopwatch: true, allowExtra: true, starsPerComplete: 5, order: 4),
        ] : [
            Quest(name: "Reading", icon: "📖", dailyCount: 1, targetMinutes: 15, starsPerComplete: 20, order: 0),
            Quest(name: "Worksheet", icon: "📝", dailyCount: 1, totalPages: 15, allowExtra: true, starsPerComplete: 30, order: 1),
            Quest(name: "Piano", icon: "🎹", dailyCount: 5, starsPerComplete: 6, order: 2),
            Quest(name: "Vocabulary", icon: "📖", dailyCount: 1, starsPerComplete: 10, order: 3),
            Quest(name: "Math drill", icon: "🧮", dailyCount: 1, isStopwatch: true, allowExtra: true, starsPerComplete: 5, order: 4),
        ]
        quests.forEach { modelContext.insert($0) }

        let lessons = ja ? [
            Lesson(name: "バレエ", icon: "🩰", weekday: 2, startHour: 16),
            Lesson(name: "水泳", icon: "🏊", weekday: 3, startHour: 15, startMinute: 30),
            Lesson(name: "水泳", icon: "🏊", weekday: 3, startHour: 17),
            Lesson(name: "テコンドー", icon: "🥋", weekday: 4, startHour: 16),
            Lesson(name: "チアリーディング", icon: "📣", weekday: 5, startHour: 16),
            Lesson(name: "アート", icon: "🎨", weekday: 6, startHour: 15, startMinute: 30),
            Lesson(name: "ピアノ教室", icon: "🎹", weekday: 7, startHour: 10),
        ] : [
            Lesson(name: "Ballet", icon: "🩰", weekday: 2, startHour: 16),
            Lesson(name: "Swimming", icon: "🏊", weekday: 3, startHour: 15, startMinute: 30),
            Lesson(name: "Swimming", icon: "🏊", weekday: 3, startHour: 17),
            Lesson(name: "Taekwondo", icon: "🥋", weekday: 4, startHour: 16),
            Lesson(name: "Cheer", icon: "📣", weekday: 5, startHour: 16),
            Lesson(name: "Art", icon: "🎨", weekday: 6, startHour: 15, startMinute: 30),
            Lesson(name: "Piano", icon: "🎹", weekday: 7, startHour: 10),
        ]
        lessons.forEach { modelContext.insert($0) }

        let rewards = ja ? [
            Reward(name: "YouTube 15分", icon: "📱", starCost: 30, isTimeBased: true, durationMinutes: 15),
            Reward(name: "ゲーム 15分", icon: "🎮", starCost: 30, isTimeBased: true, durationMinutes: 15),
            Reward(name: "アイス", icon: "🍦", starCost: 500),
            Reward(name: "おもちゃ", icon: "🧸", starCost: 2500),
            Reward(name: "遊園地", icon: "🎢", starCost: 7500),
        ] : [
            Reward(name: "YouTube 15min", icon: "📱", starCost: 30, isTimeBased: true, durationMinutes: 15),
            Reward(name: "Game 15min", icon: "🎮", starCost: 30, isTimeBased: true, durationMinutes: 15),
            Reward(name: "Ice cream", icon: "🍦", starCost: 500),
            Reward(name: "Toy", icon: "🧸", starCost: 2500),
            Reward(name: "Amusement park", icon: "🎢", starCost: 7500),
        ]
        rewards.forEach { modelContext.insert($0) }

        try? modelContext.save()
    }
}
