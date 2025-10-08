//
//  StatisticsViewModelCommandTests.swift
//  TimeRabbitTests
//
//  Created by Takumi Ikeda on 2025/10/03.
//

import Foundation
import Testing
@testable import TimeRabbit

@Suite("StatisticsViewModel Command Generation Tests")
struct StatisticsViewModelCommandTests {

  @Test("Should generate command with correct format")
  @MainActor
  func testGenerateCommandFormat() async throws {
    // Arrange
    let mockProjectRepo = MockProjectRepository(withSampleData: true)
    let projects = try mockProjectRepo.fetchProjects()
    let mockTimeRecordRepo = MockTimeRecordRepository(projects: projects, withSampleData: false)
    let mockJobRepo = MockJobRepository()
    let jobs = try mockJobRepo.fetchAllJobs()
    let dateService = DateService()

    // 過去の日付を設定（2025/09/15）
    let calendar = Calendar.current
    let testDate = calendar.date(from: DateComponents(year: 2025, month: 9, day: 15))!
    dateService.selectedDate = testDate

    // 2025/09/15のテストデータを作成
    let project = projects[0]
    let job = jobs[0]
    let startTime = calendar.date(from: DateComponents(year: 2025, month: 9, day: 15, hour: 9, minute: 0))!
    let endTime = calendar.date(from: DateComponents(year: 2025, month: 9, day: 15, hour: 10, minute: 0))!

    let record = try mockTimeRecordRepo.startTimeRecord(for: project, job: job)
    try mockTimeRecordRepo.stopCurrentTimeRecord()
    try mockTimeRecordRepo.updateTimeRecord(record, startTime: startTime, endTime: endTime, project: project, job: job)

    let factory = ViewModelFactory.create(
      with: (mockProjectRepo, mockTimeRecordRepo, mockJobRepo)
    )
    let viewModel = factory.createStatisticsViewModel()
    viewModel.selectedDate = dateService.selectedDate

    // Act
    viewModel.loadStatistics()

    // Assert
    #expect(!viewModel.projectJobDetails.isEmpty, "Should have project job details")

    if let firstDetail = viewModel.projectJobDetails.first {
      let command = viewModel.generateCommand(for: firstDetail)

      // コマンドフォーマットの検証: "add yyyy/MM/dd [projectId] [jobId] [percentage]"
      #expect(command.hasPrefix("add 2025/09/15"), "Command should start with 'add 2025/09/15'")

      let components = command.split(separator: " ")
      #expect(components.count == 5, "Command should have 5 components")
      #expect(components[0] == "add", "First component should be 'add'")
      #expect(components[1] == "2025/09/15", "Second component should be date")
      #expect(components[2] == firstDetail.projectId, "Third component should be projectId")
      #expect(components[3] == firstDetail.jobId, "Fourth component should be jobId")

      // パーセンテージは整数であることを確認
      if let percentage = Int(components[4]) {
        #expect(percentage >= 0 && percentage <= 100, "Percentage should be between 0 and 100")
      } else {
        Issue.record("Percentage should be a valid integer")
      }
    }
  }

  @Test("Should generate command text with multiple entries")
  @MainActor
  func testGenerateCommandTextMultipleEntries() async throws {
    // Arrange
    let mockProjectRepo = MockProjectRepository(withSampleData: true)
    let projects = try mockProjectRepo.fetchProjects()
    let mockTimeRecordRepo = MockTimeRecordRepository(projects: projects, withSampleData: false)
    let mockJobRepo = MockJobRepository()
    let jobs = try mockJobRepo.fetchAllJobs()
    let dateService = DateService()

    let calendar = Calendar.current
    let testDate = calendar.date(from: DateComponents(year: 2025, month: 9, day: 15))!
    dateService.selectedDate = testDate

    // 2025/09/15のテストデータを複数作成
    let project1 = projects[0]
    let project2 = projects[1]
    let job1 = jobs[0]
    let job2 = jobs[1]

    // Record 1: Project 1, Job 1, 9:00-10:00
    let record1 = try mockTimeRecordRepo.startTimeRecord(for: project1, job: job1)
    try mockTimeRecordRepo.stopCurrentTimeRecord()
    let start1 = calendar.date(from: DateComponents(year: 2025, month: 9, day: 15, hour: 9, minute: 0))!
    let end1 = calendar.date(from: DateComponents(year: 2025, month: 9, day: 15, hour: 10, minute: 0))!
    try mockTimeRecordRepo.updateTimeRecord(record1, startTime: start1, endTime: end1, project: project1, job: job1)

    // Record 2: Project 2, Job 2, 10:00-11:00
    let record2 = try mockTimeRecordRepo.startTimeRecord(for: project2, job: job2)
    try mockTimeRecordRepo.stopCurrentTimeRecord()
    let start2 = calendar.date(from: DateComponents(year: 2025, month: 9, day: 15, hour: 10, minute: 0))!
    let end2 = calendar.date(from: DateComponents(year: 2025, month: 9, day: 15, hour: 11, minute: 0))!
    try mockTimeRecordRepo.updateTimeRecord(record2, startTime: start2, endTime: end2, project: project2, job: job2)

    let factory = ViewModelFactory.create(
      with: (mockProjectRepo, mockTimeRecordRepo, mockJobRepo)
    )
    let viewModel = factory.createStatisticsViewModel()
    viewModel.selectedDate = dateService.selectedDate

    // Act
    viewModel.loadStatistics()
    let commandText = viewModel.generateCommandText()

    // Assert
    #expect(!commandText.isEmpty, "Command text should not be empty")

    let lines = commandText.split(separator: "\n")
    #expect(lines.count == viewModel.projectJobDetails.count,
            "Number of command lines should match number of project job details")

