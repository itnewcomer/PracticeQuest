import SwiftUI
import SwiftData
import UniformTypeIdentifiers

// MARK: - バックアップ用DTO（Codable）

struct PracticeQuestBackup: Codable {
    let version: Int
    let exportedAt: Date
    let totalStars: Int
    let quests: [QuestDTO]
    let lessons: [LessonDTO]
    let rewards: [RewardDTO]
    let logs: [QuestLogDTO]
    let stopwatchRecords: [StopwatchRecordDTO]

    struct QuestDTO: Codable {
        var name: String
        var icon: String
        var dailyCount: Int
        var totalPages: Int
        var targetMinutes: Int
        var isStopwatch: Bool
        var allowExtra: Bool
        var starsPerComplete: Int
        var order: Int
    }

    struct LessonDTO: Codable {
        var name: String
        var icon: String
        var weekday: Int
        var startHour: Int
        var startMinute: Int
        var durationMinutes: Int
    }

    struct RewardDTO: Codable {
        var name: String
        var icon: String
        var starCost: Int
        var isTimeBased: Bool
        var durationMinutes: Int
        var stockCount: Int
        var remainingSeconds: Int
    }

    struct QuestLogDTO: Codable {
        var questName: String
        var date: Date
        var completedCount: Int
        var earnedStars: Int
        var bonusStars: Int
        var starHistoryJSON: String
        var countHistoryJSON: String
    }

    struct StopwatchRecordDTO: Codable {
        var questName: String
        var date: Date
        var seconds: Int
    }
}

// MARK: - エクスポート用ファイルDocument

struct BackupDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.json] }
    var data: Data

    init(data: Data) { self.data = data }

    init(configuration: ReadConfiguration) throws {
        guard let data = configuration.file.regularFileContents else {
            throw CocoaError(.fileReadCorruptFile)
        }
        self.data = data
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        FileWrapper(regularFileWithContents: data)
    }
}

// MARK: - DataBackupView

