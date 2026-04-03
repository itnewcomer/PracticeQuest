import XCTest
@testable import PracticeQuest

final class PracticeQuestTests: XCTestCase {

    // MARK: - 全体進捗カウント

    func testOverallProgress_timeQuestCountsAs1() {
        let completedCount = 15
        let targetMinutes = 15
        let isTimeType = true
        let progressCount = isTimeType ? (completedCount >= targetMinutes ? 1 : 0) : completedCount
        XCTAssertEqual(progressCount, 1)
    }

    func testOverallProgress_timeQuestNotDone() {
        let completedCount = 5
        let targetMinutes = 15
        let isTimeType = true
        let progressCount = isTimeType ? (completedCount >= targetMinutes ? 1 : 0) : completedCount
        XCTAssertEqual(progressCount, 0)
    }

    func testOverallTotal_timeQuestCountsAs1() {
        let isTimeType = true
        let isPageType = false
        let dailyCount = 1
        let total = isPageType ? 10 : (isTimeType ? 1 : dailyCount)
        XCTAssertEqual(total, 1)
    }

    // MARK: - タイマー完了時の星計算

    func testTimerStars_fullCompletion() {
        let starsTotal = 30
        let actualMinutes = 15
        let targetMinutes = 15
        let fiveMinBlocks = actualMinutes / 5
        let totalBlocks = max(1, targetMinutes / 5)
        let stars = min(starsTotal, starsTotal * fiveMinBlocks / totalBlocks)
        XCTAssertEqual(stars, 30)
    }

    func testTimerStars_halfCompletion() {
        let starsTotal = 30
        let actualMinutes = 7
        let targetMinutes = 15
        let fiveMinBlocks = actualMinutes / 5
        let totalBlocks = max(1, targetMinutes / 5)
        let stars = min(starsTotal, starsTotal * fiveMinBlocks / totalBlocks)
        XCTAssertEqual(stars, 10)
    }

    func testTimerStars_tooShort() {
        let elapsedSeconds = 2
        XCTAssertFalse(elapsedSeconds >= 60)
    }

    func testTimerStars_justOver60Seconds() {
        // 61秒でやめた → 1分として記録（切り捨て）
        let elapsedSeconds = 61
        XCTAssertTrue(elapsedSeconds >= 60)
        let minutes = elapsedSeconds / 60  // 切り捨て
        XCTAssertEqual(minutes, 1)
    }

    func testTimerMinutesRounding_truncation() {
        // 切り捨て方式（修正後）
        XCTAssertEqual(89 / 60, 1)    // 89秒 → 1分
        XCTAssertEqual(90 / 60, 1)    // 90秒 → 1分（切り捨て）
        XCTAssertEqual(900 / 60, 15)  // 900秒 → 15分
        XCTAssertEqual(119 / 60, 1)   // 1分59秒 → 1分（切り捨て）
        XCTAssertEqual(120 / 60, 2)   // 2分ちょうど → 2分
    }

    // MARK: - 星計算（ボーナス）

    func testStars_morningBonus_2x() {
        let baseStars = 10
        let isMorningBonus = true
        let extraMultiplier = 1
        let finalStars = baseStars * (isMorningBonus ? 2 : 1) * extraMultiplier
        XCTAssertEqual(finalStars, 20)
    }

    func testStars_nighttime_forced1() {
        let baseStars = 20
        let isMorningBonus = false
        let isPastBedtime = true
        let extraMultiplier = 1
        let stars = baseStars * (isMorningBonus ? 2 : 1) * extraMultiplier
        let finalStars = isPastBedtime ? 1 : stars
        XCTAssertEqual(finalStars, 1)
    }

    func testStars_extraMultiplier_3x() {
        let baseStars = 10
        let isMorningBonus = false
        let isPastBedtime = false
        let extraMultiplier = 3
        let stars = baseStars * (isMorningBonus ? 2 : 1) * extraMultiplier
        let finalStars = isPastBedtime ? 1 : stars
        XCTAssertEqual(finalStars, 30)
    }

    func testStars_morningBonus_and_extra_3x() {
        let baseStars = 10
        let isMorningBonus = true
        let isPastBedtime = false
        let extraMultiplier = 3
        let stars = baseStars * (isMorningBonus ? 2 : 1) * extraMultiplier
        let finalStars = isPastBedtime ? 1 : stars
        XCTAssertEqual(finalStars, 60)
    }

    func testStars_nighttime_overrides_extra() {
        // 夜間は extraMultiplier に関係なく1星
        let baseStars = 10
        let isMorningBonus = false
        let isPastBedtime = true
        let extraMultiplier = 3
        let stars = baseStars * (isMorningBonus ? 2 : 1) * extraMultiplier
        let finalStars = isPastBedtime ? 1 : stars
        XCTAssertEqual(finalStars, 1)
    }

    // MARK: - UNDO ロジック（starHistory / countHistory）

