//
//  TimeRecordRepository.swift
//  TimeRabbit
//
//  Created by Takumi Ikeda on 2025/08/09.
//

import Foundation
import SwiftData
import SwiftUI

// MARK: - Time Record Repository Protocol

protocol TimeRecordRepositoryProtocol {
  func startTimeRecord(for project: Project, job: Job) throws -> TimeRecord
  func stopCurrentTimeRecord() throws
  func fetchCurrentTimeRecord() throws -> TimeRecord?
  func fetchTimeRecords(for project: Project?, from startDate: Date, to endDate: Date) throws -> [TimeRecord]
  func deleteTimeRecord(_ record: TimeRecord) throws
  func updateTimeRecord(_ record: TimeRecord, startTime: Date, endTime: Date, project: Project, job: Job) throws
  func validateTimeRange(startTime: Date, endTime: Date, excludingRecord: TimeRecord?) throws -> Bool
}

// MARK: - Time Record Repository Implementation

class TimeRecordRepository: TimeRecordRepositoryProtocol, ObservableObject {
  private let modelContext: ModelContext

  init(modelContext: ModelContext) {
    self.modelContext = modelContext
  }

  @discardableResult
  func startTimeRecord(for project: Project, job: Job) throws -> TimeRecord {
    AppLogger.repository.debug("Starting time record for project: \(project.id), job: \(job.id)")
    
    // Stop any current recording
    try stopCurrentTimeRecord()

    let record = TimeRecord(startTime: Date(), project: project, job: job)
    modelContext.insert(record)
    do {
      try modelContext.save()
      AppLogger.repository.info("Successfully started time record for project: \(project.id), job: \(job.id)")
    } catch {
      AppLogger.repository.error("Failed to start time record: \(error)")
      if let swiftDataError = error as? SwiftDataError {
        AppLogger.swiftData.error("SwiftDataError in startTimeRecord: \(swiftDataError)")
      }
      throw error
    }
    return record
  }

  func stopCurrentTimeRecord() throws {
    guard let currentRecord = try fetchCurrentTimeRecord() else { return }
    currentRecord.endTime = Date()
    do {
      try modelContext.save()
    } catch {
      AppLogger.repository.error("Failed to stop time record: \(error)")
      if let swiftDataError = error as? SwiftDataError {
        AppLogger.swiftData.error("SwiftDataError in stopCurrentTimeRecord: \(swiftDataError)")
      }
      throw error
    }
  }

  func fetchCurrentTimeRecord() throws -> TimeRecord? {
    let descriptor = FetchDescriptor<TimeRecord>(
      predicate: #Predicate<TimeRecord> { $0.endTime == nil },
      sortBy: [SortDescriptor(\.startTime, order: .reverse)]
    )
    return try modelContext.fetch(descriptor).first
  }

