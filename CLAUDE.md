# PracticeQuest

子ども向けの練習・習慣管理アプリ。クエスト形式で練習を楽しくする。

## アプリ概要

- **ターゲット**: 子どもと保護者
- **コンセプト**: 練習（ピアノ・勉強など）をクエストとして管理・達成
- **主な機能**: クエスト管理、タイマー、スケジュール、ショップ（ご褒美）、保護者設定

## 技術スタック

- Swift / SwiftUI
- SwiftData（永続化）
- XcodeGen（`project.yml` からプロジェクト生成）
- `L10n.swift` でローカライズ管理

## ファイル構成

```
Sources/
  PracticeQuestApp.swift  # エントリポイント
  AppColors.swift         # カラーパレット
  Models.swift            # SwiftDataモデル
  L10n.swift              # ローカライズ
  ContentView.swift       # メインナビゲーション
  QuestBoardView.swift    # クエスト一覧
  EditQuestView.swift     # クエスト編集
  EditViews.swift         # 共通編集コンポーネント
  TimerView.swift         # 練習タイマー
  StopwatchView.swift     # ストップウォッチ
  ScheduleView.swift      # スケジュール
  StatsView.swift         # 統計
  ShopView.swift          # ご褒美ショップ
  ParentSettingsView.swift # 保護者設定
  DataBackupView.swift    # データバックアップ
  SetupView.swift         # 初回オンボーディング
Resources/
docs/
```

## 注意事項

- XcodeGen使用: 変更後は `xcodegen generate`
- コミットに `Co-Authored-By:` 行は入れない

## Git ブランチ運用

- **main へ直接コミットしない**。次のリリース (1.0.4 以降) からは feature ブランチを切る運用に切り替える。
- ブランチ命名: `fix/issue-123-summary` / `feat/short-summary` / `chore/short-summary`
- 1 ブランチ = 1 つの目的（複数 Issue を扱う場合は理由を PR 説明に明記）
- リリース準備（version bump + 動作確認チェックリスト）は `release/1.0.x` ブランチで行う
- マージ前に必ずビルド確認 + 簡単な動作確認

## 作業分担方針（Opus / Sonnet）

- **Opus**: 設計判断・難所の実装・レビュー（コード品質、UX、アーキテクチャ観点）
- **Sonnet**: 単純な実装作業（明確な変更指示があるタスク、定型的な修正）
- Opusは必要に応じて Agent ツール（subagent_type を指定）で Sonnet にタスクを委譲する
- 委譲する際は、変更対象ファイル・行番号・具体的な修正内容を明示する（理解はOpus側で完結させる）

## コード規約・パターン

### 状態管理

- **日付跨ぎ対応が必要な値**（today / todayWeekday 等）: `@State` + `.onChange(of: scenePhase)` (`.active`時) + `.onReceive(NotificationCenter.default.publisher(for: .NSCalendarDayChanged))` の三段で更新する。`let today = Calendar.current.startOfDay(for: Date())` のような stored property は使わない（深夜跨ぎで stale になる）。実装例: `QuestBoardView.swift`, `ScheduleView.swift`
- **時刻系設定** (`schoolStartHour`, `bedtimeHour`, `wakeupHour` 等) は `@AppStorage` を使う。`UserDefaults.standard.object(forKey:)` での読み取りは body 描画時の自動更新が効かないので避ける。例外: `[Int]` (schoolDays) は AppStorage 非対応のため computed property で読む。
- **AppStorage キー一覧**: `totalStars`, `isSetupDone`, `appLanguage`, `wakeupHour/Min`, `schoolStartHour/Min`, `schoolEndHour/Min`, `bedtimeHour/Min`, `schoolDays` ([Int])

### タイマー

- `Timer.scheduledTimer` を再起動する箇所では、必ず冒頭で `timer?.invalidate(); timer = nil` を実行する（連続呼び出しでタイマーリーク → 秒が2倍速で進む）。
- バックグラウンド復帰 (`scenePhase == .active`) で `backgroundedAt` を見て elapsed/remaining を補正したあと、`isRunning` なら `startTimer()` を再呼び出しして RunLoop 上の Timer fire を確実に再開する。
- 通知識別子はクエスト名 / リワード名でユニーク化 (`"timer-goal-\(questName)"`)。固定文字列だと将来的に衝突する。

### 通知

- 通知許可は起動時には求めない。`NotificationPermission.requestIfNeeded()` (in `PracticeQuestApp.swift`) を **タイマー初回起動時** に呼ぶ。`getNotificationSettings` で `.notDetermined` のときだけ `requestAuthorization` する。

### モデル / ヘルパ

- 時間型クエストの按分星計算は `Quest.timeQuestStars(elapsedMinutes:targetMinutes:starsTotal:)` に集約。TimerView と QuestBoardView の両方から呼ぶ。5分以上は5分ブロック単位、5分未満は分数比例。重複ロジックを書かない。
- アイコン候補配列は `IconCatalog.quest / .lesson / .reward` (in `Models.swift`) を使う。各 View にインライン配列を書かない。

### バリデーション

- 数値入力 (`targetMinutes`, `totalPages`, `starsPerComplete`, `durationMinutes`, `starCost` 等):
  - **Add シート**: 「追加」ボタン押下時に `max(1, ...)` で clamp（途中入力を妨げない）
  - **Edit View**: `.onDisappear` で clamp（編集中の入力を妨げない）
  - **使用側 (TimerView 等)**: ゼロ除算防御として `safeTargetSeconds = max(60, targetMinutes * 60)` を使う

### 子供向け誤操作防止

- 破壊的操作には確認ダイアログを必ず置く: 購入確認 / 「つかう」確認 / UNDO 確認 / リセット確認 / インポート確認
- UNDO の長押しは **1.0 秒以上**、`UIImpactFeedbackGenerator(style: .medium)` で触覚フィードバック、確認ダイアログ経由で発火
- 保護者設定は `onLongPressGesture(minimumDuration: 0.8)` でのみ開く（タップでは開かない）
- アクセシビリティ: 主要ボタンに `.accessibilityLabel`、ジェスチャー操作には `.accessibilityAction(named:)`

## タスク管理（GitHub Issues）

セッションを跨いで残るタスク・将来やること・リリース前の確認項目は `gh issue create` で GitHub Issue 化する。会話の中だけで管理しない（忘れる）。

- **Issue化する対象**
  - レビューで挙がった "今すぐ直さない" 項目（リファクタ・技術負債・改善案）
  - リリース前の動作確認チェックリスト（チェックボックス付き、全部チェックで Close）
  - バグだが優先度低めで次回まとめて対応するもの
- **本文に含める**: 問題 / 影響 / 修正案 / 関連ファイル（行番号 + シンボル名を併記。コード変更で行はズレる前提）
- **ラベル**: `bug` / `enhancement` を使い分け
- **一覧確認**: `gh issue list --repo itnewcomer/PracticeQuest`
