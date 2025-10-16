# Issue #6: 作業中タスクの開始時間変更時のバグ修正 - 設計書

## 1. 問題の概要

作業中（in-progress）のタスクの開始時間を編集すると、以下の問題が発生する：

1. タイムクロック（経過時間の更新）が停止する
2. 作業履歴画面で作業中を示す緑色の背景が消え、黒色（完了状態）になる
3. 作業履歴画面で作業中を示す文言が表示されなくなる

## 2. 根本原因の分析

### 2.1 問題の発生箇所

**EditHistoryViewModel.swift**の2箇所で問題が発生している：

#### 問題1: `startEditing()` メソッド（89行目）
```swift
func startEditing(_ record: TimeRecord) {
    self.editingRecord = record
    self.selectedProject = record.project
    self.selectedJob = record.job
    self.startTime = record.startTime
    self.endTime = record.endTime ?? Date()  // ❌ 問題: 作業中の場合nilをDate()に変換
    self.showingEditSheet = true
    // ...
}
```

**問題点**: 作業中レコード（`endTime == nil`）の場合、`Date()`（現在時刻）を`endTime`に設定してしまう。

#### 問題2: `saveChanges()` メソッド（111行目）
```swift
func saveChanges() {
    // ...
    try self.timeRecordRepository.updateTimeRecord(
        record,
        startTime: self.startTime,
        endTime: self.endTime,  // ❌ 問題: 作業中でも必ずDate値を渡してしまう
        project: project,
        job: job
    )
    // ...
}
```

**問題点**: 元々`endTime == nil`だったレコードに対して、`self.endTime`（Date値）を渡してしまい、作業中状態が失われる。

### 2.2 データフロー

```
1. 作業中レコード (endTime == nil)
   ↓
2. startEditing() → endTime = Date() に変換
   ↓
3. ユーザーが開始時間を編集
   ↓
4. saveChanges() → endTime: Date() を渡す
   ↓
5. TimeRecordRepository.updateTimeRecord() → record.endTime = Date()
   ↓
6. 結果: 作業完了状態になる（endTime != nil）
```

### 2.3 影響範囲

- **TimeRecordモデル**: `endTime`が意図せず設定される
- **HistoryView**: `inProgressRecord`の判定（`endTime == nil`）が失敗し、緑色背景が消える
- **タイマー機能**: 作業中判定が失敗し、タイマーが停止する
- **統計機能**: 作業中タスクが完了済みとして扱われる

## 3. 解決方針

### 3.1 設計原則

1. **作業中レコードの`endTime`は常に`nil`を保持する**
2. **UIでは作業中の場合に`endTime`の編集を不可にする**（現在の実装）
3. **ViewModelとRepositoryで作業中状態を明示的に扱う**

### 3.2 修正アプローチ

#### アプローチA: ViewModelレベルで作業中を判定・保持（推奨）

**メリット**:
- ViewModelが作業中状態を明示的に管理
- UIとビジネスロジックの分離が明確
- テストが容易

**実装方法**:
1. `EditHistoryViewModel`に`isInProgress: Bool`プロパティを追加
2. `startEditing()`で元レコードの`endTime`が`nil`かを記録
3. `saveChanges()`で作業中の場合は`endTime: nil`を渡す

#### アプローチB: Repository層のシグネチャ変更

**メリット**:
- 型システムでnilを明示的に扱える

**デメリット**:
- Repositoryの変更が広範囲に影響
- 既存のテストも修正が必要

**結論**: **アプローチAを採用**（影響範囲が限定的で、既存設計との整合性が高い）

## 4. 詳細設計

### 4.1 EditHistoryViewModel の修正

#### 4.1.1 新規プロパティの追加

```swift
@MainActor
class EditHistoryViewModel: BaseViewModel {
    // ...既存のプロパティ...

    // 新規追加: 編集対象レコードが作業中かどうかを保持
    @Published var isEditingInProgressRecord: Bool = false
}
```

#### 4.1.2 `startEditing()` メソッドの修正

**修正前**:
```swift
func startEditing(_ record: TimeRecord) {
    self.editingRecord = record
    self.selectedProject = record.project
    self.selectedJob = record.job
    self.startTime = record.startTime
    self.endTime = record.endTime ?? Date()  // ❌ 問題
    self.showingEditSheet = true
    // ...
}
```