  func fetchTimeRecords(for project: Project? = nil, from startDate: Date, to endDate: Date) throws -> [TimeRecord] {
    let descriptor: FetchDescriptor<TimeRecord>

    if let project = project {
      let projectId = project.id
      descriptor = FetchDescriptor<TimeRecord>(
        predicate: #Predicate<TimeRecord> { record in
          record.projectId == projectId && record.startTime >= startDate && record.startTime <= endDate
        },
        sortBy: [SortDescriptor(\.startTime, order: .reverse)]
      )
    } else {
      descriptor = FetchDescriptor<TimeRecord>(
        predicate: #Predicate<TimeRecord> { record in
          record.startTime >= startDate && record.startTime <= endDate
        },
        sortBy: [SortDescriptor(\.startTime, order: .reverse)]
      )
    }

    return try modelContext.fetch(descriptor)
  }

  func deleteTimeRecord(_ record: TimeRecord) throws {
    modelContext.delete(record)
    do {
      try modelContext.save()
    } catch {
      AppLogger.repository.error("Failed to delete time record: \(error)")
      if let swiftDataError = error as? SwiftDataError {
        AppLogger.swiftData.error("SwiftDataError in deleteTimeRecord: \(swiftDataError)")
      }
      throw error
    }
  }
  
  func updateTimeRecord(_ record: TimeRecord, startTime: Date, endTime: Date, project: Project, job: Job) throws {
    AppLogger.repository.debug("updateTimeRecord started")
    AppLogger.repository.debug("Original record ID: \(record.id)")
    AppLogger.repository.debug("Original record project: \(record.project?.name ?? "nil")")
    AppLogger.repository.debug("Original record job: \(record.job?.name ?? "nil")")
    AppLogger.repository.debug("New project: \(project.name)")
    AppLogger.repository.debug("New job: \(job.name)")
    AppLogger.repository.debug("New startTime: \(startTime)")
    AppLogger.repository.debug("New endTime: \(endTime)")
    
    guard try validateTimeRange(startTime: startTime, endTime: endTime, excludingRecord: record) else {
      AppLogger.repository.warning("Validation failed for time range")
      throw TimeRecordError.invalidTimeRange
    }
    AppLogger.repository.debug("Time range validation passed")
    
    // 保存前の状態をログ
    AppLogger.repository.debug("Before update - record.startTime: \(record.startTime)")
    AppLogger.repository.debug("Before update - record.endTime: \(record.endTime ?? Date())")
    AppLogger.repository.debug("Before update - record.project: \(record.project?.name ?? "nil")")
    AppLogger.repository.debug("Before update - record.job: \(record.job?.name ?? "nil")")
    
    record.startTime = startTime
    record.endTime = endTime
    record.project = project
    record.job = job
    record.projectId = project.id
    record.projectName = project.name
    record.projectColor = project.color
    record.jobId = job.id
    record.jobName = job.name
    
    // 保存後の状態をログ
    AppLogger.repository.debug("After update - record.startTime: \(record.startTime)")
    AppLogger.repository.debug("After update - record.endTime: \(record.endTime ?? Date())")
    AppLogger.repository.debug("After update - record.project: \(record.project?.name ?? "nil")")
    AppLogger.repository.debug("After update - record.job: \(record.job?.name ?? "nil")")
    AppLogger.swiftData.debug("About to save to ModelContext")
    
    do {
      try modelContext.save()
      AppLogger.swiftData.info("ModelContext.save() completed successfully")
    } catch {
      AppLogger.swiftData.critical("ModelContext.save() failed")
      AppLogger.swiftData.error("Error: \(error)")
      AppLogger.swiftData.error("Error localizedDescription: \(error.localizedDescription)")
      if let swiftDataError = error as? SwiftDataError {
        AppLogger.swiftData.error("SwiftDataError: \(swiftDataError)")
        AppLogger.swiftData.error("SwiftDataError description: \(swiftDataError.localizedDescription)")
      }
      if let nsError = error as NSError? {
        AppLogger.swiftData.error("NSError domain: \(nsError.domain)")
        AppLogger.swiftData.error("NSError code: \(nsError.code)")
        AppLogger.swiftData.error("NSError userInfo: \(nsError.userInfo)")
      }
      throw error
    }
    AppLogger.repository.debug("updateTimeRecord completed")
  }
  
  func validateTimeRange(startTime: Date, endTime: Date, excludingRecord: TimeRecord? = nil) throws -> Bool {
    AppLogger.repository.debug("validateTimeRange started")
    AppLogger.repository.debug("Validating startTime: \(startTime), endTime: \(endTime)")
    AppLogger.repository.debug("Excluding record ID: \(excludingRecord?.id.description ?? "none")")
    
    // 基本的なバリデーション
    guard startTime < endTime else {
      AppLogger.repository.warning("VALIDATION FAILED: startTime >= endTime")
      throw TimeRecordError.startTimeAfterEndTime
    }
    AppLogger.repository.debug("✓ Basic time order validation passed")
    
    guard endTime <= Date() else {
      AppLogger.repository.warning("VALIDATION FAILED: endTime is in future")
      throw TimeRecordError.futureTime
    }
    AppLogger.repository.debug("✓ Future time validation passed")
    
    let duration = endTime.timeIntervalSince(startTime)
    guard duration >= 60 else { // 最小1分
      AppLogger.repository.warning("VALIDATION FAILED: duration too short (\(duration) seconds)")
      throw TimeRecordError.tooShort
    }
    AppLogger.repository.debug("✓ Minimum duration validation passed (\(Int(duration)) seconds)")
    
    guard duration <= 86400 else { // 最大24時間
      AppLogger.repository.warning("VALIDATION FAILED: duration too long (\(Int(duration)) seconds)")
      throw TimeRecordError.tooLong
    }
    AppLogger.repository.debug("✓ Maximum duration validation passed")
    
    // 重複チェック
    AppLogger.repository.debug("Starting overlap check...")
    
    // SwiftDataのPredicateでForcedUnwrapを使わずに重複チェックを実施
    // 完了済みレコードのみを取得
    let completedRecordsDescriptor = FetchDescriptor<TimeRecord>(
      predicate: #Predicate<TimeRecord> { record in
        record.endTime != nil
      }
    )
    
    let allCompletedRecords: [TimeRecord]
    do {
      allCompletedRecords = try modelContext.fetch(completedRecordsDescriptor)
      AppLogger.database.debug("Successfully fetched \(allCompletedRecords.count) completed records")
    } catch {
      AppLogger.database.critical("Failed to fetch completed records")
      AppLogger.database.error("Error during fetch: \(error)")
      if let nsError = error as NSError? {
        AppLogger.database.error("NSError domain: \(nsError.domain)")
        AppLogger.database.error("NSError code: \(nsError.code)")
        AppLogger.database.error("NSError userInfo: \(nsError.userInfo)")
      }
      throw error
    }
    
    // メモリ内で重複チェックを実施
    let overlappingRecords = allCompletedRecords.filter { record in
      guard let recordEndTime = record.endTime else { return false }
      return record.startTime < endTime && recordEndTime > startTime
    }
    
    AppLogger.repository.debug("Found \(overlappingRecords.count) potentially overlapping records")
    
    // 編集中のレコードを除外
    let filteredRecords = overlappingRecords.filter { record in
      excludingRecord == nil || record.id != excludingRecord!.id
    }
    AppLogger.repository.debug("After filtering, found \(filteredRecords.count) overlapping records")
    
    if !filteredRecords.isEmpty {
      AppLogger.repository.warning("VALIDATION FAILED: Found overlapping records:")
      for record in filteredRecords {
        AppLogger.repository.warning("  - Record ID: \(record.id)")
        AppLogger.repository.warning("    Start: \(record.startTime)")
        AppLogger.repository.warning("    End: \(record.endTime?.description ?? "nil")")
      }
    }
    
    guard filteredRecords.isEmpty else {
      throw TimeRecordError.overlappingTime
    }
    
    AppLogger.repository.debug("✓ All validations passed successfully")
    AppLogger.repository.debug("validateTimeRange completed")
    return true
  }
}

// MARK: - Time Record Errors

enum TimeRecordError: LocalizedError {
  case invalidTimeRange
  case startTimeAfterEndTime
  case futureTime
  case tooShort
  case tooLong
  case overlappingTime
  
  var errorDescription: String? {
    switch self {
    case .invalidTimeRange:
      return "無効な時間範囲です"
    case .startTimeAfterEndTime:
      return "開始時間が終了時間より後です"
    case .futureTime:
      return "未来の時間は設定できません"
    case .tooShort:
      return "作業時間は最低1分以上である必要があります"
    case .tooLong:
      return "作業時間は24時間以内である必要があります"
    case .overlappingTime:
      return "他のレコードと時間が重複しています"
    }
  }
}