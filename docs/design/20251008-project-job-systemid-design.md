# Issue #2: ProjectとJobにsystemIdを追加する - 設計書

**日付**: 2025年10月8日
**対象Issue**: [#2](https://github.com/ITK13201/TimeRabbit/issues/2)
**ステータス**: 実装完了

## 1. 概要

`Project`と`Job`モデルにUUIDベースの`id`プロパティを追加し、全モデルで一貫した識別子体系を確立。ユーザー定義のIDは`projectId`/`jobId`として、ビジネスロジック用に使用する。

**最終的な実装:**
- UUIDベースのIDを全モデルで`id`に統一
- ユーザー定義IDは`projectId` (Project) / `jobId` (Job) に変更
- TimeRecordのバックアップフィールドをprefix形式に変更

## 2. 背景と目的

- ユーザー定義の`id`（String）は編集可能であり、一意性制約はあるが変更される可能性がある
- システム内部で不変の識別子を持つことで、データの整合性とトレーサビリティを向上
- 以前削除された機能だが、再度実装が必要になった

## 3. 設計詳細

### 3.1 モデル変更

#### 3.1.1 Project モデル (`Models.swift:14-31`)

**実装されたモデル構造:**
```swift
@Model
final class Project {
  var id: UUID             // システム内部管理用の一意識別子（UUID）
  var projectId: String    // ユーザー編集可能な案件ID（ビジネスロジック用）
  var name: String         // 案件名
  var color: String
  var createdAt: Date

  @Relationship(deleteRule: .nullify, inverse: \TimeRecord.project)
  var timeRecords: [TimeRecord] = []

  init(projectId: String, name: String, color: String = "blue") {
    self.id = UUID()         // 自動生成
    self.projectId = projectId
    self.name = name
    self.color = color
    self.createdAt = Date()
  }
}
```

**重要な変更点:**
- `systemId` → `id` (UUID) に変更（全モデルで統一）
- 旧 `id` → `projectId` (String) に変更（ビジネスロジック用）

#### 3.1.2 Job モデル (`Models.swift:33-58`)

**実装されたモデル構造:**
```swift
@Model
final class Job {
  var id: UUID             // システム内部管理用の一意識別子（UUID）
  var jobId: String        // 固定値: "001", "002", "003", "006", "999"
  var name: String         // 固定値: 対応する作業区分名
  var createdAt: Date

  @Relationship(deleteRule: .nullify, inverse: \TimeRecord.job)
  var timeRecords: [TimeRecord] = []

  init(jobId: String, name: String) {
    self.id = UUID()         // 自動生成
    self.jobId = jobId
    self.name = name
    self.createdAt = Date()
  }

  static let predefinedJobs = [
    ("001", "開発"),
    ("002", "保守"),
    ("003", "POサポート・コンサル"),
    ("006", "デザイン"),
    ("999", "その他")
  ]
}
```

**重要な変更点:**
- `systemId` → `id` (UUID) に変更（全モデルで統一）
- 旧 `id` → `jobId` (String) に変更（ビジネスロジック用）

#### 3.1.3 TimeRecord モデルのバックアップフィールド (`Models.swift:70-75`)

**実装されたバックアップフィールド構造:**
```swift
// Backup data for deleted entities
var backupProjectId: String     // Project.projectId のバックアップ
var backupProjectName: String   // Project.name のバックアップ
var backupProjectColor: String  // Project.color のバックアップ
var backupJobId: String         // Job.jobId のバックアップ
var backupJobName: String       // Job.name のバックアップ
```

**重要な変更点:**
- prefix形式に統一: `projectId` → `backupProjectId`, `jobId` → `backupJobId` など
- 名前の衝突を回避し、意図を明確化

### 3.2 SwiftDataマイグレーション対応

**課題:**
- 既存のデータベースには`systemId`が存在しない
- 既存の`Project`と`Job`レコードに対して自動的にUUIDを割り当てる必要がある

**SwiftDataの挙動:**
- SwiftDataはスキーマ変更を自動検出し、新規プロパティを追加する
- `UUID`型はデフォルト値を持たないため、既存レコードには**自動的にランダムなUUIDが割り当てられる**
- 明示的なマイグレーション処理は**不要**

**確認事項:**
- アプリ起動時に既存データが正常に読み込まれること
- 新規作成される`Project`と`Job`に正しく`systemId`が生成されること

### 3.3 Repository層の影響（実装完了）

#### 3.3.1 ProjectRepository (`ProjectRepository.swift`)

**実施した変更:**
- メソッド引数を `id` → `projectId` に変更
- `createProject(projectId:name:color:)`: 引数名変更
- `updateProject(_:projectId:name:color:)`: 引数名変更
- `isProjectIdUnique(_ projectId:excluding:)`: 引数名とロジック変更
- `fetchTimeRecordsForProject()`: `backupProjectId`で検索するように変更
- Predicateを`project.projectId`に変更

#### 3.3.2 JobRepository (`JobRepository.swift`)

**実施した変更:**
- メソッド引数を `id` → `jobId` に変更
- `getJobById(_ jobId:)`: 引数名変更
- `fetchAllJobs()`: ソート条件を`\.jobId`に変更
- `initializePredefinedJobs()`: `Job(jobId:name:)`に変更
- Predicateを`job.jobId`に変更

#### 3.3.3 TimeRecordRepository (`TimeRecordRepository.swift`)

**実施した変更:**
- `fetchTimeRecords()`: Predicateを`record.backupProjectId`に変更
- `updateTimeRecord()`: バックアップフィールドを`backup*`形式に変更
- ログ出力を`project.projectId`, `job.jobId`に変更

#### 3.3.4 MockRepositories

**実施した変更:**
- `MockProjectRepository.swift`: 全メソッドを`projectId`に変更、**deleteProject()でオブジェクト同一性確認に`id` (UUID)を使用**
- `MockJobRepository.swift`: 全メソッドを`jobId`に変更
- `MockTimeRecordRepository.swift`: バックアップフィールドを`backup*`形式に変更

### 3.4 ViewModel層の影響（実装完了）

**実施した変更:**
- `ProjectRowViewModel.swift`:
  - `project.projectId`, `job.jobId`に変更
  - UserDefaultsキー: `"selectedJob_\(project.projectId)"`に変更
  - `currentRecord?.backupProjectId`に変更
- `AddProjectViewModel.swift`: `createProject(projectId:...)`に変更

### 3.5 View層の影響（実装完了）

**実施した変更:**
- `ProjectRowView.swift`: `viewModel.project.projectId`に変更

### 3.6 識別子の使い分けルール（重要）

**オブジェクトの同一性確認:**
- **必ず`id` (UUID)を使用**
- 例: `project.id == otherProject.id`, `$0.id == record.id`
- SwiftDataの`persistentModelID`と役割が異なる独立したUUID

**ビジネスロジック（検索・集計・一意性チェック）:**
- **`projectId`/`jobId` (String)を使用**
- 例: `project.projectId == "PRJ001"`, `job.jobId == "001"`
- タイムレコード集計時の同一性確認
- ユーザー向け表示

**実装で守られていること:**
- MockProjectRepository.deleteProject(): `$0.id == project.id` ✅
- MockTimeRecordRepository.deleteTimeRecord(): `$0.id == record.id` ✅
- テストコード: 全て`id` (UUID)で同一性確認 ✅

### 3.7 テスト影響（実装完了）

#### 3.7.1 既存テスト修正完了

**修正したファイル:**
- `TimeRabbitTests/TimeRabbitTests.swift`: テスト名と内容を`id` (UUID)に更新
- `TimeRabbitTests/EditHistoryViewModelTests.swift`: `job.jobId == "001"`に変更
- `TimeRabbitTests/StatisticsViewModelCommandTests.swift`: `createProject(projectId:...)`, `job.jobId`に変更

**修正内容:**
- モデル生成: `createProject(id:` → `createProject(projectId:`
- Job検索: `jobs.first { $0.id == "001" }` → `jobs.first { $0.jobId == "001" }`
- テスト名: "systemId" → "id (UUID)"に更新

#### 3.7.2 新規テスト追加完了

**追加したテスト (`TimeRabbitTests.swift`):**
```swift
@Suite("Project and Job systemId Tests")
struct SystemIdTests {

  @Test("Project id (UUID) is automatically generated and unique")
  func testProjectSystemIdGeneration() throws {
    let repo = MockProjectRepository(withSampleData: false)
    let project1 = try repo.createProject(projectId: "P001", name: "Project 1", color: "blue")
    let project2 = try repo.createProject(projectId: "P002", name: "Project 2", color: "red")

    // id (UUID) が生成されている
    let zeroUUID = UUID(uuidString: "00000000-0000-0000-0000-000000000000")!
    #expect(project1.id != zeroUUID)
    #expect(project2.id != zeroUUID)

    // id (UUID) が一意
    #expect(project1.id != project2.id)
  }

  @Test("Project id (UUID) remains unchanged when projectId is updated")
  func testProjectSystemIdImmutable() throws {
    let repo = MockProjectRepository(withSampleData: false)
    let project = try repo.createProject(projectId: "P001", name: "Project", color: "blue")
    let originalId = project.id

    try repo.updateProject(project, projectId: "P002", name: "Updated", color: "green")

    // id (UUID) は変更されない
    #expect(project.id == originalId)
  }

  @Test("Job id (UUID) is automatically generated and unique")
  func testJobSystemIdGeneration() throws {
    let repo = MockJobRepository()
    let jobs = try repo.fetchAllJobs()

    #expect(jobs.count >= 2)

    let job1 = jobs[0]
    let job2 = jobs[1]

    let zeroUUID = UUID(uuidString: "00000000-0000-0000-0000-000000000000")!
    #expect(job1.id != zeroUUID)
    #expect(job2.id != zeroUUID)
    #expect(job1.id != job2.id)
  }

  @Test("All predefined jobs have unique ids (UUID)")
  func testAllJobsHaveUniqueSystemIds() throws {
    let repo = MockJobRepository()
    let jobs = try repo.fetchAllJobs()

    let ids = jobs.map { $0.id }
    let uniqueIds = Set(ids)
    #expect(ids.count == uniqueIds.count)
  }
}
```

**テスト結果:** 全40テスト成功 ✅

## 4. 実装手順（実施済み）

### 4.1 実施した手順

1. **モデル更新** (`Models.swift`) ✅
   - `Project`: `systemId` → `id` (UUID), `id` → `projectId` (String)
   - `Job`: `systemId` → `id` (UUID), `id` → `jobId` (String)
   - `TimeRecord`: バックアップフィールドをprefix形式に変更

2. **Repository層更新** ✅
   - ProjectRepository, JobRepository, TimeRecordRepository
   - MockProjectRepository, MockJobRepository, MockTimeRecordRepository
   - メソッド引数、Predicate、ロジックを全て更新

3. **ViewModel層更新** ✅
   - ProjectRowViewModel, AddProjectViewModel
   - `projectId`/`jobId`への参照を更新

4. **View層更新** ✅
   - ProjectRowView: `project.projectId`に変更

5. **テスト更新** ✅
   - TimeRabbitTests.swift: 新規テスト追加
   - EditHistoryViewModelTests.swift: `jobId`に更新
   - StatisticsViewModelCommandTests.swift: `projectId`/`jobId`に更新

6. **ビルド&テスト確認** ✅
   ```bash
   xcodebuild build -project TimeRabbit.xcodeproj -scheme TimeRabbit -destination 'platform=macOS'
   # 結果: BUILD SUCCEEDED

   xcodebuild test -project TimeRabbit.xcodeproj -scheme TimeRabbit -destination 'platform=macOS' -testPlan TimeRabbitTests
   # 結果: TEST SUCCEEDED (全40テスト成功)
   ```

### 4.2 修正したファイル一覧（合計18ファイル）

**Models & Repositories (7ファイル):**
- Models.swift
- ProjectRepository.swift
- JobRepository.swift
- TimeRecordRepository.swift
- MockProjectRepository.swift
- MockJobRepository.swift
- MockTimeRecordRepository.swift

**ViewModels (2ファイル):**
- ProjectRowViewModel.swift
- AddProjectViewModel.swift

**Views (1ファイル):**
- ProjectRowView.swift

**Tests (3ファイル):**
- TimeRabbitTests.swift
- EditHistoryViewModelTests.swift
- StatisticsViewModelCommandTests.swift

## 5. リスクと対策

| リスク | 影響度 | 対策 |
|--------|--------|------|
| 既存データのマイグレーション失敗 | 高 | SwiftDataが自動的にUUIDを割り当てるため、マイグレーション処理は不要。アプリ起動時に既存データが読み込まれることを確認 |
| テストの失敗 | 中 | モデルのinitで自動生成されるため、既存テストへの影響は最小限。テスト実行で確認 |
| パフォーマンス低下 | 低 | UUIDプロパティ1つの追加による影響は微小。既存の検索ロジックは`id`を使用するため変更なし |

## 6. 今後の拡張性

### 6.1 systemIdを活用した機能
- **監査ログ**: `systemId`を使って変更履歴をトレース
- **データ同期**: 複数デバイス間でのデータ同期時に`systemId`で一意性を保証
- **高度な検索**: `systemId`ベースのクエリメソッド追加

### 6.2 TimeRecordへの拡張
将来的に必要な場合、`TimeRecord`にバックアップフィールドを追加:
```swift
var projectSystemId: UUID?  // Project.systemId のバックアップ
var jobSystemId: UUID?      // Job.systemId のバックアップ
```

## 7. まとめ

### 7.1 実装結果

- **変更範囲**: Models, Repository, ViewModel, View, Tests（合計18ファイル）
- **マイグレーション**: SwiftDataが自動処理（明示的な処理不要）
- **テスト結果**: 全40テスト成功 ✅
- **ビルド**: 成功 ✅

### 7.2 達成した目標

1. **全モデルでUUID `id`を統一** ✅
   - `Project.id`, `Job.id`, `TimeRecord.id` 全てUUID型
   - SwiftDataの`persistentModelID`とは独立した識別子

2. **ビジネスロジック用IDの明確化** ✅
   - `projectId` (String): ユーザー編集可能な案件ID
   - `jobId` (String): 固定の作業区分ID
   - タイムレコード集計時の同一性確認に使用

3. **識別子の使い分けルール確立** ✅
   - オブジェクト同一性: `id` (UUID)を使用
   - ビジネスロジック: `projectId`/`jobId` (String)を使用
   - 実装で厳密に守られている

4. **バックアップフィールドの整理** ✅
   - prefix形式: `backupProjectId`, `backupJobId`など
   - 名前の衝突を回避し、意図を明確化

### 7.3 今後の保守における注意点

**必ず守るべきルール:**
- オブジェクトの削除・比較: `$0.id == object.id` (UUID)
- ビジネスロジック検索: `project.projectId == "PRJ001"` (String)
- 新規Repository実装時も同様のパターンを踏襲

**SwiftDataとの関係:**
- `id` (UUID): アプリ独自の識別子
- `persistentModelID`: SwiftData管理の識別子
- 両者は独立して存在し、異なる目的で使用

この実装により、一貫性のある識別子体系を確立し、データの整合性とトレーサビリティを向上させることができました。
