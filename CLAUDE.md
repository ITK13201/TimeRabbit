# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

TimeRabbit is a macOS time tracking application built with SwiftUI and SwiftData. It allows users to create projects, track time for each project, and view statistics and history of their work sessions.

## Architecture

The app follows a **1:1 View-ViewModel MVVM pattern** with a repository layer for data persistence:

### Core Components

- **Models** (`Models.swift`): SwiftData models for `Project`, `Job`, and `TimeRecord` with proper relationships
  - `Project`: User-defined project with String ID (案件)
  - `Job`: Fixed work categories (作業区分) with 5 predefined types
  - `TimeRecord`: Time tracking records with Project + Job associations
- **Repositories** (`repositories/`): Data persistence layer using SwiftData's ModelContext
  - `ProjectRepository.swift`: Project-specific operations with ID uniqueness validation
  - `TimeRecordRepository.swift`: Time tracking operations with update/delete capabilities and Job support
  - `JobRepository.swift`: Job management with predefined work categories initialization
  - `MockProjectRepository.swift`: Mock project operations for testing/previews
  - `MockTimeRecordRepository.swift`: Mock time tracking operations for testing/previews
  - `MockJobRepository.swift`: Mock job operations for testing/previews
- **Services** (`DateService.swift`): Shared date management service for statistics and history screen synchronization
- **Utilities** (`Utils.swift`): Date/time formatting functions and color utilities
- **Logging System** (`Logger.swift`): Professional OSLog-based categorized logging for app, repository, SwiftData, ViewModel, UI, and database operations

### 1:1 View-ViewModel Architecture

Each View has its dedicated ViewModel following single responsibility principle:

- **ViewModels** (`viewmodels/`): Dedicated ViewModels for each View
  - `ContentViewModel.swift` ↔ `ContentView.swift`: Main app navigation and project list
  - `MainContentViewModel.swift` ↔ `MainContentView.swift`: Tab-based content management
  - `StatisticsViewModel.swift` ↔ `StatisticsView.swift`: Daily statistics and analytics
  - `HistoryViewModel.swift` ↔ `HistoryView.swift`: Historical records with date filtering
  - `EditHistoryViewModel.swift` ↔ `EditHistorySheetView.swift`: History record editing
  - `ProjectRowViewModel.swift` ↔ `ProjectRowView.swift`: Individual project management
  - `AddProjectViewModel.swift` ↔ `AddProjectSheetView.swift`: New project creation
  - `base/BaseViewModel.swift`: Common ViewModel functionality and error handling
  - `base/ViewModelFactory.swift`: Centralized ViewModel creation with dependency injection

- **Views** (`views/`): SwiftUI views with dedicated ViewModels
  - `ContentView.swift`: Main app view with project list and navigation
  - `MainContentView.swift`: Tab-based main content area (Statistics/History)
  - `StatisticsView.swift`: Daily statistics and project time breakdown
  - `HistoryView.swift`: Historical work records with date picker and editing
  - `EditHistorySheetView.swift`: Modal for editing time records
  - `ProjectRowView.swift`: Individual project list item with time tracking
  - `AddProjectSheetView.swift`: Modal for creating new projects
  - `HistoryRowView.swift`: Individual history record display
  - `ProjectStatRowUpdated.swift`: Statistical display for project time

### Key Design Patterns

- **1:1 View-ViewModel Mapping**: Each View has its dedicated ViewModel for clear responsibility separation
- **Repository Pattern**: Separate repositories for projects, jobs, and time records with protocol-based interfaces
- **Dependency Injection**: ViewModelFactory manages ViewModel creation and repository injection
- **Clean Architecture**: Clear separation between data layer (repositories) and presentation layer (ViewModels)
- **Mock Strategy**: Mock repositories enable SwiftUI previews and facilitate testing
- **Base ViewModel**: Common functionality like error handling, loading states through BaseViewModel
- **Data Integrity**: SwiftData models with proper cascade/nullify relationships
- **Defensive Design**: TimeRecords preserve project and job info even when they are deleted
- **Shared State Management**: DateService provides synchronized date selection between statistics and history screens
- **Copy Functionality**: Statistics screen includes Markdown-formatted data export with visual feedback
- **Job Selection Persistence**: UserDefaults stores job selection per project for consistent user experience
- **Auto-Refresh**: Statistics auto-refresh when history records are edited via Combine observation
- **Flexible Time Validation**: Time overlap validation allows records within 60 seconds proximity for realistic usage patterns

## Development Commands

### Building and Running
```bash
# Build the project
xcodebuild -project TimeRabbit.xcodeproj -scheme TimeRabbit build

# Build and run
xcodebuild -project TimeRabbit.xcodeproj -scheme TimeRabbit -destination 'platform=macOS' build

# Build project
xcodebuild build -project TimeRabbit.xcodeproj -scheme TimeRabbit -destination 'platform=macOS'

# Run UnitTests only (UITests excluded)
xcodebuild test -project TimeRabbit.xcodeproj -scheme TimeRabbit -destination 'platform=macOS' -testPlan TimeRabbitTests
```

