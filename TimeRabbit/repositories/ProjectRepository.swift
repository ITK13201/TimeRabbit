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
  func createProject(name: String, color: String) throws -> Project
  func updateProject(_ project: Project, name: String, color: String) throws
  func deleteProject(_ project: Project) throws
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
  func createProject(name: String, color: String = "blue") throws -> Project {
    let project = Project(name: name, color: color)
    modelContext.insert(project)
    do {
      try modelContext.save()
    } catch {
      AppLogger.repository.error("Failed to save project: \(error)")
      if let swiftDataError = error as? SwiftDataError {
        AppLogger.swiftData.error("SwiftDataError in saveProject: \(swiftDataError)")
      }
      throw error
    }
    return project
  }

  func updateProject(_ project: Project, name: String, color: String) throws {
    let oldName = project.name
    let oldColor = project.color

    project.name = name
    project.color = color

    // 関連するTimeRecordの保存された情報も更新
    let records = try fetchTimeRecordsForProject(project)
    for record in records {
      if record.projectName == oldName && record.projectColor == oldColor {
        record.projectName = name
        record.projectColor = color
      }
    }

    do {
      try modelContext.save()
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

  // プロジェクトに関連するTimeRecordを取得するヘルパーメソッド
  private func fetchTimeRecordsForProject(_ project: Project) throws -> [TimeRecord] {
    let projectId = project.id
    let descriptor = FetchDescriptor<TimeRecord>(
      predicate: #Predicate<TimeRecord> { record in
        record.project?.id == projectId
      }
    )
    return try modelContext.fetch(descriptor)
  }
}