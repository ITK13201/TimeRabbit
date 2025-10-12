//
//  StatisticsViewModel.swift
//  TimeRabbit
//
//  Created by Takumi Ikeda on 2025/08/09.
//

import Combine
import Foundation
import SwiftUI

@MainActor
class StatisticsViewModel: BaseViewModel {
    // MARK: - Published Properties

    @Published var projectJobTimes: [(String, String, String, TimeInterval)] = [] // (projectName, jobName, projectColor, duration)
    @Published var projectJobDetails: [(projectId: String, projectName: String, projectColor: String, jobId: String, jobName: String, duration: TimeInterval)] = []
    @Published var totalTime: TimeInterval = 0

    // MARK: - Dependencies

    private let timeRecordRepository: TimeRecordRepositoryProtocol
    let dateService: DateService
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Initialization

    init(timeRecordRepository: TimeRecordRepositoryProtocol, dateService: DateService) {
        self.timeRecordRepository = timeRecordRepository
        self.dateService = dateService
        super.init()

        self.setupDateObserver()
        self.loadStatistics()
    }

    private func setupDateObserver() {
        self.dateService.$selectedDate
            .sink { [weak self] _ in
                self?.loadStatistics()
            }
            .store(in: &self.cancellables)

        self.dateService.$showingDatePicker
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                DispatchQueue.main.async {
                    self?.objectWillChange.send()
                }
            }
            .store(in: &self.cancellables)
    }

    // MARK: - Data Loading

    func loadStatistics() {
        let startOfDay = Calendar.current.startOfDay(for: self.dateService.selectedDate)
        let endOfDay = Calendar.current.date(byAdding: .day, value: 1, to: startOfDay)!

        if let records = withLoadingSync({
            try timeRecordRepository.fetchTimeRecords(for: nil, from: startOfDay, to: endOfDay)
        }) {
            // 完了した記録のみを対象にする
            let completedRecords = records.filter { $0.endTime != nil }

            // プロジェクトID + ジョブIDでグループ化
            let groupedRecords = Dictionary(grouping: completedRecords) { record in
                "\(record.displayProjectId)_\(record.displayJobId)"
            }

            // 統計データを計算
            self.projectJobDetails = groupedRecords.map { _, records in
                let firstRecord = records.first!
                let projectId = firstRecord.displayProjectId
                let projectName = firstRecord.displayProjectName
                let projectColor = firstRecord.displayProjectColor
                let jobId = firstRecord.displayJobId
                let jobName = firstRecord.displayJobName
                let totalTime = records.reduce(0) { $0 + $1.duration }
                return (projectId, projectName, projectColor, jobId, jobName, totalTime)
            }.sorted { $0.duration > $1.duration } // 時間順でソート

            // 後方互換性のため、既存のprojectJobTimesも更新
            self.projectJobTimes = self.projectJobDetails.map { detail in
                (detail.projectName, detail.jobName, detail.projectColor, detail.duration)
            }

            // 総作業時間を計算
            self.totalTime = completedRecords.reduce(0) { $0 + $1.duration }
        }
    }

    func refreshData() {
        self.loadStatistics()
    }

    // MARK: - Date Picker Methods

    func toggleDatePicker() {
        self.dateService.toggleDatePicker()
    }

    func hideDatePicker() {
        self.dateService.hideDatePicker()
    }

    func getFormattedDate() -> String {
        return self.dateService.getFormattedDate()
    }

    func getEmptyMessage() -> String {
        if Calendar.current.isDateInToday(self.dateService.selectedDate) {
            return "今日はまだ作業記録がありません"
        } else {
            return "この日の作業記録はありません"
        }
    }

    var showingDatePicker: Bool {
        return self.dateService.showingDatePicker
    }

    var selectedDate: Date {
        get { self.dateService.selectedDate }
        set { self.dateService.selectedDate = newValue }
    }

    // MARK: - Helper Methods

    func getPercentage(for duration: TimeInterval) -> Double {
        guard self.totalTime > 0 else { return 0 }
        return (duration / self.totalTime) * 100
    }

    var hasData: Bool {
        return !self.projectJobTimes.isEmpty
    }

    func getFormattedTotalTime() -> String {
        return formatDuration(self.totalTime)
    }

    func getFormattedDuration(_ duration: TimeInterval) -> String {
        return formatDuration(duration)
    }

    func generateStatisticsText() -> String {
        let dateText = self.getFormattedDate()
        let totalTimeText = self.getFormattedTotalTime()

        var result = "# \(dateText) の作業統計\n\n"
        result += "**総作業時間**: \(totalTimeText)\n\n"

        if !self.projectJobTimes.isEmpty {
            result += "## 案件・作業区分別作業時間\n\n"
            for (projectName, jobName, _, duration) in self.projectJobTimes {
                let formattedDuration = self.getFormattedDuration(duration)
                let percentage = String(format: "%.1f", getPercentage(for: duration))
                result += "- **\(projectName)** - \(jobName): \(formattedDuration) (\(percentage)%)\n"
            }
        }

        return result
    }

    func generateCommandText() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy/MM/dd"
        let dateText = dateFormatter.string(from: self.dateService.selectedDate)

        var result = ""
        for detail in self.projectJobDetails {
            let percentage = Int(round(getPercentage(for: detail.duration)))
            result += "add \(dateText) \(detail.projectId) \(detail.jobId) \(percentage)\n"
        }

        return result.trimmingCharacters(in: .newlines)
    }

    func generateCommand(for detail: (projectId: String, projectName: String, projectColor: String, jobId: String, jobName: String, duration: TimeInterval)) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy/MM/dd"
        let dateText = dateFormatter.string(from: self.dateService.selectedDate)
        let percentage = Int(round(getPercentage(for: detail.duration)))
        return "add \(dateText) \(detail.projectId) \(detail.jobId) \(percentage)"
    }
}
