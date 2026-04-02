import SwiftUI
import SwiftData

struct ScheduleView: View {
    @Query(sort: \Lesson.startHour) private var lessons: [Lesson]
    @Query(sort: \Quest.order) private var quests: [Quest]

    private let calendar = Calendar.current
    private var weekdayNames: [String] { L10n.weekdays }
    private let todayWeekday = Calendar.current.component(.weekday, from: Date())

    @State private var selectedWeekday: Int = Calendar.current.component(.weekday, from: Date())

    private var schoolDays: [Int] {
        UserDefaults.standard.array(forKey: "schoolDays") as? [Int] ?? [2,3,4,5,6]
    }
    private var schoolStartHour: Int { UserDefaults.standard.object(forKey: "schoolStartHour") as? Int ?? 9 }
    private var schoolStartMin: Int { UserDefaults.standard.object(forKey: "schoolStartMin") as? Int ?? 0 }
    private var schoolEndHour: Int { UserDefaults.standard.object(forKey: "schoolEndHour") as? Int ?? 15 }
    private var schoolEndMin: Int { UserDefaults.standard.object(forKey: "schoolEndMin") as? Int ?? 15 }
    private var bedtimeHour: Int { UserDefaults.standard.object(forKey: "bedtimeHour") as? Int ?? 20 }
    private var bedtimeMin: Int { UserDefaults.standard.object(forKey: "bedtimeMin") as? Int ?? 30 }

    private var isSchoolDay: Bool { schoolDays.contains(selectedWeekday) }

    private var lessonsForDay: [Lesson] {
        lessons.filter { $0.weekday == selectedWeekday }
            .sorted { $0.startHour * 60 + $0.startMinute < $1.startHour * 60 + $1.startMinute }
    }

    private var freeMinutes: Int {
        let bedtime = bedtimeHour * 60 + bedtimeMin
        let lessonMinutes = lessonsForDay.reduce(0) { $0 + $1.durationMinutes }
        if isSchoolDay {
            let morningAvailable = schoolStartHour * 60 + schoolStartMin - 7 * 60
            let afternoonAvailable = bedtime - (schoolEndHour * 60 + schoolEndMin)
            return max(0, morningAvailable + afternoonAvailable - lessonMinutes)
        } else {
            return max(0, bedtime - 7 * 60 - lessonMinutes)
        }
    }

    // タイムラインを時刻順に並べるための中間データ
    private struct ScheduleEntry {
        let sortMinutes: Int
        let timeLabel: String
        let icon: String
        let title: String
        let color: Color
        let isLesson: Bool
    }

    private var sortedTimeline: [ScheduleEntry] {
        var entries: [ScheduleEntry] = []

        // 朝クエスト (7:00)
        entries.append(ScheduleEntry(sortMinutes: 7 * 60, timeLabel: "7:00", icon: "🌅", title: L10n.morningQuest, color: AppColors.morning, isLesson: false))

        // 学校（平日のみ）: 開始・終了の両方を追加
        if isSchoolDay {
            let startM = schoolStartHour * 60 + schoolStartMin
            entries.append(ScheduleEntry(sortMinutes: startM, timeLabel: String(format: "%d:%02d", schoolStartHour, schoolStartMin), icon: "🏫", title: L10n.school, color: AppColors.textSecondary, isLesson: false))
            let endM = schoolEndHour * 60 + schoolEndMin
            let endLabel = L10n.current == .ja ? "下校" : "School ends"
            entries.append(ScheduleEntry(sortMinutes: endM, timeLabel: String(format: "%d:%02d", schoolEndHour, schoolEndMin), icon: "🏫", title: endLabel, color: AppColors.textSecondary, isLesson: false))
        }

        // 習い事（時刻順）
        for lesson in lessonsForDay {
            let m = lesson.startHour * 60 + lesson.startMinute
            entries.append(ScheduleEntry(sortMinutes: m, timeLabel: lesson.timeString, icon: lesson.icon, title: lesson.name, color: AppColors.accent, isLesson: true))
        }

        entries.sort { $0.sortMinutes < $1.sortMinutes }

        // おうちクエスト・就寝は常に末尾
        entries.append(ScheduleEntry(sortMinutes: Int.max - 1, timeLabel: "", icon: "🏠", title: L10n.homeQuest, color: AppColors.afternoon, isLesson: false))
        entries.append(ScheduleEntry(sortMinutes: Int.max, timeLabel: String(format: "%d:%02d", bedtimeHour, bedtimeMin), icon: "🌙", title: L10n.goodnight, color: AppColors.evening, isLesson: false))

        return entries
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                // 曜日セレクター
                HStack(spacing: 4) {
                    ForEach(1...7, id: \.self) { day in
                        Button {
                            selectedWeekday = day
                        } label: {
                            VStack(spacing: 2) {
                                Text(weekdayNames[day - 1])
                                    .font(.system(size: 12, weight: selectedWeekday == day ? .bold : .regular))
                                if day == todayWeekday {
                                    Circle().fill(AppColors.accent).frame(width: 4, height: 4)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(selectedWeekday == day ? AppColors.accent.opacity(0.15) : Color.clear)
                            )
                            .foregroundColor(selectedWeekday == day ? AppColors.accent : AppColors.textSecondary)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .card()

                // タイムライン（時刻順）
                VStack(alignment: .leading, spacing: 0) {
                    ForEach(Array(sortedTimeline.enumerated()), id: \.offset) { _, entry in
                        TimelineItem(time: entry.timeLabel, icon: entry.icon, title: entry.title, color: entry.color, isLesson: entry.isLesson)
                    }
                    if lessonsForDay.isEmpty {
                        TimelineItem(time: "", icon: "🎉", title: L10n.noLessons, color: AppColors.success, isLesson: false)
                    }
                }
                .card()

                // 空き時間
                HStack {
                    Text("⏰")
                    Text(L10n.freeTimeDisplay(freeMinutes / 60, freeMinutes % 60))
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(freeMinutes < 60 ? AppColors.bonus : AppColors.textPrimary)
                }
                .card()
            }
            .padding(.horizontal)
            .padding(.bottom, 20)
        }
    }
}

private struct TimelineItem: View {
    let time: String
    let icon: String
    let title: String
    let color: Color
    let isLesson: Bool

    var body: some View {
        HStack(spacing: 12) {
            // 時間
            Text(time)
                .font(.system(size: 11, design: .monospaced))
                .foregroundColor(AppColors.textSecondary)
                .frame(width: 40, alignment: .trailing)

            // ライン
            VStack(spacing: 0) {
                Circle().fill(color).frame(width: 10, height: 10)
                Rectangle().fill(color.opacity(0.3)).frame(width: 2, height: 30)
            }

            // 内容
            HStack {
                Text(icon)
                Text(title)
                    .font(.system(size: 14, weight: isLesson ? .semibold : .regular))
                    .foregroundColor(isLesson ? AppColors.textPrimary : AppColors.textSecondary)
            }

            Spacer()
        }
        .padding(.vertical, 2)
    }
}
