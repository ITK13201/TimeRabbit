//
//  EditHistoryViewModelTests.swift
//  TimeRabbitTests
//
//  Created by Takumi Ikeda on 2025/08/09.
//

import Foundation
import Testing
@testable import TimeRabbit

// MARK: - Edit History ViewModel Tests

@MainActor
struct EditHistoryViewModelTests {
  // MARK: - Setup Helper

  private func createTestSetup() -> (EditHistoryViewModel, MockProjectRepository, MockTimeRecordRepository, MockJobRepository, [Project], [TimeRecord]) {
    let mockProjectRepo = MockProjectRepository(withSampleData: true)
    let projects = try! mockProjectRepo.fetchProjects()
    let mockTimeRecordRepo = MockTimeRecordRepository(projects: projects, withSampleData: true)
    let mockJobRepo = MockJobRepository()

    let viewModel = EditHistoryViewModel(
      timeRecordRepository: mockTimeRecordRepo,
      projectRepository: mockProjectRepo,
      jobRepository: mockJobRepo
    )

    let timeRecords = try! mockTimeRecordRepo.fetchTimeRecords(
      for: nil,
      from: Calendar.current.startOfDay(for: Date()),
      to: Date()
    ).filter { $0.endTime != nil } // Only completed records

    return (viewModel, mockProjectRepo, mockTimeRecordRepo, mockJobRepo, projects, timeRecords)
  }

  // MARK: - Initialization Tests

  @Test("ViewModel should initialize correctly")
  func initialization() async {
    let (viewModel, _, _, _, projects, _) = self.createTestSetup()

    // Wait a moment for async initialization
    try! await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds

    #expect(viewModel.editingRecord == nil)
    #expect(viewModel.selectedProject == nil)
    #expect(viewModel.selectedJob == nil)
    #expect(viewModel.showingEditSheet == false)
    #expect(viewModel.showingDeleteAlert == false)
    #expect(viewModel.availableProjects.count == projects.count)
    #expect(viewModel.availableJobs.count == 5) // 5 predefined jobs
  }

  // MARK: - Start Editing Tests

  @Test("Should start editing completed record")
  func startEditingCompletedRecord() async {
    let (viewModel, _, _, _, _, timeRecords) = self.createTestSetup()

    guard let recordToEdit = timeRecords.first else {
      #expect(Bool(false), "No completed records found for testing")
      return
    }

    viewModel.startEditing(recordToEdit)

    #expect(viewModel.editingRecord?.id == recordToEdit.id)
    #expect(viewModel.selectedProject?.id == recordToEdit.project?.id)
    #expect(viewModel.selectedJob?.id == recordToEdit.job?.id)
    #expect(viewModel.startTime == recordToEdit.startTime)
    #expect(viewModel.endTime == recordToEdit.endTime)
    #expect(viewModel.showingEditSheet == true)
    #expect(viewModel.errorMessage == nil)
  }

  @Test("Should edit incomplete record (in-progress)")
  func startEditingIncompleteRecord() async {
    let (viewModel, _, mockTimeRecordRepo, _, projects, _) = self.createTestSetup()

    // Get default job for testing
    let mockJobRepo = MockJobRepository()
    let jobs = try! mockJobRepo.fetchAllJobs()
    let defaultJob = jobs.first { $0.jobId == "001" }!

    // Create an incomplete record (no endTime)
    let incompleteRecord = try! mockTimeRecordRepo.startTimeRecord(for: projects[0], job: defaultJob)

    viewModel.startEditing(incompleteRecord)

    // 作業中のレコードも編集可能になった
    #expect(viewModel.editingRecord?.id == incompleteRecord.id)
    #expect(viewModel.showingEditSheet == true)
    #expect(viewModel.errorMessage == nil)
    #expect(viewModel.startTime == incompleteRecord.startTime)
  }

  // MARK: - Validation Tests