**修正後**:
```swift
func startEditing(_ record: TimeRecord) {
    self.editingRecord = record
    self.selectedProject = record.project
    self.selectedJob = record.job
    self.startTime = record.startTime

    // ✅ 作業中レコードの判定と保持
    if let endTime = record.endTime {
        // 完了済みレコード: 既存のendTimeを使用
        self.endTime = endTime
        self.isEditingInProgressRecord = false
    } else {
        // 作業中レコード: 現在時刻をUI表示用に設定（保存時は使用しない）
        self.endTime = Date()
        self.isEditingInProgressRecord = true
    }

    self.showingEditSheet = true
    clearError()

    // 編集開始時に最新のプロジェクト・作業区分一覧を再読み込み
    self.loadAvailableProjects()
    self.loadAvailableJobs()
}
```

#### 4.1.3 `saveChanges()` メソッドの修正

**修正前**:
```swift
func saveChanges() {
    guard let record = editingRecord,
          let project = selectedProject,
          let job = selectedJob
    else {
        handleError(EditHistoryError.missingData)
        return
    }

    withLoadingSync {
        try self.timeRecordRepository.updateTimeRecord(
            record,
            startTime: self.startTime,
            endTime: self.endTime,  // ❌ 問題
            project: project,
            job: job
        )
    }
    // ...
}
```

**修正後**:
```swift
func saveChanges() {
    guard let record = editingRecord,
          let project = selectedProject,
          let job = selectedJob
    else {
        handleError(EditHistoryError.missingData)
        return
    }

    withLoadingSync {
        // ✅ 作業中レコードの場合はendTimeを元のまま保持
        if self.isEditingInProgressRecord {
            // 作業中レコード: endTimeはnilのまま、startTimeのみ更新
            try self.timeRecordRepository.updateTimeRecord(
                record,
                startTime: self.startTime,
                endTime: record.endTime,  // nilを保持
                project: project,
                job: job
            )
        } else {
            // 完了済みレコード: 通常の更新
            try self.timeRecordRepository.updateTimeRecord(
                record,
                startTime: self.startTime,
                endTime: self.endTime,
                project: project,
                job: job
            )
        }
    }

    if errorMessage == nil {
        self.showingEditSheet = false
        self.resetEditingState()
    }
}
```

#### 4.1.4 `resetEditingState()` メソッドの修正

**修正前**:
```swift
private func resetEditingState() {
    self.editingRecord = nil
    self.selectedProject = nil
    self.selectedJob = nil
    self.startTime = Date()
    self.endTime = Date()
    self.availableProjects = []
    self.availableJobs = []
}
```

**修正後**:
```swift
private func resetEditingState() {
    self.editingRecord = nil
    self.selectedProject = nil
    self.selectedJob = nil
    self.startTime = Date()
    self.endTime = Date()
    self.isEditingInProgressRecord = false  // ✅ 追加
    self.availableProjects = []
    self.availableJobs = []
}
```

### 4.2 TimeRecordRepository の確認

**現在の実装**（TimeRecordRepository.swift:113-171行目）は問題なし：

```swift
func updateTimeRecord(_ record: TimeRecord, startTime: Date, endTime: Date, project: Project, job: Job) throws {
    // バリデーション
    guard try self.validateTimeRange(startTime: startTime, endTime: endTime, excludingRecord: record) else {
        throw TimeRecordError.invalidTimeRange
    }

    // レコードの更新
    record.startTime = startTime
    record.endTime = endTime  // ✅ 渡された値をそのまま設定（nilも可能）
    record.project = project
    record.job = job
    record.backupProjectId = project.projectId
    record.backupProjectName = project.name
    record.backupProjectColor = project.color
    record.backupJobId = job.jobId
    record.backupJobName = job.name

    try self.modelContext.save()
}
```

**注意点**: `endTime: Date`型だが、Optional型の値も受け取れる（Swift言語仕様）。ただし、型が`Date`なので呼び出し側で`endTime: record.endTime`のように渡す必要がある。

### 4.3 バリデーションロジックの調整

`TimeRecordRepository.validateTimeRange()` の現在の実装は**完了済みレコードのみ**を対象としているため、作業中レコード（`endTime == nil`）の開始時間変更には影響しない。

**現在の実装**（TimeRecordRepository.swift:209-212行目）:
```swift
let completedRecordsDescriptor = FetchDescriptor<TimeRecord>(
    predicate: #Predicate<TimeRecord> { record in
        record.endTime != nil  // ✅ 完了済みのみチェック
    }
)
```

**結論**: バリデーションロジックの修正は**不要**。

