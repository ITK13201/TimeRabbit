//
//  DateService.swift
//  TimeRabbit
//
//  Created by Claude Code on 2025-08-10.
//

import Combine
import Foundation

/// 統計画面と履歴画面で日付を共有するためのサービス
@MainActor
class DateService: ObservableObject {
    @Published var selectedDate: Date = .init()
    @Published var showingDatePicker: Bool = false

    // MARK: - Date Picker Methods

    func toggleDatePicker() {
        self.showingDatePicker.toggle()
    }

    func hideDatePicker() {
        self.showingDatePicker = false
    }

    func getFormattedDate() -> String {
        return formatDate(self.selectedDate)
    }
}