  @Test("Should validate valid time range")
  func validTimeRange() async {
    let (viewModel, _, _, _, _, timeRecords) = self.createTestSetup()

    guard let recordToEdit = timeRecords.first else {
      #expect(Bool(false), "No completed records found for testing")
      return
    }

    viewModel.startEditing(recordToEdit)

    // Set valid time range
    viewModel.startTime = Calendar.current.date(byAdding: .hour, value: -2, to: Date())!
    viewModel.endTime = Calendar.current.date(byAdding: .hour, value: -1, to: Date())!

    #expect(viewModel.isValidTimeRange == true)
    #expect(viewModel.canSave == true)
  }

  @Test("Should invalidate time range where start > end")
  func invalidTimeRangeStartAfterEnd() async {
    let (viewModel, _, _, _, _, timeRecords) = self.createTestSetup()

    guard let recordToEdit = timeRecords.first else {
      #expect(Bool(false), "No completed records found for testing")
      return
    }

    viewModel.startEditing(recordToEdit)

    // Set invalid time range (start after end)
    viewModel.startTime = Calendar.current.date(byAdding: .hour, value: -1, to: Date())!
    viewModel.endTime = Calendar.current.date(byAdding: .hour, value: -2, to: Date())!

    #expect(viewModel.isValidTimeRange == false)
    #expect(viewModel.canSave == false)
  }

  @Test("Should invalidate future time")
  func invalidFutureTime() async {
    let (viewModel, _, _, _, _, timeRecords) = self.createTestSetup()

    guard let recordToEdit = timeRecords.first else {
      #expect(Bool(false), "No completed records found for testing")
      return
    }

    viewModel.startEditing(recordToEdit)

    // Set future time
    viewModel.startTime = Calendar.current.date(byAdding: .hour, value: -1, to: Date())!
    viewModel.endTime = Calendar.current.date(byAdding: .hour, value: 1, to: Date())!

    #expect(viewModel.isValidTimeRange == false)
    #expect(viewModel.canSave == false)
  }

  @Test("Should invalidate too short duration")
  func invalidTooShortDuration() async {
    let (viewModel, _, _, _, _, timeRecords) = self.createTestSetup()

    guard let recordToEdit = timeRecords.first else {
      #expect(Bool(false), "No completed records found for testing")
      return
    }

    viewModel.startEditing(recordToEdit)

    // Set duration less than 1 minute
    viewModel.startTime = Calendar.current.date(byAdding: .minute, value: -1, to: Date())!
    viewModel.endTime = Calendar.current.date(byAdding: .second, value: -30, to: Date())!

    #expect(viewModel.isValidTimeRange == false)
    #expect(viewModel.canSave == false)
  }

  // MARK: - Time Adjustment Tests

  @Test("Should adjust start time correctly")
  func testAdjustStartTime() async {
    let (viewModel, _, _, _, _, timeRecords) = self.createTestSetup()

    guard let recordToEdit = timeRecords.first else {
      #expect(Bool(false), "No completed records found for testing")
      return
    }

    viewModel.startEditing(recordToEdit)

    let originalStartTime = viewModel.startTime
    viewModel.adjustStartTime(by: 15)

    let expectedTime = Calendar.current.date(byAdding: .minute, value: 15, to: originalStartTime)!
    #expect(viewModel.startTime == expectedTime)
  }

  @Test("Should adjust end time correctly")
  func testAdjustEndTime() async {
    let (viewModel, _, _, _, _, timeRecords) = self.createTestSetup()

    guard let recordToEdit = timeRecords.first else {
      #expect(Bool(false), "No completed records found for testing")
      return
    }

    viewModel.startEditing(recordToEdit)

    let originalEndTime = viewModel.endTime
    viewModel.adjustEndTime(by: -15)

    let expectedTime = Calendar.current.date(byAdding: .minute, value: -15, to: originalEndTime)!
    #expect(viewModel.endTime == expectedTime)
  }

  // MARK: - Save Changes Tests

