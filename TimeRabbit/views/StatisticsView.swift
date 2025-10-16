//
//  StatisticsView.swift
//  TimeRabbit
//
//  Created by Takumi Ikeda on 2025/08/09.
//

import AppKit
import Foundation
import SwiftData
import SwiftUI

struct StatisticsView: View {
  @ObservedObject var viewModel: StatisticsViewModel
  @State private var showCopiedFeedback = false

  init(viewModel: StatisticsViewModel) {
    self.viewModel = viewModel
  }

  var body: some View {
    VStack(alignment: .leading, spacing: 20) {
      HStack {
        Text("統計")
          .font(.largeTitle)
          .fontWeight(.bold)

        Spacer()

        Button(action: { self.viewModel.toggleDatePicker() }) {
          HStack {
            Image(systemName: "calendar")
            Text(self.viewModel.getFormattedDate())
          }
        }
        .popover(isPresented: Binding(
          get: { self.viewModel.showingDatePicker },
          set: { _ in self.viewModel.hideDatePicker() }
        )) {
          VStack {
            DatePicker(
              "日付を選択",
              selection: Binding(
                get: { self.viewModel.selectedDate },
                set: { self.viewModel.selectedDate = $0 }
              ),
              displayedComponents: .date
            )
            .datePickerStyle(.graphical)
            .padding()

            Button("完了") {
              self.viewModel.hideDatePicker()
            }
            .padding(.bottom)
          }
        }
      }

      if !self.viewModel.hasData {
        Text(self.viewModel.getEmptyMessage())
          .foregroundColor(.secondary)
          .frame(maxWidth: .infinity, maxHeight: .infinity)
      } else {
        VStack(alignment: .leading, spacing: 16) {
          Text("総作業時間: \(self.viewModel.getFormattedTotalTime())")
            .font(.title2)
            .fontWeight(.semibold)

          ScrollView {
            LazyVStack(spacing: 8) {
              ForEach(Array(self.viewModel.projectJobDetails.enumerated()), id: \.offset) { _, detail in
                let percentage = self.viewModel.getPercentage(for: detail.duration)
                let command = self.viewModel.generateCommand(for: detail)

                ProjectStatRowUpdated(
                  projectName: detail.projectName,
                  jobName: detail.jobName,
                  projectColor: detail.projectColor,
                  duration: detail.duration,
                  percentage: percentage,
                  command: command
                )
              }

              VStack(alignment: .leading, spacing: 8) {
                HStack {
                  Text("統計データ")
                    .font(.headline)
                  Spacer()
                  Button(action: {
                    // コピー操作を非同期で実行
                    Task {
                      let text = self.viewModel.generateStatisticsText()
                      let pasteboard = NSPasteboard.general
                      pasteboard.clearContents()
                      pasteboard.setString(text, forType: .string)

                      // フィードバック表示をメインスレッドで実行
                      await MainActor.run {
                        self.showCopiedFeedback = true
                      }

                      // 2秒後にリセット
                      try? await Task.sleep(nanoseconds: 2_000_000_000)

                      await MainActor.run {
                        self.showCopiedFeedback = false
                      }
                    }
                  }) {
                    HStack(spacing: 4) {
                      Image(systemName: self.showCopiedFeedback ? "checkmark" : "doc.on.clipboard")
                        .foregroundColor(self.showCopiedFeedback ? .green : .primary)
                      if self.showCopiedFeedback {
                        Text("コピー完了")
                          .font(.caption)
                          .foregroundColor(.green)
                      }
                    }
                  }
                  .buttonStyle(.borderless)
                  .help(self.showCopiedFeedback ? "コピーしました" : "統計データをクリップボードにコピー")
                  .animation(.easeInOut(duration: 0.3), value: self.showCopiedFeedback)
                }

                ScrollView {
                  VStack(alignment: .leading) {
                    Text(self.viewModel.generateStatisticsText())
                      .font(.system(.caption, design: .monospaced))
                      .textSelection(.enabled)
                      .frame(maxWidth: .infinity, alignment: .leading)
                  }
                  .padding(12)
                  .background(Color(nsColor: .controlBackgroundColor))
                  .cornerRadius(8)
                  .overlay(
                    RoundedRectangle(cornerRadius: 8)
                      .stroke(Color(nsColor: .separatorColor), lineWidth: 1)
                  )
                }
                .frame(maxHeight: 200)
              }
              .padding(.top, 16)
            }
          }
        }
      }
    }
    .padding()
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
  }
}

#Preview {
  let mockProjectRepo = MockProjectRepository(withSampleData: true)
  let projects = try! mockProjectRepo.fetchProjects()
  let mockTimeRecordRepo = MockTimeRecordRepository(projects: projects, withSampleData: true)
  let mockJobRepo = MockJobRepository()
  let factory = ViewModelFactory.create(with: (mockProjectRepo, mockTimeRecordRepo, mockJobRepo))
  StatisticsView(viewModel: factory.createStatisticsViewModel())
}
