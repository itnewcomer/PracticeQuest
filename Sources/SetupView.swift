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
        // サンプル日課
        let quests = [
            Quest(name: "読書", icon: "📖", dailyCount: 1, targetMinutes: 15, starsPerComplete: 20, order: 0),
            Quest(name: "プリント", icon: "📝", dailyCount: 1, totalPages: 15, allowExtra: true, starsPerComplete: 30, order: 1),
            Quest(name: "ピアノ", icon: "🎹", dailyCount: 5, starsPerComplete: 6, order: 2),
            Quest(name: "英単語", icon: "📖", dailyCount: 1, starsPerComplete: 10, order: 3),
            Quest(name: "100ます計算", icon: "🧮", dailyCount: 1, isStopwatch: true, allowExtra: true, starsPerComplete: 5, order: 4),
        ]
        quests.forEach { modelContext.insert($0) }

        // サンプル習い事
        let lessons = [
            Lesson(name: "バレエ", icon: "🩰", weekday: 2, startHour: 16),
            Lesson(name: "水泳", icon: "🏊", weekday: 3, startHour: 15, startMinute: 30),
            Lesson(name: "水泳", icon: "🏊", weekday: 3, startHour: 17),
            Lesson(name: "テコンドー", icon: "🥋", weekday: 4, startHour: 16),
            Lesson(name: "チアリーディング", icon: "📣", weekday: 5, startHour: 16),
            Lesson(name: "Art", icon: "🎨", weekday: 6, startHour: 15, startMinute: 30),
            Lesson(name: "ピアノ教室", icon: "🎹", weekday: 7, startHour: 10),
        ]
        lessons.forEach { modelContext.insert($0) }

        // サンプルごほうび
        let rewards = [
            Reward(name: "YouTube 15分", icon: "📱", starCost: 30, isTimeBased: true, durationMinutes: 15),
            Reward(name: "ゲーム 15分", icon: "🎮", starCost: 30, isTimeBased: true, durationMinutes: 15),
            Reward(name: "アイス", icon: "🍦", starCost: 500),
            Reward(name: "おもちゃ", icon: "🧸", starCost: 2500),
            Reward(name: "遊園地", icon: "🎢", starCost: 7500),
        ]
        rewards.forEach { modelContext.insert($0) }

        try? modelContext.save()
    }
}
