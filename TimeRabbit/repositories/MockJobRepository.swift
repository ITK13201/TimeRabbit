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
        try? self.initializePredefinedJobs()
    }

    func fetchAllJobs() throws -> [Job] {
        return self.jobs.sorted { $0.jobId < $1.jobId }
    }

    func initializePredefinedJobs() throws {
        // 既存のJobをチェック
        let existingJobIds = Set(jobs.map { $0.jobId })

        // 不足している固定Jobを作成
        for (jobId, name) in Job.predefinedJobs {
            if !existingJobIds.contains(jobId) {
                let job = Job(jobId: jobId, name: name)
                self.jobs.append(job)
            }
        }
    }

    func getJobById(_ jobId: String) throws -> Job? {
        return self.jobs.first { $0.jobId == jobId }
    }
}
