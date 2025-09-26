# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

TimeRabbit is a macOS time tracking application built with SwiftUI and SwiftData. It allows users to create projects, track time for each project, and view statistics and history of their work sessions.

## Architecture

The app follows a **1:1 View-ViewModel MVVM pattern** with a repository layer for data persistence:

### Core Components

- **Models** (`Models.swift`): SwiftData models for `Project` and `TimeRecord` with proper relationships
- **Repositories** (`repositories/`): Data persistence layer using SwiftData's ModelContext
  - `ProjectRepository.swift`: Project-specific operations
  - `TimeRecordRepository.swift`: Time tracking operations with update/delete capabilities
  - `MockProjectRepository.swift`: Mock project operations for testing/previews
  - `MockTimeRecordRepository.swift`: Mock time tracking operations for testing/previews
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
- **Repository Pattern**: Separate repositories for projects and time records with protocol-based interfaces
- **Dependency Injection**: ViewModelFactory manages ViewModel creation and repository injection
- **Clean Architecture**: Clear separation between data layer (repositories) and presentation layer (ViewModels)
- **Mock Strategy**: Mock repositories enable SwiftUI previews and facilitate testing
- **Base ViewModel**: Common functionality like error handling, loading states through BaseViewModel
- **Data Integrity**: SwiftData models with proper cascade/nullify relationships
- **Defensive Design**: TimeRecords preserve project info even when projects are deleted
- **Shared State Management**: DateService provides synchronized date selection between statistics and history screens
- **Copy Functionality**: Statistics screen includes Markdown-formatted data export with visual feedback

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

### Project Configuration
- macOS deployment target: 14.0  
- Swift version: 5.0
- Uses SwiftUI with SwiftData for persistence
- Dev build creates "TimeRabbit.dev.app"
- Release build creates "TimeRabbit.app"  
- Bundle identifier: dev.i-tk.TimeRabbit(.dev)
- Professional logging system using OSLog with categorized loggers (AppLogger)

## Key Features

1. **Project Management**: Create, delete, and manage color-coded projects
2. **Time Tracking**: Start/stop time recording with real-time duration updates
3. **Statistics**: Daily project time breakdown with percentages and exportable Markdown format
4. **History**: View past work sessions by date with detailed time logs and editing capabilities
5. **Record Editing**: Edit completed time records (start/end time, project assignment)
6. **Data Persistence**: SwiftData integration with proper model relationships
7. **Date Synchronization**: Synchronized date selection between statistics and history screens

## Working with the Code

### Development Guidelines

- **Follow 1:1 View-ViewModel pattern**: Each new View should have its dedicated ViewModel
- **Use ViewModelFactory**: Create ViewModels through the factory to ensure proper dependency injection
- **Extend BaseViewModel**: New ViewModels should inherit from BaseViewModel for common functionality
- **Repository Protocol**: Use repository protocols for data operations to maintain testability
- **Mock Usage**: Use mock repositories for SwiftUI previews and unit testing
- **Error Handling**: Handle errors through BaseViewModel's error handling mechanism
- **Japanese Localization**: Follow the existing Japanese UI text pattern
- **Color System**: Maintain the color system using the `getProjectColor` utility function in Utils.swift
- **Date Management**: Use DateService for shared date state between statistics and history screens
- **Testing Policy**: Execute unit tests (TimeRabbitTests/) but exclude UITests (TimeRabbitUITests/) from automated execution
- **Logging**: Use AppLogger for structured logging (AppLogger.app, AppLogger.repository, AppLogger.viewModel, etc.)

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
├── Models.swift                # SwiftData models (Project, TimeRecord)
├── Logger.swift                # Professional OSLog-based logging system
├── DateService.swift           # Shared date management service
├── Utils.swift                 # Date/time formatting and color utilities
├── Assets.xcassets/           # App icons and assets
├── TimeRabbit.entitlements    # macOS app entitlements
├── repositories/              # Data layer
│   ├── ProjectRepository.swift
│   ├── TimeRecordRepository.swift
│   ├── MockProjectRepository.swift
│   └── MockTimeRecordRepository.swift
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

// ViewModelFactory usage with DateService
let dateService = DateService()
let factory = ViewModelFactory.create(with: (projectRepo, timeRecordRepo), dateService: dateService)
let viewModel = factory.createYourViewModel()

// Logging usage
AppLogger.app.info("Application started")
AppLogger.repository.debug("Saving project")
AppLogger.viewModel.error("Failed to load data: \(error)")
```