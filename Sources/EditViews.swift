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
            Stepper("\(lesson.startHour):\(String(format: "%02d", lesson.startMinute))", value: $lesson.startHour, in: 6...21)
            Stepper(String(format: "  %02d", lesson.startMinute) + (L10n.current == .ja ? "分" : " min"), value: $lesson.startMinute, in: 0...45, step: 15)
            Stepper(L10n.current == .ja ? "\(lesson.durationMinutes)分間" : "\(lesson.durationMinutes) min", value: $lesson.durationMinutes, in: 30...180, step: 15)
        }
        .navigationTitle(lesson.name)
        .onChange(of: lesson.name) { _, _ in try? modelContext.save() }
        .onChange(of: lesson.weekday) { _, _ in try? modelContext.save() }
        .onChange(of: lesson.startHour) { _, _ in try? modelContext.save() }
        .onChange(of: lesson.startMinute) { _, _ in try? modelContext.save() }
        .onChange(of: lesson.durationMinutes) { _, _ in try? modelContext.save() }
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
                Stepper(L10n.current == .ja ? "\(reward.durationMinutes)分" : "\(reward.durationMinutes) min", value: $reward.durationMinutes, in: 5...180, step: 5)
            }
        }
        .navigationTitle(reward.name)
        .onChange(of: reward.name) { _, _ in try? modelContext.save() }
        .onChange(of: reward.starCost) { _, _ in try? modelContext.save() }
        .onChange(of: reward.durationMinutes) { _, _ in try? modelContext.save() }
    }
}
