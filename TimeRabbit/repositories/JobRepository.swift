//
//  JobRepository.swift
//  TimeRabbit
//
//  Created by Takumi Ikeda on 2025/09/30.
//

import Foundation
import SwiftData

// MARK: - Job Repository Protocol

protocol JobRepositoryProtocol {
    func fetchAllJobs() throws -> [Job]
    func initializePredefinedJobs() throws
    func getJobById(_ jobId: String) throws -> Job?
}

// MARK: - Job Repository Implementation

class JobRepository: JobRepositoryProtocol, ObservableObject {
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    func fetchAllJobs() throws -> [Job] {
        AppLogger.repository.debug("Fetching all jobs")
        let descriptor = FetchDescriptor<Job>(sortBy: [SortDescriptor(\.jobId)])

        do {
            let jobs = try modelContext.fetch(descriptor)
            AppLogger.repository.debug("Successfully fetched \(jobs.count) jobs")
            return jobs
        } catch let error as any Error {
            AppLogger.repository.error("Failed to fetch jobs: \(error)")
            throw error
        }
    }

    func initializePredefinedJobs() throws {
        AppLogger.repository.debug("Initializing predefined jobs")

        // 既存のJobをチェック
        let existingJobs = try fetchAllJobs()
        let existingJobIds = Set(existingJobs.map { $0.jobId })

        // 不足している固定Jobを作成
        for (jobId, name) in Job.predefinedJobs {
            if !existingJobIds.contains(jobId) {
                let job = Job(jobId: jobId, name: name)
                modelContext.insert(job)
                AppLogger.repository.debug("Created predefined job: \(jobId) - \(name)")
            }
        }

        do {
            try modelContext.save()
            AppLogger.repository.info("Successfully initialized predefined jobs")
        } catch let error as any Error {
            AppLogger.repository.error("Failed to save predefined jobs: \(error)")
            throw error
        }
    }

    func getJobById(_ jobId: String) throws -> Job? {
        AppLogger.repository.debug("Fetching job by ID: \(jobId)")
        let descriptor = FetchDescriptor<Job>(
            predicate: #Predicate<Job> { job in
                job.jobId == jobId
            }
        )

        do {
            let jobs = try modelContext.fetch(descriptor)
            let job = jobs.first
            AppLogger.repository.debug("Job found: \(job != nil)")
            return job
        } catch let error as any Error {
            AppLogger.repository.error("Failed to fetch job by ID: \(error)")
            throw error
        }
    }
}
