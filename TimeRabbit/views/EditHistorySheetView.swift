//
//  EditHistorySheetView.swift
//  TimeRabbit
//
//  Created by Takumi Ikeda on 2025/08/09.
//

import SwiftUI

struct EditHistorySheetView: View {
  @ObservedObject var viewModel: EditHistoryViewModel
  @Environment(\.dismiss) private var dismiss
  
  var body: some View {
    VStack(spacing: 0) {
      // カスタムナビゲーションバー
      HStack {
        Button("キャンセル") {
          viewModel.cancel()
          dismiss()
        }
        
        Spacer()
        
        Text("履歴レコード編集")
          .font(.headline)
          .fontWeight(.semibold)
        
        Spacer()
        
        HStack(spacing: 12) {
          Button("削除") {
            viewModel.showDeleteConfirmation()
          }
          .foregroundColor(.red)
          .disabled(!viewModel.canDelete)
          
          Button("保存") {
            viewModel.saveChanges()
            if viewModel.errorMessage == nil {
              dismiss()
            }
          }
          .disabled(!viewModel.canSave)
          .buttonStyle(.borderedProminent)
        }
      }
      .padding()
      .background(Color(NSColor.windowBackgroundColor))
      .overlay(
        Rectangle()
          .frame(height: 1)
          .foregroundColor(Color.primary.opacity(0.1)),
        alignment: .bottom
      )
      
      Form {
        Spacer()
          .frame(height: 20)
        
        Section {
          // プロジェクト選択
          HStack {
            Text("案件")
              .frame(width: 80, alignment: .leading)

            Picker("", selection: $viewModel.selectedProject) {
              Text("案件を選択")
                .foregroundColor(.secondary)
                .tag(nil as Project?)

              ForEach(viewModel.availableProjects, id: \.id) { project in
                HStack {
                  Circle()
                    .fill(getProjectColor(from: project.color))
                    .frame(width: 12, height: 12)
                  Text(project.name)
                }
                .tag(project as Project?)
              }
            }
            .pickerStyle(MenuPickerStyle())
          }

          // 作業区分選択
          HStack {
            Text("作業区分")
              .frame(width: 80, alignment: .leading)

            Picker("", selection: $viewModel.selectedJob) {
              Text("作業区分を選択")
                .foregroundColor(.secondary)
                .tag(nil as Job?)

              ForEach(viewModel.availableJobs, id: \.id) { job in
                Text(job.name)
                  .tag(job as Job?)
              }
            }
            .pickerStyle(MenuPickerStyle())
          }
        }
        
        Spacer()
          .frame(height: 40)
        
        Section {
          // 開始時間
          HStack {
            Text("開始時間")
              .frame(width: 80, alignment: .leading)
            
            DatePicker("", selection: $viewModel.startTime, displayedComponents: [.date, .hourAndMinute])
              .datePickerStyle(CompactDatePickerStyle())
            
            VStack(spacing: 2) {
              Button("+15分") {
                viewModel.adjustStartTime(by: 15)
              }
              .font(.caption2)
              .buttonStyle(BorderedButtonStyle())
              
              Button("-15分") {
                viewModel.adjustStartTime(by: -15)
              }
              .font(.caption2)
              .buttonStyle(BorderedButtonStyle())
            }
          }
          
          // 終了時間
          HStack {
            Text("終了時間")
              .frame(width: 80, alignment: .leading)
            
            DatePicker("", selection: $viewModel.endTime, displayedComponents: [.date, .hourAndMinute])
              .datePickerStyle(CompactDatePickerStyle())
            
            VStack(spacing: 2) {
              Button("+15分") {
                viewModel.adjustEndTime(by: 15)
              }
              .font(.caption2)
              .buttonStyle(BorderedButtonStyle())
              
              Button("-15分") {
                viewModel.adjustEndTime(by: -15)
              }
              .font(.caption2)
              .buttonStyle(BorderedButtonStyle())
            }
          }
        }
        
        Spacer()
          .frame(height: 20)
        
        Section {
          HStack {
            Text("計算結果")
              .frame(width: 80, alignment: .leading)
            
            Text(viewModel.formattedDuration)
              .font(.headline)
              .foregroundColor(viewModel.isValidTimeRange ? .primary : .red)
            
            Spacer()
          }
          
          if !viewModel.isValidTimeRange {
            if let validationError = viewModel.validateTimeRange() {
              Text(validationError)
                .font(.caption)
                .foregroundColor(.red)
            }
          }
        }.padding(.top, 4)
      }
      .padding()
      .alert("レコードを削除", isPresented: $viewModel.showingDeleteAlert) {
        Button("キャンセル", role: .cancel) {}
        Button("削除", role: .destructive) {
          viewModel.deleteRecord()
          dismiss()
        }
      } message: {
        VStack(alignment: .leading, spacing: 4) {
          if let record = viewModel.editingRecord {
            Text("このレコードを削除しますか？")
            Text("案件: \(record.displayProjectName)")
            Text("作業区分: \(record.displayJobName)")
            Text("時間: \(formatTimeOnly(record.startTime)) 〜 \(formatTimeOnly(record.endTime ?? Date()))")
          }
        }
      }
      .alert("エラー", isPresented: .constant(viewModel.errorMessage != nil)) {
        Button("OK") {
          viewModel.clearError()
        }
      } message: {
        Text(viewModel.errorMessage ?? "")
      }
    }
    .frame(width: 500, height: 400)
    .fixedSize()
    .onDisappear {
      if !viewModel.showingEditSheet {
        viewModel.cancel()
      }
    }
  }
}

// MARK: - Preview

#if DEBUG
struct EditHistorySheetView_Previews: PreviewProvider {
  static var previews: some View {
    let mockProjectRepo = MockProjectRepository(withSampleData: true)
    let mockProjects = try! mockProjectRepo.fetchProjects()
    let mockTimeRecordRepo = MockTimeRecordRepository(projects: mockProjects, withSampleData: true)
    let mockJobRepo = MockJobRepository()

    let viewModel = EditHistoryViewModel(
      timeRecordRepository: mockTimeRecordRepo,
      projectRepository: mockProjectRepo,
      jobRepository: mockJobRepo
    )
    
    // サンプルレコードを設定
    if let sampleRecord = try? mockTimeRecordRepo.fetchTimeRecords(
      for: Project?.none,
      from: Calendar.current.startOfDay(for: Date()),
      to: Date()
    ).first {
      viewModel.startEditing(sampleRecord)
    }
    
    return EditHistorySheetView(viewModel: viewModel)
      .previewLayout(.sizeThatFits)
  }
}
#endif
