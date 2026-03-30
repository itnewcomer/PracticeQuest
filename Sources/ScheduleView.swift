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
        lessons.filter { $0.weekday == selectedWeekday }.sorted { $0.startHour < $1.startHour }
    }

    private var freeMinutes: Int {
        let bedtime = bedtimeHour * 60 + bedtimeMin
        let dayStart: Int
        if isSchoolDay {
            dayStart = schoolEndHour * 60 + schoolEndMin
        } else {
            // 休日は朝7時から
            dayStart = 7 * 60
        }
        let totalAvailable = bedtime - dayStart
        let lessonMinutes = lessonsForDay.reduce(0) { $0 + $1.durationMinutes }
        return max(0, totalAvailable - lessonMinutes)
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

                // タイムライン
                VStack(alignment: .leading, spacing: 0) {
                    // 朝クエスト
                    TimelineItem(time: "7:00", icon: "🌅", title: L10n.morningQuest, color: AppColors.morning, isLesson: false)

                    // 学校（平日のみ）
                    if isSchoolDay {
                        TimelineItem(time: String(format: "%d:%02d", schoolStartHour, schoolStartMin), icon: "🏫", title: L10n.school, color: AppColors.textSecondary, isLesson: false)
                    }

                    // 習い事
                    ForEach(lessonsForDay) { lesson in
                        TimelineItem(time: lesson.timeString, icon: lesson.icon, title: lesson.name, color: AppColors.accent, isLesson: true)
                    }

                    if lessonsForDay.isEmpty {
                        TimelineItem(time: "", icon: "🎉", title: L10n.noLessons, color: AppColors.success, isLesson: false)
                    }

                    // おうちクエスト
                    TimelineItem(time: "", icon: "🏠", title: L10n.homeQuest, color: AppColors.afternoon, isLesson: false)

                    // 就寝
                    TimelineItem(time: String(format: "%d:%02d", bedtimeHour, bedtimeMin), icon: "🌙", title: L10n.goodnight, color: AppColors.evening, isLesson: false)
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
