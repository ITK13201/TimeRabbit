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
      Text("新しい案件")
        .font(.title2)
        .fontWeight(.bold)

      VStack(alignment: .leading, spacing: 8) {
        Text("案件ID")
        TextField("案件IDを入力", text: $viewModel.projectId)
          .textFieldStyle(.roundedBorder)
        
        if !viewModel.idValidationMessage.isEmpty {
          Text(viewModel.idValidationMessage)
            .font(.caption)
            .foregroundColor(.red)
        }
      }
      
      VStack(alignment: .leading, spacing: 8) {
        Text("案件名")
        TextField("案件名を入力", text: $viewModel.projectName)
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
        .disabled(!viewModel.isFormValid || !viewModel.isIdValid)
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