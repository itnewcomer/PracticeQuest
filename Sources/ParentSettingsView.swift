import SwiftUI
import SwiftData

struct ParentSettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \Quest.order) private var quests: [Quest]
    @Query(sort: \Lesson.startHour) private var lessons: [Lesson]
    @Query(sort: \Reward.starCost) private var rewards: [Reward]

    @State private var showAddQuest = false
    @State private var showAddLesson = false
    @State private var showAddReward = false
    @AppStorage("schoolStartHour") private var schoolStartHour = 9
    @AppStorage("schoolStartMin") private var schoolStartMin = 0
    @AppStorage("schoolEndHour") private var schoolEndHour = 15
    @AppStorage("schoolEndMin") private var schoolEndMin = 15
    @AppStorage("bedtimeHour") private var bedtimeHour = 20
    @AppStorage("bedtimeMin") private var bedtimeMin = 30
    @State private var schoolDays: [Int] = UserDefaults.standard.array(forKey: "schoolDays") as? [Int] ?? [2,3,4,5,6]
    @AppStorage("appLanguage") private var appLanguage = "ja"

    var body: some View {
        NavigationStack {
            List {
                // 日課
                Section("📋 " + (L10n.current == .ja ? "日課" : "Quests")) {
                    ForEach(quests) { quest in
                        NavigationLink {
                            EditQuestView(quest: quest)
                        } label: {
                            HStack {
                                Text(quest.icon)
                                Text(quest.name)
                                Spacer()
                                if quest.isStopwatch {
                                    Text("⏱").font(.system(size: 11))
                                } else if quest.isPageType {
                                    Text("\(quest.totalPages)p").font(.system(size: 11)).foregroundColor(.secondary)
                                } else if quest.isTimeType {
                                    Text("\(quest.targetMinutes)m").font(.system(size: 11)).foregroundColor(.secondary)
                                } else {
                                    Text("×\(quest.dailyCount)").font(.system(size: 11)).foregroundColor(.secondary)
                                }
                                if quest.allowExtra {
                                    Text("🌟").font(.system(size: 11))
                                }
                                Text("⭐\(quest.starsPerComplete)").font(.system(size: 11)).foregroundColor(AppColors.star)
                            }
                        }
                    }
                    .onDelete { indexSet in
                        for i in indexSet { modelContext.delete(quests[i]) }
                        try? modelContext.save()
                    }
                    Button("+ " + L10n.addQuest) { showAddQuest = true }
                }

                // 習い事
                Section("🎓 " + (L10n.current == .ja ? "習い事" : "Lessons")) {
                    let weekdayNames = L10n.weekdays
                    ForEach(lessons) { lesson in
                        NavigationLink {
                            EditLessonView(lesson: lesson)
                        } label: {
                            HStack {
                                Text(lesson.icon)
                                Text(lesson.name)
                                Spacer()
                                Text(weekdayNames[lesson.weekday - 1])
                                    .foregroundColor(.secondary)
                                Text(lesson.timeString)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .onDelete { indexSet in
                        for i in indexSet { modelContext.delete(lessons[i]) }
                        try? modelContext.save()
                    }
                    Button("+ " + L10n.addLesson) { showAddLesson = true }
                }

                // ごほうび
                Section("🎁 " + (L10n.current == .ja ? "ごほうび" : "Rewards")) {
                    ForEach(rewards) { reward in
                        NavigationLink {
                            EditRewardView(reward: reward)
                        } label: {
                            HStack {
                                Text(reward.icon)
                                Text(reward.name)
                                Spacer()
                                if reward.isTimeBased {
                                    Text("⏱\(reward.durationMinutes)m").font(.system(size: 11)).foregroundColor(.secondary)
                                }
                                Text("⭐\(reward.starCost)")
                                    .foregroundColor(AppColors.star)
                            }
                        }
                    }
                    .onDelete { indexSet in
                        for i in indexSet { modelContext.delete(rewards[i]) }
                        try? modelContext.save()
                    }
                    Button("+ " + (L10n.current == .ja ? "ごほうびを追加" : "Add Reward")) { showAddReward = true }

                    // 1日の星の目安
                    let normalStars = quests.reduce(0) { total, quest in
                        switch quest.questType {
                        case .page: return total + quest.starsPerComplete
                        case .time: return total + quest.starsPerComplete
                        case .count: return total + quest.starsPerComplete * quest.dailyCount
                        case .stopwatch: return total + quest.starsPerComplete
                        }
                    }
                    HStack {
                        Text(L10n.current == .ja ? "📊 1日のめやす" : "📊 Daily estimate")
                            .font(.system(size: 12))
                            .foregroundColor(AppColors.textSecondary)
                        Spacer()
                        Text("⭐\(normalStars)")
                            .font(.system(size: 12))
                            .foregroundColor(AppColors.star)
                        Text(L10n.current == .ja ? "（朝⭐\(normalStars * 2)）" : "(AM ⭐\(normalStars * 2))")
                            .font(.system(size: 11))
                            .foregroundColor(AppColors.morning)
                    }
                }

                // 時間設定（一番下）
                Section(L10n.current == .ja ? "⏰ 時間設定" : "⏰ Time Settings") {
                    HStack {
                        Text(L10n.current == .ja ? "学校の曜日" : "School days")
                        Spacer()
                        let days = L10n.weekdays
                        ForEach(1...7, id: \.self) { d in
                            let isOn = schoolDays.contains(d)
                            Button {
                                if isOn {
                                    schoolDays.removeAll(where: { $0 == d })
                                } else {
                                    schoolDays.append(d)
                                }
                                UserDefaults.standard.set(schoolDays, forKey: "schoolDays")
                            } label: {
                                Text(days[d-1])
                                    .font(.system(size: 11, weight: isOn ? .bold : .regular))
                                    .foregroundColor(isOn ? AppColors.accent : AppColors.textSecondary)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    Stepper(L10n.current == .ja ? "登校 \(schoolStartHour):\(String(format: "%02d", schoolStartMin))" : "School start \(schoolStartHour):\(String(format: "%02d", schoolStartMin))", value: $schoolStartMin, in: 0...45, step: 15)
                    Stepper(L10n.current == .ja ? "下校 \(schoolEndHour):\(String(format: "%02d", schoolEndMin))" : "School end \(schoolEndHour):\(String(format: "%02d", schoolEndMin))", value: $schoolEndMin, in: 0...45, step: 15)
                    Stepper(L10n.current == .ja ? "就寝 \(bedtimeHour):\(String(format: "%02d", bedtimeMin))" : "Bedtime \(bedtimeHour):\(String(format: "%02d", bedtimeMin))", value: $bedtimeMin, in: 0...45, step: 15)
                }

                // リセット
                Section {
                    // 言語切り替え
                    Picker(L10n.current == .ja ? "🌐 言語" : "🌐 Language", selection: $appLanguage) {
                        Text("日本語").tag("ja")
                        Text("English").tag("en")
                    }

                    Button(L10n.current == .ja ? "データをリセット" : "Reset Data", role: .destructive) {
                        quests.forEach { modelContext.delete($0) }
                        lessons.forEach { modelContext.delete($0) }
                        rewards.forEach { modelContext.delete($0) }
                        UserDefaults.standard.set(0, forKey: "totalStars")
                        UserDefaults.standard.set(false, forKey: "isSetupDone")
                        try? modelContext.save()
                        dismiss()
                    }
                }
            }
            .navigationTitle(L10n.parentSettings)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(L10n.close) { dismiss() }
                }
            }
            .sheet(isPresented: $showAddQuest) { AddQuestSheet() }
            .sheet(isPresented: $showAddLesson) { AddLessonSheet() }
            .sheet(isPresented: $showAddReward) { AddRewardSheet() }
        }
    }
}

// MARK: - 日課追加
struct AddQuestSheet: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var icon = "⭐"
    @State private var isPageType = false
    @State private var isTimeType = false
    @State private var isStopwatch = false
    @State private var allowExtra = false
    @State private var dailyCount = 1
    @State private var totalPages = 7
    @State private var targetMinutes = 30
    @State private var stars = 1
    @State private var totalStars = 14

    private let icons = ["🎵", "🎹", "📝", "📖", "🏃", "🎨", "🧮", "✏️", "📚", "🎯"]

    var body: some View {
        NavigationStack {
            Form {
                TextField(L10n.name, text: $name)
                Picker(L10n.icon, selection: $icon) {
                    ForEach(icons, id: \.self) { Text($0).tag($0) }
                }
                Toggle(L10n.pageType, isOn: $isPageType)
                    .onChange(of: isPageType) { _, v in if v { isTimeType = false; isStopwatch = false } }
                Toggle(L10n.timeType, isOn: $isTimeType)
                    .onChange(of: isTimeType) { _, v in if v { isPageType = false; isStopwatch = false } }
                Toggle(L10n.current == .ja ? "ストップウォッチ型（タイム計測）" : "Stopwatch (time challenge)", isOn: $isStopwatch)
                    .onChange(of: isStopwatch) { _, v in if v { isPageType = false; isTimeType = false } }

                Toggle(L10n.current == .ja ? "🌟 エクストラクエスト対象" : "🌟 Extra quest eligible", isOn: $allowExtra)

                if isPageType {
                    Stepper(L10n.totalN(totalPages, L10n.current == .ja ? "ページ" : "pages"), value: $totalPages, in: 1...100)
                    Stepper(L10n.totalStarsN(totalStars), value: $totalStars, in: 1...100)
                } else if isTimeType {
                    Stepper(L10n.totalN(targetMinutes, L10n.current == .ja ? "分" : "min"), value: $targetMinutes, in: 5...180, step: 5)
                    Stepper(L10n.totalStarsN(totalStars), value: $totalStars, in: 1...100)
                } else if isStopwatch {
                    Stepper(L10n.starsPerUnit(stars), value: $stars, in: 1...10)
                } else {
                    Stepper(L10n.dailyN(dailyCount), value: $dailyCount, in: 1...20)
                    Stepper(L10n.starsPerUnit(stars), value: $stars, in: 1...5)
                }
            }
            .navigationTitle(L10n.addQuest)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) { Button(L10n.cancel) { dismiss() } }
                ToolbarItem(placement: .topBarTrailing) {
                    Button(L10n.add) {
                        guard !name.isEmpty else { return }
                        let quest = Quest(
                            name: name,
                            icon: icon,
                            dailyCount: (isPageType || isTimeType) ? 1 : dailyCount,
                            totalPages: isPageType ? totalPages : 0,
                            targetMinutes: isTimeType ? targetMinutes : 0,
                            isStopwatch: isStopwatch,
                            allowExtra: allowExtra,
                            starsPerComplete: (isPageType || isTimeType) ? totalStars : stars
                        )
                        modelContext.insert(quest)
                        try? modelContext.save()
                        dismiss()
                    }
                    .bold()
                }
            }
        }
    }
}

