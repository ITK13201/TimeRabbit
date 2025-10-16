//
//  HistoryView.swift
//  TimeRabbit
//
//  Created by Takumi Ikeda on 2025/08/09.
//

import Foundation
import SwiftData
import SwiftUI

struct HistoryView: View {
  @StateObject private var viewModel: HistoryViewModel
  @StateObject private var editHistoryViewModel: EditHistoryViewModel

  init(viewModel: HistoryViewModel) {
    _viewModel = StateObject(wrappedValue: viewModel)
    _editHistoryViewModel = StateObject(wrappedValue: viewModel.editHistoryViewModel)
  }

  var body: some View {
    VStack(alignment: .leading, spacing: 20) {
      HStack {
        Text("作業履歴")
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

      if !self.viewModel.hasRecords {
        Text(self.viewModel.getEmptyMessage())
          .foregroundColor(.secondary)
          .frame(maxWidth: .infinity, maxHeight: .infinity)
      } else {
        VStack(alignment: .leading, spacing: 16) {
          HStack {
            Text("総作業時間: \(self.viewModel.getFormattedTotalTime())")
              .font(.title2)
              .fontWeight(.semibold)

            Spacer()

            Text(self.viewModel.getRecordCountText())
              .font(.subheadline)
              .foregroundColor(.secondary)
          }

          ScrollView {
            LazyVStack(spacing: 8) {
              // 作業中のレコードを最初に表示
              if let inProgressRecord = viewModel.inProgressRecord {
                VStack(alignment: .leading, spacing: 4) {
                  Text("作業中")
                    .font(.caption)
                    .foregroundColor(.green)
                    .fontWeight(.semibold)
                  HistoryRowView(
                    record: inProgressRecord,
                    onEdit: { record in
                      self.editHistoryViewModel.startEditing(record)
                    },
                    onDelete: { record in
                      self.editHistoryViewModel.startEditing(record)
                      self.editHistoryViewModel.showDeleteConfirmation()
                    }
                  )
                }
              }

              // 完了済みのレコード
              ForEach(self.viewModel.completedRecords, id: \.id) { record in
                HistoryRowView(
                  record: record,
                  onEdit: { record in
                    self.editHistoryViewModel.startEditing(record)
                  },
                  onDelete: { record in
                    self.editHistoryViewModel.startEditing(record)
                    self.editHistoryViewModel.showDeleteConfirmation()
                  }
                )
              }
            }
          }
        }
      }
    }
    .padding()
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    .sheet(isPresented: self.$editHistoryViewModel.showingEditSheet) {
      EditHistorySheetView(viewModel: self.editHistoryViewModel)
    }
    .onChange(of: self.editHistoryViewModel.showingEditSheet) { isShowing in
      if !isShowing {
        self.viewModel.refreshData()
      }
    }
  }
}

#Preview {
  let mockProjectRepo = MockProjectRepository(withSampleData: true)
  let projects = try! mockProjectRepo.fetchProjects()
  let mockTimeRecordRepo = MockTimeRecordRepository(projects: projects, withSampleData: true)
  let mockJobRepo = MockJobRepository()
  let factory = ViewModelFactory.create(with: (mockProjectRepo, mockTimeRecordRepo, mockJobRepo))
  HistoryView(viewModel: factory.createHistoryViewModel())
}
