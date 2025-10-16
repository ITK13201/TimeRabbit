//
//  MainContentViewModel.swift
//  TimeRabbit
//
//  Created by Takumi Ikeda on 2025/08/09.
//

import Combine
import Foundation
import SwiftUI

@MainActor
class MainContentViewModel: BaseViewModel {
  // MARK: - Published Properties

  @Published var selectedTab = 0

  // MARK: - Child ViewModels

  let statisticsViewModel: StatisticsViewModel
  let historyViewModel: HistoryViewModel

  // MARK: - Tab Constants

  enum Tab: Int, CaseIterable {
    case history = 0
    case statistics = 1

    var title: String {
      switch self {
      case .statistics: return "統計"
      case .history: return "履歴"
      }
    }

    var systemImageName: String {
      switch self {
      case .statistics: return "chart.pie"
      case .history: return "clock"
      }
    }
  }

  // MARK: - Computed Properties

  var currentTab: Tab {
    return Tab(rawValue: self.selectedTab) ?? .history
  }

  // MARK: - Initialization

  init(statisticsViewModel: StatisticsViewModel, historyViewModel: HistoryViewModel) {
    self.statisticsViewModel = statisticsViewModel
    self.historyViewModel = historyViewModel
    super.init()
    self.setupEditHistoryObservation()
  }

  // MARK: - Observation Setup

  private var cancellables = Set<AnyCancellable>()

  private func setupEditHistoryObservation() {
    // EditHistoryViewModelのシート状態を監視して、編集完了時に統計を更新
    self.historyViewModel.editHistoryViewModel.$showingEditSheet
      .receive(on: DispatchQueue.main)
      .sink { [weak self] isShowing in
        if !isShowing {
          // 編集シートが閉じられたら統計も更新
          self?.statisticsViewModel.refreshData()
        }
      }
      .store(in: &self.cancellables)
  }

  // MARK: - Tab Management

  func selectTab(_ tab: Tab) {
    self.selectedTab = tab.rawValue

    // タブ切り替え時にデータを更新
    self.refreshCurrentTabData()
  }

  func selectTab(at index: Int) {
    guard let tab = Tab(rawValue: index) else { return }
    self.selectTab(tab)
  }

  // MARK: - Data Management

  func refreshCurrentTabData() {
    switch self.currentTab {
    case .history:
      self.historyViewModel.refreshData()
    case .statistics:
      self.statisticsViewModel.refreshData()
    }
  }

  func refreshAllData() {
    self.historyViewModel.refreshData()
    self.statisticsViewModel.refreshData()
  }
}
