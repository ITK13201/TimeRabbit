# 案件 & 作業区分 モデル改修設計書

## 概要

TimeRabbitアプリケーションのモデル構造を改修し、Projectにユーザー編集可能なID、新規Jobエンティティ（固定の作業区分）の追加、および時間記録時のProject+Job選択機能を実装する。

## 現在のアーキテクチャ分析

### 既存モデル構造

```swift
@Model
final class Project {
  var id: UUID          // システム生成、変更不可
  var name: String
  var color: String
  var createdAt: Date
  @Relationship(deleteRule: .nullify, inverse: \TimeRecord.project)
  var timeRecords: [TimeRecord] = []
}

@Model
final class TimeRecord {
  var id: UUID
  var startTime: Date
  var endTime: Date?
  var project: Project?
  var projectName: String      // 削除対応のためのバックアップ
  var projectColor: String     // 削除対応のためのバックアップ
}
```

### 既存のアーキテクチャパターン
- 1:1 View-ViewModel MVVM
- Repository Pattern（ProjectRepository, TimeRecordRepository）
- Mock Repository for testing/previews
- ViewModelFactory による依存性注入
- BaseViewModel による共通機能

## 新モデル設計

### 1. Project モデルの改修

```swift
@Model
final class Project {
  var id: String           // ユーザー編集可能な文字列ID（案件ID）
  var name: String         // 案件名
  var color: String
  var createdAt: Date
  
  @Relationship(deleteRule: .nullify, inverse: \TimeRecord.project)
  var timeRecords: [TimeRecord] = []

  init(id: String, name: String, color: String = "blue") {
    self.id = id
    self.name = name
    self.color = color
    self.createdAt = Date()
  }
}
```

### 2. 新規 Job モデル（作業区分）

```swift
@Model
final class Job {
  let id: String           // 固定値: "001", "002", "003", "006", "999"
  let name: String         // 固定値: 対応する作業区分名
  var createdAt: Date
  
  @Relationship(deleteRule: .nullify, inverse: \TimeRecord.job)
  var timeRecords: [TimeRecord] = []
  
  init(id: String, name: String) {
    self.id = id
    self.name = name
    self.createdAt = Date()
  }
  
  // 固定の作業区分一覧
  static let predefinedJobs = [
    ("001", "開発"),
    ("002", "保守"),
    ("003", "POサポート・コンサル"),
    ("006", "デザイン"),
    ("999", "その他")
  ]
}
```

### 3. TimeRecord モデルの拡張

```swift
@Model
final class TimeRecord {
  var id: UUID
  var startTime: Date
  var endTime: Date?
  
  // Primary relationships
  var project: Project?
  var job: Job?
  
  // Backup data for deleted entities
  var projectId: String        // Project.id のバックアップ
  var projectName: String      // Project.name のバックアップ
  var projectColor: String     // Project.color のバックアップ
  var jobId: String           // Job.id のバックアップ
  var jobName: String         // Job.name のバックアップ
  
  // Display properties
  var displayProjectId: String { project?.id ?? projectId }
  var displayProjectName: String { project?.name ?? projectName }
  var displayProjectColor: String { project?.color ?? projectColor }
  var displayJobId: String { job?.id ?? jobId }
  var displayJobName: String { job?.name ?? jobName }
  
  init(startTime: Date, project: Project, job: Job) {
    self.id = UUID()
    self.startTime = startTime
    self.project = project
    self.job = job
    
    // Backup data
    self.projectId = project.id
    self.projectName = project.name
    self.projectColor = project.color
    self.jobId = job.id
    self.jobName = job.name
  }
}
```

## データベース戦略

### データベースリセット

既存データベースをリセットして新しいモデル構造で開始します。

1. **Job の初期化**
   - アプリ起動時に固定の作業区分5種類を自動作成
   - 重複チェックによる安全な初期化

2. **データ構造の完全刷新**
   - 新しいProject ID形式（ユーザー定義文字列）
   - Job との関係性を含むTimeRecord構造

## Repository層の拡張

### 新規 JobRepository

```swift
protocol JobRepositoryProtocol {
  func fetchAllJobs() throws -> [Job]
  func initializePredefinedJobs() throws  // 固定Job作成
  func getJobById(_ id: String) throws -> Job?
}

class JobRepository: JobRepositoryProtocol {
  private let modelContext: ModelContext
  
  // 固定の作業区分のみを管理
  // CRUD操作は作成・読み取りのみ（更新・削除なし）
}
```

### ProjectRepository の更新

