//
//  AddProjectViewModel.swift
//  TimeRabbit
//
//  Created by Takumi Ikeda on 2025/08/09.
//

import Combine
import Foundation
import SwiftUI

@MainActor
class AddProjectViewModel: BaseViewModel {
  // MARK: - Published Properties

  @Published var projectId = "" {
    didSet {
      self.validateProjectId(self.projectId)
    }
  }

  @Published var projectName = ""
  @Published var selectedColor = "blue"
  @Published var idValidationMessage = ""
  @Published var isIdValid = true

  // MARK: - Constants

  let availableColors = ["blue", "green", "red", "orange", "purple", "pink", "yellow"]

  // MARK: - Dependencies

  private let projectRepository: ProjectRepositoryProtocol

  // MARK: - Callbacks

  var onProjectCreated: ((Project) -> Void)?
  var onCancel: (() -> Void)?

  // MARK: - Computed Properties

  var isFormValid: Bool {
    let trimmedId = self.projectId.trimmingCharacters(in: .whitespacesAndNewlines)
    let trimmedName = self.projectName.trimmingCharacters(in: .whitespacesAndNewlines)
    return !trimmedId.isEmpty && !trimmedName.isEmpty && self.isIdValid
  }

  // MARK: - Initialization

  init(projectRepository: ProjectRepositoryProtocol) {
    self.projectRepository = projectRepository
    super.init()
  }

  // MARK: - Actions

  func createProject() {
    guard self.isFormValid else { return }

    let trimmedId = self.projectId.trimmingCharacters(in: .whitespacesAndNewlines)
    let trimmedName = self.projectName.trimmingCharacters(in: .whitespacesAndNewlines)

    // 最終的なID重複チェック
    do {
      guard try self.projectRepository.isProjectIdUnique(trimmedId, excluding: nil) else {
        handleError(ProjectError.duplicateId)
        return
      }
    } catch {
      handleError(error)
      return
    }

    if let newProject = withLoadingSync({
      try projectRepository.createProject(projectId: trimmedId, name: trimmedName, color: selectedColor)
    }) {
      // フォームをリセット
      self.resetForm()

      // コールバックを呼び出し
      self.onProjectCreated?(newProject)
    }
  }

  func cancel() {
    self.resetForm()
    clearError()
    self.onCancel?()
  }

  func resetForm() {
    self.projectId = ""
    self.projectName = ""
    self.selectedColor = "blue"
    self.idValidationMessage = ""
    self.isIdValid = true
  }

  // MARK: - Color Management

  func selectColor(_ color: String) {
    self.selectedColor = color
  }

  func isColorSelected(_ color: String) -> Bool {
    return self.selectedColor == color
  }

  // MARK: - ID Validation

  func validateProjectId(_ id: String) {
    let trimmedId = id.trimmingCharacters(in: .whitespacesAndNewlines)

    // 基本的なバリデーション
    guard !trimmedId.isEmpty else {
      self.idValidationMessage = ""
      self.isIdValid = true
      return
    }

    // 文字数チェック（例: 3-20文字）
    guard trimmedId.count >= 3, trimmedId.count <= 20 else {
      self.idValidationMessage = "案件IDは3〜20文字で入力してください"
      self.isIdValid = false
      return
    }

    // 文字種チェック（英数字とハイフンのみ）
    let allowedCharacters = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "-"))
    guard trimmedId.unicodeScalars.allSatisfy({ allowedCharacters.contains($0) }) else {
      self.idValidationMessage = "案件IDは英数字とハイフン(-)のみ使用できます"
      self.isIdValid = false
      return
    }

    // 重複チェック
    do {
      let isUnique = try projectRepository.isProjectIdUnique(trimmedId, excluding: nil)
      if !isUnique {
        self.idValidationMessage = "この案件IDは既に使用されています"
        self.isIdValid = false
      } else {
        self.idValidationMessage = ""
        self.isIdValid = true
      }
    } catch {
      self.idValidationMessage = "ID確認中にエラーが発生しました"
      self.isIdValid = false
    }
  }
}
