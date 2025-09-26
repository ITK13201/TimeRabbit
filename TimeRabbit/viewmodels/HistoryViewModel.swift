//
//  HistoryViewModel.swift
//  TimeRabbit
//
//  Created by Takumi Ikeda on 2025/08/09.
//

import Foundation
import SwiftUI
import Combine

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
    return dayRecords.filter { $0.endTime != nil }
  }
  
  var totalDayTime: TimeInterval {
    return completedRecords.reduce(0) { $0 + $1.duration }
  }
  
  var hasRecords: Bool {
    return !completedRecords.isEmpty
  }
  
  var recordCount: Int {
    return completedRecords.count
  }
  
  // MARK: - Initialization
  
  init(timeRecordRepository: TimeRecordRepositoryProtocol, 
       projectRepository: ProjectRepositoryProtocol,
       editHistoryViewModel: EditHistoryViewModel,
       dateService: DateService) {
    self.timeRecordRepository = timeRecordRepository
    self.projectRepository = projectRepository
    self.editHistoryViewModel = editHistoryViewModel
    self.dateService = dateService
    super.init()
    
    setupDateObserver()
    loadRecordsForSelectedDate()
    setupEditHistoryObservation()
  }
  
  private func setupDateObserver() {
    dateService.$selectedDate
      .sink { [weak self] _ in
        self?.loadRecordsForSelectedDate()
      }
      .store(in: &cancellables)
    
    dateService.$showingDatePicker
      .receive(on: DispatchQueue.main)
      .sink { [weak self] _ in
        DispatchQueue.main.async {
          self?.objectWillChange.send()
        }
      }
      .store(in: &cancellables)
  }
  
  // MARK: - Data Loading
  
  private func loadRecordsForSelectedDate() {
    loadRecordsForDate(dateService.selectedDate)
  }
  
  func loadRecordsForDate(_ date: Date) {
    let startOfDay = Calendar.current.startOfDay(for: date)
    let endOfDay = Calendar.current.date(byAdding: .day, value: 1, to: startOfDay)!
    
    if let records = withLoadingSync({
      try timeRecordRepository.fetchTimeRecords(for: nil, from: startOfDay, to: endOfDay)
    }) {
      dayRecords = records
    }
  }
  
  func refreshData() {
    loadRecordsForSelectedDate()
  }
  
  // MARK: - Date Management
  
  func selectDate(_ date: Date) {
    dateService.selectedDate = date
    dateService.hideDatePicker()
  }
  
  func toggleDatePicker() {
    dateService.toggleDatePicker()
  }
  
  func hideDatePicker() {
    dateService.hideDatePicker()
  }
  
  func getFormattedDate() -> String {
    return dateService.getFormattedDate()
  }
  
  func getEmptyMessage() -> String {
    return isToday(dateService.selectedDate) ? "今日はまだ作業記録がありません" : "この日の作業記録はありません"
  }
  
  var showingDatePicker: Bool {
    return dateService.showingDatePicker
  }
  
  var selectedDate: Date {
    get { dateService.selectedDate }
    set { dateService.selectedDate = newValue }
  }
  
  // MARK: - Record Management
  
  func deleteRecord(_ record: TimeRecord) {
    withLoadingSync {
      try timeRecordRepository.deleteTimeRecord(record)
    }
    
    if errorMessage == nil {
      // データを再読み込み
      loadRecordsForSelectedDate()
    }
  }
  
  private func setupEditHistoryObservation() {
    // EditHistoryViewModelが編集や削除を完了したらデータをリフレッシュ
    editHistoryViewModel.$showingEditSheet
      .receive(on: DispatchQueue.main)
      .sink { [weak self] isShowing in
        if !isShowing {
          // シートが閉じられた時にデータをリフレッシュ
          self?.refreshData()
        }
      }
      .store(in: &cancellables)
  }
  
  // MARK: - Helper Methods
  
  func isToday(_ date: Date) -> Bool {
    return Calendar.current.isDate(date, inSameDayAs: Date())
  }
  
  
  func getFormattedTotalTime() -> String {
    return formatDuration(totalDayTime)
  }
  
  func getRecordCountText() -> String {
    return "\(recordCount)件の記録"
  }
}