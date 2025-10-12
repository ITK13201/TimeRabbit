//
//  ProjectRowView.swift
//  TimeRabbit
//
//  Created by Takumi Ikeda on 2025/08/09.
//

import Foundation
import SwiftData
import SwiftUI

struct ProjectRowView: View {
    @StateObject private var viewModel: ProjectRowViewModel

    init(viewModel: ProjectRowViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(getProjectColor(from: viewModel.project.color))
                .frame(width: 12, height: 12)

            VStack(alignment: .leading, spacing: 2) {
                Text(viewModel.project.projectId)
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text(viewModel.project.name)
                    .foregroundColor(viewModel.isActive ? .primary : .secondary)
            }
            .fixedSize(horizontal: true, vertical: false)

            Spacer()

            // 作業区分選択プルダウン
            if !viewModel.isActive {
                Picker(selection: $viewModel.selectedJob) {
                    ForEach(viewModel.availableJobs, id: \.id) { job in
                        Text(job.name)
                            .tag(job as Job?)
                    }
                } label: {
                    EmptyView()
                }
                .pickerStyle(.menu)
                .frame(width: 120)
                .onChange(of: viewModel.selectedJob) { _, newJob in
                    if let newJob = newJob {
                        viewModel.updateSelectedJob(newJob)
                    }
                }
            } else {
                Text("作業中: \(viewModel.selectedJob?.name ?? "")")
                    .foregroundColor(.green)
                    .lineLimit(1)
                    .frame(width: 100, alignment: .leading)
            }

            if viewModel.isActive {
                Button("実行中") {
                    // Already active
                }
                .buttonStyle(.borderless)
                .foregroundColor(.green)
                .disabled(true)
                .frame(width: 50)
            } else {
                Button("開始") {
                    viewModel.startTracking()
                }
                .buttonStyle(.borderless)
                .disabled(viewModel.selectedJob == nil)
                .frame(width: 30)
            }

            Button(action: {
                viewModel.deleteProject()
            }) {
                Image(systemName: "trash")
                    .foregroundColor(.red)
            }
            .buttonStyle(.borderless)
            .frame(width: 20)
        }
        .padding(.vertical, 4)
    }
}
