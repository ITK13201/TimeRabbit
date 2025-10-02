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
  @Published var selectedJob: Job?
  @Published var availableJobs: [Job] = []
  
  // MARK: - Dependencies
  
  private let projectRepository: ProjectRepositoryProtocol
  private let timeRecordRepository: TimeRecordRepositoryProtocol
  private let jobRepository: JobRepositoryProtocol
  private let userDefaults = UserDefaults.standard
  
  // MARK: - Callbacks
  
  var onProjectUpdated: ((Project) -> Void)?
  var onProjectDeleted: ((Project) -> Void)?
  var onTrackingStarted: ((Project) -> Void)?
  
  // MARK: - Initialization
  
  init(project: Project, 
       projectRepository: ProjectRepositoryProtocol, 
       timeRecordRepository: TimeRecordRepositoryProtocol,
       jobRepository: JobRepositoryProtocol) {
    self.project = project
    self.projectRepository = projectRepository
    self.timeRecordRepository = timeRecordRepository
    self.jobRepository = jobRepository
    super.init()
    
    loadAvailableJobs()
    loadSavedJobSelection()
    updateActiveStatus()
  }
  
  // MARK: - Status Management
  
  func updateActiveStatus() {
    if let currentRecord = withLoadingSync({
      try timeRecordRepository.fetchCurrentTimeRecord()
    }) {
      isActive = currentRecord?.projectId == project.id
    } else {
      isActive = false
    }
  }
  
  // MARK: - Actions
  
  func startTracking() {
    guard let selectedJob = selectedJob else {
        AppLogger.viewModel.warning("No job selected for project: \(self.project.id)")
      return
    }
    
    if let _ = withLoadingSync({
      try timeRecordRepository.startTimeRecord(for: project, job: selectedJob)
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
  
  // MARK: - Job Management
  
  func loadAvailableJobs() {
    if let jobs = withLoadingSync({
      try jobRepository.fetchAllJobs()
    }) {
      availableJobs = jobs
    }
  }
  
  func updateSelectedJob(_ job: Job) {
    selectedJob = job
    saveJobSelection()
    AppLogger.viewModel.debug("Updated selected job for project \(self.project.id): \(job.name)")
  }
  
  func loadSavedJobSelection() {
    let savedJobId = userDefaults.string(forKey: "selectedJob_\(self.project.id)")
    if let savedJobId = savedJobId,
       let savedJob = availableJobs.first(where: { $0.id == savedJobId }) {
      selectedJob = savedJob
      AppLogger.viewModel.debug("Loaded saved job selection for project \(self.project.id): \(savedJob.name)")
    } else {
      // デフォルトは「開発」(001)
      selectedJob = availableJobs.first { $0.id == "001" }
      AppLogger.viewModel.debug("Set default job selection for project \(self.project.id): 開発")
    }
  }
  
  private func saveJobSelection() {
    if let selectedJob = selectedJob {
      userDefaults.set(selectedJob.id, forKey: "selectedJob_\(self.project.id)")
      AppLogger.viewModel.debug("Saved job selection for project \(self.project.id): \(selectedJob.name)")
    }
  }
}