ただし、作業中レコードの開始時間を編集する場合、以下の条件を満たす必要がある：
- 開始時間 < 現在時刻（未来の時間は不可）
- 開始時間 >= 当日の0時（過去の日付にまたがる編集は不可、UI制約で対応済み）

**追加検討**: `isValidTimeRange`の計算ロジック（EditHistoryViewModel.swift:30-36行目）も作業中レコードに対応する必要がある。

#### 4.3.1 `isValidTimeRange` の修正

**修正前**:
```swift
var isValidTimeRange: Bool {
    guard self.startTime < self.endTime else { return false }
    guard self.endTime <= Date() else { return false }

    let duration = self.endTime.timeIntervalSince(self.startTime)
    return duration >= 60 && duration <= 86400
}
```

**修正後**:
```swift
var isValidTimeRange: Bool {
    // ✅ 作業中レコードの場合は開始時間のみチェック
    if self.isEditingInProgressRecord {
        // 開始時間が現在時刻より前であればOK
        return self.startTime <= Date()
    }

    // 完了済みレコードの場合は既存のバリデーション
    guard self.startTime < self.endTime else { return false }
    guard self.endTime <= Date() else { return false }

    let duration = self.endTime.timeIntervalSince(self.startTime)
    return duration >= 60 && duration <= 86400
}
```

#### 4.3.2 `canSave` の確認

**現在の実装**（EditHistoryViewModel.swift:54-56行目）:
```swift
var canSave: Bool {
    return self.selectedProject != nil && self.selectedJob != nil && self.isValidTimeRange && !isLoading
}
```

**結論**: 修正不要（`isValidTimeRange`の修正により自動的に対応）

### 4.4 UI（EditHistorySheetView）の確認

**現在の実装**（EditHistorySheetView.swift:132-165行目）は問題なし：

```swift
// 終了時間（作業中の場合は編集不可）
if self.viewModel.editingRecord?.endTime != nil {
    // 完了済みレコード: DatePickerを表示
    HStack {
        Text("終了時間")
        DatePicker("", selection: self.$viewModel.endTime, ...)
        // ...
    }
} else {
    // 作業中レコード: 「作業中」と表示（編集不可）
    HStack {
        Text("終了時間")
        Text("作業中")
            .foregroundColor(.green)
            .fontWeight(.semibold)
        Spacer()
    }
}
```

**結論**: UI側の修正は**不要**。

## 5. テスト設計

### 5.1 ユニットテスト

#### 5.1.1 EditHistoryViewModelのテスト

新規テストファイル: `TimeRabbitTests/EditHistoryViewModelInProgressTests.swift`

**テストケース**:

1. **`testStartEditingInProgressRecord()`**
   - 作業中レコードで`startEditing()`を呼び出す
   - `isEditingInProgressRecord == true`を確認
   - `endTime`がDate()に設定されている（UI表示用）
   - `editingRecord.endTime == nil`（元データは保持）

2. **`testStartEditingCompletedRecord()`**
   - 完了済みレコードで`startEditing()`を呼び出す
   - `isEditingInProgressRecord == false`を確認
   - `endTime`が元の値と一致

3. **`testSaveChangesInProgressRecord()`**
   - 作業中レコードの開始時間を変更
   - `saveChanges()`を呼び出す
   - レコードの`endTime == nil`が保持されている
   - `startTime`が更新されている

4. **`testSaveChangesCompletedRecord()`**
   - 完了済みレコードの開始・終了時間を変更
   - `saveChanges()`を呼び出す
   - `endTime`が新しい値に更新されている

5. **`testIsValidTimeRangeInProgressRecord()`**
   - 作業中レコードで開始時間が現在時刻以前の場合は`true`
   - 作業中レコードで開始時間が未来の場合は`false`

6. **`testResetEditingState()`**
   - `resetEditingState()`を呼び出す
   - `isEditingInProgressRecord == false`を確認

### 5.2 統合テスト（手動）

#### シナリオ1: 作業中タスクの開始時間編集

1. プロジェクトで「開始」ボタンをクリック
2. 作業履歴画面を開く → 緑色背景で「作業中」表示を確認
3. 作業中タスクの「編集」ボタンをクリック
4. 開始時間を変更（例: 現在時刻 - 30分）
5. 「保存」をクリック
6. **期待結果**:
   - 作業履歴画面で緑色背景が維持される
   - 「作業中」の表示が維持される
   - タイムクロックが動作し続ける
   - 開始時間が更新されている