  @Test("Should save valid changes")
  func saveValidChanges() async {
    let (viewModel, _, _, _, projects, timeRecords) = self.createTestSetup()

    guard let recordToEdit = timeRecords.first else {
      #expect(Bool(false), "No completed records found for testing")
      return
    }

    viewModel.startEditing(recordToEdit)

    // Make valid changes - use time range that doesn't overlap with sample data
    viewModel.selectedProject = projects[1] // Change project
    viewModel.startTime = Calendar.current.date(byAdding: .hour, value: -6, to: Date())!
    viewModel.endTime = Calendar.current.date(byAdding: .hour, value: -5, to: Date())!

    viewModel.saveChanges()

    #expect(viewModel.errorMessage == nil)
    #expect(viewModel.showingEditSheet == false)
    #expect(viewModel.editingRecord == nil)
  }

  @Test("Should not save when missing required data")
  func saveWithMissingData() async {
    let (viewModel, _, _, _, _, timeRecords) = self.createTestSetup()

    guard let recordToEdit = timeRecords.first else {
      #expect(Bool(false), "No completed records found for testing")
      return
    }

    viewModel.startEditing(recordToEdit)

    // Remove required project
    viewModel.selectedProject = nil

    viewModel.saveChanges()

    #expect(viewModel.errorMessage != nil)
    #expect(viewModel.showingEditSheet == true)
  }

  @Test("Should not save when missing job")
  func saveWithMissingJob() async {
    let (viewModel, _, _, _, _, timeRecords) = self.createTestSetup()

    guard let recordToEdit = timeRecords.first else {
      #expect(Bool(false), "No completed records found for testing")
      return
    }

    viewModel.startEditing(recordToEdit)

    // Remove required job
    viewModel.selectedJob = nil

    viewModel.saveChanges()

    #expect(viewModel.errorMessage != nil)
    #expect(viewModel.showingEditSheet == true)
  }

  // MARK: - Time Overlap Validation Tests

  @Test("Should allow same minute start/end times (within 60 seconds)")
  func allowSameMinuteStartEnd() async {
    // Create fresh setup without sample data to avoid time conflicts
    let mockProjectRepo = MockProjectRepository(withSampleData: true)
    let projects = try! mockProjectRepo.fetchProjects()
    let mockTimeRecordRepo = MockTimeRecordRepository(projects: projects, withSampleData: false) // No sample data
    let mockJobRepo = MockJobRepository()

    let viewModel = EditHistoryViewModel(
      timeRecordRepository: mockTimeRecordRepo,
      projectRepository: mockProjectRepo,
      jobRepository: mockJobRepo
    )

    let jobs = try! mockJobRepo.fetchAllJobs()
    let defaultJob = jobs.first { $0.jobId == "001" }!

    // Create first record: 10:00:00 - 11:00:03
    let baseTime = Calendar.current.date(byAdding: .hour, value: -10, to: Date())!
    let firstStart = baseTime
    let firstEnd = Calendar.current.date(byAdding: .hour, value: 1, to: firstStart)!
      .addingTimeInterval(3) // Add 3 seconds

    let firstRecord = try! mockTimeRecordRepo.startTimeRecord(for: projects[0], job: defaultJob)
    try! mockTimeRecordRepo.stopCurrentTimeRecord() // Stop it first
    try! mockTimeRecordRepo.updateTimeRecord(firstRecord, startTime: firstStart, endTime: firstEnd, project: projects[0], job: defaultJob)

    // Create second record with temporary time, then edit to target time
    let secondRecord = try! mockTimeRecordRepo.startTimeRecord(for: projects[1], job: defaultJob)
    try! mockTimeRecordRepo.stopCurrentTimeRecord() // Stop it before editing

    // Edit second record to be 36 seconds after first ends
    let secondStart = firstEnd.addingTimeInterval(36)
    let secondEnd = Calendar.current.date(byAdding: .hour, value: 1, to: secondStart)!

    viewModel.startEditing(secondRecord)
    viewModel.startTime = secondStart
    viewModel.endTime = secondEnd

    // Should be valid (within 60 seconds is allowed)
    #expect(viewModel.isValidTimeRange == true)

    viewModel.saveChanges()

    #expect(viewModel.errorMessage == nil)
    #expect(viewModel.showingEditSheet == false)
  }

