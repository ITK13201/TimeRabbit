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
        id = UUID()
        self.projectId = projectId
        self.name = name
        self.color = color
        createdAt = Date()
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
        id = UUID()
        self.jobId = jobId
        self.name = name
        createdAt = Date()
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
        let end = endTime ?? Date()
        return end.timeIntervalSince(startTime)
    }

    // Display properties
    var displayProjectId: String { project?.projectId ?? backupProjectId }
    var displayProjectName: String { project?.name ?? backupProjectName }
    var displayProjectColor: String { project?.color ?? backupProjectColor }
    var displayJobId: String { job?.jobId ?? backupJobId }
    var displayJobName: String { job?.name ?? backupJobName }

    init(startTime: Date, project: Project, job: Job) {
        id = UUID()
        self.startTime = startTime
        self.project = project
        self.job = job

        // Backup data
        backupProjectId = project.projectId
        backupProjectName = project.name
        backupProjectColor = project.color
        backupJobId = job.jobId
        backupJobName = job.name
    }
}