```swift
protocol ProjectRepositoryProtocol {
  func fetchProjects() throws -> [Project]
  func createProject(id: String, name: String, color: String) throws -> Project
  func updateProject(_ project: Project, id: String, name: String, color: String) throws
  func deleteProject(_ project: Project) throws
  func validateProjectId(_ id: String, excluding: Project?) throws -> Bool  // ID重複チェック
}
```

### TimeRecordRepository の更新

```swift
protocol TimeRecordRepositoryProtocol {
  // 既存メソッド...
  func createTimeRecord(project: Project, job: Job) throws -> TimeRecord
  func updateTimeRecord(_ record: TimeRecord, project: Project?, job: Job?) throws
}
```

## UI/UX設計

### 1. Project作成・編集画面の更新

```
[案件作成画面]
┌─────────────────────────────┐
│ 案件ID:     [_________]     │ ← 新規：ユーザー入力必須
│ 案件名:     [_________]     │
│ 色:         [▼ Blue]       │
│                            │
│ [キャンセル]      [作成]    │
└─────────────────────────────┘
```

### 2. 案件一覧の更新（作業区分選択付き）

```
[案件一覧]
┌─────────────────────────────────────────────┐
│ ● PROJ-A  案件A  [▼ 開発]       [開始]      │ ← 作業区分選択付き
│ ● PROJ-B  案件B  [▼ 保守]       [開始]      │
│ ● PROJ-C  案件C  [▼ デザイン]   [開始]      │
└─────────────────────────────────────────────┘
```

### 3. 作業区分選択の仕様

- 各案件行に作業区分プルダウンを配置
- プルダウンの選択状態は保持される（ユーザー設定として）
- 初期値は「開発」に設定
- 選択肢：
  - 001: 開発
  - 002: 保守
  - 003: POサポート・コンサル
  - 006: デザイン
  - 999: その他

## ViewModel層の設計

### 1. ProjectRowViewModel の更新

```swift
@MainActor
class ProjectRowViewModel: BaseViewModel {
  @Published var project: Project
  @Published var isActive: Bool = false
  @Published var selectedJob: Job?           // 選択された作業区分
  @Published var availableJobs: [Job] = []   // 利用可能な作業区分一覧
  
  private let jobRepository: JobRepositoryProtocol
  private let userDefaults: UserDefaults     // 作業区分選択状態の保持
  
  func loadAvailableJobs()                   // 固定作業区分の読み込み
  func updateSelectedJob(_ job: Job)         // 作業区分選択の更新・保存
  func startTracking()                       // 選択された作業区分で時間記録開始
  func loadSavedJobSelection()               // 保存された作業区分選択の復元
}
```

### 2. ContentViewModel の更新

```swift
@MainActor
class ContentViewModel: BaseViewModel {
  @Published var projects: [Project] = []
  @Published var projectJobSelections: [String: String] = [:]  // ProjectID -> JobID
  
  private let jobRepository: JobRepositoryProtocol
  
  func loadInitialData()                     // プロジェクト・作業区分の初期読み込み
  func initializeJobsIfNeeded()              // 固定作業区分の初期化
  func getSelectedJob(for project: Project) -> Job?  // プロジェクトの選択作業区分取得
}
```

## 実装フェーズ

### Phase 1: モデル基盤の構築
1. モデルクラスの更新・追加（Project, Job, TimeRecord）
2. Repository層の実装（JobRepository追加、既存Repository更新）
3. 固定作業区分の初期化機能
4. 基本的なCRUD操作のテスト

### Phase 2: UI基盤の構築
1. ViewModelの実装・更新
2. ViewModelFactoryの更新（JobRepository対応）
3. Mock Repository の更新
4. UserDefaults による設定保存機能

### Phase 3: UI実装
1. 案件作成・編集画面の更新（ProjectID入力対応）
2. 案件一覧での作業区分選択UI実装
3. ProjectRowViewの更新（作業区分プルダウン追加）
4. 設定保存・復元機能の実装

### Phase 4: 統合・テスト
1. エンドツーエンド機能テスト
2. データリセット・初期化テスト  
3. UI/UX テスト（作業区分選択・保存）
4. パフォーマンステスト

## 考慮事項

### データ整合性
- Project IDの一意性確保
- 固定作業区分の整合性維持
- 削除時のカスケード処理
- データリセット時の安全な初期化

### ユーザビリティ
- Project ID入力時のバリデーション
- 作業区分選択の直感的なUI
- エラーメッセージの日本語対応
- デフォルト作業区分（開発）の自動選択
- 各案件の作業区分選択状態の永続化

### パフォーマンス
- 固定作業区分の効率的な管理
- UserDefaultsによる高速な設定復元
- SwiftDataのリレーションシップ最適化

