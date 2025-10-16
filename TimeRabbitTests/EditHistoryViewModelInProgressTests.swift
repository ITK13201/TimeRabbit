//
//  EditHistoryViewModelInProgressTests.swift
//  TimeRabbitTests
//
//  Created for Issue #6: Fix in-progress record edit
//

import Foundation
import Testing

@testable import TimeRabbit

@Suite("EditHistoryViewModel In-Progress Record Tests")
struct EditHistoryViewModelInProgressTests {
    // MARK: - Test: startEditing with in-progress record

    @Test("startEditing() sets isEditingInProgressRecord to true for in-progress records")
    @MainActor
    func startEditingInProgressRecord() async throws {
        // Arrange
        let mockProjectRepo = MockProjectRepository(withSampleData: true)
        let mockProjects = try mockProjectRepo.fetchProjects()
        let mockTimeRecordRepo = MockTimeRecordRepository(projects: mockProjects, withSampleData: false)
        let mockJobRepo = MockJobRepository()
        let mockJobs = try mockJobRepo.fetchAllJobs()

        // 作業中レコードを作成（endTime == nil）
        let inProgressRecord = TimeRecord(
            startTime: Calendar.current.date(byAdding: .minute, value: -30, to: Date())!,
            project: mockProjects[0],
            job: mockJobs[0]
        )
        // endTimeはnilのまま（作業中）

        let viewModel = EditHistoryViewModel(
            timeRecordRepository: mockTimeRecordRepo,
            projectRepository: mockProjectRepo,
            jobRepository: mockJobRepo
        )

        // Act
        viewModel.startEditing(inProgressRecord)

        // Assert
        #expect(viewModel.isEditingInProgressRecord == true)
        #expect(viewModel.editingRecord?.id == inProgressRecord.id)
        #expect(viewModel.editingRecord?.endTime == nil)
        // endTimeはUI表示用にDate()が設定されている
        #expect(viewModel.endTime != Date.distantPast)
    }

    // MARK: - Test: startEditing with completed record

    @Test("startEditing() sets isEditingInProgressRecord to false for completed records")
    @MainActor
    func startEditingCompletedRecord() async throws {
        // Arrange
        let mockProjectRepo = MockProjectRepository(withSampleData: true)
        let mockProjects = try mockProjectRepo.fetchProjects()
        let mockTimeRecordRepo = MockTimeRecordRepository(projects: mockProjects, withSampleData: false)
        let mockJobRepo = MockJobRepository()
        let mockJobs = try mockJobRepo.fetchAllJobs()

        // 完了済みレコードを作成（endTime != nil）
        let completedRecord = TimeRecord(
            startTime: Calendar.current.date(byAdding: .hour, value: -2, to: Date())!,
            project: mockProjects[0],
            job: mockJobs[0]
        )
        completedRecord.endTime = Calendar.current.date(byAdding: .hour, value: -1, to: Date())!

        let viewModel = EditHistoryViewModel(
            timeRecordRepository: mockTimeRecordRepo,
            projectRepository: mockProjectRepo,
            jobRepository: mockJobRepo
        )

        // Act
        viewModel.startEditing(completedRecord)

        // Assert
        #expect(viewModel.isEditingInProgressRecord == false)
        #expect(viewModel.endTime == completedRecord.endTime)
    }

    // MARK: - Test: saveChanges preserves endTime == nil for in-progress records

    @Test("saveChanges() preserves endTime == nil for in-progress records")
    @MainActor
    func saveChangesInProgressRecord() async throws {
        // Arrange
        let mockProjectRepo = MockProjectRepository(withSampleData: true)
        let mockProjects = try mockProjectRepo.fetchProjects()
        let mockTimeRecordRepo = MockTimeRecordRepository(projects: mockProjects, withSampleData: false)
        let mockJobRepo = MockJobRepository()
        let mockJobs = try mockJobRepo.fetchAllJobs()

        // 作業中レコードを作成
        let inProgressRecord = TimeRecord(
            startTime: Calendar.current.date(byAdding: .minute, value: -30, to: Date())!,
            project: mockProjects[0],
            job: mockJobs[0]
        )
        // endTimeはnilのまま

        let viewModel = EditHistoryViewModel(
            timeRecordRepository: mockTimeRecordRepo,
            projectRepository: mockProjectRepo,
            jobRepository: mockJobRepo
        )

        viewModel.startEditing(inProgressRecord)

        // 開始時間を変更
        let newStartTime = Calendar.current.date(byAdding: .minute, value: -45, to: Date())!
        viewModel.startTime = newStartTime

        // Act
        viewModel.saveChanges()

        // Assert
        #expect(inProgressRecord.endTime == nil) // endTimeがnilのまま保持されている
        #expect(inProgressRecord.startTime == newStartTime) // startTimeは更新されている
    }

    // MARK: - Test: saveChanges updates endTime for completed records