// MARK: - 習い事追加
struct AddLessonSheet: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var icon = "📚"
    @State private var weekday = 2
    @State private var hour = 16
    @State private var minute = 0
    @State private var duration = 60

    private let icons = ["🩰", "🏊", "🥋", "🥁", "📣", "🎨", "🎹", "⚽", "🎾", "📚", "🏀", "⚾", "🧮", "💃", "🎤", "🏃", "🎯", "🧘", "♟️", "🎻", "🪘", "🏸", "⛸️", "🤸", "🏇", "🧗"]
    private let weekdays = L10n.weekdays

    var body: some View {
        NavigationStack {
            Form {
                TextField(L10n.name, text: $name)
                Picker(L10n.icon, selection: $icon) {
                    ForEach(icons, id: \.self) { Text($0).tag($0) }
                }
                Picker(L10n.weekday, selection: $weekday) {
                    ForEach(1...7, id: \.self) { Text(weekdays[$0 - 1]).tag($0) }
                }
                Stepper(L10n.startTime(hour, minute), value: $hour, in: 6...21)
                Stepper(L10n.durationN(duration), value: $duration, in: 30...180, step: 15)
            }
            .navigationTitle(L10n.addLesson)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) { Button(L10n.cancel) { dismiss() } }
                ToolbarItem(placement: .topBarTrailing) {
                    Button(L10n.add) {
                        guard !name.isEmpty else { return }
                        modelContext.insert(Lesson(name: name, icon: icon, weekday: weekday, startHour: hour, startMinute: minute, durationMinutes: duration))
                        try? modelContext.save()
                        dismiss()
                    }
                    .bold()
                }
            }
        }
    }
}

