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
  private let dateService: DateService
  
  init(projectRepository: ProjectRepositoryProtocol, timeRecordRepository: TimeRecordRepositoryProtocol, dateService: DateService) {
    self.projectRepository = projectRepository
    self.timeRecordRepository = timeRecordRepository
    self.dateService = dateService
  }
  
  // MARK: - ViewModel Creation Methods
  
  func createProjectRowViewModel(for project: Project) -> ProjectRowViewModel {
    return ProjectRowViewModel(
      project: project,
      projectRepository: projectRepository,
      timeRecordRepository: timeRecordRepository
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
      projectRepository: projectRepository
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
      mainContentViewModel: createMainContentViewModel(),
      addProjectViewModel: createAddProjectViewModel()
    )
  }
}

// MARK: - Convenience Factory Methods

extension ViewModelFactory {
  static func create(with repositories: (ProjectRepositoryProtocol, TimeRecordRepositoryProtocol)) -> ViewModelFactory {
    let dateService = DateService()
    return ViewModelFactory(
      projectRepository: repositories.0,
      timeRecordRepository: repositories.1,
      dateService: dateService
    )
  }
  
}