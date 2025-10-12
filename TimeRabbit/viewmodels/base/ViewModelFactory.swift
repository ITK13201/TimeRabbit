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
            projectRepository: self.projectRepository,
            timeRecordRepository: self.timeRecordRepository,
            jobRepository: self.jobRepository
        )
    }

    func createAddProjectViewModel() -> AddProjectViewModel {
        return AddProjectViewModel(projectRepository: self.projectRepository)
    }

    func createStatisticsViewModel() -> StatisticsViewModel {
        return StatisticsViewModel(timeRecordRepository: self.timeRecordRepository, dateService: self.dateService)
    }

    func createEditHistoryViewModel() -> EditHistoryViewModel {
        return EditHistoryViewModel(
            timeRecordRepository: self.timeRecordRepository,
            projectRepository: self.projectRepository,
            jobRepository: self.jobRepository
        )
    }

    func createHistoryViewModel() -> HistoryViewModel {
        return HistoryViewModel(
            timeRecordRepository: self.timeRecordRepository,
            projectRepository: self.projectRepository,
            editHistoryViewModel: self.createEditHistoryViewModel(),
            dateService: self.dateService
        )
    }

    func createMainContentViewModel() -> MainContentViewModel {
        return MainContentViewModel(
            statisticsViewModel: self.createStatisticsViewModel(),
            historyViewModel: self.createHistoryViewModel()
        )
    }

    func createContentViewModel() -> ContentViewModel {
        return ContentViewModel(
            projectRepository: self.projectRepository,
            timeRecordRepository: self.timeRecordRepository,
            jobRepository: self.jobRepository,
            mainContentViewModel: self.createMainContentViewModel(),
            addProjectViewModel: self.createAddProjectViewModel()
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
