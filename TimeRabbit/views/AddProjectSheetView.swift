//
//  AddProjectSheetView.swift
//  TimeRabbit
//
//  Created by Takumi Ikeda on 2025/08/09.
//

import Foundation
import SwiftData
import SwiftUI

struct AddProjectSheetView: View {
  @StateObject private var viewModel: AddProjectViewModel
  
  init(viewModel: AddProjectViewModel) {
    self._viewModel = StateObject(wrappedValue: viewModel)
  }

  var body: some View {
    VStack(alignment: .leading, spacing: 16) {
      Text("新しいプロジェクト")
        .font(.title2)
        .fontWeight(.bold)

      VStack(alignment: .leading, spacing: 8) {
        Text("プロジェクト名")
        TextField("プロジェクト名を入力", text: $viewModel.projectName)
          .textFieldStyle(.roundedBorder)
      }

      VStack(alignment: .leading, spacing: 8) {
        Text("色")
        HStack {
          ForEach(viewModel.availableColors, id: \.self) { color in
            Button(action: { viewModel.selectColor(color) }) {
              Circle()
                .fill(getProjectColor(from: color))
                .frame(width: 24, height: 24)
                .overlay(
                  Circle()
                    .stroke(viewModel.isColorSelected(color) ? Color.primary : Color.clear, lineWidth: 2)
                )
            }
            .buttonStyle(.plain)
          }
        }
      }

      HStack {
        Button("キャンセル") {
          viewModel.cancel()
        }
        Spacer()
        Button("作成") {
          viewModel.createProject()
        }
        .disabled(!viewModel.isFormValid)
        .buttonStyle(.borderedProminent)
      }
    }
    .padding()
    .frame(width: 300)
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