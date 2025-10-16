//
//  HistoryViewModel.swift
//  TimeRabbit
//
//  Created by Takumi Ikeda on 2025/08/09.
//

import Combine
import Foundation
import SwiftUI

@MainActor
class HistoryViewModel: BaseViewModel {
  // MARK: - Published Properties

  @Published var dayRecords: [TimeRecord] = []

  private var cancellables = Set<AnyCancellable>()

  // MARK: - Child ViewModels

  let editHistoryViewModel: EditHistoryViewModel

  // MARK: - Dependencies

  private let timeRecordRepository: TimeRecordRepositoryProtocol
  private let projectRepository: ProjectRepositoryProtocol
  let dateService: DateService

  // MARK: - Computed Properties

  var completedRecords: [TimeRecord] {
    return self.dayRecords.filter { $0.endTime != nil }
  }

  var allRecords: [TimeRecord] {
    return self.dayRecords // 完了済みと作業中の両方を含む
  }

  var inProgressRecord: TimeRecord? {
    return self.dayRecords.first { $0.endTime == nil }
  }

  var totalDayTime: TimeInterval {
    return self.completedRecords.reduce(0) { $0 + $1.duration }
  }

  var hasRecords: Bool {
    return !self.dayRecords.isEmpty
  }

  var recordCount: Int {
    return self.dayRecords.count
  }

  // MARK: - Initialization

  init(timeRecordRepository: TimeRecordRepositoryProtocol,
       projectRepository: ProjectRepositoryProtocol,
       editHistoryViewModel: EditHistoryViewModel,
       dateService: DateService)
  {
    self.timeRecordRepository = timeRecordRepository
    self.projectRepository = projectRepository
    self.editHistoryViewModel = editHistoryViewModel
    self.dateService = dateService
    super.init()

    self.setupDateObserver()
    self.loadRecordsForSelectedDate()
    self.setupEditHistoryObservation()
  }

  private func setupDateObserver() {
    self.dateService.$selectedDate
      .sink { [weak self] _ in
        self?.loadRecordsForSelectedDate()
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

  private func loadRecordsForSelectedDate() {
    self.loadRecordsForDate(self.dateService.selectedDate)
  }

  func loadRecordsForDate(_ date: Date) {
    let startOfDay = Calendar.current.startOfDay(for: date)
    let endOfDay = Calendar.current.date(byAdding: .day, value: 1, to: startOfDay)!

    if let records = withLoadingSync({
      try timeRecordRepository.fetchTimeRecords(for: nil, from: startOfDay, to: endOfDay)
    }) {
      self.dayRecords = records
    }
  }

  func refreshData() {
    self.loadRecordsForSelectedDate()
  }

  // MARK: - Date Management

  func selectDate(_ date: Date) {
    self.dateService.selectedDate = date
    self.dateService.hideDatePicker()
  }

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
    return self.isToday(self.dateService.selectedDate) ? "今日はまだ作業記録がありません" : "この日の作業記録はありません"
  }

  var showingDatePicker: Bool {
    return self.dateService.showingDatePicker
  }

  var selectedDate: Date {
    get { self.dateService.selectedDate }
    set { self.dateService.selectedDate = newValue }
  }

  // MARK: - Record Management

  func deleteRecord(_ record: TimeRecord) {
    withLoadingSync {
      try self.timeRecordRepository.deleteTimeRecord(record)
    }

    if errorMessage == nil {
      // データを再読み込み
      self.loadRecordsForSelectedDate()
    }
  }

  private func setupEditHistoryObservation() {
    // EditHistoryViewModelが編集や削除を完了したらデータをリフレッシュ
    self.editHistoryViewModel.$showingEditSheet
      .receive(on: DispatchQueue.main)
      .sink { [weak self] isShowing in
        if !isShowing {
          // シートが閉じられた時にデータをリフレッシュ
          self?.refreshData()
        }
      }
      .store(in: &self.cancellables)
  }

  // MARK: - Helper Methods

  func isToday(_ date: Date) -> Bool {
    return Calendar.current.isDate(date, inSameDayAs: Date())
  }

  func getFormattedTotalTime() -> String {
    return formatDuration(self.totalDayTime)
  }

  func getRecordCountText() -> String {
    return "\(self.recordCount)件の記録"
  }
}