    // 各行がコマンドフォーマットに従っているか検証
    for line in lines {
      let lineComponents = line.split(separator: " ")
      #expect(lineComponents.count == 5, "Each command line should have 5 components")
      #expect(lineComponents[0] == "add", "Each line should start with 'add'")
      #expect(lineComponents[1] == "2025/09/15", "Each line should have the date")
    }
  }

  @Test("Should round percentage correctly")
  @MainActor
  func testPercentageRounding() async throws {
    // Arrange
    let mockProjectRepo = MockProjectRepository(withSampleData: false)
    let project1 = try mockProjectRepo.createProject(projectId: "PRJ001", name: "Project 1", color: "blue")
    let project2 = try mockProjectRepo.createProject(projectId: "PRJ002", name: "Project 2", color: "red")

    let projects = try mockProjectRepo.fetchProjects()
    let mockTimeRecordRepo = MockTimeRecordRepository(projects: projects, withSampleData: false)
    let mockJobRepo = MockJobRepository()
    let jobs = try mockJobRepo.fetchAllJobs()
    let job = jobs.first!

    let dateService = DateService()
    let calendar = Calendar.current
    let components = DateComponents(year: 2025, month: 9, day: 15, hour: 9, minute: 0)
    let startDate = calendar.date(from: components)!
    dateService.selectedDate = startDate

    // 33.3%, 33.3%, 33.4% になるような時間記録を作成
    // 総時間: 3時間 = 10800秒
    // Project1: 1時間 = 3600秒 (33.3%)
    // Project2: 2時間 = 7200秒 (66.7%)

    let record1 = try mockTimeRecordRepo.startTimeRecord(for: project1, job: job)
    try mockTimeRecordRepo.stopCurrentTimeRecord()
    let record1EndTime = calendar.date(byAdding: .hour, value: 1, to: startDate)!
    try mockTimeRecordRepo.updateTimeRecord(record1, startTime: startDate, endTime: record1EndTime, project: project1, job: job)

    let record2StartTime = calendar.date(byAdding: .hour, value: 1, to: startDate)!
    let record2 = try mockTimeRecordRepo.startTimeRecord(for: project2, job: job)
    try mockTimeRecordRepo.stopCurrentTimeRecord()
    let record2EndTime = calendar.date(byAdding: .hour, value: 2, to: record2StartTime)!
    try mockTimeRecordRepo.updateTimeRecord(record2, startTime: record2StartTime, endTime: record2EndTime, project: project2, job: job)

    let factory = ViewModelFactory.create(
      with: (mockProjectRepo, mockTimeRecordRepo, mockJobRepo)
    )
    let viewModel = factory.createStatisticsViewModel()
    viewModel.selectedDate = dateService.selectedDate

    // Act
    viewModel.loadStatistics()

    // Assert
    #expect(viewModel.projectJobDetails.count == 2, "Should have 2 project job details")

    for detail in viewModel.projectJobDetails {
      let command = viewModel.generateCommand(for: detail)
      let commandComponents = command.split(separator: " ")

      if let percentage = Int(commandComponents[4]) {
        // 33.3% → 33, 66.7% → 67 (四捨五入)
        if detail.projectId == "PRJ001" {
          #expect(percentage == 33, "Project1 should have 33% (rounded from 33.3%)")
        } else if detail.projectId == "PRJ002" {
          #expect(percentage == 67, "Project2 should have 67% (rounded from 66.7%)")
        }
      } else {
        Issue.record("Percentage should be a valid integer")
      }
    }
  }

  @Test("Should handle empty data correctly")
  @MainActor
  func testEmptyData() async throws {
    // Arrange
    let mockProjectRepo = MockProjectRepository(withSampleData: false)
    let projects = try mockProjectRepo.fetchProjects()
    let mockTimeRecordRepo = MockTimeRecordRepository(projects: projects, withSampleData: false)
    let mockJobRepo = MockJobRepository()
    let dateService = DateService()

    let factory = ViewModelFactory.create(
      with: (mockProjectRepo, mockTimeRecordRepo, mockJobRepo)
    )
    let viewModel = factory.createStatisticsViewModel()
    viewModel.selectedDate = dateService.selectedDate

    // Act
    viewModel.loadStatistics()
    let commandText = viewModel.generateCommandText()

    // Assert
    #expect(viewModel.projectJobDetails.isEmpty, "Should have no project job details")
    #expect(commandText.isEmpty, "Command text should be empty when no data")
  }

  @Test("Should use correct date format")
  @MainActor
  func testDateFormat() async throws {
    // Arrange
    let mockProjectRepo = MockProjectRepository(withSampleData: true)
    let projects = try mockProjectRepo.fetchProjects()
    let mockTimeRecordRepo = MockTimeRecordRepository(projects: projects, withSampleData: true)
    let mockJobRepo = MockJobRepository()
    let dateService = DateService()

    // 異なる日付でテスト（過去の日付を使用）
    let testDates: [(year: Int, month: Int, day: Int, expected: String)] = [
      (2025, 1, 1, "2025/01/01"),
      (2025, 9, 15, "2025/09/15"),
      (2024, 12, 31, "2024/12/31")
    ]

    for testDate in testDates {
      let calendar = Calendar.current
      let components = DateComponents(year: testDate.year, month: testDate.month, day: testDate.day)
      dateService.selectedDate = calendar.date(from: components)!

      let factory = ViewModelFactory.create(
        with: (mockProjectRepo, mockTimeRecordRepo, mockJobRepo)
      )
      let viewModel = factory.createStatisticsViewModel()
      viewModel.selectedDate = dateService.selectedDate

      // Act
      viewModel.loadStatistics()

      // Assert
      if let firstDetail = viewModel.projectJobDetails.first {
        let command = viewModel.generateCommand(for: firstDetail)
        #expect(command.contains(testDate.expected),
                "Command should contain date in yyyy/MM/dd format: \(testDate.expected)")
      }
    }
  }

  @Test("Should group by project and job correctly")
  @MainActor
  func testGroupingByProjectAndJob() async throws {
    // Arrange
    let mockProjectRepo = MockProjectRepository(withSampleData: false)
    let project = try mockProjectRepo.createProject(projectId: "PRJ001", name: "Project 1", color: "blue")

    let projects = try mockProjectRepo.fetchProjects()
    let mockTimeRecordRepo = MockTimeRecordRepository(projects: projects, withSampleData: false)
    let mockJobRepo = MockJobRepository()
    let jobs = try mockJobRepo.fetchAllJobs()
    let job1 = jobs.first { $0.jobId == "001" }! // 開発
    let job2 = jobs.first { $0.jobId == "002" }! // 保守

    let dateService = DateService()
    let calendar = Calendar.current
    let components = DateComponents(year: 2025, month: 9, day: 15, hour: 9, minute: 0)
    let startDate = calendar.date(from: components)!
    dateService.selectedDate = startDate

    // 同じプロジェクトで異なるジョブの記録を作成
    let record1 = try mockTimeRecordRepo.startTimeRecord(for: project, job: job1)
    try mockTimeRecordRepo.stopCurrentTimeRecord()
    let record1EndTime = calendar.date(byAdding: .hour, value: 1, to: startDate)!
    try mockTimeRecordRepo.updateTimeRecord(record1, startTime: startDate, endTime: record1EndTime, project: project, job: job1)

    let record2StartTime = calendar.date(byAdding: .hour, value: 1, to: startDate)!
    let record2 = try mockTimeRecordRepo.startTimeRecord(for: project, job: job2)
    try mockTimeRecordRepo.stopCurrentTimeRecord()
    let record2EndTime = calendar.date(byAdding: .hour, value: 1, to: record2StartTime)!
    try mockTimeRecordRepo.updateTimeRecord(record2, startTime: record2StartTime, endTime: record2EndTime, project: project, job: job2)

    let factory = ViewModelFactory.create(
      with: (mockProjectRepo, mockTimeRecordRepo, mockJobRepo)
    )
    let viewModel = factory.createStatisticsViewModel()
    viewModel.selectedDate = dateService.selectedDate

    // Act
    viewModel.loadStatistics()

    // Assert
    #expect(viewModel.projectJobDetails.count == 2,
            "Should have 2 entries for same project with different jobs")

    let job1Detail = viewModel.projectJobDetails.first { $0.jobId == "001" }
    let job2Detail = viewModel.projectJobDetails.first { $0.jobId == "002" }

    #expect(job1Detail != nil, "Should have entry for job 001")
    #expect(job2Detail != nil, "Should have entry for job 002")

    if let job1Detail = job1Detail, let job2Detail = job2Detail {
      #expect(job1Detail.projectId == "PRJ001", "Both should be for PRJ001")
      #expect(job2Detail.projectId == "PRJ001", "Both should be for PRJ001")

      let command1 = viewModel.generateCommand(for: job1Detail)
      let command2 = viewModel.generateCommand(for: job2Detail)

      #expect(command1.contains("001"), "Command should contain job ID 001")
      #expect(command2.contains("002"), "Command should contain job ID 002")
    }
  }
}
