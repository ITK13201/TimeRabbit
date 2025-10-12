//
//  ViewModelFactory.swift
//  TimeRabbit
//
//  Created by Takumi Ikeda on 2025/08/09.
//

import Foundation
import SwiftUI

// MARK: - ViewModel Factory

@MainActor
class ViewModelFactory: ObservableObject {
    private let projectRepository: ProjectRepositoryProtocol
    private let timeRecordRepository: TimeRecordRepositoryProtocol
    private let jobRepository: JobRepositoryProtocol
    private let dateService: DateService

    init(projectRepository: ProjectRepositoryProtocol, timeRecordRepository: TimeRecordRepositoryProtocol, jobRepository: JobRepositoryProtocol, dateService: DateService) {
        self.projectRepository = projectRepository
        self.timeRecordRepository = timeRecordRepository
        self.jobRepository = jobRepository
        self.dateService = dateService
    }

    // MARK: - ViewModel Creation Methods

    func createProjectRowViewModel(for project: Project) -> ProjectRowViewModel {
        return ProjectRowViewModel(
            project: project,
            projectRepository: projectRepository,
            timeRecordRepository: timeRecordRepository,
            jobRepository: jobRepository
        )
    }

    func createAddProjectViewModel() -> AddProjectViewModel {
        return AddProjectViewModel(projectRepository: projectRepository)
    }

    func createStatisticsViewModel() -> StatisticsViewModel {
        return StatisticsViewModel(timeRecordRepository: timeRecordRepository, dateService: dateService)
    }

    func createEditHistoryViewModel() -> EditHistoryViewModel {
        return EditHistoryViewModel(
            timeRecordRepository: timeRecordRepository,
            projectRepository: projectRepository,
            jobRepository: jobRepository
        )
    }

    func createHistoryViewModel() -> HistoryViewModel {
        return HistoryViewModel(
            timeRecordRepository: timeRecordRepository,
            projectRepository: projectRepository,
            editHistoryViewModel: createEditHistoryViewModel(),
            dateService: dateService
        )
    }

    func createMainContentViewModel() -> MainContentViewModel {
        return MainContentViewModel(
            statisticsViewModel: createStatisticsViewModel(),
            historyViewModel: createHistoryViewModel()
        )
    }

    func createContentViewModel() -> ContentViewModel {
        return ContentViewModel(
            projectRepository: projectRepository,
            timeRecordRepository: timeRecordRepository,
            jobRepository: jobRepository,
            mainContentViewModel: createMainContentViewModel(),
            addProjectViewModel: createAddProjectViewModel()
        )
    }
}

// MARK: - Convenience Factory Methods

extension ViewModelFactory {
    static func create(with repositories: (ProjectRepositoryProtocol, TimeRecordRepositoryProtocol, JobRepositoryProtocol)) -> ViewModelFactory {
        let dateService = DateService()
        return ViewModelFactory(
            projectRepository: repositories.0,
            timeRecordRepository: repositories.1,
            jobRepository: repositories.2,
            dateService: dateService
        )
    }
}
