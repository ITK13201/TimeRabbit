//
//  ProjectRowViewModel.swift
//  TimeRabbit
//
//  Created by Takumi Ikeda on 2025/08/09.
//

import Combine
import Foundation
import SwiftUI

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
       jobRepository: JobRepositoryProtocol)
  {
    self.project = project
    self.projectRepository = projectRepository
    self.timeRecordRepository = timeRecordRepository
    self.jobRepository = jobRepository
    super.init()

    self.loadAvailableJobs()
    self.loadSavedJobSelection()
    self.updateActiveStatus()
  }

  // MARK: - Status Management

  func updateActiveStatus() {
    if let currentRecord = withLoadingSync({
      try timeRecordRepository.fetchCurrentTimeRecord()
    }) {
      self.isActive = currentRecord?.backupProjectId == self.project.projectId
    } else {
      self.isActive = false
    }
  }

  // MARK: - Actions

  func startTracking() {
    guard let selectedJob = selectedJob else {
      AppLogger.viewModel.warning("No job selected for project: \(self.project.projectId)")
      return
    }

    if let _ = withLoadingSync({
      try timeRecordRepository.startTimeRecord(for: self.project, job: selectedJob)
    }) {
      self.isActive = true
      self.onTrackingStarted?(self.project)
    }
  }

  func deleteProject() {
    // 現在記録中の場合は停止
    if self.isActive {
      withLoadingSync {
        try self.timeRecordRepository.stopCurrentTimeRecord()
      }
    }

    if let _ = withLoadingSync({
      try projectRepository.deleteProject(project)
    }) {
      self.onProjectDeleted?(self.project)
    }
  }

  // MARK: - Job Management

  func loadAvailableJobs() {
    if let jobs = withLoadingSync({
      try jobRepository.fetchAllJobs()
    }) {
      self.availableJobs = jobs
    }
  }

  func updateSelectedJob(_ job: Job) {
    self.selectedJob = job
    self.saveJobSelection()
    AppLogger.viewModel.debug("Updated selected job for project \(self.project.projectId): \(job.name)")
  }

  func loadSavedJobSelection() {
    let savedJobId = self.userDefaults.string(forKey: "selectedJob_\(self.project.projectId)")
    if let savedJobId = savedJobId,
       let savedJob = availableJobs.first(where: { $0.jobId == savedJobId })
    {
      self.selectedJob = savedJob
      AppLogger.viewModel.debug("Loaded saved job selection for project \(self.project.projectId): \(savedJob.name)")
    } else {
      // デフォルトは「開発」(001)
      self.selectedJob = self.availableJobs.first { $0.jobId == "001" }
      AppLogger.viewModel.debug("Set default job selection for project \(self.project.projectId): 開発")
    }
  }

  private func saveJobSelection() {
    if let selectedJob = selectedJob {
      self.userDefaults.set(selectedJob.jobId, forKey: "selectedJob_\(self.project.projectId)")
      AppLogger.viewModel.debug("Saved job selection for project \(self.project.projectId): \(selectedJob.name)")
    }
  }
}