### Testing
- **Unit tests are located in `TimeRabbitTests/` and should be executed**
- **UITests are excluded from execution** (located in `TimeRabbitUITests/` but not run)
- Uses Swift Testing framework (not XCTest)
- Mock repositories available for testing individual ViewModels and components
- ViewModelFactory supports mock repository injection for comprehensive testing
- Each ViewModel can be tested in isolation using its dedicated mock dependencies
- Unit tests should be executed when doing development validation

#### Running Tests
**UnitTests only (recommended):**
```bash
xcodebuild test -project TimeRabbit.xcodeproj -scheme TimeRabbit -destination 'platform=macOS' -testPlan TimeRabbitTests
```

**Key Benefits:**
- UITests are completely excluded for faster execution
- Uses TimeRabbitTests.xctestplan to run only TimeRabbitTests target
- Execution time: ~0.1 seconds vs several minutes with UITests included
- Avoid running UITests (TimeRabbitUITests/) - focus on TimeRabbitTests/ only

**Important Test Considerations:**
- Test data must use **past dates** to avoid `futureTime` validation errors in `TimeRecordRepository.validateTimeRange()`
- Mock repositories with `withSampleData: false` allow explicit test data creation for specific dates
- Time validation allows 60-second proximity between records (not strict overlap prevention)

### Project Configuration
- macOS deployment target: 14.0
- Swift version: 5.0
- Xcode project format: objectVersion 77 (requires Xcode 16.1+)
- Uses SwiftUI with SwiftData for persistence
- Dev build creates "TimeRabbit.dev.app"
- Release build creates "TimeRabbit.app"
- Bundle identifier: dev.i-tk.TimeRabbit(.dev)
- Professional logging system using OSLog with categorized loggers (AppLogger)

### CI/CD
- **GitHub Actions** workflows in `.github/workflows/`
- **CI** (`ci.yml`): Runs tests on PR and main branch pushes
- **Release** (`release.yml`): Two-stage workflow (test → build-and-release) triggered by version tags (`v*.*.*`)
  - Uses macOS 15 runners with Xcode 16.4
  - Creates unsigned builds (no Apple Developer Program required)
  - Generates ZIP, DMG, and SHA256 checksums
  - Auto-publishes to GitHub Releases with generated release notes
- Test failures block releases (tests must pass before deployment)

## Key Features

1. **Project Management (案件管理)**:
   - Create, delete, and manage color-coded projects with user-defined String IDs
   - Project ID uniqueness validation (3-20 characters)
   - UI terminology: "案件" (Project in code)

2. **Job Management (作業区分管理)**:
   - 5 fixed work categories (001: 開発, 002: 保守, 003: POサポート・コンサル, 006: デザイン, 999: その他)
   - Job selection per project with UserDefaults persistence
   - Default job selection (開発/Development)

3. **Time Tracking**:
   - Start/stop time recording with Project + Job combination
   - Real-time duration updates
   - Job selection dropdown on project rows

4. **Statistics**:
   - Daily project time breakdown with percentages
   - Grouped by Project + Job combinations (not just project names)
   - Exportable command format: `add yyyy/MM/dd [project ID] [job ID] [percentage]`
   - Individual copy buttons per project-job row for external software integration
   - Percentage calculation uses `Int(round())` for consistency between display and export

5. **History**: View past work sessions by date with detailed time logs and editing capabilities

6. **Record Editing**:
   - Edit completed time records (start/end time, project assignment, job assignment)
   - Edit in-progress tasks (start time only, end time read-only)
   - Job selection in edit screen
   - Backup fields preserve deleted project/job information
   - Time overlap validation allows records within 60 seconds of each other

7. **Data Persistence**: SwiftData integration with proper model relationships (Project, Job, TimeRecord)

8. **Date Synchronization**: Synchronized date selection between statistics and history screens

9. **In-Progress Task Management**:
   - Display in-progress tasks at top of history view with green background
   - Edit button available for in-progress tasks (delete disabled until completion)
   - Auto-refresh statistics when history records are edited

## Working with the Code

### Development Guidelines