  @Test("Should reject overlapping times (more than 60 seconds overlap)")
  func rejectOverlappingTimes() async {
    // Create fresh setup without sample data to avoid time conflicts
    let mockProjectRepo = MockProjectRepository(withSampleData: true)
    let projects = try! mockProjectRepo.fetchProjects()
    let mockTimeRecordRepo = MockTimeRecordRepository(projects: projects, withSampleData: false)
    let mockJobRepo = MockJobRepository()

    let viewModel = EditHistoryViewModel(
      timeRecordRepository: mockTimeRecordRepo,
      projectRepository: mockProjectRepo,
      jobRepository: mockJobRepo
    )

    let jobs = try! mockJobRepo.fetchAllJobs()
    let defaultJob = jobs.first { $0.jobId == "001" }!

    // Create first record: 10:00:00 - 11:00:00
    let baseTime = Calendar.current.date(byAdding: .hour, value: -10, to: Date())!
    let firstStart = baseTime
    let firstEnd = Calendar.current.date(byAdding: .hour, value: 1, to: firstStart)!

    let firstRecord = try! mockTimeRecordRepo.startTimeRecord(for: projects[0], job: defaultJob)
    try! mockTimeRecordRepo.stopCurrentTimeRecord()
    try! mockTimeRecordRepo.updateTimeRecord(firstRecord, startTime: firstStart, endTime: firstEnd, project: projects[0], job: defaultJob)

    // Try to edit second record: 10:58:00 - 12:00:00 (overlaps by 2 minutes)
    let secondStart = Calendar.current.date(byAdding: .minute, value: -2, to: firstEnd)!
    let secondEnd = Calendar.current.date(byAdding: .hour, value: 1, to: secondStart)!

    let secondRecord = try! mockTimeRecordRepo.startTimeRecord(for: projects[1], job: defaultJob)
    try! mockTimeRecordRepo.stopCurrentTimeRecord()

    viewModel.startEditing(secondRecord)
    viewModel.startTime = secondStart
    viewModel.endTime = secondEnd

    // Should save but validation will fail
    viewModel.saveChanges()

    #expect(viewModel.errorMessage != nil)
    #expect(viewModel.showingEditSheet == true)
  }

  @Test("Should allow exact same time (0 second difference)")
  func allowExactSameTime() async {
    // Create fresh setup without sample data to avoid time conflicts
    let mockProjectRepo = MockProjectRepository(withSampleData: true)
    let projects = try! mockProjectRepo.fetchProjects()
    let mockTimeRecordRepo = MockTimeRecordRepository(projects: projects, withSampleData: false)
    let mockJobRepo = MockJobRepository()

    let viewModel = EditHistoryViewModel(
      timeRecordRepository: mockTimeRecordRepo,
      projectRepository: mockProjectRepo,
      jobRepository: mockJobRepo
    )

    let jobs = try! mockJobRepo.fetchAllJobs()
    let defaultJob = jobs.first { $0.jobId == "001" }!

    // Create first record: 10:00:00 - 11:00:00
    let baseTime = Calendar.current.date(byAdding: .hour, value: -10, to: Date())!
    let firstStart = baseTime
    let firstEnd = Calendar.current.date(byAdding: .hour, value: 1, to: firstStart)!

    let firstRecord = try! mockTimeRecordRepo.startTimeRecord(for: projects[0], job: defaultJob)
    try! mockTimeRecordRepo.stopCurrentTimeRecord()
    try! mockTimeRecordRepo.updateTimeRecord(firstRecord, startTime: firstStart, endTime: firstEnd, project: projects[0], job: defaultJob)

    // Edit second record: 11:00:00 - 12:00:00 (exact same time as first ends)
    let secondStart = firstEnd
    let secondEnd = Calendar.current.date(byAdding: .hour, value: 1, to: secondStart)!

    let secondRecord = try! mockTimeRecordRepo.startTimeRecord(for: projects[1], job: defaultJob)
    try! mockTimeRecordRepo.stopCurrentTimeRecord()

    viewModel.startEditing(secondRecord)
    viewModel.startTime = secondStart
    viewModel.endTime = secondEnd

    viewModel.saveChanges()

    #expect(viewModel.errorMessage == nil)
    #expect(viewModel.showingEditSheet == false)
  }

