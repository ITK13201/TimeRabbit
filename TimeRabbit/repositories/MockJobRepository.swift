//
//  MockJobRepository.swift
//  TimeRabbit
//
//  Created by Takumi Ikeda on 2025/09/30.
//

import Foundation
import SwiftUI

// MARK: - Mock Job Repository

class MockJobRepository: JobRepositoryProtocol, ObservableObject {
  @Published private var jobs: [Job] = []
  
  init() {
    // 固定の作業区分で初期化
    try? initializePredefinedJobs()
  }
  
  func fetchAllJobs() throws -> [Job] {
    return jobs.sorted { $0.id < $1.id }
  }
  
  func initializePredefinedJobs() throws {
    // 既存のJobをチェック
    let existingJobIds = Set(jobs.map { $0.id })
    
    // 不足している固定Jobを作成
    for (id, name) in Job.predefinedJobs {
      if !existingJobIds.contains(id) {
        let job = Job(id: id, name: name)
        jobs.append(job)
      }
    }
  }
  
  func getJobById(_ id: String) throws -> Job? {
    return jobs.first { $0.id == id }
  }
}