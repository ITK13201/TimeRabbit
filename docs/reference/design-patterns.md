# TimeRabbit 設計パターンカタログ

**最終更新**: 2025年10月12日

---

## はじめに

このドキュメントでは、TimeRabbitで使用されている設計パターンをカタログ形式で解説します。

---

## MVVM (Model-View-ViewModel)

### 概要

TimeRabbitの中核となる設計パターン。**1:1 View-ViewModel** の厳格な対応を採用しています。

### 構造

```
View ↔ ViewModel ↔ Repository ↔ Model
```

### 実装例

```swift
// Model
@Model
final class Project {
  var id: UUID
  var projectId: String
  var name: String
}

// ViewModel
@MainActor
class ContentViewModel: BaseViewModel {
  @Published var projects: [Project] = []
  private let repository: ProjectRepositoryProtocol

  func loadProjects() {
    withLoadingSync {
      projects = try repository.fetchProjects()
    }
  }
}

// View
struct ContentView: View {
  @ObservedObject var viewModel: ContentViewModel

  var body: some View {
    List(viewModel.projects) { project in
      Text(project.name)
    }
    .onAppear {
      viewModel.loadProjects()
    }
  }
}
```

### 利点

- 責務の明確な分離
- テスタビリティの向上
- UI とビジネスロジックの独立性

---

## Repository Pattern

### 概要

データアクセス層を抽象化し、ビジネスロジックとデータ永続化を分離するパターン。

### 構造

```
ViewModel → RepositoryProtocol ← Repository
                                ← MockRepository
```

### 実装例

```swift
// Protocol
protocol ProjectRepositoryProtocol {
  func fetchProjects() throws -> [Project]
  func createProject(projectId: String, name: String, color: String) throws -> Project
}

// 実装
class ProjectRepository: ProjectRepositoryProtocol {
  private let modelContext: ModelContext

  func fetchProjects() throws -> [Project] {
    let descriptor = FetchDescriptor<Project>()
    return try modelContext.fetch(descriptor)
  }
}

// Mock
class MockProjectRepository: ProjectRepositoryProtocol {
  private var projects: [Project] = []

  func fetchProjects() throws -> [Project] {
    return projects
  }
}
```

### 利点

- データソースの切り替えが容易
- テスト時のモック注入
- ビジネスロジックとデータ層の分離

---

## Factory Pattern (ViewModelFactory)

### 概要

ViewModelの生成を一元管理し、依存性注入を実現するパターン。

### 実装例

```swift
class ViewModelFactory {
  private let projectRepository: ProjectRepositoryProtocol
  private let timeRecordRepository: TimeRecordRepositoryProtocol
  private let jobRepository: JobRepositoryProtocol
  private let dateService: DateService

  static func create(
    with repositories: (ProjectRepositoryProtocol, TimeRecordRepositoryProtocol, JobRepositoryProtocol),
    dateService: DateService
  ) -> ViewModelFactory {
    return ViewModelFactory(
      projectRepository: repositories.0,
      timeRecordRepository: repositories.1,
      jobRepository: repositories.2,
      dateService: dateService
    )
  }

  func createContentViewModel() -> ContentViewModel {
    ContentViewModel(repository: projectRepository)
  }

  func createStatisticsViewModel() -> StatisticsViewModel {
    StatisticsViewModel(
      repository: timeRecordRepository,
      dateService: dateService
    )
  }
}
```

### 利点

- 依存関係の集中管理
- テスト時の設定が容易
- ViewModelの生成ロジックをカプセル化

---

## Protocol-Oriented Programming

### 概要

Protocolを中心とした設計により、柔軟性とテスタビリティを向上させるパターン。

### 実装例

```swift
// Protocol定義
protocol ProjectRepositoryProtocol {
  func fetchProjects() throws -> [Project]
}

// 実装1: 本番環境
class ProjectRepository: ProjectRepositoryProtocol {
  private let modelContext: ModelContext
  func fetchProjects() throws -> [Project] { ... }
}

// 実装2: テスト環境
class MockProjectRepository: ProjectRepositoryProtocol {
  private var projects: [Project] = []
  func fetchProjects() throws -> [Project] { ... }
}

// 使用側（Protocolに依存）
class ContentViewModel {
  private let repository: ProjectRepositoryProtocol  // Protocol型

  init(repository: ProjectRepositoryProtocol) {
    self.repository = repository
  }
}
```

### 利点

- 実装の柔軟な切り替え
- モックによるテスト容易化
- 依存性の逆転（DIP）

---

## Observer Pattern (Combine)

### 概要

Combineフレームワークを使用した、状態変化の監視パターン。

### 実装例

```swift
// DateService（Observable）
@MainActor
class DateService: ObservableObject {
  @Published var selectedDate: Date = Date()
}

// Observer 1
class StatisticsViewModel: BaseViewModel {
  private let dateService: DateService
  private var cancellables = Set<AnyCancellable>()

  init(dateService: DateService) {
    self.dateService = dateService
    super.init()

    dateService.$selectedDate
      .sink { [weak self] date in
        self?.loadStatistics(for: date)
      }
      .store(in: &cancellables)
  }
}

// Observer 2
class HistoryViewModel: BaseViewModel {
  private let dateService: DateService

  var selectedDate: Date {
    get { dateService.selectedDate }
    set { dateService.selectedDate = newValue }
  }
}
```

