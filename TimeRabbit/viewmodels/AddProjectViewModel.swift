//
//  AddProjectViewModel.swift
//  TimeRabbit
//
//  Created by Takumi Ikeda on 2025/08/09.
//

import Foundation
import SwiftUI
import Combine

@MainActor
class AddProjectViewModel: BaseViewModel {
  // MARK: - Published Properties
  
  @Published var projectName = ""
  @Published var selectedColor = "blue"
  
  // MARK: - Constants
  
  let availableColors = ["blue", "green", "red", "orange", "purple", "pink", "yellow"]
  
  // MARK: - Dependencies
  
  private let projectRepository: ProjectRepositoryProtocol
  
  // MARK: - Callbacks
  
  var onProjectCreated: ((Project) -> Void)?
  var onCancel: (() -> Void)?
  
  // MARK: - Computed Properties
  
  var isFormValid: Bool {
    !projectName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
  }
  
  // MARK: - Initialization
  
  init(projectRepository: ProjectRepositoryProtocol) {
    self.projectRepository = projectRepository
    super.init()
  }
  
  // MARK: - Actions
  
  func createProject() {
    guard isFormValid else { return }
    
    let trimmedName = projectName.trimmingCharacters(in: .whitespacesAndNewlines)
    
    if let newProject = withLoadingSync({
      try projectRepository.createProject(name: trimmedName, color: selectedColor)
    }) {
      // フォームをリセット
      resetForm()
      
      // コールバックを呼び出し
      onProjectCreated?(newProject)
    }
  }
  
  func cancel() {
    resetForm()
    clearError()
    onCancel?()
  }
  
  func resetForm() {
    projectName = ""
    selectedColor = "blue"
  }
  
  // MARK: - Color Management
  
  func selectColor(_ color: String) {
    selectedColor = color
  }
  
  func isColorSelected(_ color: String) -> Bool {
    return selectedColor == color
  }
}