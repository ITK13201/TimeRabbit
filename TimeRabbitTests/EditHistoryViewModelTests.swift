//
//  EditHistoryViewModelTests.swift
//  TimeRabbitTests
//
//  Created by Takumi Ikeda on 2025/08/09.
//

import Testing
import Foundation
@testable import TimeRabbit

// MARK: - Edit History ViewModel Tests

@MainActor
struct EditHistoryViewModelTests {
  
  // MARK: - Setup Helper
  
  private func createTestSetup() -> (EditHistoryViewModel, MockProjectRepository, MockTimeRecordRepository, [Project], [TimeRecord]) {
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
    
    return (viewModel, mockProjectRepo, mockTimeRecordRepo, projects, timeRecords)
  }
  
  // MARK: - Initialization Tests
  
  @Test("ViewModel should initialize correctly")
  func testInitialization() async {
    let (viewModel, _, _, projects, _) = createTestSetup()
    
    // Wait a moment for async initialization
    try! await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
    
    #expect(viewModel.editingRecord == nil)
    #expect(viewModel.selectedProject == nil)
    #expect(viewModel.showingEditSheet == false)
    #expect(viewModel.showingDeleteAlert == false)
    #expect(viewModel.availableProjects.count == projects.count)
  }
  
  // MARK: - Start Editing Tests
  
  @Test("Should start editing completed record")
  func testStartEditingCompletedRecord() async {
    let (viewModel, _, _, _, timeRecords) = createTestSetup()
    
    guard let recordToEdit = timeRecords.first else {
      #expect(Bool(false), "No completed records found for testing")
      return
    }
    
    viewModel.startEditing(recordToEdit)
    
    #expect(viewModel.editingRecord?.id == recordToEdit.id)
    #expect(viewModel.selectedProject?.id == recordToEdit.project?.id)
    #expect(viewModel.startTime == recordToEdit.startTime)
    #expect(viewModel.endTime == recordToEdit.endTime)
    #expect(viewModel.showingEditSheet == true)
    #expect(viewModel.errorMessage == nil)
  }
  
  @Test("Should not edit incomplete record")
  func testStartEditingIncompleteRecord() async {
    let (viewModel, _, mockTimeRecordRepo, projects, _) = createTestSetup()

    // Get default job for testing
    let mockJobRepo = MockJobRepository()
    let jobs = try! mockJobRepo.fetchAllJobs()
    let defaultJob = jobs.first { $0.id == "001" }!

    // Create an incomplete record (no endTime)
    let incompleteRecord = try! mockTimeRecordRepo.startTimeRecord(for: projects[0], job: defaultJob)
    
    viewModel.startEditing(incompleteRecord)
    
    #expect(viewModel.editingRecord == nil)
    #expect(viewModel.showingEditSheet == false)
    #expect(viewModel.errorMessage != nil)
  }
  
  // MARK: - Validation Tests
  
  @Test("Should validate valid time range")
  func testValidTimeRange() async {
    let (viewModel, _, _, _, timeRecords) = createTestSetup()
    
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
  func testInvalidTimeRangeStartAfterEnd() async {
    let (viewModel, _, _, _, timeRecords) = createTestSetup()
    
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
  func testInvalidFutureTime() async {
    let (viewModel, _, _, _, timeRecords) = createTestSetup()
    
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
  func testInvalidTooShortDuration() async {
    let (viewModel, _, _, _, timeRecords) = createTestSetup()
    
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
    let (viewModel, _, _, _, timeRecords) = createTestSetup()
    
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
    let (viewModel, _, _, _, timeRecords) = createTestSetup()
    
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
  func testSaveValidChanges() async {
    let (viewModel, _, _, projects, timeRecords) = createTestSetup()
    
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
  func testSaveWithMissingData() async {
    let (viewModel, _, _, _, timeRecords) = createTestSetup()
    
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
  
  // MARK: - Delete Tests
  
  @Test("Should delete record")
  func testDeleteRecord() async {
    let (viewModel, _, _, _, timeRecords) = createTestSetup()
    
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
  func testDeleteWithoutRecord() async {
    let (viewModel, _, _, _, _) = createTestSetup()
    
    viewModel.deleteRecord()
    
    #expect(viewModel.errorMessage != nil)
  }
  
  // MARK: - Cancel Tests
  
  @Test("Should cancel editing")
  func testCancel() async {
    let (viewModel, _, _, _, timeRecords) = createTestSetup()
    
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
    #expect(viewModel.errorMessage == nil)
  }
  
  // MARK: - Computed Properties Tests
  
  @Test("Should format duration correctly")
  func testFormattedDuration() async {
    let (viewModel, _, _, _, _) = createTestSetup()
    
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
  func testLoadingState() async {
    let (viewModel, _, _, _, _) = createTestSetup()
    
    #expect(viewModel.isLoading == false)
    
    // Check canSave and canDelete respect loading state
    viewModel.isLoading = true
    #expect(viewModel.canSave == false)
    #expect(viewModel.canDelete == false)
  }
}