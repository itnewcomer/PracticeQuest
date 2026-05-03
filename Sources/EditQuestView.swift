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
                    HStack { Text(L10n.current == .ja ? "📄 合計ページ" : "📄 Total pages"); Spacer(); TextField("7", value: $quest.totalPages, format: .number).keyboardType(.numberPad).multilineTextAlignment(.trailing) }
                } else if quest.isTimeType {
                    Text(L10n.timeType).foregroundColor(.secondary)
                    HStack { Text(L10n.current == .ja ? "⏱ 目標時間（分）" : "⏱ Target (min)"); Spacer(); TextField("30", value: $quest.targetMinutes, format: .number).keyboardType(.numberPad).multilineTextAlignment(.trailing) }
                } else if quest.isStopwatch {
                    Text(L10n.current == .ja ? "ストップウォッチ型" : "Stopwatch type").foregroundColor(.secondary)
                } else {
                    Stepper(L10n.dailyN(quest.dailyCount), value: $quest.dailyCount, in: 1...9999)
                }
            }

            Section(L10n.current == .ja ? "ほうしゅう" : "Rewards") {
                HStack { Text("⭐"); TextField("1", value: $quest.starsPerComplete, format: .number).keyboardType(.numberPad) }
                Toggle(L10n.current == .ja ? "🌟 エクストラクエスト対象" : "🌟 Extra quest eligible", isOn: $quest.allowExtra)
            }
        }
        .navigationTitle(quest.name)
        .onChange(of: quest.name) { _, _ in try? modelContext.save() }
        .onChange(of: quest.icon) { _, _ in try? modelContext.save() }
        .onChange(of: quest.dailyCount) { _, _ in try? modelContext.save() }
        .onChange(of: quest.totalPages) { _, _ in try? modelContext.save() }
        .onChange(of: quest.targetMinutes) { _, _ in try? modelContext.save() }
        .onChange(of: quest.starsPerComplete) { _, _ in try? modelContext.save() }
        .onChange(of: quest.allowExtra) { _, _ in try? modelContext.save() }
        .onDisappear {
            if quest.isPageType, quest.totalPages < 1 { quest.totalPages = 1 }
            if quest.isTimeType, quest.targetMinutes < 1 { quest.targetMinutes = 1 }
            if quest.dailyCount < 1 { quest.dailyCount = 1 }
            if quest.starsPerComplete < 1 { quest.starsPerComplete = 1 }
            try? modelContext.save()
        }
    }
}
