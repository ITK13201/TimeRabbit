//
//  EditHistoryViewModelSimpleTests.swift
//  TimeRabbitTests
//
//  Created by Takumi Ikeda on 2025/08/09.
//

import Foundation
import Testing
@testable import TimeRabbit

@MainActor
struct EditHistoryViewModelSimpleTests {
    @Test("ViewModel initializes correctly")
    func viewModelInitialization() async {
        let mockProjectRepo = MockProjectRepository(withSampleData: true)
        let projects = try! mockProjectRepo.fetchProjects()
        let mockTimeRecordRepo = MockTimeRecordRepository(projects: projects, withSampleData: true)
        let mockJobRepo = MockJobRepository()

        let viewModel = EditHistoryViewModel(
            timeRecordRepository: mockTimeRecordRepo,
            projectRepository: mockProjectRepo,
            jobRepository: mockJobRepo
        )

        // Basic state verification
        #expect(viewModel.editingRecord == nil)
        #expect(viewModel.selectedProject == nil)
        #expect(viewModel.selectedJob == nil)
        #expect(viewModel.showingEditSheet == false)
        #expect(viewModel.showingDeleteAlert == false)
        #expect(viewModel.availableJobs.count == 5)
    }

    @Test("Time range validation works")
    func timeRangeValidation() async {
        let mockProjectRepo = MockProjectRepository(withSampleData: true)
        let projects = try! mockProjectRepo.fetchProjects()
        let mockTimeRecordRepo = MockTimeRecordRepository(projects: projects, withSampleData: true)
        let mockJobRepo = MockJobRepository()

        let viewModel = EditHistoryViewModel(
            timeRecordRepository: mockTimeRecordRepo,
            projectRepository: mockProjectRepo,
            jobRepository: mockJobRepo
        )

        // Test valid time range
        viewModel.startTime = Calendar.current.date(byAdding: .hour, value: -2, to: Date())!
        viewModel.endTime = Calendar.current.date(byAdding: .hour, value: -1, to: Date())!

        #expect(viewModel.isValidTimeRange == true)

        // Test invalid time range (start after end)
        viewModel.startTime = Calendar.current.date(byAdding: .hour, value: -1, to: Date())!
        viewModel.endTime = Calendar.current.date(byAdding: .hour, value: -2, to: Date())!

        #expect(viewModel.isValidTimeRange == false)
    }

    @Test("Duration formatting works correctly")
    func durationFormatting() async {
        let mockProjectRepo = MockProjectRepository(withSampleData: true)
        let projects = try! mockProjectRepo.fetchProjects()
        let mockTimeRecordRepo = MockTimeRecordRepository(projects: projects, withSampleData: true)
        let mockJobRepo = MockJobRepository()

        let viewModel = EditHistoryViewModel(
            timeRecordRepository: mockTimeRecordRepo,
            projectRepository: mockProjectRepo,
            jobRepository: mockJobRepo
        )

        // Test hours and minutes
        viewModel.startTime = Date()
        viewModel.endTime = Calendar.current.date(byAdding: .hour, value: 2, to: viewModel.startTime)!
        viewModel.endTime = Calendar.current.date(byAdding: .minute, value: 30, to: viewModel.endTime)!

        #expect(viewModel.formattedDuration == "2時間30分")

        // Test minutes only
        viewModel.endTime = Calendar.current.date(byAdding: .minute, value: 45, to: viewModel.startTime)!

        #expect(viewModel.formattedDuration == "45分")
    }
}