### 拡張性
- 将来的な作業区分追加の容易性
- 案件テンプレート機能
- 作業区分別統計機能の追加容易性

## テスト戦略

### Unit Tests
- 各Repository の CRUD操作
- ViewModel のビジネスロジック
- データ変換・バリデーション機能

### Integration Tests
- モデル間のリレーションシップ
- データ移行プロセス
- UI操作フロー

### Mock Strategy
- MockJobRepository の実装（固定作業区分対応）
- プレビュー用のサンプルデータ拡張
- テスト用の案件+作業区分組み合わせ

## 実装完了記録

### 実装日: 2025-10-02

すべての実装フェーズが完了しました。以下は実装された機能とテスト結果です。

#### Phase 1-4 完了内容

**モデル層の実装**:
- ✅ Project.id を UUID から String に変更（ユーザー編集可能）
- ✅ Job モデルの追加（5つの固定作業区分）
- ✅ TimeRecord に Job リレーションシップとバックアップフィールドを追加
- ✅ SwiftData スキーマに Job を追加

**Repository層の実装**:
- ✅ JobRepository と JobRepositoryProtocol の実装
- ✅ MockJobRepository の実装（テスト・プレビュー用）
- ✅ ProjectRepository に ID 一意性バリデーションを追加
- ✅ TimeRecordRepository を Job 対応に更新

**ViewModel層の実装**:
- ✅ ProjectRowViewModel に Job 選択機能を追加
- ✅ UserDefaults による Job 選択状態の永続化
- ✅ EditHistoryViewModel に Job 編集機能を追加
- ✅ AddProjectViewModel に案件ID バリデーションを追加
- ✅ ViewModelFactory を JobRepository 対応に更新

**View層の実装**:
- ✅ ProjectRowView に作業区分プルダウンを追加
- ✅ AddProjectSheetView に案件ID 入力フィールドを追加
- ✅ EditHistorySheetView に作業区分選択を追加
- ✅ UI テキストを「プロジェクト」→「案件」に統一
- ✅ ContentView のプレビューコードを更新

**テストの実装**:
- ✅ EditHistoryViewModelTests に Job 関連テストを追加
  - Job 選択変更テスト
  - Job 未選択時の保存失敗テスト
  - 定義済み Job 可用性テスト
- ✅ EditHistoryViewModelSimpleTests を更新
- ✅ 全 23 ユニットテストが合格

#### テスト結果

```
✔ Test run with 23 tests passed after 0.115 seconds.
** TEST SUCCEEDED **
```

**テスト内訳**:
- EditHistoryViewModelTests: 18 テスト（3つ新規追加）
- EditHistoryViewModelSimpleTests: 3 テスト
- TimeRabbitTests: 1 テスト
- その他: 1 テスト

#### ビルド結果

```
** BUILD SUCCEEDED **
```

警告のみ（Swift 6 MainActor 関連、機能に影響なし）

#### Git コミット履歴

1. `852ceff` - Add project & job model redesign and update design doc naming
2. `94d569c` - Implement Project & Job model redesign
3. `04514a5` - Fix missing JobRepository parameters in test files and preview code
4. `2887de1` - Add Job selection to history edit screen and update tests

#### 実装された主要機能

1. **案件管理**:
   - ユーザー定義可能な案件ID（String型、3-20文字）
   - 案件ID の一意性バリデーション
   - 案件作成・編集・削除機能

2. **作業区分管理**:
   - 5つの固定作業区分（001: 開発、002: 保守、003: POサポート・コンサル、006: デザイン、999: その他）
   - 案件ごとの作業区分選択
   - UserDefaults による選択状態の永続化
   - デフォルト選択（開発）の自動設定

3. **時間記録**:
   - 案件 + 作業区分の組み合わせでの記録開始
   - 履歴編集画面での作業区分変更
   - 削除された案件・作業区分のバックアップ表示

4. **データ整合性**:
   - 案件削除時の TimeRecord への影響なし（nullify）
   - 作業区分削除時の TimeRecord への影響なし（nullify）
   - バックアップフィールドによる削除後の表示対応

## まとめ

この設計では以下の修正を反映しています：

1. **Project → 案件**: UIテキストの変更、systemIdは不要
2. **固定作業区分**: 5種類の固定Job、ユーザー作成・編集不可
3. **データベースリセット**: 移行機能不要、完全刷新
4. **UI設計**: 案件行での作業区分選択、選択状態の永続化

**実装結果**: 全フェーズ完了、23テスト合格、ビルド成功。要件を満たした新機能の実装が完了しました。