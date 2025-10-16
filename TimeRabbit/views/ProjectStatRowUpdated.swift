//
//  ProjectStatRowUpdated.swift
//  TimeRabbit
//
//  Created by Takumi Ikeda on 2025/08/09.
//

import AppKit
import Foundation
import SwiftData
import SwiftUI

struct ProjectStatRowUpdated: View {
  let projectName: String
  let jobName: String
  let projectColor: String
  let duration: TimeInterval
  let percentage: Double
  let command: String

  @State private var showCopiedFeedback = false

  var body: some View {
    VStack(alignment: .leading, spacing: 8) {
      HStack {
        Circle()
          .fill(getProjectColor(from: self.projectColor))
          .frame(width: 16, height: 16)

        VStack(alignment: .leading, spacing: 2) {
          Text(self.projectName)
            .font(.headline)
          Text(self.jobName)
            .font(.caption)
            .foregroundColor(.secondary)
        }

        Spacer()

        VStack(alignment: .trailing) {
          Text(formatDuration(self.duration))
            .font(.title3)
            .fontWeight(.semibold)
          Text("\(Int(round(self.percentage)))%")
            .font(.caption)
            .foregroundColor(.secondary)
        }

        Button(action: {
          Task {
            let pasteboard = NSPasteboard.general
            pasteboard.clearContents()
            pasteboard.setString(self.command, forType: .string)

            await MainActor.run {
              self.showCopiedFeedback = true
            }

            try? await Task.sleep(nanoseconds: 2_000_000_000)

            await MainActor.run {
              self.showCopiedFeedback = false
            }
          }
        }) {
          HStack(spacing: 4) {
            Image(systemName: self.showCopiedFeedback ? "checkmark" : "doc.on.clipboard")
              .foregroundColor(self.showCopiedFeedback ? .green : .secondary)
              .font(.caption)
            if self.showCopiedFeedback {
              Text("完了")
                .font(.caption2)
                .foregroundColor(.green)
            }
          }
        }
        .buttonStyle(.borderless)
        .help(self.showCopiedFeedback ? "コピーしました" : "コマンドをクリップボードにコピー")
        .animation(.easeInOut(duration: 0.3), value: self.showCopiedFeedback)
      }

      ProgressView(value: self.percentage, total: 100)
        .progressViewStyle(LinearProgressViewStyle(tint: getProjectColor(from: self.projectColor)))
    }
    .padding()
    .background(Color(nsColor: .controlBackgroundColor))
    .cornerRadius(8)
  }
}