#### シナリオ2: 完了済みタスクの編集（回帰テスト）

1. 完了済みのタスクの「編集」ボタンをクリック
2. 開始・終了時間を変更
3. 「保存」をクリック
4. **期待結果**:
   - 黒色背景のまま（完了状態）
   - 開始・終了時間が更新されている

## 6. 実装手順

### ステップ1: EditHistoryViewModel の修正
1. `isEditingInProgressRecord`プロパティを追加
2. `startEditing()`メソッドを修正
3. `saveChanges()`メソッドを修正
4. `isValidTimeRange`計算プロパティを修正
5. `resetEditingState()`メソッドを修正

### ステップ2: ユニットテストの作成
1. `EditHistoryViewModelInProgressTests.swift`を作成
2. テストケース1〜6を実装

### ステップ3: コードフォーマットとテスト実行
1. `swiftformat .`を実行
2. 全ユニットテストを実行して成功を確認

### ステップ4: 統合テスト（手動）
1. シナリオ1を実行
2. シナリオ2を実行

### ステップ5: コミットとPR
1. `git commit -m "#6 bugfix: Fix in-progress record edit preserving endTime nil"`
2. `git push`
3. GitHub上でPR作成

## 7. リスク管理

### 7.1 潜在的なリスク

| リスク | 影響度 | 対策 |
|--------|--------|------|
| TimeRecordRepositoryの型が`Date`なので`nil`を渡せない可能性 | 高 | 事前に型定義を確認（Optional型かどうか） |
| 他の箇所で`EditHistoryViewModel.endTime`を直接参照している可能性 | 中 | Grep検索で参照箇所を確認 |
| UIテストが失敗する可能性 | 低 | UIテストは除外されているため影響なし |

### 7.2 型定義の確認結果

`TimeRecordRepository.updateTimeRecord()`のシグネチャ（TimeRecordRepository.swift:20行目）:

```swift
func updateTimeRecord(_ record: TimeRecord, startTime: Date, endTime: Date, project: Project, job: Job) throws
```

**問題発見**: `endTime`の型が`Date`（非Optional）であり、`nil`を渡せない！

### 7.3 解決策の再検討

#### 解決策A: Repositoryのシグネチャを変更（推奨）

**変更前**:
```swift
func updateTimeRecord(_ record: TimeRecord, startTime: Date, endTime: Date, project: Project, job: Job) throws
```

**変更後**:
```swift
func updateTimeRecord(_ record: TimeRecord, startTime: Date, endTime: Date?, project: Project, job: Job) throws
```

**影響範囲**:
- `TimeRecordRepositoryProtocol`（プロトコル定義）
- `TimeRecordRepository`（実装）
- `MockTimeRecordRepository`（Mock実装）
- 既存のテストコード

**メリット**:
- 型システムで作業中状態を明示的に扱える
- `nil`を渡せることが型で保証される

**デメリット**:
- 既存コードの修正範囲が増える

#### 解決策B: ViewModelで分岐してRepositoryメソッドを使い分ける

**追加メソッド案**:
```swift
// TimeRecordRepositoryProtocolに追加
func updateInProgressTimeRecord(_ record: TimeRecord, startTime: Date, project: Project, job: Job) throws
```

**デメリット**:
- メソッドが増えて複雑化
- 設計の一貫性が低下

**結論**: **解決策Aを採用**（型安全性が高く、設計が明確）

## 8. 最終設計（修正版）

### 8.1 TimeRecordRepositoryProtocol の修正

**修正前**:
```swift
protocol TimeRecordRepositoryProtocol {
    // ...
    func updateTimeRecord(_ record: TimeRecord, startTime: Date, endTime: Date, project: Project, job: Job) throws
    // ...
}
```

**修正後**:
```swift
protocol TimeRecordRepositoryProtocol {
    // ...
    func updateTimeRecord(_ record: TimeRecord, startTime: Date, endTime: Date?, project: Project, job: Job) throws
    // ...
}
```

### 8.2 TimeRecordRepository の修正

**修正前**:
```swift
func updateTimeRecord(_ record: TimeRecord, startTime: Date, endTime: Date, project: Project, job: Job) throws {
    // ...
    record.endTime = endTime
    // ...
}
```

**修正後**:
```swift
func updateTimeRecord(_ record: TimeRecord, startTime: Date, endTime: Date?, project: Project, job: Job) throws {
    // ...
    record.endTime = endTime  // Optionalを受け取るのでそのまま代入
    // ...
}
```

