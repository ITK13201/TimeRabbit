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
  
  init(projects: [Project], withSampleData: Bool = false) {
    self.projects = projects
    if withSampleData {
      setupSampleTimeRecords()
    }
  }
  
  private func setupSampleTimeRecords() {
    guard projects.count >= 3 else { return }
    
    let calendar = Calendar.current
    let today = Date()
    let yesterday = calendar.date(byAdding: .day, value: -1, to: today)!
    
    // 今日の記録
    let record1 = TimeRecord(startTime: calendar.date(byAdding: .hour, value: -3, to: today)!, project: projects[0])
    record1.endTime = calendar.date(byAdding: .hour, value: -1, to: today)!
    
    let record2 = TimeRecord(startTime: calendar.date(byAdding: .minute, value: -30, to: today)!, project: projects[1])
    record2.endTime = calendar.date(byAdding: .minute, value: -10, to: today)!
    
    // 昨日の記録
    let record3 = TimeRecord(startTime: calendar.date(byAdding: .hour, value: -4, to: yesterday)!, project: projects[2])
    record3.endTime = calendar.date(byAdding: .hour, value: -2, to: yesterday)!
    
    // 現在実行中の記録
    let currentRecord = TimeRecord(startTime: calendar.date(byAdding: .minute, value: -5, to: today)!, project: projects[0])
    self.currentRecord = currentRecord
    
    timeRecords = [record1, record2, record3, currentRecord]
  }
  
  func startTimeRecord(for project: Project) throws -> TimeRecord {
    try stopCurrentTimeRecord()
    let record = TimeRecord(startTime: Date(), project: project)
    timeRecords.append(record)
    currentRecord = record
    return record
  }
  
  func stopCurrentTimeRecord() throws {
    currentRecord?.endTime = Date()
    currentRecord = nil
  }
  
  func fetchCurrentTimeRecord() throws -> TimeRecord? {
    return currentRecord
  }
  
  func fetchTimeRecords(for project: Project?, from startDate: Date, to endDate: Date) throws -> [TimeRecord] {
    return timeRecords.filter { record in
      let matchesProject = project == nil || record.project?.id == project?.id
      let inDateRange = record.startTime >= startDate && record.startTime <= endDate
      return matchesProject && inDateRange
    }.sorted { $0.startTime > $1.startTime }
  }
  
  func deleteTimeRecord(_ record: TimeRecord) throws {
    timeRecords.removeAll { $0.id == record.id }
    if currentRecord?.id == record.id {
      currentRecord = nil
    }
  }
  
  func updateTimeRecord(_ record: TimeRecord, startTime: Date, endTime: Date, project: Project) throws {
    guard try validateTimeRange(startTime: startTime, endTime: endTime, excludingRecord: record) else {
      throw TimeRecordError.invalidTimeRange
    }
    
    record.startTime = startTime
    record.endTime = endTime
    record.project = project
    record.projectName = project.name
    record.projectColor = project.color
  }
  
  func validateTimeRange(startTime: Date, endTime: Date, excludingRecord: TimeRecord? = nil) throws -> Bool {
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
    let overlappingRecords = timeRecords.filter { record in
      guard let recordEndTime = record.endTime else { return false }
      return record.startTime < endTime && recordEndTime > startTime
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