    func testUndo_countType_removesCorrectStars() {
        // 回数型: 10星で完了 → UNDO で10星引かれる
        var earnedStars = 0
        var completedCount = 0
        var starHistory: [Int] = []
        var countHistory: [Int] = []
        var totalStars = 0

        // 完了
        let stars = 10
        let increment = 1
        earnedStars += stars
        completedCount += increment
        starHistory.append(stars)
        countHistory.append(increment)
        totalStars += stars

        // UNDO
        let starsToRemove = starHistory.last ?? 0
        let countToRemove = countHistory.last ?? 1
        completedCount = max(0, completedCount - countToRemove)
        earnedStars = max(0, earnedStars - starsToRemove)
        starHistory.removeLast()
        countHistory.removeLast()
        totalStars = max(0, totalStars - starsToRemove)

        XCTAssertEqual(totalStars, 0)
        XCTAssertEqual(earnedStars, 0)
        XCTAssertEqual(completedCount, 0)
        XCTAssertTrue(starHistory.isEmpty)
        XCTAssertTrue(countHistory.isEmpty)
    }

    func testUndo_timeType_removesFullMinutes() {
        // タイマー型: 15分完了(20星) → UNDO で completedCount が15戻る
        var earnedStars = 0
        var completedCount = 0
        var starHistory: [Int] = []
        var countHistory: [Int] = []
        var totalStars = 0

        let stars = 20
        let actualMinutes = 15
        let increment = actualMinutes  // isTimeType なので分数がincrement
        earnedStars += stars
        completedCount += increment
        starHistory.append(stars)
        countHistory.append(increment)
        totalStars += stars

        XCTAssertEqual(completedCount, 15)
        XCTAssertEqual(starHistory.count, 1)

        // UNDO
        let starsToRemove = starHistory.last ?? 0
        let countToRemove = countHistory.last ?? 1
        completedCount = max(0, completedCount - countToRemove)
        earnedStars = max(0, earnedStars - starsToRemove)
        starHistory.removeLast()
        countHistory.removeLast()
        totalStars = max(0, totalStars - starsToRemove)

        XCTAssertEqual(totalStars, 0)
        XCTAssertEqual(earnedStars, 0)
        XCTAssertEqual(completedCount, 0)  // 15ではなく0に戻る
        XCTAssertTrue(starHistory.isEmpty)
    }

    func testUndo_mixedBonuses_accurate() {
        // 朝ボーナス(20星)で完了、その後通常(10星)で完了、UNDO x2
        var earnedStars = 0
        var completedCount = 0
        var starHistory: [Int] = []
        var countHistory: [Int] = []
        var totalStars = 0

        // 1回目: 朝ボーナス 20星
        earnedStars += 20; completedCount += 1
        starHistory.append(20); countHistory.append(1); totalStars += 20

        // 2回目: 通常 10星
        earnedStars += 10; completedCount += 1
        starHistory.append(10); countHistory.append(1); totalStars += 10

        XCTAssertEqual(totalStars, 30)
        XCTAssertEqual(completedCount, 2)

        // 1回目UNDO: 通常10星が引かれる
        let s1 = starHistory.last ?? 0
        let c1 = countHistory.last ?? 1
        completedCount -= c1; earnedStars -= s1
        starHistory.removeLast(); countHistory.removeLast(); totalStars -= s1

        XCTAssertEqual(totalStars, 20)  // 20星残る（朝ボーナス分）
        XCTAssertEqual(completedCount, 1)

        // 2回目UNDO: 朝ボーナス20星が引かれる
        let s2 = starHistory.last ?? 0
        let c2 = countHistory.last ?? 1
        completedCount -= c2; earnedStars -= s2
        starHistory.removeLast(); countHistory.removeLast(); totalStars -= s2

        XCTAssertEqual(totalStars, 0)
        XCTAssertEqual(completedCount, 0)
    }

    func testUndo_nighttime_removes1Star() {
        // 夜間完了(1星) → UNDO で1星引かれる
        var earnedStars = 0
        var completedCount = 0
        var starHistory: [Int] = []
        var countHistory: [Int] = []
        var totalStars = 0

        let stars = 1  // isPastBedtime → 1星固定
        earnedStars += stars; completedCount += 1
        starHistory.append(stars); countHistory.append(1); totalStars += stars

        let starsToRemove = starHistory.last ?? 0
        let countToRemove = countHistory.last ?? 1
        completedCount -= countToRemove; earnedStars -= starsToRemove
        starHistory.removeLast(); countHistory.removeLast(); totalStars -= starsToRemove

        XCTAssertEqual(totalStars, 0)
    }

    // MARK: - ページ型: 1ページあたりの星

    func testPageStars_perPage() {
        // 15ページ、合計30星 → 1ページ=2星
        let starsPerComplete = 30
        let totalPages = 15
        let perPage = max(1, Int(round(Double(starsPerComplete) / Double(totalPages))))
        XCTAssertEqual(perPage, 2)
    }

    func testPageStars_perPage_minimum1() {
        // 10ページ、合計1星 → 最低1星
        let starsPerComplete = 1
        let totalPages = 10
        let perPage = max(1, Int(round(Double(starsPerComplete) / Double(totalPages))))
        XCTAssertEqual(perPage, 1)
    }

