//
//  StatisticsView.swift
//  TimeRabbit
//
//  Created by Takumi Ikeda on 2025/08/09.
//

import Foundation
import SwiftData
import SwiftUI
import AppKit

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

        Button(action: { viewModel.toggleDatePicker() }) {
          HStack {
            Image(systemName: "calendar")
            Text(viewModel.getFormattedDate())
          }
        }
        .popover(isPresented: Binding(
          get: { viewModel.showingDatePicker },
          set: { _ in viewModel.hideDatePicker() }
        )) {
          VStack {
            DatePicker(
              "日付を選択",
              selection: Binding(
                get: { viewModel.selectedDate },
                set: { viewModel.selectedDate = $0 }
              ),
              displayedComponents: .date
            )
            .datePickerStyle(.graphical)
            .padding()

            Button("完了") {
              viewModel.hideDatePicker()
            }
            .padding(.bottom)
          }
        }
      }

      if !viewModel.hasData {
        Text(viewModel.getEmptyMessage())
          .foregroundColor(.secondary)
          .frame(maxWidth: .infinity, maxHeight: .infinity)
      } else {
        VStack(alignment: .leading, spacing: 16) {
          Text("総作業時間: \(viewModel.getFormattedTotalTime())")
            .font(.title2)
            .fontWeight(.semibold)

          ScrollView {
            LazyVStack(spacing: 8) {
              ForEach(Array(viewModel.projectTimes.enumerated()), id: \.offset) { index, item in
                let (projectName, projectColor, duration) = item
                let percentage = viewModel.getPercentage(for: duration)

                ProjectStatRowUpdated(
                  projectName: projectName,
                  projectColor: projectColor,
                  duration: duration,
                  percentage: percentage
                )
              }
              
              // コピー可能な統計データ表示
              VStack(alignment: .leading, spacing: 8) {
                HStack {
                  Text("統計データ")
                    .font(.headline)
                  Spacer()
                  Button(action: {
                    // コピー操作を非同期で実行
                    Task {
                      let text = viewModel.generateStatisticsText()
                      let pasteboard = NSPasteboard.general
                      pasteboard.clearContents()
                      pasteboard.setString(text, forType: .string)
                      
                      // フィードバック表示をメインスレッドで実行
                      await MainActor.run {
                        showCopiedFeedback = true
                      }
                      
                      // 2秒後にリセット
                      try? await Task.sleep(nanoseconds: 2_000_000_000)
                      
                      await MainActor.run {
                        showCopiedFeedback = false
                      }
                    }
                  }) {
                    HStack(spacing: 4) {
                      Image(systemName: showCopiedFeedback ? "checkmark" : "doc.on.clipboard")
                        .foregroundColor(showCopiedFeedback ? .green : .primary)
                      if showCopiedFeedback {
                        Text("コピー完了")
                          .font(.caption)
                          .foregroundColor(.green)
                      }
                    }
                  }
                  .buttonStyle(.borderless)
                  .help(showCopiedFeedback ? "コピーしました" : "統計データをクリップボードにコピー")
                  .animation(.easeInOut(duration: 0.3), value: showCopiedFeedback)
                }
                
                ScrollView {
                  VStack(alignment: .leading) {
                    Text(viewModel.generateStatisticsText())
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