struct DataBackupView: View {
    private static let supportedVersion = 1

    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Quest.order) private var quests: [Quest]
    @Query(sort: \Lesson.startHour) private var lessons: [Lesson]
    @Query(sort: \Reward.starCost) private var rewards: [Reward]
    @Query private var logs: [QuestLog]
    @Query(sort: \StopwatchRecord.date) private var stopwatchRecords: [StopwatchRecord]
    @AppStorage("totalStars") private var totalStars = 0

    @State private var showExporter = false
    @State private var showImporter = false
    @State private var showImportConfirm = false
    @State private var showImportSuccess = false
    @State private var showError = false
    @State private var exportDocument: BackupDocument?
    @State private var pendingImportURL: URL?
    @State private var errorMessage = ""

    private var ja: Bool { L10n.current == .ja }

    var body: some View {
        Section("💾 " + (ja ? "データのバックアップ" : "Data Backup")) {
            // エクスポート
            Button {
                exportDocument = makeExportDocument()
                showExporter = true
            } label: {
                HStack {
                    Image(systemName: "square.and.arrow.up")
                    Text(ja ? "データをエクスポート" : "Export Data")
                }
            }

            // インポート
            Button {
                showImporter = true
            } label: {
                HStack {
                    Image(systemName: "square.and.arrow.down")
                    Text(ja ? "データをインポート" : "Import Data")
                }
                .foregroundColor(.orange)
            }

            Text(ja ? "インポートすると現在のデータが上書きされます" : "Importing will overwrite current data")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .fileExporter(
            isPresented: $showExporter,
            document: exportDocument,
            contentType: .json,
            defaultFilename: "PracticeQuest_\(dateString()).json"
        ) { result in
            if case .failure(let error) = result {
                errorMessage = error.localizedDescription
                showError = true
            }
        }
        .fileImporter(
            isPresented: $showImporter,
            allowedContentTypes: [.json]
        ) { result in
            switch result {
            case .success(let url):
                pendingImportURL = url
                showImportConfirm = true
            case .failure(let error):
                errorMessage = error.localizedDescription
                showError = true
            }
        }
        .confirmationDialog(
            ja ? "データをインポートしますか？" : "Import data?",
            isPresented: $showImportConfirm,
            titleVisibility: .visible
        ) {
            Button(ja ? "上書きしてインポート" : "Import & Overwrite", role: .destructive) {
                if let url = pendingImportURL {
                    importData(from: url)
                }
            }
            Button(ja ? "キャンセル" : "Cancel", role: .cancel) {}
        } message: {
            Text(ja ? "現在のクエスト・履歴・ごほうびがすべて置き換えられます。" : "All current quests, history and rewards will be replaced.")
        }
        .alert(ja ? "インポート完了" : "Import Complete", isPresented: $showImportSuccess) {
            Button("OK") {}
        } message: {
            Text(ja ? "データを読み込みました。" : "Data imported successfully.")
        }
        .alert(ja ? "エラー" : "Error", isPresented: $showError) {
            Button("OK") {}
        } message: {
            Text(errorMessage)
        }
    }

    // MARK: - エクスポート

    private func makeExportDocument() -> BackupDocument {
        let backup = PracticeQuestBackup(
            version: 1,
            exportedAt: Date(),
            totalStars: totalStars,
            quests: quests.map {
                .init(name: $0.name, icon: $0.icon, dailyCount: $0.dailyCount,
                      totalPages: $0.totalPages, targetMinutes: $0.targetMinutes,
                      isStopwatch: $0.isStopwatch, allowExtra: $0.allowExtra,
                      starsPerComplete: $0.starsPerComplete, order: $0.order)
            },
            lessons: lessons.map {
                .init(name: $0.name, icon: $0.icon, weekday: $0.weekday,
                      startHour: $0.startHour, startMinute: $0.startMinute,
                      durationMinutes: $0.durationMinutes)
            },
            rewards: rewards.map {
                .init(name: $0.name, icon: $0.icon, starCost: $0.starCost,
                      isTimeBased: $0.isTimeBased, durationMinutes: $0.durationMinutes,
                      stockCount: $0.stockCount, remainingSeconds: $0.remainingSeconds)
            },
            logs: logs.map {
                .init(questName: $0.questName, date: $0.date,
                      completedCount: $0.completedCount, earnedStars: $0.earnedStars,
                      bonusStars: $0.bonusStars,
                      starHistoryJSON: $0.starHistoryJSON, countHistoryJSON: $0.countHistoryJSON)
            },
            stopwatchRecords: stopwatchRecords.map {
                .init(questName: $0.questName, date: $0.date, seconds: $0.seconds)
            }
        )
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = .prettyPrinted
        let data = (try? encoder.encode(backup)) ?? Data()
        return BackupDocument(data: data)
    }

    // MARK: - インポート

    private func importData(from url: URL) {
        guard url.startAccessingSecurityScopedResource() else {
            errorMessage = L10n.current == .ja ? "ファイルにアクセスできません" : "Cannot access file"
            showError = true
            return
        }
        defer { url.stopAccessingSecurityScopedResource() }

        guard let data = try? Data(contentsOf: url) else {
            errorMessage = L10n.current == .ja ? "ファイルを読み込めません" : "Cannot read file"
            showError = true
            return
        }

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        guard let backup = try? decoder.decode(PracticeQuestBackup.self, from: data) else {
            errorMessage = L10n.current == .ja ? "ファイルの形式が正しくありません" : "Invalid file format"
            showError = true
            return
        }

        guard backup.version <= Self.supportedVersion else {
            errorMessage = L10n.current == .ja
                ? "新しいバージョンのバックアップです。アプリを更新してください。"
                : "This backup is from a newer app version. Please update the app."
            showError = true
            return
        }

        // 既存データを削除
        quests.forEach { modelContext.delete($0) }
        lessons.forEach { modelContext.delete($0) }
        rewards.forEach { modelContext.delete($0) }
        logs.forEach { modelContext.delete($0) }
        stopwatchRecords.forEach { modelContext.delete($0) }

        // インポート
        backup.quests.forEach {
            modelContext.insert(Quest(name: $0.name, icon: $0.icon, dailyCount: $0.dailyCount,
                                     totalPages: $0.totalPages, targetMinutes: $0.targetMinutes,
                                     isStopwatch: $0.isStopwatch, allowExtra: $0.allowExtra,
                                     starsPerComplete: $0.starsPerComplete, order: $0.order))
        }
        backup.lessons.forEach {
            modelContext.insert(Lesson(name: $0.name, icon: $0.icon, weekday: $0.weekday,
                                      startHour: $0.startHour, startMinute: $0.startMinute,
                                      durationMinutes: $0.durationMinutes))
        }
        backup.rewards.forEach {
            let r = Reward(name: $0.name, icon: $0.icon, starCost: $0.starCost,
                           isTimeBased: $0.isTimeBased, durationMinutes: $0.durationMinutes,
                           stockCount: $0.stockCount, remainingSeconds: $0.remainingSeconds)
            modelContext.insert(r)
        }
        backup.logs.forEach {
            let log = QuestLog(questName: $0.questName, date: $0.date,
                               completedCount: $0.completedCount, earnedStars: $0.earnedStars,
                               bonusStars: $0.bonusStars)
            log.starHistoryJSON = $0.starHistoryJSON
            log.countHistoryJSON = $0.countHistoryJSON
            modelContext.insert(log)
        }
        backup.stopwatchRecords.forEach {
            modelContext.insert(StopwatchRecord(questName: $0.questName, date: $0.date, seconds: $0.seconds))
        }

        totalStars = backup.totalStars
        try? modelContext.save()
        showImportSuccess = true
    }

    private func dateString() -> String {
        let f = DateFormatter()
        f.dateFormat = "yyyyMMdd"
        return f.string(from: Date())
    }
}