### 利点

- 画面間の状態同期
- Single Source of Truth
- 自動的な更新通知

---

## Defensive Design Pattern

### 概要

データの整合性を保つため、削除後も情報を保持するパターン。

### 実装例

```swift
@Model
final class TimeRecord {
  // Primary relationships
  var project: Project?
  var job: Job?

  // Backup data（Defensive Design）
  var backupProjectId: String
  var backupProjectName: String
  var backupProjectColor: String
  var backupJobId: String
  var backupJobName: String

  // Display properties（Fallback logic）
  var displayProjectId: String {
    project?.projectId ?? backupProjectId
  }

  var displayProjectName: String {
    project?.name ?? backupProjectName
  }

  init(startTime: Date, project: Project, job: Job) {
    self.project = project
    self.job = job

    // Backup at creation
    self.backupProjectId = project.projectId
    self.backupProjectName = project.name
    self.backupProjectColor = project.color
    self.backupJobId = job.jobId
    self.backupJobName = job.name
  }
}
```

### 利点

- データ損失の防止
- 削除後も履歴の完全性を維持
- ユーザー体験の向上

---

## Singleton Pattern (Logger)

### 概要

アプリ全体で共有するロガーインスタンスをシングルトンとして提供。

### 実装例

```swift
import OSLog

enum AppLogger {
  static let app = Logger(subsystem: "dev.i-tk.TimeRabbit", category: "App")
  static let repository = Logger(subsystem: "dev.i-tk.TimeRabbit", category: "Repository")
  static let viewModel = Logger(subsystem: "dev.i-tk.TimeRabbit", category: "ViewModel")
  static let swiftData = Logger(subsystem: "dev.i-tk.TimeRabbit", category: "SwiftData")
  static let ui = Logger(subsystem: "dev.i-tk.TimeRabbit", category: "UI")
  static let database = Logger(subsystem: "dev.i-tk.TimeRabbit", category: "Database")
}

// 使用例
AppLogger.repository.debug("Creating project: \(projectId)")
AppLogger.viewModel.error("Failed to load data: \(error)")
```

### 利点

- グローバルアクセス
- カテゴリ別のログ管理
- 一貫したロギング戦略

---

## Template Method Pattern (BaseViewModel)

### 概要

共通処理を基底クラスで定義し、サブクラスで具体的な処理を実装するパターン。

### 実装例

```swift
// Base class
@MainActor
class BaseViewModel: ObservableObject {
  @Published var isLoading: Bool = false
  @Published var errorMessage: String?

  // Template method
  func withLoadingSync<T>(_ operation: () throws -> T) -> T? {
    isLoading = true
    defer { isLoading = false }

    do {
      return try operation()
    } catch {
      handleError(error)
      return nil
    }
  }

  func handleError(_ error: Error) {
    errorMessage = error.localizedDescription
  }
}

// Concrete class
class ContentViewModel: BaseViewModel {
  func loadProjects() {
    withLoadingSync {  // Use template method
      projects = try repository.fetchProjects()
    }
  }
}
```

### 利点

- 共通処理の一元化
- コードの重複排除
- エラーハンドリングの統一

---

## Dual Identifier Pattern

### 概要

TimeRabbit独自のパターン。システム用とビジネス用の2つの識別子を使い分ける。

### 実装例

```swift
@Model
final class Project {
  var id: UUID             // System identifier（不変）
  var projectId: String    // Business identifier（可変）
  var name: String
}

// 使用例
// ✅ Object identity（UUID使用）
projects.removeAll { $0.id == project.id }

// ✅ Business logic（String使用）
let proj = projects.first { $0.projectId == "PRJ001" }
```

### ルール

| 用途 | 使用する識別子 |
|------|--------------|
| オブジェクトの同一性確認 | UUID `id` |
| 削除・比較操作 | UUID `id` |
| ビジネスロジック検索 | String `projectId` / `jobId` |
| UI表示 | String `projectId` / `jobId` |
| 統計集計 | String `projectId` / `jobId` |

### 利点

- オブジェクト同一性の保証
- ユーザー定義IDの柔軟性
- ビジネスロジックとシステムの分離

---

## まとめ

TimeRabbitは、以下の設計パターンを組み合わせて構築されています：

| パターン | 用途 | 主な利点 |
|---------|------|---------|
| **MVVM** | アーキテクチャ全体 | 責務分離、テスタビリティ |
| **Repository** | データ層 | データソース抽象化 |
| **Factory** | 依存性注入 | 生成ロジック一元化 |
| **Protocol-Oriented** | 全体 | 柔軟性、テスト容易化 |
| **Observer (Combine)** | 状態管理 | 自動更新、状態同期 |
| **Defensive Design** | データ整合性 | データ損失防止 |
| **Singleton** | ロギング | グローバルアクセス |
| **Template Method** | 共通処理 | コード重複排除 |
| **Dual Identifier** | 識別子管理 | システムとビジネスの分離 |

これらのパターンにより、保守性・拡張性・テスタビリティに優れたアプリケーションを実現しています。

---

## 関連ドキュメント

- [../guides/architecture-guide.md](../guides/architecture-guide.md) - アーキテクチャ詳細
- [data-models.md](data-models.md) - データモデル
- [tech-stack.md](tech-stack.md) - 技術スタック
