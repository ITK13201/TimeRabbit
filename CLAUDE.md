# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

TimeRabbit is a macOS time tracking application built with SwiftUI and SwiftData. It allows users to create projects, track time for each project, and view statistics and history of their work sessions.

## Architecture

The app follows a **1:1 View-ViewModel MVVM pattern** with a repository layer for data persistence:

### Core Components

- **Models** (`Models.swift`): SwiftData models for `Project`, `Job`, and `TimeRecord`
  - **Identifier Convention (CRITICAL)**: All models use UUID `id` for object identity, String `projectId`/`jobId` for business logic
- **Repositories** (`repositories/`): Data persistence layer with protocol-based interfaces
  - Includes mock implementations for testing/previews
- **ViewModels** (`viewmodels/`): Dedicated ViewModel for each View (1:1 mapping)
  - `base/BaseViewModel.swift`: Common functionality (error handling, loading states)
  - `base/ViewModelFactory.swift`: Centralized ViewModel creation with dependency injection
- **Views** (`views/`): SwiftUI views with dedicated ViewModels
- **Services** (`DateService.swift`): Shared date management for statistics/history synchronization
- **Utilities** (`Utils.swift`): Date/time formatting and color utilities
- **Logging** (`Logger.swift`): OSLog-based categorized logging (AppLogger)

### Key Design Patterns

- **1:1 View-ViewModel Mapping**: Each View has its dedicated ViewModel
- **Repository Pattern**: Protocol-based data layer for testability
- **Dependency Injection**: ViewModelFactory manages dependencies
- **Mock Strategy**: Mock repositories for SwiftUI previews and testing
- **Defensive Design**: TimeRecords preserve project/job info via backup fields
- **Shared State Management**: DateService synchronizes date selection across screens

## Development Commands

### Building and Running

```bash
# Build the project
xcodebuild -project TimeRabbit.xcodeproj -scheme TimeRabbit -destination 'platform=macOS' build

# Open in Xcode
open TimeRabbit.xcodeproj
```

### Code Formatting

**Format all Swift files:**
```bash
swiftformat . --exclude TimeRabbit.xcodeproj,build,.build
```

**Check formatting without modifying files:**
```bash
swiftformat --lint . --exclude TimeRabbit.xcodeproj,build,.build
```

**Formatting Notes:**
- **IMPORTANT**: Always run `swiftformat .` before pushing code
- Pre-push hook automatically checks formatting and blocks push if unformatted
- CI workflow includes SwiftFormat check job that must pass before tests run
- Uses SwiftFormat 0.58.3+

### Testing

**Run all unit tests (UITests excluded):**
```bash
xcodebuild test -project TimeRabbit.xcodeproj -scheme TimeRabbit -destination 'platform=macOS' -testPlan TimeRabbitTests
```

**Run specific test class:**
```bash
xcodebuild test -project TimeRabbit.xcodeproj -scheme TimeRabbit -destination 'platform=macOS' -testPlan TimeRabbitTests -only-testing:TimeRabbitTests/StatisticsViewModelCommandTests
```

**Run specific test method:**
```bash
xcodebuild test -project TimeRabbit.xcodeproj -scheme TimeRabbit -destination 'platform=macOS' -testPlan TimeRabbitTests -only-testing:TimeRabbitTests/StatisticsViewModelCommandTests/testGenerateCommand
```

**Testing Notes:**
- Uses Swift Testing framework (not XCTest)
- UITests in `TimeRabbitUITests/` are excluded (too slow, ~minutes vs ~0.1 seconds)
- Test data must use **past dates** to avoid `futureTime` validation errors
- Mock repositories with `withSampleData: false` allow explicit test data creation

### Git Commit Convention

Format: `#[issue_number] [type]: [message]` (omit `#[issue_number]` if no related issue)

**Types:** `feature`, `bugfix`, `hotfix`, `docs`, `refactor`, `test`, `chore`

**Examples:**
```
#2 feature: Unify identifier naming with UUID-based id for all models
#15 bugfix: Fix time overlap validation logic
#8 docs: Update architecture documentation
refactor: Apply SwiftFormat to all files
chore: Update dependencies
```

**Important:**
- Use `#[issue_number]` prefix ONLY when there is a related issue
- Do NOT use `#0` for commits without an issue

### Release Procedure

1. Prepare `develop` branch (all tests pass)
2. Create PR: `gh pr create --base main --head develop` with `Closes #XX`
3. Merge PR (issues auto-close)
4. Tag version: `git tag -a v0.1.0 -m "Release v0.1.0"` → `git push origin v0.1.0`
5. GitHub Actions auto-builds and publishes (ZIP, DMG, checksums)
6. Sync `develop`: merge `main` back to `develop`

See [docs/operations/release-procedure.md](docs/operations/release-procedure.md) for details.

### Issue Management

- **All GitHub Issues and Pull Requests must be written in Japanese**
- Commit messages use English convention (`#XX type: message`)
- Labels: `bug`, `enhancement`, `documentation`, `priority: high/medium/low`

## Development Guidelines

### Critical Rules

