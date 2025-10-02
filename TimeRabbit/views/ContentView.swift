//
//  ContentView.swift
//  TimeRabbit
//
//  Created by Takumi Ikeda on 2025/07/29.
//

import Foundation
import SwiftData
import SwiftUI

struct ContentView: View {
  @StateObject private var viewModel: ContentViewModel

  init(viewModelFactory: ViewModelFactory) {
    self._viewModel = StateObject(wrappedValue: viewModelFactory.createContentViewModel())
  }

  var body: some View {
    NavigationSplitView {
      // Sidebar
      VStack(alignment: .leading, spacing: 16) {
        // Current tracking section
        HStack {
          Spacer()
          VStack(alignment: .center, spacing: 8) {
            Text("現在の作業")
              .font(.headline)

            if viewModel.isTracking() {
              VStack(alignment: .center, spacing: 4) {
                Text(viewModel.getCurrentProjectName())
                  .font(.title2)
                  .foregroundColor(getProjectColor(from: viewModel.getCurrentProjectColor()))
                  .lineLimit(1)
                  
                Text("[作業区分: \(viewModel.getCurrentJobName())]")
                  .font(.caption)
                  .foregroundColor(.secondary)

                Text(formatDuration(viewModel.getCurrentDuration()))
                  .font(.title)
                  .fontWeight(.bold)
                  .foregroundColor(.primary)

                if let startTime = viewModel.getCurrentStartTime() {
                  Text("開始時間: \(formatTime(startTime))")
                    .font(.caption)
                    .foregroundColor(.secondary)
                }

                Button("停止") {
                  viewModel.stopTracking()
                }
                .buttonStyle(.borderedProminent)
              }
              .frame(minWidth: 180, minHeight: 120)
              .padding()
              .background(Color(nsColor: .controlBackgroundColor))
              .cornerRadius(8)
            } else {
              Text("作業中のプロジェクトはありません")
                .foregroundColor(.secondary)
                .frame(minWidth: 180, minHeight: 120)
                .multilineTextAlignment(.center)
                .padding()
                .background(Color(nsColor: .controlBackgroundColor))
                .cornerRadius(8)
            }
          }
          Spacer()
        }

        Divider()

        // Projects section
        VStack(alignment: .leading, spacing: 8) {
          HStack {
            Text("プロジェクト")
              .font(.headline)
            Spacer()
            Button(action: { viewModel.showAddProject() }) {
              Image(systemName: "plus")
            }
          }

          if viewModel.projects.isEmpty {
            Text("プロジェクトがありません")
              .foregroundColor(.secondary)
          } else {
            ForEach(viewModel.projectRowViewModels, id: \.project.id) { projectRowViewModel in
              ProjectRowView(viewModel: projectRowViewModel)
            }
          }
        }

        Spacer()
      }
      .padding()
      .frame(minWidth: 250)
    } detail: {
      // Main content
      MainContentView(viewModel: viewModel.mainContentViewModel)
    }
    .navigationTitle("TimeRabbit")
    .sheet(isPresented: $viewModel.showingAddProject) {
      AddProjectSheetView(viewModel: viewModel.addProjectViewModel)
    }
    .alert("エラー", isPresented: .constant(viewModel.errorMessage != nil)) {
      Button("OK") {
        viewModel.clearError()
      }
    } message: {
      if let error = viewModel.errorMessage {
        Text(error)
      }
    }
  }
}

#Preview {
  let mockProjectRepo = MockProjectRepository()
  let projects = try! mockProjectRepo.fetchProjects()
  let mockTimeRecordRepo = MockTimeRecordRepository(projects: projects)
  let mockJobRepo = MockJobRepository()
  let factory = ViewModelFactory.create(with: (mockProjectRepo, mockTimeRecordRepo, mockJobRepo))
  ContentView(viewModelFactory: factory)
}

#Preview("with sample data") {
  let mockProjectRepo = MockProjectRepository(withSampleData: true)
  let projects = try! mockProjectRepo.fetchProjects()
  let mockTimeRecordRepo = MockTimeRecordRepository(projects: projects, withSampleData: true)
  let mockJobRepo = MockJobRepository()
  let factory = ViewModelFactory.create(with: (mockProjectRepo, mockTimeRecordRepo, mockJobRepo))
  ContentView(viewModelFactory: factory)
}