// MARK: - ごほうび追加
struct AddRewardSheet: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var icon = "🎁"
    @State private var starCost = 30
    @State private var isTimeBased = false
    @State private var durationMinutes = 30

    private let icons = ["🍦", "📱", "🎮", "🧸", "🎢", "🍰", "🎬", "👟", "📕", "🎁"]

    var body: some View {
        NavigationStack {
            Form {
                TextField(L10n.current == .ja ? "なまえ" : "Name", text: $name)
                Picker(L10n.current == .ja ? "アイコン" : "Icon", selection: $icon) {
                    ForEach(icons, id: \.self) { Text($0).tag($0) }
                }
                Stepper("⭐ \(starCost)", value: $starCost, in: 5...1000, step: 5)
                Toggle(L10n.current == .ja ? "⏱ 時間で使うごほうび" : "⏱ Time-based reward", isOn: $isTimeBased)
                if isTimeBased {
                    Stepper(L10n.current == .ja ? "\(durationMinutes)分" : "\(durationMinutes) min", value: $durationMinutes, in: 5...180, step: 5)
                }
            }
            .navigationTitle(L10n.current == .ja ? "ごほうびを追加" : "Add Reward")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) { Button(L10n.current == .ja ? "やめる" : "Cancel") { dismiss() } }
                ToolbarItem(placement: .topBarTrailing) {
                    Button(L10n.current == .ja ? "追加" : "Add") {
                        guard !name.isEmpty else { return }
                        modelContext.insert(Reward(name: name, icon: icon, starCost: starCost, isTimeBased: isTimeBased, durationMinutes: isTimeBased ? durationMinutes : 0))
                        try? modelContext.save()
                        dismiss()
                    }
                    .bold()
                }
            }
        }
    }
}
