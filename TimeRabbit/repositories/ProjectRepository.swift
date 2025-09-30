//
//  ProjectRepository.swift
//  TimeRabbit
//
//  Created by Takumi Ikeda on 2025/08/09.
//

import Foundation
import SwiftData
import SwiftUI

// MARK: - Project Repository Protocol

protocol ProjectRepositoryProtocol {
  func fetchProjects() throws -> [Project]
  func createProject(id: String, name: String, color: String) throws -> Project
  func updateProject(_ project: Project, id: String, name: String, color: String) throws
  func deleteProject(_ project: Project) throws
  func isProjectIdUnique(_ id: String, excluding: Project?) throws -> Bool
}

// MARK: - Project Repository Implementation

class ProjectRepository: ProjectRepositoryProtocol, ObservableObject {
  private let modelContext: ModelContext

  init(modelContext: ModelContext) {
    self.modelContext = modelContext
  }

  func fetchProjects() throws -> [Project] {
    let descriptor = FetchDescriptor<Project>(sortBy: [SortDescriptor(\.name)])
    return try modelContext.fetch(descriptor)
  }

  @discardableResult
  func createProject(id: String, name: String, color: String = "blue") throws -> Project {
    AppLogger.repository.debug("Creating project with ID: \(id), name: \(name)")
    
    // Check ID uniqueness
    guard try isProjectIdUnique(id, excluding: nil) else {
      AppLogger.repository.error("Project ID \(id) already exists")
      throw ProjectError.duplicateId
    }
    
    let project = Project(id: id, name: name, color: color)
    modelContext.insert(project)
    do {
      try modelContext.save()
      AppLogger.repository.info("Successfully created project: \(id)")
    } catch {
      AppLogger.repository.error("Failed to save project: \(error)")
      if let swiftDataError = error as? SwiftDataError {
        AppLogger.swiftData.error("SwiftDataError in saveProject: \(swiftDataError)")
      }
      throw error
    }
    return project
  }

  func updateProject(_ project: Project, id: String, name: String, color: String) throws {
    AppLogger.repository.debug("Updating project: \(project.id) -> \(id)")
    
    // Check ID uniqueness if ID is changing
    if project.id != id {
      guard try isProjectIdUnique(id, excluding: project) else {
        AppLogger.repository.error("Project ID \(id) already exists")
        throw ProjectError.duplicateId
      }
    }
    
    let oldId = project.id
    let oldName = project.name
    let oldColor = project.color

    project.id = id
    project.name = name
    project.color = color

    // 関連するTimeRecordの保存された情報も更新
    let records = try fetchTimeRecordsForProject(oldId)
    for record in records {
      if record.projectId == oldId {
        record.projectId = id
        record.projectName = name
        record.projectColor = color
      }
    }

    do {
      try modelContext.save()
      AppLogger.repository.info("Successfully updated project: \(id)")
    } catch {
      AppLogger.repository.error("Failed to update project: \(error)")
      if let swiftDataError = error as? SwiftDataError {
        AppLogger.swiftData.error("SwiftDataError in updateProject: \(swiftDataError)")
      }
      throw error
    }
  }

  func deleteProject(_ project: Project) throws {
    modelContext.delete(project)
    do {
      try modelContext.save()
    } catch {
      AppLogger.repository.error("Failed to delete project: \(error)")
      if let swiftDataError = error as? SwiftDataError {
        AppLogger.swiftData.error("SwiftDataError in deleteProject: \(swiftDataError)")
      }
      throw error
    }
  }

  func isProjectIdUnique(_ id: String, excluding: Project?) throws -> Bool {
    AppLogger.repository.debug("Checking uniqueness for project ID: \(id)")
    
    let descriptor = FetchDescriptor<Project>(
      predicate: #Predicate<Project> { project in
        project.id == id
      }
    )
    
    let existingProjects = try modelContext.fetch(descriptor)
    
    if let excluding = excluding {
      // 編集時: 自分以外に同じIDがあるかチェック
      let isUnique = existingProjects.allSatisfy { $0.id == excluding.id }
      AppLogger.repository.debug("ID uniqueness check result: \(isUnique)")
      return isUnique
    } else {
      // 新規作成時: 同じIDが存在しないかチェック
      let isUnique = existingProjects.isEmpty
      AppLogger.repository.debug("ID uniqueness check result: \(isUnique)")
      return isUnique
    }
  }
  
  // プロジェクトに関連するTimeRecordを取得するヘルパーメソッド
  private func fetchTimeRecordsForProject(_ projectId: String) throws -> [TimeRecord] {
    let descriptor = FetchDescriptor<TimeRecord>(
      predicate: #Predicate<TimeRecord> { record in
        record.projectId == projectId
      }
    )
    return try modelContext.fetch(descriptor)
  }
}

// MARK: - Project Errors

enum ProjectError: Error {
  case duplicateId
  case invalidId
  
  var localizedDescription: String {
    switch self {
    case .duplicateId:
      return "指定された案件IDは既に使用されています"
    case .invalidId:
      return "案件IDが無効です"
    }
  }
}