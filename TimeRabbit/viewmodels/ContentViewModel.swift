//
//  ContentViewModel.swift
//  TimeRabbit
//
//  Created by Takumi Ikeda on 2025/08/09.
//

import Foundation
import SwiftUI
import Combine

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
  
  // MARK: - Project Row ViewModels
  
  @Published var projectRowViewModels: [ProjectRowViewModel] = []
  
  // MARK: - Timer for real-time updates
  
  private var timer: Timer?
  
  // MARK: - Initialization
  
  init(projectRepository: ProjectRepositoryProtocol,
       timeRecordRepository: TimeRecordRepositoryProtocol,
       mainContentViewModel: MainContentViewModel,
       addProjectViewModel: AddProjectViewModel) {
    self.projectRepository = projectRepository
    self.timeRecordRepository = timeRecordRepository
    self.mainContentViewModel = mainContentViewModel
    self.addProjectViewModel = addProjectViewModel
    
    super.init()
    
    setupAddProjectCallbacks()
    startTimer()
    loadData()
  }
  
  deinit {
    timer?.invalidate()
  }
  
  // MARK: - Setup
  
  private func setupAddProjectCallbacks() {
    addProjectViewModel.onProjectCreated = { [weak self] newProject in
      self?.handleProjectCreated(newProject)
    }
    
    addProjectViewModel.onCancel = { [weak self] in
      self?.hideAddProject()
    }
  }
  
  private func startTimer() {
    timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
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
      projects = fetchedProjects
    }
    
    if let currentRecord = withLoadingSync({
      try timeRecordRepository.fetchCurrentTimeRecord()
    }) {
      currentTimeRecord = currentRecord
    }
    
    if errorMessage == nil {
      // プロジェクト行のViewModelを更新
      updateProjectRowViewModels()
      
      // メインコンテンツのデータも更新
      mainContentViewModel.refreshAllData()
    }
  }
  
  private func updateProjectRowViewModels() {
    projectRowViewModels = projects.map { project in
      let viewModel = ProjectRowViewModel(
        project: project,
        projectRepository: projectRepository,
        timeRecordRepository: timeRecordRepository
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
    projectRowViewModels.forEach { $0.updateActiveStatus() }
  }
  
  // MARK: - Project Management
  
  func showAddProject() {
    showingAddProject = true
  }
  
  func hideAddProject() {
    showingAddProject = false
  }
  
  private func handleProjectCreated(_ newProject: Project) {
    loadData() // データを再読み込み
    hideAddProject()
  }
  
  private func handleProjectDeleted(_ deletedProject: Project) {
    loadData() // データを再読み込み
  }
  
  private func handleTrackingStarted(for project: Project) {
    if let currentRecord = withLoadingSync({
      try timeRecordRepository.fetchCurrentTimeRecord()
    }) {
      currentTimeRecord = currentRecord
    }
    
    if errorMessage == nil {
      // 統計データも更新
      mainContentViewModel.refreshAllData()
    }
  }
  
  // MARK: - Time Tracking
  
  func stopTracking() {
    withLoadingSync {
      try timeRecordRepository.stopCurrentTimeRecord()
    }
    
    if errorMessage == nil {
      if let currentRecord = withLoadingSync({
        try timeRecordRepository.fetchCurrentTimeRecord()
      }) {
        currentTimeRecord = currentRecord
      }
      
      // データを更新
      mainContentViewModel.refreshAllData()
    }
  }
  
  // MARK: - Helper Methods
  
  func getCurrentProjectName() -> String {
    return currentTimeRecord?.displayProjectName ?? ""
  }
  
  func getCurrentProjectColor() -> String {
    return currentTimeRecord?.displayProjectColor ?? "blue"
  }
  
  func getCurrentDuration() -> TimeInterval {
    return currentTimeRecord?.duration ?? 0
  }
  
  func getCurrentStartTime() -> Date? {
    return currentTimeRecord?.startTime
  }
  
  func isTracking() -> Bool {
    return currentTimeRecord != nil
  }
}