    @Test("saveChanges() updates endTime for completed records")
    @MainActor
    func saveChangesCompletedRecord() async throws {
        // Arrange
        let mockProjectRepo = MockProjectRepository(withSampleData: true)
        let mockProjects = try mockProjectRepo.fetchProjects()
        let mockTimeRecordRepo = MockTimeRecordRepository(projects: mockProjects, withSampleData: false)
        let mockJobRepo = MockJobRepository()
        let mockJobs = try mockJobRepo.fetchAllJobs()

        // 完了済みレコードを作成
        let completedRecord = TimeRecord(
            startTime: Calendar.current.date(byAdding: .hour, value: -2, to: Date())!,
            project: mockProjects[0],
            job: mockJobs[0]
        )
        let originalEndTime = Calendar.current.date(byAdding: .hour, value: -1, to: Date())!
        completedRecord.endTime = originalEndTime

        let viewModel = EditHistoryViewModel(
            timeRecordRepository: mockTimeRecordRepo,
            projectRepository: mockProjectRepo,
            jobRepository: mockJobRepo
        )

        viewModel.startEditing(completedRecord)

        // 終了時間を変更
        let newEndTime = Calendar.current.date(byAdding: .minute, value: -30, to: Date())!
        viewModel.endTime = newEndTime

        // Act
        viewModel.saveChanges()

        // Assert
        #expect(completedRecord.endTime == newEndTime) // endTimeが更新されている
        #expect(completedRecord.endTime != originalEndTime)
    }

    // MARK: - Test: isValidTimeRange for in-progress records

    @Test("isValidTimeRange returns true when startTime is before current time for in-progress records")
    @MainActor
    func isValidTimeRangeInProgressRecord() async throws {
        // Arrange
        let mockProjectRepo = MockProjectRepository(withSampleData: true)
        let mockProjects = try mockProjectRepo.fetchProjects()
        let mockTimeRecordRepo = MockTimeRecordRepository(projects: mockProjects, withSampleData: false)
        let mockJobRepo = MockJobRepository()
        let mockJobs = try mockJobRepo.fetchAllJobs()

        let inProgressRecord = TimeRecord(
            startTime: Calendar.current.date(byAdding: .minute, value: -30, to: Date())!,
            project: mockProjects[0],
            job: mockJobs[0]
        )

        let viewModel = EditHistoryViewModel(
            timeRecordRepository: mockTimeRecordRepo,
            projectRepository: mockProjectRepo,
            jobRepository: mockJobRepo
        )

        viewModel.startEditing(inProgressRecord)

        // Act & Assert: 開始時間が現在時刻より前の場合はtrue
        viewModel.startTime = Calendar.current.date(byAdding: .minute, value: -15, to: Date())!
        #expect(viewModel.isValidTimeRange == true)
    }

    @Test("isValidTimeRange returns false when startTime is in future for in-progress records")
    @MainActor
    func isValidTimeRangeInProgressRecordFutureStartTime() async throws {
        // Arrange
        let mockProjectRepo = MockProjectRepository(withSampleData: true)
        let mockProjects = try mockProjectRepo.fetchProjects()
        let mockTimeRecordRepo = MockTimeRecordRepository(projects: mockProjects, withSampleData: false)
        let mockJobRepo = MockJobRepository()
        let mockJobs = try mockJobRepo.fetchAllJobs()

        let inProgressRecord = TimeRecord(
            startTime: Calendar.current.date(byAdding: .minute, value: -30, to: Date())!,
            project: mockProjects[0],
            job: mockJobs[0]
        )

        let viewModel = EditHistoryViewModel(
            timeRecordRepository: mockTimeRecordRepo,
            projectRepository: mockProjectRepo,
            jobRepository: mockJobRepo
        )

        viewModel.startEditing(inProgressRecord)

        // Act & Assert: 開始時間が未来の場合はfalse
        viewModel.startTime = Calendar.current.date(byAdding: .minute, value: 10, to: Date())!
        #expect(viewModel.isValidTimeRange == false)
    }

    // MARK: - Test: resetEditingState resets isEditingInProgressRecord

    @Test("resetEditingState() resets isEditingInProgressRecord to false")
    @MainActor
    func resetEditingState() async throws {
        // Arrange
        let mockProjectRepo = MockProjectRepository(withSampleData: true)
        let mockProjects = try mockProjectRepo.fetchProjects()
        let mockTimeRecordRepo = MockTimeRecordRepository(projects: mockProjects, withSampleData: false)
        let mockJobRepo = MockJobRepository()
        let mockJobs = try mockJobRepo.fetchAllJobs()

        let inProgressRecord = TimeRecord(
            startTime: Calendar.current.date(byAdding: .minute, value: -30, to: Date())!,
            project: mockProjects[0],
            job: mockJobs[0]
        )

        let viewModel = EditHistoryViewModel(
            timeRecordRepository: mockTimeRecordRepo,
            projectRepository: mockProjectRepo,
            jobRepository: mockJobRepo
        )

        viewModel.startEditing(inProgressRecord)
        #expect(viewModel.isEditingInProgressRecord == true)

        // Act
        viewModel.cancel()

        // Assert
        #expect(viewModel.isEditingInProgressRecord == false)
        #expect(viewModel.editingRecord == nil)
    }
}
