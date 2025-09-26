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
    let project1 = Project(name: "Webアプリ開発", color: "blue")
    let project2 = Project(name: "モバイルアプリ", color: "green")
    let project3 = Project(name: "デザイン作業", color: "purple")
    projects = [project1, project2, project3]
  }
  
  func fetchProjects() throws -> [Project] {
    return projects.sorted { $0.name < $1.name }
  }
  
  func createProject(name: String, color: String) throws -> Project {
    let project = Project(name: name, color: color)
    projects.append(project)
    return project
  }
  
  func updateProject(_ project: Project, name: String, color: String) throws {
    project.name = name
    project.color = color
  }
  
  func deleteProject(_ project: Project) throws {
    projects.removeAll { $0.id == project.id }
  }
}