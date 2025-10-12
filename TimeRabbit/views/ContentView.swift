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
        _viewModel = StateObject(wrappedValue: viewModelFactory.createContentViewModel())
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

                        if self.viewModel.isTracking() {
                            VStack(alignment: .center, spacing: 4) {
                                Text(self.viewModel.getCurrentProjectName())
                                    .font(.title2)
                                    .foregroundColor(getProjectColor(from: self.viewModel.getCurrentProjectColor()))
                                    .lineLimit(1)

                                Text("[作業区分: \(self.viewModel.getCurrentJobName())]")
                                    .font(.caption)
                                    .foregroundColor(.secondary)

                                Text(formatDuration(self.viewModel.getCurrentDuration()))
                                    .font(.title)
                                    .fontWeight(.bold)
                                    .foregroundColor(.primary)

                                if let startTime = viewModel.getCurrentStartTime() {
                                    Text("開始時間: \(formatTime(startTime))")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }

                                Button("停止") {
                                    self.viewModel.stopTracking()
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
                        Button(action: { self.viewModel.showAddProject() }) {
                            Image(systemName: "plus")
                        }
                    }

                    if self.viewModel.projects.isEmpty {
                        Text("プロジェクトがありません")
                            .foregroundColor(.secondary)
                    } else {
                        ForEach(self.viewModel.projectRowViewModels, id: \.project.id) { projectRowViewModel in
                            ProjectRowView(viewModel: projectRowViewModel)
                        }
                    }
                }

                Spacer()
            }
            .padding()
            .frame(minWidth: 400)
        } detail: {
            // Main content
            MainContentView(viewModel: self.viewModel.mainContentViewModel)
        }
        .navigationTitle("TimeRabbit")
        .sheet(isPresented: self.$viewModel.showingAddProject) {
            AddProjectSheetView(viewModel: self.viewModel.addProjectViewModel)
        }
        .alert("エラー", isPresented: .constant(self.viewModel.errorMessage != nil)) {
            Button("OK") {
                self.viewModel.clearError()
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
        .frame(width: 1000, height: 700)
}

#Preview("with sample data") {
    let mockProjectRepo = MockProjectRepository(withSampleData: true)
    let projects = try! mockProjectRepo.fetchProjects()
    let mockTimeRecordRepo = MockTimeRecordRepository(projects: projects, withSampleData: true)
    let mockJobRepo = MockJobRepository()
    let factory = ViewModelFactory.create(with: (mockProjectRepo, mockTimeRecordRepo, mockJobRepo))
    ContentView(viewModelFactory: factory)
        .frame(width: 1000, height: 700)
}
