//
//  EditHistoryViewModel.swift
//  TimeRabbit
//
//  Created by Takumi Ikeda on 2025/08/09.
//

import Combine
import Foundation
import SwiftUI

// MARK: - Edit History ViewModel

@MainActor
class EditHistoryViewModel: BaseViewModel {
    // MARK: - Published Properties

    @Published var editingRecord: TimeRecord?
    @Published var selectedProject: Project?
    @Published var selectedJob: Job?
    @Published var startTime: Date = .init()
    @Published var endTime: Date = .init()
    @Published var showingEditSheet = false
    @Published var showingDeleteAlert = false
    @Published var availableProjects: [Project] = []
    @Published var availableJobs: [Job] = []
    @Published var isEditingInProgressRecord: Bool = false

    // MARK: - Computed Properties

    var isValidTimeRange: Bool {
        // 作業中レコードの場合は開始時間のみチェック
        if self.isEditingInProgressRecord {
            // 開始時間が現在時刻より前であればOK
            return self.startTime <= Date()
        }

        // 完了済みレコードの場合は既存のバリデーション
        guard self.startTime < self.endTime else { return false }
        guard self.endTime <= Date() else { return false }

        let duration = self.endTime.timeIntervalSince(self.startTime)
        return duration >= 60 && duration <= 86400
    }

    var calculatedDuration: TimeInterval {
        return self.endTime.timeIntervalSince(self.startTime)
    }

    var formattedDuration: String {
        let duration = max(calculatedDuration, 0) // 負の値を防ぐ
        let hours = Int(duration) / 3600
        let minutes = (Int(duration) % 3600) / 60

        if hours > 0 {
            return "\(hours)時間\(minutes)分"
        } else {
            return "\(minutes)分"
        }
    }

    var canSave: Bool {
        return self.selectedProject != nil && self.selectedJob != nil && self.isValidTimeRange && !isLoading
    }

    var canDelete: Bool {
        return self.editingRecord != nil && !isLoading
    }

    // MARK: - Dependencies

    private let timeRecordRepository: TimeRecordRepositoryProtocol
    private let projectRepository: ProjectRepositoryProtocol
    private let jobRepository: JobRepositoryProtocol

    // MARK: - Initialization

    init(timeRecordRepository: TimeRecordRepositoryProtocol,
         projectRepository: ProjectRepositoryProtocol,
         jobRepository: JobRepositoryProtocol)
    {
        self.timeRecordRepository = timeRecordRepository
        self.projectRepository = projectRepository
        self.jobRepository = jobRepository
        super.init()
        self.loadAvailableProjects()
        self.loadAvailableJobs()
    }

    // MARK: - Actions

    func startEditing(_ record: TimeRecord) {
        self.editingRecord = record
        self.selectedProject = record.project
        self.selectedJob = record.job
        self.startTime = record.startTime

        // 作業中レコードの判定と保持
        if let endTime = record.endTime {
            // 完了済みレコード: 既存のendTimeを使用
            self.endTime = endTime
            self.isEditingInProgressRecord = false
        } else {
            // 作業中レコード: 現在時刻をUI表示用に設定（保存時は使用しない）
            self.endTime = Date()
            self.isEditingInProgressRecord = true
        }

        self.showingEditSheet = true
        clearError()

        // 編集開始時に最新のプロジェクト・作業区分一覧を再読み込み
        self.loadAvailableProjects()
        self.loadAvailableJobs()
    }

    func saveChanges() {
        guard let record = editingRecord,
              let project = selectedProject,
              let job = selectedJob
        else {
            handleError(EditHistoryError.missingData)
            return
        }

        withLoadingSync {
            // 作業中レコードの場合はendTime: nil、完了済みの場合はendTime: Date
            let finalEndTime = self.isEditingInProgressRecord ? nil : self.endTime

            try self.timeRecordRepository.updateTimeRecord(
                record,
                startTime: self.startTime,
                endTime: finalEndTime,
                project: project,
                job: job
            )
        }

        if errorMessage == nil {
            self.showingEditSheet = false
            self.resetEditingState()
        }
    }

    func deleteRecord() {
        guard let record = editingRecord else {
            handleError(EditHistoryError.missingData)
            return
        }

        withLoadingSync {
            try self.timeRecordRepository.deleteTimeRecord(record)
        }

        if errorMessage == nil {
            self.showingDeleteAlert = false
            self.showingEditSheet = false
            self.resetEditingState()
        }
    }

    func cancel() {
        self.showingEditSheet = false
        self.showingDeleteAlert = false
        self.resetEditingState()
        clearError()
    }

    func showDeleteConfirmation() {
        self.showingDeleteAlert = true
    }

    // MARK: - Time Adjustment Methods

    func adjustStartTime(by minutes: Int) {
        guard let newStartTime = Calendar.current.date(byAdding: .minute, value: minutes, to: startTime) else { return }
        if newStartTime < self.endTime, newStartTime <= Date() {
            self.startTime = newStartTime
        }
    }

    func adjustEndTime(by minutes: Int) {
        guard let newEndTime = Calendar.current.date(byAdding: .minute, value: minutes, to: endTime) else { return }
        if newEndTime > self.startTime, newEndTime <= Date() {
            self.endTime = newEndTime
        }
    }

    // MARK: - Private Methods

    private func loadAvailableProjects() {
        if let projects = withLoadingSync({
            try projectRepository.fetchProjects()
        }) {
            self.availableProjects = projects
        }
    }

    private func loadAvailableJobs() {
        if let jobs = withLoadingSync({
            try jobRepository.fetchAllJobs()
        }) {
            self.availableJobs = jobs
        }
    }

    private func resetEditingState() {
        self.editingRecord = nil
        self.selectedProject = nil
        self.selectedJob = nil
        self.startTime = Date()
        self.endTime = Date()
        self.isEditingInProgressRecord = false
        self.availableProjects = []
        self.availableJobs = []
    }

    // MARK: - Validation

    func validateTimeRange() -> String? {
        do {
            guard let record = editingRecord else { return nil }
            let finalEndTime = self.isEditingInProgressRecord ? nil : self.endTime
            _ = try self.timeRecordRepository.validateTimeRange(
                startTime: self.startTime,
                endTime: finalEndTime,
                excludingRecord: record
            )
            return nil
        } catch {
            return error.localizedDescription
        }
    }
}

// MARK: - Edit History Errors

enum EditHistoryError: LocalizedError {
    case recordNotCompleted
    case missingData
    case validationFailed

    var errorDescription: String? {
        switch self {
        case .recordNotCompleted:
            return "進行中のレコードは編集できません"
        case .missingData:
            return "編集に必要な情報が不足しています"
        case .validationFailed:
            return "入力データの検証に失敗しました"
        }
    }
}
