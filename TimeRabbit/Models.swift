//
//  Models.swift
//  TimeRabbit
//
//  Created by Takumi Ikeda on 2025/07/29.
//

import SwiftData
import SwiftUI

// MARK: - Models

@Model
final class Project {
  var id: UUID
  var name: String
  var color: String
  var createdAt: Date

  @Relationship(deleteRule: .nullify, inverse: \TimeRecord.project)
  var timeRecords: [TimeRecord] = []

  init(name: String, color: String = "blue") {
    self.id = UUID()
    self.name = name
    self.color = color
    self.createdAt = Date()
  }
}

@Model
final class TimeRecord {
  var id: UUID
  var startTime: Date
  var endTime: Date?
  var project: Project?

  // プロジェクトが削除された場合に備えて、プロジェクト情報を保持
  var projectName: String
  var projectColor: String

  var duration: TimeInterval {
    let end = endTime ?? Date()
    return end.timeIntervalSince(startTime)
  }

  // 表示用のプロジェクト名（削除されたプロジェクトも考慮）
  var displayProjectName: String {
    return project?.name ?? projectName
  }

  // 表示用のプロジェクト色（削除されたプロジェクトも考慮）
  var displayProjectColor: String {
    return project?.color ?? projectColor
  }

  init(startTime: Date, project: Project) {
    self.id = UUID()
    self.startTime = startTime
    self.project = project
    self.projectName = project.name
    self.projectColor = project.color
  }
}
