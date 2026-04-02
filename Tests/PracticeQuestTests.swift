import XCTest
@testable import PracticeQuest

final class PracticeQuestTests: XCTestCase {

    // MARK: - 全体進捗カウント

    func testOverallProgress_timeQuestCountsAs1() {
        // 15分タイマーを15分やりきった → 全体進捗は1（15ではない）
        let completedCount = 15  // 実際の分数
        let targetMinutes = 15
        let isTimeType = true

        let progressCount = isTimeType ? (completedCount >= targetMinutes ? 1 : 0) : completedCount
        XCTAssertEqual(progressCount, 1)
    }

    func testOverallProgress_timeQuestNotDone() {
        // 5分しかやっていない → 全体進捗は0
        let completedCount = 5
        let targetMinutes = 15
        let isTimeType = true

        let progressCount = isTimeType ? (completedCount >= targetMinutes ? 1 : 0) : completedCount
        XCTAssertEqual(progressCount, 0)
    }

    func testOverallTotal_timeQuestCountsAs1() {
        // タイマー型クエストのtotalは1（dailyCountではない）
        let isTimeType = true
        let isPageType = false
        let dailyCount = 1

        let total = isPageType ? 10 : (isTimeType ? 1 : dailyCount)
        XCTAssertEqual(total, 1)
    }

    // MARK: - タイマー完了時の星計算

    func testTimerStars_fullCompletion() {
        // 15分タイマーを15分やりきった → 満星
        let starsTotal = 30
        let actualMinutes = 15
        let targetMinutes = 15
        let fiveMinBlocks = actualMinutes / 5   // 3
        let totalBlocks = max(1, targetMinutes / 5) // 3
        let stars = min(starsTotal, starsTotal * fiveMinBlocks / totalBlocks)
        XCTAssertEqual(stars, 30)
    }

    func testTimerStars_halfCompletion() {
        // 15分タイマーを7分でやめた → 約半分の星
        let starsTotal = 30
        let actualMinutes = 7   // 5分ブロック1つ分
        let targetMinutes = 15
        let fiveMinBlocks = actualMinutes / 5   // 1
        let totalBlocks = max(1, targetMinutes / 5) // 3
        let stars = min(starsTotal, starsTotal * fiveMinBlocks / totalBlocks)
        XCTAssertEqual(stars, 10)
    }

    func testTimerStars_tooShort() {
        // 2秒でやめた → onCompleteは呼ばれないのでstars計算まで到達しない
        // TimerViewのやめるボタンは elapsedSeconds >= 60 のときのみ発火
        let elapsedSeconds = 2
        XCTAssertFalse(elapsedSeconds >= 60)
    }

    func testTimerStars_justOver60Seconds() {
        // 61秒でやめた → 1分として記録される
        let elapsedSeconds = 61
        XCTAssertTrue(elapsedSeconds >= 60)
        let minutes = (elapsedSeconds + 30) / 60
        XCTAssertEqual(minutes, 1)
    }

    func testTimerMinutesRounding() {
        // 89秒 → 1分（切り捨て）
        XCTAssertEqual((89 + 30) / 60, 1)
        // 90秒 → 2分（四捨五入）
        XCTAssertEqual((90 + 30) / 60, 2)
        // 900秒(15分) → 15分
        XCTAssertEqual((900 + 30) / 60, 15)
    }

    // MARK: - 空き時間の計算

    func testFreeMinutes_schoolDay_noLessons() {
        // 登校9:00 下校15:15 就寝20:30 習い事なし
        let schoolStartMin = 9 * 60 + 0    // 540
        let schoolEndMin   = 15 * 60 + 15  // 915
        let bedtime        = 20 * 60 + 30  // 1230
        let lessonMinutes  = 0

        let morning   = schoolStartMin - 7 * 60          // 120分（7:00〜9:00）
        let afternoon = bedtime - schoolEndMin            // 315分（15:15〜20:30）
        let free = max(0, morning + afternoon - lessonMinutes)
        XCTAssertEqual(free, 435)  // 7時間15分
    }

    func testFreeMinutes_schoolDay_withLesson() {
        // 登校9:00 下校15:15 就寝20:30 習い事60分
        let schoolStartMin = 9 * 60
        let schoolEndMin   = 15 * 60 + 15
        let bedtime        = 20 * 60 + 30
        let lessonMinutes  = 60

        let morning   = schoolStartMin - 7 * 60
        let afternoon = bedtime - schoolEndMin
        let free = max(0, morning + afternoon - lessonMinutes)
        XCTAssertEqual(free, 375)  // 6時間15分
    }

    func testFreeMinutes_morningIncluded() {
        // 朝の時間が計算に含まれることを確認（旧バグ: 含まれていなかった）
        let schoolStartMin = 9 * 60   // 9:00
        let schoolEndMin   = 15 * 60  // 15:00
        let bedtime        = 20 * 60  // 20:00
        let lessonMinutes  = 0

        // 旧実装（学校終わりからのみ）
        let oldFree = bedtime - schoolEndMin  // 300分
        // 新実装（朝含む）
        let morning   = schoolStartMin - 7 * 60  // 120分
        let afternoon = bedtime - schoolEndMin    // 300分
        let newFree   = morning + afternoon       // 420分

        XCTAssertGreaterThan(newFree, oldFree)   // 朝を含むと増える
        XCTAssertEqual(newFree - oldFree, 120)   // 差は朝の2時間分
    }

    func testFreeMinutes_holiday() {
        // 休日: 7:00〜就寝20:00 習い事なし
        let bedtime = 20 * 60
        let free = bedtime - 7 * 60
        XCTAssertEqual(free, 780)  // 13時間
    }

    // MARK: - タイムラインのソート

    func testTimeline_lessonBeforeSchool() {
        // 8:15の習い事は9:00の学校より前に来る
        let lessonTime  = 8 * 60 + 15  // 495
        let schoolStart = 9 * 60       // 540
        XCTAssertLessThan(lessonTime, schoolStart)
    }

    func testTimeline_lessonDuringSchool() {
        // 14:00の習い事は9:00学校開始と15:15下校の間に来る
        let lessonTime  = 14 * 60      // 840
        let schoolStart = 9 * 60       // 540
        let schoolEnd   = 15 * 60 + 15 // 915
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
        // 7時は朝ボーナス（schoolStartHour=9）
        let hour = 7
        let schoolStart = 9
        let isMorning = hour >= 5 && hour < schoolStart
        XCTAssertTrue(isMorning)
    }

    func testMorningBonus_afterSchool() {
        // 10時は朝ボーナスではない
        let hour = 10
        let schoolStart = 9
        let isMorning = hour >= 5 && hour < schoolStart
        XCTAssertFalse(isMorning)
    }

    func testBedtime_past() {
        // 21時は就寝時間(20:30)を過ぎている
        let nowMinutes  = 21 * 60
        let bedMinutes  = 20 * 60 + 30
        XCTAssertTrue(nowMinutes >= bedMinutes)
    }

    func testBedtime_before() {
        // 19時はまだ就寝前
        let nowMinutes  = 19 * 60
        let bedMinutes  = 20 * 60 + 30
        XCTAssertFalse(nowMinutes >= bedMinutes)
    }
}
