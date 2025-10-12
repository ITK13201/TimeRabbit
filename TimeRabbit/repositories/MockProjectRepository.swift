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
            self.setupSampleProjects()
        }
    }

    private func setupSampleProjects() {
        let project1 = Project(projectId: "PROJ-001", name: "Webアプリ開発", color: "blue")
        let project2 = Project(projectId: "PROJ-002", name: "モバイルアプリ", color: "green")
        let project3 = Project(projectId: "PROJ-003", name: "デザイン作業", color: "purple")
        self.projects = [project1, project2, project3]
    }

    func fetchProjects() throws -> [Project] {
        return self.projects.sorted { $0.name < $1.name }
    }

    func createProject(projectId: String, name: String, color: String) throws -> Project {
        // Check ID uniqueness
        guard try self.isProjectIdUnique(projectId, excluding: nil) else {
            throw ProjectError.duplicateId
        }

        let project = Project(projectId: projectId, name: name, color: color)
        self.projects.append(project)
        return project
    }

    func updateProject(_ project: Project, projectId: String, name: String, color: String) throws {
        // Check ID uniqueness if ID is changing
        if project.projectId != projectId {
            guard try self.isProjectIdUnique(projectId, excluding: project) else {
                throw ProjectError.duplicateId
            }
        }

        project.projectId = projectId
        project.name = name
        project.color = color
    }

    func deleteProject(_ project: Project) throws {
        self.projects.removeAll { $0.id == project.id }
    }

    func isProjectIdUnique(_ projectId: String, excluding: Project?) throws -> Bool {
        let existingProjects = self.projects.filter { $0.projectId == projectId }

        if let excluding = excluding {
            // 編集時: 自分以外に同じIDがあるかチェック
            return existingProjects.allSatisfy { $0.projectId == excluding.projectId }
        } else {
            // 新規作成時: 同じIDが存在しないかチェック
            return existingProjects.isEmpty
        }
    }
}
