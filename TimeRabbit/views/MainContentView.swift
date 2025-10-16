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
    _viewModel = StateObject(wrappedValue: viewModel)
  }

  var body: some View {
    TabView(selection: self.$viewModel.selectedTab) {
      HistoryView(viewModel: self.viewModel.historyViewModel)
        .tabItem {
          Image(systemName: MainContentViewModel.Tab.history.systemImageName)
          Text(MainContentViewModel.Tab.history.title)
        }
        .tag(MainContentViewModel.Tab.history.rawValue)

      StatisticsView(viewModel: self.viewModel.statisticsViewModel)
        .tabItem {
          Image(systemName: MainContentViewModel.Tab.statistics.systemImageName)
          Text(MainContentViewModel.Tab.statistics.title)
        }
        .tag(MainContentViewModel.Tab.statistics.rawValue)
    }
  }
}