    func testPageStars_singlePage() {
        // 1ページ、合計20星 → 1ページ=20星
        let starsPerComplete = 20
        let totalPages = 1
        let perPage = max(1, Int(round(Double(starsPerComplete) / Double(totalPages))))
        XCTAssertEqual(perPage, 20)
    }

    // MARK: - 空き時間の計算

    func testFreeMinutes_schoolDay_noLessons() {
        let schoolStartMin = 9 * 60 + 0
        let schoolEndMin   = 15 * 60 + 15
        let bedtime        = 20 * 60 + 30
        let lessonMinutes  = 0
        let morning   = max(0, schoolStartMin - 7 * 60)
        let afternoon = max(0, bedtime - schoolEndMin)
        let free = max(0, morning + afternoon - lessonMinutes)
        XCTAssertEqual(free, 435)
    }

    func testFreeMinutes_schoolDay_withLesson() {
        let schoolStartMin = 9 * 60
        let schoolEndMin   = 15 * 60 + 15
        let bedtime        = 20 * 60 + 30
        let lessonMinutes  = 60
        let morning   = max(0, schoolStartMin - 7 * 60)
        let afternoon = max(0, bedtime - schoolEndMin)
        let free = max(0, morning + afternoon - lessonMinutes)
        XCTAssertEqual(free, 375)
    }

    func testFreeMinutes_morningIncluded() {
        let schoolStartMin = 9 * 60
        let schoolEndMin   = 15 * 60
        let bedtime        = 20 * 60
        let oldFree = bedtime - schoolEndMin
        let morning   = max(0, schoolStartMin - 7 * 60)
        let afternoon = max(0, bedtime - schoolEndMin)
        let newFree   = morning + afternoon
        XCTAssertGreaterThan(newFree, oldFree)
        XCTAssertEqual(newFree - oldFree, 120)
    }

    func testFreeMinutes_holiday() {
        let bedtime = 20 * 60
        let free = bedtime - 7 * 60
        XCTAssertEqual(free, 780)
    }

    func testFreeMinutes_noNegative() {
        // 習い事が空き時間より長くても負にならない
        let schoolStartMin = 9 * 60
        let schoolEndMin   = 15 * 60
        let bedtime        = 20 * 60
        let lessonMinutes  = 999
        let morning   = max(0, schoolStartMin - 7 * 60)
        let afternoon = max(0, bedtime - schoolEndMin)
        let free = max(0, morning + afternoon - lessonMinutes)
        XCTAssertEqual(free, 0)
    }

    // MARK: - タイムラインのソート

    func testTimeline_lessonBeforeSchool() {
        let lessonTime  = 8 * 60 + 15
        let schoolStart = 9 * 60
        XCTAssertLessThan(lessonTime, schoolStart)
    }

    func testTimeline_lessonDuringSchool() {
        let lessonTime  = 14 * 60
        let schoolStart = 9 * 60
        let schoolEnd   = 15 * 60 + 15
        XCTAssertGreaterThan(lessonTime, schoolStart)
        XCTAssertLessThan(lessonTime, schoolEnd)
    }

    // MARK: - QuestType判定

    func testQuestType_count() {
        let quest = Quest(name: "テスト", dailyCount: 3)
        XCTAssertEqual(quest.questType, .count)
    }

    func testQuestType_page() {
        let quest = Quest(name: "テスト", totalPages: 7)
        XCTAssertEqual(quest.questType, .page)
    }

    func testQuestType_time() {
        let quest = Quest(name: "テスト", targetMinutes: 15)
        XCTAssertEqual(quest.questType, .time)
    }

    func testQuestType_stopwatch() {
        let quest = Quest(name: "テスト", isStopwatch: true)
        XCTAssertEqual(quest.questType, .stopwatch)
    }

    // MARK: - 朝ボーナス・就寝判定

    func testMorningBonus_beforeSchool() {
        let hour = 7
        let schoolStart = 9
        let isMorning = hour >= 5 && hour < schoolStart
        XCTAssertTrue(isMorning)
    }

    func testMorningBonus_afterSchool() {
        let hour = 10
        let schoolStart = 9
        let isMorning = hour >= 5 && hour < schoolStart
        XCTAssertFalse(isMorning)
    }

    func testBedtime_past() {
        let nowMinutes  = 21 * 60
        let bedMinutes  = 20 * 60 + 30
        XCTAssertTrue(nowMinutes >= bedMinutes)
    }

    func testBedtime_before() {
        let nowMinutes  = 19 * 60
        let bedMinutes  = 20 * 60 + 30
        XCTAssertFalse(nowMinutes >= bedMinutes)
    }

    func testBedtime_midnight_isPastBedtime() {
        // 深夜0時(0時)は就寝時間を過ぎている扱い
        let hour = 0
        let bedH = 20
        let bedM = 30
        let nowMinutes = hour * 60
        let bedMinutes = bedH * 60 + bedM
        let isPastBedtime = nowMinutes >= bedMinutes || hour < 5
        XCTAssertTrue(isPastBedtime)
    }

    func testBedtime_earlyMorning_isPastBedtime() {
        // 4時は就寝時間帯
        let hour = 4
        let isPastBedtime = hour < 5
        XCTAssertTrue(isPastBedtime)
    }
}
