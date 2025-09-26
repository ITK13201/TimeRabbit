//
//  Logger.swift
//  TimeRabbit
//
//  Created by Claude Code on 2025-08-10.
//

import Foundation
import os.log

/// Application-wide logging system using OSLog with categorized loggers
struct AppLogger {

  // MARK: - Log Categories

  /// General application lifecycle and main operations
  static let app = Logger(
    subsystem: Bundle.main.bundleIdentifier ?? "dev.i-tk.TimeRabbit", category: "App")

  /// Repository layer operations and data persistence
  static let repository = Logger(
    subsystem: Bundle.main.bundleIdentifier ?? "dev.i-tk.TimeRabbit", category: "Repository")

  /// SwiftData specific operations and errors
  static let swiftData = Logger(
    subsystem: Bundle.main.bundleIdentifier ?? "dev.i-tk.TimeRabbit", category: "SwiftData")

  /// ViewModel operations and business logic
  static let viewModel = Logger(
    subsystem: Bundle.main.bundleIdentifier ?? "dev.i-tk.TimeRabbit", category: "ViewModel")

  /// UI operations and user interactions
  static let ui = Logger(
    subsystem: Bundle.main.bundleIdentifier ?? "dev.i-tk.TimeRabbit", category: "UI")

  /// Database operations and data validation
  static let database = Logger(
    subsystem: Bundle.main.bundleIdentifier ?? "dev.i-tk.TimeRabbit", category: "Database")
}

// MARK: - Usage Notes
//
// Usage examples:
//   AppLogger.app.debug("Debug message")
//   AppLogger.repository.info("Info message")
//   AppLogger.swiftData.error("Error message")
//   AppLogger.database.warning("Warning message")
//   AppLogger.viewModel.critical("Critical error")
//   AppLogger.ui.info("UI event")
