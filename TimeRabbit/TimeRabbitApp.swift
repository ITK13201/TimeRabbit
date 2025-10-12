//
//  TimeRabbitApp.swift
//  TimeRabbit
//
//  Created by Takumi Ikeda on 2025/07/29.
//

import SwiftData
import SwiftUI

@main
struct TimeRabbitApp: App {
    let modelContainer: ModelContainer

    init() {
        do {
            let schema = Schema([
                Project.self,
                Job.self,
                TimeRecord.self,
            ])
            let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
            modelContainer = try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            AppLogger.app.critical("Failed to create ModelContainer: \(error)")

            // スキーマの問題が原因の場合、データベースをリセットしてリトライ
            if error is SwiftDataError {
                AppLogger.app.warning("SwiftDataError detected, attempting to reset database...")
                do {
                    try Self.resetDatabase()
                    let schema = Schema([
                        Project.self,
                        Job.self,
                        TimeRecord.self,
                    ])
                    let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
                    modelContainer = try ModelContainer(for: schema, configurations: [modelConfiguration])
                    AppLogger.app.info("Database reset successful")
                } catch {
                    AppLogger.app.critical("Failed to reset database: \(error)")
                    fatalError("Failed to create ModelContainer after reset: \(error)")
                }
            } else {
                fatalError("Failed to create ModelContainer: \(error)")
            }
        }
    }

    private static func resetDatabase() throws {
        // データベースファイルの場所を取得
        let url = URL.applicationSupportDirectory.appending(path: "default.store")
        if FileManager.default.fileExists(atPath: url.path) {
            try FileManager.default.removeItem(at: url)
            AppLogger.database.info("Removed existing database at: \(url.path)")
        }

        // wal and shm ファイルも削除
        let walURL = url.appendingPathExtension("wal")
        let shmURL = url.appendingPathExtension("shm")

        if FileManager.default.fileExists(atPath: walURL.path) {
            try FileManager.default.removeItem(at: walURL)
        }

        if FileManager.default.fileExists(atPath: shmURL.path) {
            try FileManager.default.removeItem(at: shmURL)
        }
    }

    var body: some Scene {
        WindowGroup {
            let projectRepository = ProjectRepository(modelContext: modelContainer.mainContext)
            let timeRecordRepository = TimeRecordRepository(modelContext: modelContainer.mainContext)
            let jobRepository = JobRepository(modelContext: modelContainer.mainContext)
            let viewModelFactory = ViewModelFactory.create(with: (projectRepository, timeRecordRepository, jobRepository))
            ContentView(viewModelFactory: viewModelFactory)
        }
        .modelContainer(modelContainer)
        .defaultSize(width: 1000, height: 700)
    }
}
