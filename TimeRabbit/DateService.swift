//
//  DateService.swift
//  TimeRabbit
//
//  Created by Claude Code on 2025-08-10.
//

import Foundation
import Combine

/// 統計画面と履歴画面で日付を共有するためのサービス
@MainActor
class DateService: ObservableObject {
  @Published var selectedDate: Date = Date()
  @Published var showingDatePicker: Bool = false
  
  // MARK: - Date Picker Methods
  
  func toggleDatePicker() {
    showingDatePicker.toggle()
  }
  
  func hideDatePicker() {
    showingDatePicker = false
  }
  
  func getFormattedDate() -> String {
    return formatDate(selectedDate)
  }
}