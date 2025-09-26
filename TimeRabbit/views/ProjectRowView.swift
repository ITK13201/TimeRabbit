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
    self._viewModel = StateObject(wrappedValue: viewModel)
  }

  var body: some View {
    HStack {
      Circle()
        .fill(getProjectColor(from: viewModel.project.color))
        .frame(width: 12, height: 12)

      Text(viewModel.project.name)
        .foregroundColor(viewModel.isActive ? .primary : .secondary)

      Spacer()

      if viewModel.isActive {
        Button("実行中") {
          // Already active
        }
        .buttonStyle(.borderless)
        .foregroundColor(.green)
        .disabled(true)
      } else {
        Button("開始") {
          viewModel.startTracking()
        }
        .buttonStyle(.borderless)
      }

      Button(action: {
        viewModel.deleteProject()
      }) {
        Image(systemName: "trash")
          .foregroundColor(.red)
      }
      .buttonStyle(.borderless)
    }
    .padding(.vertical, 4)
  }
}