  // MARK: - Job Selection Tests

  @Test("Should change job selection")
  func changeJobSelection() async {
    let (viewModel, _, _, _, _, timeRecords) = self.createTestSetup()

    guard let recordToEdit = timeRecords.first else {
      #expect(Bool(false), "No completed records found for testing")
      return
    }

    viewModel.startEditing(recordToEdit)

    let originalJob = viewModel.selectedJob

    // Change to a different job
    if let newJob = viewModel.availableJobs.first(where: { $0.id != originalJob?.id }) {
      viewModel.selectedJob = newJob

      #expect(viewModel.selectedJob?.id == newJob.id)
      #expect(viewModel.selectedJob?.id != originalJob?.id)
    }
  }

  @Test("Should have all predefined jobs available")
  func predefinedJobsAvailable() async {
    let (viewModel, _, _, _, _, _) = self.createTestSetup()

    #expect(viewModel.availableJobs.count == 5)

    let expectedJobIds = ["001", "002", "003", "006", "999"]
    for jobId in expectedJobIds {
      #expect(viewModel.availableJobs.contains(where: { $0.jobId == jobId }))
    }
  }

  // MARK: - Delete Tests

  @Test("Should delete record")
  func testDeleteRecord() async {
    let (viewModel, _, _, _, _, timeRecords) = self.createTestSetup()

    guard let recordToEdit = timeRecords.first else {
      #expect(Bool(false), "No completed records found for testing")
      return
    }

    viewModel.startEditing(recordToEdit)

    viewModel.deleteRecord()

    #expect(viewModel.errorMessage == nil)
    #expect(viewModel.showingEditSheet == false)
    #expect(viewModel.showingDeleteAlert == false)
    #expect(viewModel.editingRecord == nil)
  }

  @Test("Should not delete when no record selected")
  func deleteWithoutRecord() async {
    let (viewModel, _, _, _, _, _) = self.createTestSetup()

    viewModel.deleteRecord()

    #expect(viewModel.errorMessage != nil)
  }

  // MARK: - Cancel Tests

  @Test("Should cancel editing")
  func testCancel() async {
    let (viewModel, _, _, _, _, timeRecords) = self.createTestSetup()

    guard let recordToEdit = timeRecords.first else {
      #expect(Bool(false), "No completed records found for testing")
      return
    }

    viewModel.startEditing(recordToEdit)

    viewModel.cancel()

    #expect(viewModel.showingEditSheet == false)
    #expect(viewModel.showingDeleteAlert == false)
    #expect(viewModel.editingRecord == nil)
    #expect(viewModel.selectedProject == nil)
    #expect(viewModel.selectedJob == nil)
    #expect(viewModel.errorMessage == nil)
  }

  // MARK: - Computed Properties Tests

  @Test("Should format duration correctly")
  func testFormattedDuration() async {
    let (viewModel, _, _, _, _, _) = self.createTestSetup()

    // Test hours and minutes
    viewModel.startTime = Date()
    viewModel.endTime = Calendar.current.date(byAdding: .hour, value: 2, to: viewModel.startTime)!
    viewModel.endTime = Calendar.current.date(byAdding: .minute, value: 30, to: viewModel.endTime)!

    #expect(viewModel.formattedDuration == "2時間30分")

    // Test minutes only
    viewModel.endTime = Calendar.current.date(byAdding: .minute, value: 45, to: viewModel.startTime)!

    #expect(viewModel.formattedDuration == "45分")
  }

  // MARK: - State Management Tests

  @Test("Should manage loading state correctly")
  func loadingState() async {
    let (viewModel, _, _, _, _, _) = self.createTestSetup()

    #expect(viewModel.isLoading == false)

    // Check canSave and canDelete respect loading state
    viewModel.isLoading = true
    #expect(viewModel.canSave == false)
    #expect(viewModel.canDelete == false)
  }
}
