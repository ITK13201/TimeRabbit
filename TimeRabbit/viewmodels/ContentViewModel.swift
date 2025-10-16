//
//  ContentViewModel.swift
//  TimeRabbit
//
//  Created by Takumi Ikeda on 2025/08/09.
//

import Combine
import Foundation
import SwiftUI

@MainActor
class ContentViewModel: BaseViewModel {
  // MARK: - Published Properties

  @Published var projects: [Project] = []
  @Published var currentTimeRecord: TimeRecord?
  @Published var showingAddProject = false

  // MARK: - Child ViewModels

  let mainContentViewModel: MainContentViewModel
  let addProjectViewModel: AddProjectViewModel

  // MARK: - Dependencies

  private let projectRepository: ProjectRepositoryProtocol
  private let timeRecordRepository: TimeRecordRepositoryProtocol
  private let jobRepository: JobRepositoryProtocol

  // MARK: - Project Row ViewModels

  @Published var projectRowViewModels: [ProjectRowViewModel] = []

  // MARK: - Timer for real-time updates

  private var timer: Timer?

  // MARK: - Initialization

  init(projectRepository: ProjectRepositoryProtocol,
       timeRecordRepository: TimeRecordRepositoryProtocol,
       jobRepository: JobRepositoryProtocol,
       mainContentViewModel: MainContentViewModel,
       addProjectViewModel: AddProjectViewModel)
  {
    self.projectRepository = projectRepository
    self.timeRecordRepository = timeRecordRepository
    self.jobRepository = jobRepository
    self.mainContentViewModel = mainContentViewModel
    self.addProjectViewModel = addProjectViewModel

    super.init()

    self.setupAddProjectCallbacks()
    self.startTimer()
    self.initializeJobsIfNeeded()
    self.loadData()
  }

  deinit {
    timer?.invalidate()
  }

  // MARK: - Setup

  private func setupAddProjectCallbacks() {
    self.addProjectViewModel.onProjectCreated = { [weak self] newProject in
      self?.handleProjectCreated(newProject)
    }

    self.addProjectViewModel.onCancel = { [weak self] in
      self?.hideAddProject()
    }
  }

  private func startTimer() {
    self.timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
      Task { @MainActor in
        // リアルタイム更新のために objectWillChange を発行
        self.objectWillChange.send()

        // プロジェクト行のアクティブ状態を更新
        self.updateProjectRowActiveStates()
      }
    }
  }

  // MARK: - Data Loading

  func loadData() {
    if let fetchedProjects = withLoadingSync({
      try projectRepository.fetchProjects()
    }) {
      self.projects = fetchedProjects
    }

    if let currentRecord = withLoadingSync({
      try timeRecordRepository.fetchCurrentTimeRecord()
    }) {
      self.currentTimeRecord = currentRecord
    }

    if errorMessage == nil {
      // プロジェクト行のViewModelを更新
      self.updateProjectRowViewModels()

      // メインコンテンツのデータも更新
      self.mainContentViewModel.refreshAllData()
    }
  }

  func initializeJobsIfNeeded() {
    withLoadingSync {
      try self.jobRepository.initializePredefinedJobs()
    }
  }

  private func updateProjectRowViewModels() {
    self.projectRowViewModels = self.projects.map { project in
      let viewModel = ProjectRowViewModel(
        project: project,
        projectRepository: projectRepository,
        timeRecordRepository: timeRecordRepository,
        jobRepository: jobRepository
      )

      // コールバックを設定
      viewModel.onProjectDeleted = { [weak self] deletedProject in
        self?.handleProjectDeleted(deletedProject)
      }

      viewModel.onTrackingStarted = { [weak self] project in
        self?.handleTrackingStarted(for: project)
      }

      return viewModel
    }
  }

  private func updateProjectRowActiveStates() {
    self.projectRowViewModels.forEach { $0.updateActiveStatus() }
  }

  // MARK: - Project Management

  func showAddProject() {
    self.showingAddProject = true
  }

  func hideAddProject() {
    self.showingAddProject = false
  }

  private func handleProjectCreated(_: Project) {
    self.loadData() // データを再読み込み
    self.hideAddProject()
  }

  private func handleProjectDeleted(_: Project) {
    self.loadData() // データを再読み込み
  }

  private func handleTrackingStarted(for _: Project) {
    if let currentRecord = withLoadingSync({
      try timeRecordRepository.fetchCurrentTimeRecord()
    }) {
      self.currentTimeRecord = currentRecord
    }

    if errorMessage == nil {
      // 統計データも更新
      self.mainContentViewModel.refreshAllData()
    }
  }

  // MARK: - Time Tracking

  func stopTracking() {
    withLoadingSync {
      try self.timeRecordRepository.stopCurrentTimeRecord()
    }

    if errorMessage == nil {
      if let currentRecord = withLoadingSync({
        try timeRecordRepository.fetchCurrentTimeRecord()
      }) {
        self.currentTimeRecord = currentRecord
      }

      // データを更新
      self.mainContentViewModel.refreshAllData()
    }
  }

  // MARK: - Helper Methods

  func getCurrentProjectName() -> String {
    return self.currentTimeRecord?.displayProjectName ?? ""
  }

  func getCurrentProjectColor() -> String {
    return self.currentTimeRecord?.displayProjectColor ?? "blue"
  }

  func getCurrentJobName() -> String {
    return self.currentTimeRecord?.displayJobName ?? ""
  }

  func getCurrentDuration() -> TimeInterval {
    return self.currentTimeRecord?.duration ?? 0
  }

  func getCurrentStartTime() -> Date? {
    return self.currentTimeRecord?.startTime
  }

  func isTracking() -> Bool {
    return self.currentTimeRecord != nil
  }
}