### 8.3 MockTimeRecordRepository の修正

MockTimeRecordRepository.swiftも同様に修正。

### 8.4 EditHistoryViewModel の修正（最終版）

**`saveChanges()`メソッド**:
```swift
func saveChanges() {
    guard let record = editingRecord,
          let project = selectedProject,
          let job = selectedJob
    else {
        handleError(EditHistoryError.missingData)
        return
    }

    withLoadingSync {
        // ✅ 作業中レコードの場合はendTime: nil、完了済みの場合はendTime: Date
        let finalEndTime = self.isEditingInProgressRecord ? nil : self.endTime

        try self.timeRecordRepository.updateTimeRecord(
            record,
            startTime: self.startTime,
            endTime: finalEndTime,
            project: project,
            job: job
        )
    }

    if errorMessage == nil {
        self.showingEditSheet = false
        self.resetEditingState()
    }
}
```

### 8.5 バリデーションロジックの修正

`validateTimeRange()`メソッド（TimeRecordRepository.swift:173-277行目）の修正：

**修正前**:
```swift
func validateTimeRange(startTime: Date, endTime: Date, excludingRecord: TimeRecord? = nil) throws -> Bool {
    // ...
}
```

**修正後**:
```swift
func validateTimeRange(startTime: Date, endTime: Date?, excludingRecord: TimeRecord? = nil) throws -> Bool {
    // ✅ 作業中レコード（endTime == nil）の場合は開始時間のみチェック
    guard let endTime = endTime else {
        // 作業中レコード: 開始時間が未来でなければOK
        guard startTime <= Date() else {
            throw TimeRecordError.futureTime
        }
        return true
    }

    // 完了済みレコード: 既存のバリデーション
    guard startTime < endTime else {
        throw TimeRecordError.startTimeAfterEndTime
    }
    // ... 以降は既存のロジック
}
```

**注意**: `EditHistoryViewModel.validateTimeRange()`も同様に修正が必要（197-209行目）。

## 9. 実装手順（最終版）

### ステップ1: Repository層の修正
1. `TimeRecordRepositoryProtocol`のシグネチャ修正（`endTime: Date?`）
2. `TimeRecordRepository.updateTimeRecord()`の修正
3. `TimeRecordRepository.validateTimeRange()`の修正
4. `MockTimeRecordRepository`の修正

### ステップ2: EditHistoryViewModel の修正
1. `isEditingInProgressRecord`プロパティを追加
2. `startEditing()`メソッドを修正
3. `saveChanges()`メソッドを修正
4. `isValidTimeRange`計算プロパティを修正
5. `validateTimeRange()`メソッドを修正
6. `resetEditingState()`メソッドを修正

### ステップ3: ユニットテストの作成と修正
1. 既存のテストでRepository呼び出し部分を確認・修正
2. `EditHistoryViewModelInProgressTests.swift`を作成
3. テストケース1〜6を実装

### ステップ4: コードフォーマットとテスト実行
1. `swiftformat .`を実行
2. 全ユニットテストを実行して成功を確認

### ステップ5: 統合テスト（手動）
1. シナリオ1を実行
2. シナリオ2を実行

### ステップ6: コミットとPR
1. `git commit -m "#6 bugfix: Fix in-progress record edit preserving endTime nil"`
2. Pre-push hook（フォーマット・テスト）が成功することを確認
3. `git push`
4. GitHub上でPR作成（日本語）

## 10. 受け入れ基準

- [ ] 作業中タスクの開始時間を変更しても、`endTime == nil`が保持される
- [ ] 作業履歴画面で緑色背景が維持される
- [ ] 作業履歴画面で「作業中」の文言が表示され続ける
- [ ] タイムクロックが動作し続ける
- [ ] 完了済みタスクの編集が従来通り動作する（回帰テストクリア）
- [ ] 既存のユニットテストが全て成功する
- [ ] 新規ユニットテストが追加され、成功する
- [ ] SwiftFormatチェックが成功する
- [ ] Pre-push hookが成功する

## 11. 参考資料

- Issue #6: https://github.com/ITK13201/TimeRabbit/issues/6
- CLAUDE.md: プロジェクトのアーキテクチャガイド
- TimeRecord Model定義: `TimeRabbit/Models.swift:60-101`
- EditHistoryViewModel: `TimeRabbit/viewmodels/EditHistoryViewModel.swift`
- TimeRecordRepository: `TimeRabbit/repositories/TimeRecordRepository.swift`
