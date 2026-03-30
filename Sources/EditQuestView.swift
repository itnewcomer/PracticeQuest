import SwiftUI
import SwiftData

struct EditQuestView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Bindable var quest: Quest

    private let icons = ["🎵", "🎹", "📝", "📖", "🏃", "🎨", "🧮", "✏️", "📚", "🎯", "⏱"]

    var body: some View {
        Form {
            Section(L10n.current == .ja ? "基本" : "Basic") {
                TextField(L10n.name, text: $quest.name)
                Picker(L10n.icon, selection: $quest.icon) {
                    ForEach(icons, id: \.self) { Text($0).tag($0) }
                }
            }

            Section(L10n.current == .ja ? "タイプ" : "Type") {
                if quest.isPageType {
                    Text(L10n.pageType).foregroundColor(.secondary)
                    Stepper(L10n.current == .ja ? "全 \(quest.totalPages) ページ" : "Total \(quest.totalPages) pages", value: $quest.totalPages, in: 1...200)
                } else if quest.isTimeType {
                    Text(L10n.timeType).foregroundColor(.secondary)
                    Stepper(L10n.current == .ja ? "\(quest.targetMinutes) 分" : "\(quest.targetMinutes) min", value: $quest.targetMinutes, in: 5...180, step: 5)
                } else if quest.isStopwatch {
                    Text(L10n.current == .ja ? "ストップウォッチ型" : "Stopwatch type").foregroundColor(.secondary)
                } else {
                    Stepper(L10n.dailyN(quest.dailyCount), value: $quest.dailyCount, in: 1...20)
                }
            }

            Section(L10n.current == .ja ? "ほうしゅう" : "Rewards") {
                Stepper("⭐ \(quest.starsPerComplete)", value: $quest.starsPerComplete, in: 1...100)
                Toggle(L10n.current == .ja ? "🌟 エクストラクエスト対象" : "🌟 Extra quest eligible", isOn: $quest.allowExtra)
            }
        }
        .navigationTitle(quest.name)
        .onChange(of: quest.name) { _, _ in try? modelContext.save() }
        .onChange(of: quest.dailyCount) { _, _ in try? modelContext.save() }
        .onChange(of: quest.totalPages) { _, _ in try? modelContext.save() }
        .onChange(of: quest.targetMinutes) { _, _ in try? modelContext.save() }
        .onChange(of: quest.starsPerComplete) { _, _ in try? modelContext.save() }
        .onChange(of: quest.allowExtra) { _, _ in try? modelContext.save() }
    }
}
