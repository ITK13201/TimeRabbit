//
//  MockTimeRecordRepository.swift
//  TimeRabbit
//
//  Created by Takumi Ikeda on 2025/08/09.
//

import Foundation
import SwiftData
import SwiftUI

// MARK: - Mock Time Record Repository

class MockTimeRecordRepository: TimeRecordRepositoryProtocol {
  private var timeRecords: [TimeRecord] = []
  private var currentRecord: TimeRecord?
  private let projects: [Project]
  private let jobs: [Job]

  init(projects: [Project], withSampleData: Bool = false) {
    self.projects = projects
    // 固定Jobを初期化
    self.jobs = Job.predefinedJobs.map { Job(jobId: $0.0, name: $0.1) }
    if withSampleData {
      self.setupSampleTimeRecords()
    }
  }

  private func setupSampleTimeRecords() {
    guard self.projects.count >= 3, self.jobs.count >= 3 else { return }

    let calendar = Calendar.current
    let today = Date()
    let yesterday = calendar.date(byAdding: .day, value: -1, to: today)!

    // 今日の記録
    let record1 = TimeRecord(startTime: calendar.date(byAdding: .hour, value: -3, to: today)!, project: self.projects[0], job: self.jobs[0]) // 開発
    record1.endTime = calendar.date(byAdding: .hour, value: -1, to: today)!

    let record2 = TimeRecord(startTime: calendar.date(byAdding: .minute, value: -30, to: today)!, project: self.projects[1], job: self.jobs[1]) // 保守
    record2.endTime = calendar.date(byAdding: .minute, value: -10, to: today)!

    // 昨日の記録
    let record3 = TimeRecord(startTime: calendar.date(byAdding: .hour, value: -4, to: yesterday)!, project: self.projects[2], job: self.jobs[3]) // デザイン
    record3.endTime = calendar.date(byAdding: .hour, value: -2, to: yesterday)!

    // 現在実行中の記録
    let currentRecord = TimeRecord(startTime: calendar.date(byAdding: .minute, value: -5, to: today)!, project: self.projects[0], job: self.jobs[0])
    self.currentRecord = currentRecord

    self.timeRecords = [record1, record2, record3, currentRecord]
  }

  func startTimeRecord(for project: Project, job: Job) throws -> TimeRecord {
    try self.stopCurrentTimeRecord()
    let record = TimeRecord(startTime: Date(), project: project, job: job)
    self.timeRecords.append(record)
    self.currentRecord = record
    return record
  }

  func stopCurrentTimeRecord() throws {
    self.currentRecord?.endTime = Date()
    self.currentRecord = nil
  }

  func fetchCurrentTimeRecord() throws -> TimeRecord? {
    return self.currentRecord
  }

  func fetchTimeRecords(for project: Project?, from startDate: Date, to endDate: Date) throws -> [TimeRecord] {
    return self.timeRecords.filter { record in
      let matchesProject = project == nil || record.backupProjectId == project?.projectId
      let inDateRange = record.startTime >= startDate && record.startTime <= endDate
      return matchesProject && inDateRange
    }.sorted { $0.startTime > $1.startTime }
  }

  func deleteTimeRecord(_ record: TimeRecord) throws {
    self.timeRecords.removeAll { $0.id == record.id }
    if self.currentRecord?.id == record.id {
      self.currentRecord = nil
    }
  }

  func updateTimeRecord(_ record: TimeRecord, startTime: Date, endTime: Date?, project: Project, job: Job) throws {
    guard try self.validateTimeRange(startTime: startTime, endTime: endTime, excludingRecord: record) else {
      throw TimeRecordError.invalidTimeRange
    }

    record.startTime = startTime
    record.endTime = endTime
    record.project = project
    record.job = job
    record.backupProjectId = project.projectId
    record.backupProjectName = project.name
    record.backupProjectColor = project.color
    record.backupJobId = job.jobId
    record.backupJobName = job.name
  }

  func validateTimeRange(startTime: Date, endTime: Date?, excludingRecord: TimeRecord? = nil) throws -> Bool {
    // 作業中レコード（endTime == nil）の場合は開始時間のみチェック
    guard let endTime = endTime else {
      guard startTime <= Date() else {
        throw TimeRecordError.futureTime
      }
      return true
    }

    // 完了済みレコードの場合は既存のバリデーション
    // 基本的なバリデーション
    guard startTime < endTime else {
      throw TimeRecordError.startTimeAfterEndTime
    }

    guard endTime <= Date() else {
      throw TimeRecordError.futureTime
    }

    let duration = endTime.timeIntervalSince(startTime)
    guard duration >= 60 else { // 最小1分
      throw TimeRecordError.tooShort
    }

    guard duration <= 86400 else { // 最大24時間
      throw TimeRecordError.tooLong
    }

    // 重複チェック
    // 60秒以内の接触は許容し、完全に重複している場合のみエラーとする
    let overlappingRecords = self.timeRecords.filter { record in
      guard let recordEndTime = record.endTime else { return false }

      // 新しいレコードが既存レコードの後に続く場合（既存の終了時刻 <= 新規の開始時刻）
      if startTime >= recordEndTime {
        // 60秒以上離れている場合は重複ではない（false）
        // 60秒未満の場合は重複とみなさない（false）
        return false
      }

      // 新しいレコードが既存レコードの前に来る場合（新規の終了時刻 <= 既存の開始時刻）
      if endTime <= record.startTime {
        // 60秒以上離れている場合は重複ではない（false）
        // 60秒未満の場合は重複とみなさない（false）
        return false
      }

      // それ以外は真の重複なのでエラー（true）
      return true
    }

    // 編集中のレコードを除外
    let filteredRecords = overlappingRecords.filter { record in
      excludingRecord == nil || record.id != excludingRecord!.id
    }

    guard filteredRecords.isEmpty else {
      throw TimeRecordError.overlappingTime
    }

    return true
  }
}
