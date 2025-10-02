//
//  EditHistoryViewModel.swift
//  TimeRabbit
//
//  Created by Takumi Ikeda on 2025/08/09.
//

import Foundation
import SwiftUI
import Combine

// MARK: - Edit History ViewModel

@MainActor
class EditHistoryViewModel: BaseViewModel {
  // MARK: - Published Properties
  
  @Published var editingRecord: TimeRecord?
  @Published var selectedProject: Project?
  @Published var selectedJob: Job?
  @Published var startTime: Date = Date()
  @Published var endTime: Date = Date()
  @Published var showingEditSheet = false
  @Published var showingDeleteAlert = false
  @Published var availableProjects: [Project] = []
  @Published var availableJobs: [Job] = []
  
  // MARK: - Computed Properties
  
  var isValidTimeRange: Bool {
    guard startTime < endTime else { return false }
    guard endTime <= Date() else { return false }
    
    let duration = endTime.timeIntervalSince(startTime)
    return duration >= 60 && duration <= 86400
  }
  
  var calculatedDuration: TimeInterval {
    return endTime.timeIntervalSince(startTime)
  }
  
  var formattedDuration: String {
    let duration = max(calculatedDuration, 0) // 負の値を防ぐ
    let hours = Int(duration) / 3600
    let minutes = (Int(duration) % 3600) / 60
    
    if hours > 0 {
      return "\(hours)時間\(minutes)分"
    } else {
      return "\(minutes)分"
    }
  }
  
  var canSave: Bool {
    return selectedProject != nil && selectedJob != nil && isValidTimeRange && !isLoading
  }
  
  var canDelete: Bool {
    return editingRecord != nil && !isLoading
  }
  
  // MARK: - Dependencies
  
  private let timeRecordRepository: TimeRecordRepositoryProtocol
  private let projectRepository: ProjectRepositoryProtocol
  private let jobRepository: JobRepositoryProtocol
  
  // MARK: - Initialization
  
  init(timeRecordRepository: TimeRecordRepositoryProtocol, 
       projectRepository: ProjectRepositoryProtocol,
       jobRepository: JobRepositoryProtocol) {
    self.timeRecordRepository = timeRecordRepository
    self.projectRepository = projectRepository
    self.jobRepository = jobRepository
    super.init()
    loadAvailableProjects()
    loadAvailableJobs()
  }
  
  // MARK: - Actions
  
  func startEditing(_ record: TimeRecord) {
    editingRecord = record
    selectedProject = record.project
    selectedJob = record.job
    startTime = record.startTime
    endTime = record.endTime ?? Date()
    showingEditSheet = true
    clearError()

    // 編集開始時に最新のプロジェクト・作業区分一覧を再読み込み
    loadAvailableProjects()
    loadAvailableJobs()
  }
  
  func saveChanges() {
    guard let record = editingRecord,
          let project = selectedProject,
          let job = selectedJob else {
      handleError(EditHistoryError.missingData)
      return
    }
    
    withLoadingSync {
      try timeRecordRepository.updateTimeRecord(
        record,
        startTime: startTime,
        endTime: endTime,
        project: project,
        job: job
      )
    }
    
    if errorMessage == nil {
      showingEditSheet = false
      resetEditingState()
    }
  }
  
  func deleteRecord() {
    guard let record = editingRecord else {
      handleError(EditHistoryError.missingData)
      return
    }
    
    withLoadingSync {
      try timeRecordRepository.deleteTimeRecord(record)
    }
    
    if errorMessage == nil {
      showingDeleteAlert = false
      showingEditSheet = false
      resetEditingState()
    }
  }
  
  func cancel() {
    showingEditSheet = false
    showingDeleteAlert = false
    resetEditingState()
    clearError()
  }
  
  func showDeleteConfirmation() {
    showingDeleteAlert = true
  }
  
  // MARK: - Time Adjustment Methods
  
  func adjustStartTime(by minutes: Int) {
    guard let newStartTime = Calendar.current.date(byAdding: .minute, value: minutes, to: startTime) else { return }
    if newStartTime < endTime && newStartTime <= Date() {
      startTime = newStartTime
    }
  }
  
  func adjustEndTime(by minutes: Int) {
    guard let newEndTime = Calendar.current.date(byAdding: .minute, value: minutes, to: endTime) else { return }
    if newEndTime > startTime && newEndTime <= Date() {
      endTime = newEndTime
    }
  }
  
  // MARK: - Private Methods
  
  private func loadAvailableProjects() {
    if let projects = withLoadingSync({
      try projectRepository.fetchProjects()
    }) {
      availableProjects = projects
    }
  }
  
  private func loadAvailableJobs() {
    if let jobs = withLoadingSync({
      try jobRepository.fetchAllJobs()
    }) {
      availableJobs = jobs
    }
  }
  
  private func resetEditingState() {
    editingRecord = nil
    selectedProject = nil
    selectedJob = nil
    startTime = Date()
    endTime = Date()
    availableProjects = []
    availableJobs = []
  }
  
  // MARK: - Validation
  
  func validateTimeRange() -> String? {
    do {
      guard let record = editingRecord else { return nil }
      _ = try timeRecordRepository.validateTimeRange(
        startTime: startTime,
        endTime: endTime,
        excludingRecord: record
      )
      return nil
    } catch {
      return error.localizedDescription
    }
  }
}

// MARK: - Edit History Errors

enum EditHistoryError: LocalizedError {
  case recordNotCompleted
  case missingData
  case validationFailed
  
  var errorDescription: String? {
    switch self {
    case .recordNotCompleted:
      return "進行中のレコードは編集できません"
    case .missingData:
      return "編集に必要な情報が不足しています"
    case .validationFailed:
      return "入力データの検証に失敗しました"
    }
  }
}