- **Follow 1:1 View-ViewModel pattern**: Each new View should have its dedicated ViewModel
- **Use ViewModelFactory**: Create ViewModels through the factory to ensure proper dependency injection (includes JobRepository)
- **Extend BaseViewModel**: New ViewModels should inherit from BaseViewModel for common functionality
- **Repository Protocol**: Use repository protocols for data operations to maintain testability
- **Mock Usage**: Use mock repositories for SwiftUI previews and unit testing (MockProjectRepository, MockTimeRecordRepository, MockJobRepository)
- **Error Handling**: Handle errors through BaseViewModel's error handling mechanism
- **Japanese Localization**: Follow the existing Japanese UI text pattern ("案件" for projects, "作業区分" for jobs)
- **Color System**: Maintain the color system using the `getProjectColor` utility function in Utils.swift
- **Date Management**: Use DateService for shared date state between statistics and history screens
- **Job Selection**: Always include both Project and Job when starting time records
- **Job Persistence**: Use UserDefaults for persisting job selection per project (key: "selectedJob_{projectId}")
- **Testing Policy**: Execute unit tests (TimeRabbitTests/) but exclude UITests (TimeRabbitUITests/) from automated execution
- **Logging**: Use AppLogger for structured logging (AppLogger.app, AppLogger.repository, AppLogger.viewModel, etc.)
- **Time Validation**: Understand that time overlap validation allows 60-second proximity between records (see `validateTimeRange()` in repositories)

### Adding New Features

1. Create the ViewModel extending BaseViewModel
2. Add ViewModel creation method to ViewModelFactory
3. Create or update the corresponding View
4. Add repository methods if needed (with protocol extension)
5. Update mock repositories for testing/previews
6. Test using both real and mock data

### Project Structure

```
TimeRabbit/
├── TimeRabbitApp.swift         # Main app entry point
├── Models.swift                # SwiftData models (Project, Job, TimeRecord)
├── Logger.swift                # Professional OSLog-based logging system
├── DateService.swift           # Shared date management service
├── Utils.swift                 # Date/time formatting and color utilities
├── Assets.xcassets/           # App icons and assets
├── TimeRabbit.entitlements    # macOS app entitlements
├── repositories/              # Data layer
│   ├── ProjectRepository.swift
│   ├── TimeRecordRepository.swift
│   ├── JobRepository.swift
│   ├── MockProjectRepository.swift
│   ├── MockTimeRecordRepository.swift
│   └── MockJobRepository.swift
├── viewmodels/                # Presentation layer
│   ├── base/
│   │   ├── BaseViewModel.swift
│   │   └── ViewModelFactory.swift
│   ├── ContentViewModel.swift
│   ├── MainContentViewModel.swift
│   ├── StatisticsViewModel.swift
│   ├── HistoryViewModel.swift
│   ├── EditHistoryViewModel.swift
│   ├── ProjectRowViewModel.swift
│   └── AddProjectViewModel.swift
└── views/                     # UI layer
    ├── ContentView.swift
    ├── MainContentView.swift
    ├── StatisticsView.swift
    ├── HistoryView.swift
    ├── HistoryRowView.swift
    ├── EditHistorySheetView.swift
    ├── ProjectRowView.swift
    ├── AddProjectSheetView.swift
    └── ProjectStatRowUpdated.swift
```

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

// ViewModelFactory usage with DateService and JobRepository
let dateService = DateService()
let factory = ViewModelFactory.create(
  with: (projectRepo, timeRecordRepo, jobRepo),
  dateService: dateService
)
let viewModel = factory.createYourViewModel()

// Job selection pattern in ViewModels
let mockJobRepo = MockJobRepository()
let jobs = try! mockJobRepo.fetchAllJobs()
let defaultJob = jobs.first { $0.id == "001" } // 開発

// Starting time record with Job
try timeRecordRepository.startTimeRecord(for: project, job: selectedJob)

// Logging usage
AppLogger.app.info("Application started")
AppLogger.repository.debug("Saving project")
AppLogger.viewModel.error("Failed to load data: \(error)")
```

### Critical Implementation Details

#### Time Validation Logic
`TimeRecordRepository.validateTimeRange()` enforces:
- Start time must be before end time
- End time cannot be in the future (`endTime <= Date()`)
- Minimum duration: 60 seconds
- Maximum duration: 24 hours (86400 seconds)
- Overlap tolerance: Records within 60 seconds proximity are allowed (flexible validation)

#### Statistics Command Export
- Command format: `add yyyy/MM/dd [projectId] [jobId] [percentage]`
- Date format: `yyyy/MM/dd` (e.g., "2025/09/15")
- Percentage: Rounded integer using `Int(round(percentage))`
- Grouping: By `(projectId, jobId)` tuple, not by display names
- Generated via `StatisticsViewModel.generateCommand(for:)` method

#### SwiftData Model Relationships
- `Project` → `TimeRecord`: `.nullify` (TimeRecords preserve deleted project info in backup fields)
- `Job` → `TimeRecord`: `.nullify` (TimeRecords preserve deleted job info in backup fields)
- Backup fields (`projectIdBackup`, `projectNameBackup`, `jobIdBackup`, `jobNameBackup`) ensure data integrity even after parent deletion