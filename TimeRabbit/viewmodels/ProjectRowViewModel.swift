//
//  ProjectRowViewModel.swift
//  TimeRabbit
//
//  Created by Takumi Ikeda on 2025/08/09.
//

import Foundation
import SwiftUI
import Combine

@MainActor
class ProjectRowViewModel: BaseViewModel {
  // MARK: - Published Properties
  
  @Published var project: Project
  @Published var isActive: Bool = false
  
  // MARK: - Dependencies
  
  private let projectRepository: ProjectRepositoryProtocol
  private let timeRecordRepository: TimeRecordRepositoryProtocol
  
  // MARK: - Callbacks
  
  var onProjectUpdated: ((Project) -> Void)?
  var onProjectDeleted: ((Project) -> Void)?
  var onTrackingStarted: ((Project) -> Void)?
  
  // MARK: - Initialization
  
  init(project: Project, 
       projectRepository: ProjectRepositoryProtocol, 
       timeRecordRepository: TimeRecordRepositoryProtocol) {
    self.project = project
    self.projectRepository = projectRepository
    self.timeRecordRepository = timeRecordRepository
    super.init()
    
    updateActiveStatus()
  }
  
  // MARK: - Status Management
  
  func updateActiveStatus() {
    if let currentRecord = withLoadingSync({
      try timeRecordRepository.fetchCurrentTimeRecord()
    }) {
      isActive = currentRecord?.project?.id == project.id
    } else {
      isActive = false
    }
  }
  
  // MARK: - Actions
  
  func startTracking() {
    if let _ = withLoadingSync({
      try timeRecordRepository.startTimeRecord(for: project)
    }) {
      isActive = true
      onTrackingStarted?(project)
    }
  }
  
  func deleteProject() {
    // 現在記録中の場合は停止
    if isActive {
      withLoadingSync {
        try timeRecordRepository.stopCurrentTimeRecord()
      }
    }
    
    if let _ = withLoadingSync({
      try projectRepository.deleteProject(project)
    }) {
      onProjectDeleted?(project)
    }
  }
}