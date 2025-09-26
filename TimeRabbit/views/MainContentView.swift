//
//  MainContentView.swift
//  TimeRabbit
//
//  Created by Takumi Ikeda on 2025/08/09.
//

import Foundation
import SwiftData
import SwiftUI

struct MainContentView: View {
  @StateObject private var viewModel: MainContentViewModel
  
  init(viewModel: MainContentViewModel) {
    self._viewModel = StateObject(wrappedValue: viewModel)
  }

  var body: some View {
    TabView(selection: $viewModel.selectedTab) {
      HistoryView(viewModel: viewModel.historyViewModel)
        .tabItem {
          Image(systemName: MainContentViewModel.Tab.history.systemImageName)
          Text(MainContentViewModel.Tab.history.title)
        }
        .tag(MainContentViewModel.Tab.history.rawValue)

      StatisticsView(viewModel: viewModel.statisticsViewModel)
        .tabItem {
          Image(systemName: MainContentViewModel.Tab.statistics.systemImageName)
          Text(MainContentViewModel.Tab.statistics.title)
        }
        .tag(MainContentViewModel.Tab.statistics.rawValue)
    }
  }
}