1. **Identifier Usage (MOST IMPORTANT)**:
   - **Object identity/comparison**: ALWAYS use `id` (UUID)
     ```swift
     // ✅ CORRECT
     projects.removeAll { $0.id == project.id }
     if record.id == editingRecord.id { ... }
     ```
   - **Business logic/display**: ALWAYS use `projectId`/`jobId` (String)
     ```swift
     // ✅ CORRECT
     let proj = projects.first { $0.projectId == "PRJ001" }
     let job = jobs.first { $0.jobId == "001" }
     ```
   - **Never mix**: Using `projectId` for object identity causes bugs
     ```swift
     // ❌ WRONG
     projects.removeAll { $0.projectId == project.projectId } // BUG!
     ```

2. **1:1 View-ViewModel Pattern**: Each new View must have its dedicated ViewModel

3. **ViewModelFactory**: Create ViewModels through factory for proper dependency injection

4. **BaseViewModel**: New ViewModels must inherit from BaseViewModel

5. **Repository Protocol**: Use protocols for data operations (testability)

6. **Mock Usage**: Use mock repositories for SwiftUI previews and testing

7. **Logging**: Use AppLogger for structured logging
   ```swift
   AppLogger.app.info("Application started")
   AppLogger.repository.debug("Saving project")
   AppLogger.viewModel.error("Failed: \(error)")
   ```

8. **Time Validation**: Overlap validation allows 60-second proximity (see `validateTimeRange()`)

9. **Job Selection**: Always include both Project and Job when starting time records

10. **Code Formatting**: Always run `swiftformat .` before pushing code

11. **Testing**: Execute unit tests when doing development validation

### Adding New Features

1. Create ViewModel extending BaseViewModel
2. Add creation method to ViewModelFactory
3. Create/update corresponding View
4. Add repository methods if needed (with protocol extension)
5. Update mock repositories for testing/previews
6. Test with both real and mock data

### Common Patterns

```swift
// ViewModel structure
@MainActor
class YourViewModel: BaseViewModel {
  private let repository: YourRepositoryProtocol
  init(repository: YourRepositoryProtocol) { ... }

  func performAction() {
    AppLogger.viewModel.debug("Performing action")
    withLoadingSync {
      try repository.someOperation()
    }
  }
}

// View structure
struct YourView: View {
  @ObservedObject var viewModel: YourViewModel
  var body: some View { ... }
}

// ViewModelFactory usage
let dateService = DateService()
let factory = ViewModelFactory.create(
  with: (projectRepo, timeRecordRepo, jobRepo),
  dateService: dateService
)
let viewModel = factory.createYourViewModel()
```

## Critical Implementation Details

### Time Validation Logic
`TimeRecordRepository.validateTimeRange()` enforces:
- Start time must be before end time
- End time cannot be in the future
- Minimum duration: 60 seconds
- Maximum duration: 24 hours
- Overlap tolerance: 60-second proximity allowed

### Statistics Command Export
- Format: `add yyyy/MM/dd [projectId] [jobId] [percentage]`
- Example: `add 2025/09/15 PRJ001 001 42`
- Percentage: `Int(round())` for consistency
- Grouping: By `(projectId, jobId)` tuple
- Generated via `StatisticsViewModel.generateCommand(for:)`

### SwiftData Relationships
- `Project` → `TimeRecord`: `.nullify` (backup fields preserve data)
- `Job` → `TimeRecord`: `.nullify` (backup fields preserve data)

## Key Features

1. **Project Management**: Color-coded projects with String ID validation (3-20 chars)
2. **Job Management**: 5 fixed categories (001: 開発, 002: 保守, 003: POサポート・コンサル, 006: デザイン, 999: その他)
3. **Time Tracking**: Start/stop with Project + Job combination
4. **Statistics**: Daily breakdown by Project×Job with Markdown export
5. **History**: Date-filtered records with editing capabilities
6. **Data Persistence**: SwiftData with proper relationships

## Documentation

Comprehensive documentation available in [docs/](docs/):
- **Getting Started**: [docs/guides/getting-started.md](docs/guides/getting-started.md)
- **Architecture**: [docs/guides/architecture-guide.md](docs/guides/architecture-guide.md)
- **Development**: [docs/guides/development-guide.md](docs/guides/development-guide.md)
- **Data Models**: [docs/reference/data-models.md](docs/reference/data-models.md)

Full documentation index: [docs/README.md](docs/README.md)

## Project Configuration

- macOS deployment target: 14.0
- Swift version: 5.0
- Xcode: 16.1+ (objectVersion 77)
- Bundle ID: dev.i-tk.TimeRabbit(.dev)
- Dev build: "TimeRabbit.dev.app"
- Release build: "TimeRabbit.app"

## CI/CD

- **CI** (`ci.yml`): Format check and tests on PR/main push (macOS 15, Xcode 16.4)
  - `format-check` job: Validates SwiftFormat compliance (blocks if unformatted)
  - `test` job: Runs unit tests (requires format-check to pass)
- **Release** (`release.yml`): Two-stage workflow triggered by `v*.*.*` tags
  - Test → Build → Package (ZIP, DMG, SHA256)
  - Auto-publishes to GitHub Releases
  - Unsigned builds (no Apple Developer Program)
