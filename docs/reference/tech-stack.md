# TimeRabbit 技術スタック

**最終更新**: 2025年10月12日

---

## コア技術

### Swift & SwiftUI

| 技術 | バージョン | 用途 |
|------|-----------|------|
| **Swift** | 5.0 | プログラミング言語 |
| **SwiftUI** | macOS 14.0+ | UIフレームワーク |
| **SwiftData** | macOS 14.0+ | データ永続化 |
| **Combine** | macOS 14.0+ | リアクティブプログラミング |
| **OSLog** | macOS 14.0+ | ロギングシステム |

### SwiftUIの活用

```swift
// 宣言的UI
struct ContentView: View {
  @ObservedObject var viewModel: ContentViewModel

  var body: some View {
    NavigationSplitView {
      // ...
    }
  }
}

// プレビュー
#Preview {
  let mockRepo = MockProjectRepository(withSampleData: true)
  let factory = ViewModelFactory.create(with: (mockRepo, ...), ...)

  ContentView(viewModel: factory.createContentViewModel())
}
```

### SwiftDataの活用

```swift
// モデル定義
@Model
final class Project {
  var id: UUID
  var projectId: String
  var name: String
  // ...
}

// リレーションシップ
@Relationship(deleteRule: .nullify, inverse: \TimeRecord.project)
var timeRecords: [TimeRecord] = []
```

---

## 開発ツール

### Xcode

| 項目 | 値 | 備考 |
|------|-----|------|
| **バージョン** | 16.1+ | objectVersion 77対応 |
| **プロジェクトフォーマット** | objectVersion 77 | Xcode 16.1+必須 |
| **デプロイターゲット** | macOS 14.0 | Sonoma以降 |

### テストフレームワーク

| ツール | 用途 | 備考 |
|--------|------|------|
| **Swift Testing** | ユニットテスト | XCTestの代替 |
| **XCTest** | - | 使用せず（Swift Testingに統一） |

**Swift Testingの特徴:**
```swift
import Testing

@Suite("Project Tests")
struct ProjectTests {
  @Test("Create project with valid data")
  func testCreateProject() throws {
    let repo = MockProjectRepository(withSampleData: false)
    let project = try repo.createProject(projectId: "P001", name: "Test", color: "blue")

    #expect(project.projectId == "P001")
  }
}
```

### CI/CD

| ツール | 用途 | 実行環境 |
|--------|------|---------|
| **GitHub Actions** | CI/CD | macOS 15, Xcode 16.4 |

---

## プロジェクト設定

### ビルド設定

```swift
// project.pbxproj より
MACOSX_DEPLOYMENT_TARGET = 14.0
SWIFT_VERSION = 5.0
MARKETING_VERSION = 1.0
SWIFT_EMIT_LOC_STRINGS = YES
ENABLE_PREVIEWS = YES
```

### Bundle Identifier

| ビルド構成 | Bundle ID | アプリ名 |
|-----------|----------|---------|
| **Debug** | `dev.i-tk.TimeRabbit.dev` | `TimeRabbit.dev.app` |
| **Release** | `dev.i-tk.TimeRabbit` | `TimeRabbit.app` |

### コード署名

```swift
CODE_SIGN_STYLE = Automatic
CODE_SIGN_IDENTITY = "-"  // Ad-hoc署名（リリース時）
```

**特徴:**
- Apple Developer証明書不要
- Ad-hoc署名で配布
- macOS Gatekeeper警告あり（回避策をリリースノートに記載）

---

## アーキテクチャパターン

### MVVM (Model-View-ViewModel)

```swift
// Model
@Model
final class Project { ... }

// View
struct ContentView: View {
  @ObservedObject var viewModel: ContentViewModel
}

// ViewModel
@MainActor
class ContentViewModel: BaseViewModel {
  @Published var projects: [Project] = []
}
```

### Repository Pattern

```swift
// Protocol
protocol ProjectRepositoryProtocol {
  func fetchProjects() throws -> [Project]
  func createProject(...) throws -> Project
}

// 実装
class ProjectRepository: ProjectRepositoryProtocol { ... }

// Mock
class MockProjectRepository: ProjectRepositoryProtocol { ... }
```

### Dependency Injection

