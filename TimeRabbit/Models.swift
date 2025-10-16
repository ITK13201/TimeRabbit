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
  var id: UUID // システム内部管理用の一意識別子
  var projectId: String // ユーザー編集可能な案件ID
  var name: String // 案件名
  var color: String
  var createdAt: Date

  @Relationship(deleteRule: .nullify, inverse: \TimeRecord.project)
  var timeRecords: [TimeRecord] = []

  init(projectId: String, name: String, color: String = "blue") {
    self.id = UUID()
    self.projectId = projectId
    self.name = name
    self.color = color
    self.createdAt = Date()
  }
}

@Model
final class Job {
  var id: UUID // システム内部管理用の一意識別子
  var jobId: String // 固定値: "001", "002", "003", "006", "999"
  var name: String // 固定値: 対応する作業区分名
  var createdAt: Date

  @Relationship(deleteRule: .nullify, inverse: \TimeRecord.job)
  var timeRecords: [TimeRecord] = []

  init(jobId: String, name: String) {
    self.id = UUID()
    self.jobId = jobId
    self.name = name
    self.createdAt = Date()
  }

  // 固定の作業区分一覧
  static let predefinedJobs = [
    ("001", "開発"),
    ("002", "保守"),
    ("003", "POサポート・コンサル"),
    ("006", "デザイン"),
    ("999", "その他"),
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
  var backupProjectId: String // Project.projectId のバックアップ
  var backupProjectName: String // Project.name のバックアップ
  var backupProjectColor: String // Project.color のバックアップ
  var backupJobId: String // Job.jobId のバックアップ
  var backupJobName: String // Job.name のバックアップ

  var duration: TimeInterval {
    let end = self.endTime ?? Date()
    return end.timeIntervalSince(self.startTime)
  }

  // Display properties
  var displayProjectId: String { self.project?.projectId ?? self.backupProjectId }
  var displayProjectName: String { self.project?.name ?? self.backupProjectName }
  var displayProjectColor: String { self.project?.color ?? self.backupProjectColor }
  var displayJobId: String { self.job?.jobId ?? self.backupJobId }
  var displayJobName: String { self.job?.name ?? self.backupJobName }

  init(startTime: Date, project: Project, job: Job) {
    self.id = UUID()
    self.startTime = startTime
    self.project = project
    self.job = job

    // Backup data
    self.backupProjectId = project.projectId
    self.backupProjectName = project.name
    self.backupProjectColor = project.color
    self.backupJobId = job.jobId
    self.backupJobName = job.name
  }
}
