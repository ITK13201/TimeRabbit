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
  var id: String           // ユーザー編集可能な案件ID
  var name: String         // 案件名
  var color: String
  var createdAt: Date

  @Relationship(deleteRule: .nullify, inverse: \TimeRecord.project)
  var timeRecords: [TimeRecord] = []

  init(id: String, name: String, color: String = "blue") {
    self.id = id
    self.name = name
    self.color = color
    self.createdAt = Date()
  }
}

@Model
final class Job {
  var id: String           // 固定値: "001", "002", "003", "006", "999"
  var name: String         // 固定値: 対応する作業区分名
  var createdAt: Date
  
  @Relationship(deleteRule: .nullify, inverse: \TimeRecord.job)
  var timeRecords: [TimeRecord] = []
  
  init(id: String, name: String) {
    self.id = id
    self.name = name
    self.createdAt = Date()
  }
  
  // 固定の作業区分一覧
  static let predefinedJobs = [
    ("001", "開発"),
    ("002", "保守"),
    ("003", "POサポート・コンサル"),
    ("006", "デザイン"),
    ("999", "その他")
  ]
}

@Model
final class TimeRecord {
  var id: UUID
  var startTime: Date
  var endTime: Date?
  
  // Primary relationships
  var project: Project?
  var job: Job?
  
  // Backup data for deleted entities
  var projectId: String        // Project.id のバックアップ
  var projectName: String      // Project.name のバックアップ
  var projectColor: String     // Project.color のバックアップ
  var jobId: String           // Job.id のバックアップ
  var jobName: String         // Job.name のバックアップ
  
  var duration: TimeInterval {
    let end = endTime ?? Date()
    return end.timeIntervalSince(startTime)
  }
  
  // Display properties
  var displayProjectId: String { project?.id ?? projectId }
  var displayProjectName: String { project?.name ?? projectName }
  var displayProjectColor: String { project?.color ?? projectColor }
  var displayJobId: String { job?.id ?? jobId }
  var displayJobName: String { job?.name ?? jobName }

  init(startTime: Date, project: Project, job: Job) {
    self.id = UUID()
    self.startTime = startTime
    self.project = project
    self.job = job
    
    // Backup data
    self.projectId = project.id
    self.projectName = project.name
    self.projectColor = project.color
    self.jobId = job.id
    self.jobName = job.name
  }
}
