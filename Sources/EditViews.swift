import SwiftUI
import SwiftData

struct EditLessonView: View {
    @Environment(\.modelContext) private var modelContext
    @Bindable var lesson: Lesson
    private let icons = ["🩰", "🏊", "🥋", "🥁", "📣", "🎨", "🎹", "⚽", "🎾", "📚", "🏀", "⚾", "🧮", "💃", "🎤", "🏃", "🎯", "🧘", "♟️", "🎻", "🪘", "🏸", "⛸️", "🤸", "🏇", "🧗"]

    var body: some View {
        Form {
            TextField(L10n.name, text: $lesson.name)
            Picker(L10n.icon, selection: $lesson.icon) {
                ForEach(icons, id: \.self) { Text($0).tag($0) }
            }
            Picker(L10n.weekday, selection: $lesson.weekday) {
                ForEach(1...7, id: \.self) { Text(L10n.weekdays[$0 - 1]).tag($0) }
            }
            DatePicker(
                L10n.current == .ja ? "開始時刻" : "Start time",
                selection: Binding(
                    get: {
                        Calendar.current.date(
                            bySettingHour: lesson.startHour,
                            minute: lesson.startMinute,
                            second: 0,
                            of: Date()
                        ) ?? Date()
                    },
                    set: { date in
                        lesson.startHour = Calendar.current.component(.hour, from: date)
                        lesson.startMinute = Calendar.current.component(.minute, from: date)
                    }
                ),
                displayedComponents: .hourAndMinute
            )
            HStack { Text(L10n.current == .ja ? "⏱ 時間（分）" : "⏱ Duration (min)"); Spacer(); TextField("60", value: $lesson.durationMinutes, format: .number).keyboardType(.numberPad).multilineTextAlignment(.trailing) }
        }
        .navigationTitle(lesson.name)
        .onChange(of: lesson.name) { _, _ in try? modelContext.save() }
        .onChange(of: lesson.weekday) { _, _ in try? modelContext.save() }
        .onChange(of: lesson.startHour) { _, _ in try? modelContext.save() }
        .onChange(of: lesson.startMinute) { _, _ in try? modelContext.save() }
        .onChange(of: lesson.durationMinutes) { _, _ in try? modelContext.save() }
        .onDisappear {
            if lesson.durationMinutes < 5 { lesson.durationMinutes = 5 }
            try? modelContext.save()
        }
    }
}

struct EditRewardView: View {
    @Environment(\.modelContext) private var modelContext
    @Bindable var reward: Reward
    private let icons = ["🍦", "📱", "🎮", "🧸", "🎢", "🍰", "🎬", "👟", "📕", "🎁"]

    var body: some View {
        Form {
            TextField(L10n.name, text: $reward.name)
            Picker(L10n.icon, selection: $reward.icon) {
                ForEach(icons, id: \.self) { Text($0).tag($0) }
            }
            HStack {
                Text("⭐")
                TextField("500", value: $reward.starCost, format: .number)
                    .keyboardType(.numberPad)
            }
            if reward.isTimeBased {
                HStack { Text(L10n.current == .ja ? "⏱ 時間（分）" : "⏱ Duration (min)"); Spacer(); TextField("30", value: $reward.durationMinutes, format: .number).keyboardType(.numberPad).multilineTextAlignment(.trailing) }
            }
        }
        .navigationTitle(reward.name)
        .onChange(of: reward.name) { _, _ in try? modelContext.save() }
        .onChange(of: reward.starCost) { _, _ in try? modelContext.save() }
        .onChange(of: reward.durationMinutes) { _, _ in try? modelContext.save() }
        .onDisappear {
            if reward.starCost < 1 { reward.starCost = 1 }
            if reward.isTimeBased, reward.durationMinutes < 1 { reward.durationMinutes = 1 }
            try? modelContext.save()
        }
    }
}
