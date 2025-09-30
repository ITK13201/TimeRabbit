//
//  MockProjectRepository.swift
//  TimeRabbit
//
//  Created by Takumi Ikeda on 2025/08/09.
//

import Foundation
import SwiftData
import SwiftUI

// MARK: - Mock Project Repository

class MockProjectRepository: ProjectRepositoryProtocol {
  private var projects: [Project] = []
  
  init(withSampleData: Bool = false) {
    if withSampleData {
      setupSampleProjects()
    }
  }
  
  private func setupSampleProjects() {
    let project1 = Project(id: "PROJ-001", name: "Webアプリ開発", color: "blue")
    let project2 = Project(id: "PROJ-002", name: "モバイルアプリ", color: "green")
    let project3 = Project(id: "PROJ-003", name: "デザイン作業", color: "purple")
    projects = [project1, project2, project3]
  }
  
  func fetchProjects() throws -> [Project] {
    return projects.sorted { $0.name < $1.name }
  }
  
  func createProject(id: String, name: String, color: String) throws -> Project {
    // Check ID uniqueness
    guard try isProjectIdUnique(id, excluding: nil) else {
      throw ProjectError.duplicateId
    }
    
    let project = Project(id: id, name: name, color: color)
    projects.append(project)
    return project
  }
  
  func updateProject(_ project: Project, id: String, name: String, color: String) throws {
    // Check ID uniqueness if ID is changing
    if project.id != id {
      guard try isProjectIdUnique(id, excluding: project) else {
        throw ProjectError.duplicateId
      }
    }
    
    project.id = id
    project.name = name
    project.color = color
  }
  
  func deleteProject(_ project: Project) throws {
    projects.removeAll { $0.id == project.id }
  }
  
  func isProjectIdUnique(_ id: String, excluding: Project?) throws -> Bool {
    let existingProjects = projects.filter { $0.id == id }
    
    if let excluding = excluding {
      // 編集時: 自分以外に同じIDがあるかチェック
      return existingProjects.allSatisfy { $0.id == excluding.id }
    } else {
      // 新規作成時: 同じIDが存在しないかチェック
      return existingProjects.isEmpty
    }
  }
}