```swift
// Factory
class ViewModelFactory {
  private let projectRepository: ProjectRepositoryProtocol

  func createContentViewModel() -> ContentViewModel {
    ContentViewModel(repository: projectRepository, ...)
  }
}
```

---

## データ永続化

### SwiftData

```swift
// ModelContext
let modelContext = ModelContext(modelContainer)

// CRUD操作
modelContext.insert(project)
try modelContext.save()
modelContext.delete(project)
```

### UserDefaults

```swift
// Job選択の永続化
let key = "selectedJob_\(project.projectId)"
UserDefaults.standard.set(job.jobId, forKey: key)

// 復元
if let savedJobId = UserDefaults.standard.string(forKey: key) {
  selectedJob = jobs.first { $0.jobId == savedJobId }
}
```

---

## ロギング

### OSLog

```swift
import OSLog

enum AppLogger {
  static let app = Logger(subsystem: "dev.i-tk.TimeRabbit", category: "App")
  static let repository = Logger(subsystem: "dev.i-tk.TimeRabbit", category: "Repository")
  static let swiftData = Logger(subsystem: "dev.i-tk.TimeRabbit", category: "SwiftData")
  static let viewModel = Logger(subsystem: "dev.i-tk.TimeRabbit", category: "ViewModel")
  static let ui = Logger(subsystem: "dev.i-tk.TimeRabbit", category: "UI")
  static let database = Logger(subsystem: "dev.i-tk.TimeRabbit", category: "Database")
}
```

**使用例:**
```swift
AppLogger.repository.debug("Creating project with ID: \(projectId)")
AppLogger.viewModel.error("Failed to load data: \(error)")
```

**デバッグ方法:**
```bash
# Xcodeコンソール
# Console.appでフィルタ: subsystem:dev.i-tk.TimeRabbit category:Repository
```

---

## ビルドスクリプト

### DMG作成

```bash
# scripts/create-dmg.sh
#!/bin/bash
APP_PATH="$1"
OUTPUT_DMG="$2"

hdiutil create -volname "TimeRabbit" \
  -srcfolder "$APP_PATH" \
  -ov -format UDZO \
  "$OUTPUT_DMG"
```

### エクスポート設定

```xml
<!-- exportOptions.plist -->
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "...">
<plist version="1.0">
<dict>
  <key>method</key>
  <string>mac-application</string>
  <key>signingStyle</key>
  <string>automatic</string>
</dict>
</plist>
```

---

## パフォーマンス最適化

### SwiftDataクエリ最適化

```swift
// ✅ 効率的なクエリ
let descriptor = FetchDescriptor<Project>(
  predicate: #Predicate<Project> { project in
    project.projectId == targetId
  },
  sortBy: [SortDescriptor(\.name)]
)

// ❌ 非効率（全件取得後フィルタ）
let projects = try modelContext.fetch(FetchDescriptor<Project>())
let filtered = projects.filter { $0.projectId == targetId }
```

### Combine活用

```swift
// DateServiceで状態共有
@MainActor
class DateService: ObservableObject {
  @Published var selectedDate: Date = ...
}

// 複数ViewModelで購読
class StatisticsViewModel: BaseViewModel {
  private var cancellables = Set<AnyCancellable>()

  init(dateService: DateService) {
    dateService.$selectedDate
      .sink { [weak self] date in
        self?.loadStatistics(for: date)
      }
      .store(in: &cancellables)
  }
}
```

---

## セキュリティ

### データ保護

- **ローカルストレージのみ**: クラウド同期なし
- **SwiftData暗号化**: macOSのファイルシステム暗号化に依存
- **個人情報**: プロジェクト名・作業時間のみ（機密情報なし）

### コード署名

```bash
# リリースビルドの署名確認
codesign -dv --verbose=4 TimeRabbit.app

# 署名検証
codesign --verify --verbose=4 TimeRabbit.app
```

---

## 関連ドキュメント

- [architecture-overview.md](architecture-overview.md): アーキテクチャ詳細
- [design-philosophy.md](design-philosophy.md): 設計思想
- [development-workflow.md](development-workflow.md): 開発フロー
- [operations/github-actions-cicd.md](operations/github-actions-cicd.md): CI/CD詳細
