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
                    .fill(getProjectColor(from: projectColor))
                    .frame(width: 16, height: 16)

                VStack(alignment: .leading, spacing: 2) {
                    Text(projectName)
                        .font(.headline)
                    Text(jobName)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                VStack(alignment: .trailing) {
                    Text(formatDuration(duration))
                        .font(.title3)
                        .fontWeight(.semibold)
                    Text("\(Int(round(percentage)))%")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Button(action: {
                    Task {
                        let pasteboard = NSPasteboard.general
                        pasteboard.clearContents()
                        pasteboard.setString(command, forType: .string)

                        await MainActor.run {
                            showCopiedFeedback = true
                        }

                        try? await Task.sleep(nanoseconds: 2_000_000_000)

                        await MainActor.run {
                            showCopiedFeedback = false
                        }
                    }
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: showCopiedFeedback ? "checkmark" : "doc.on.clipboard")
                            .foregroundColor(showCopiedFeedback ? .green : .secondary)
                            .font(.caption)
                        if showCopiedFeedback {
                            Text("完了")
                                .font(.caption2)
                                .foregroundColor(.green)
                        }
                    }
                }
                .buttonStyle(.borderless)
                .help(showCopiedFeedback ? "コピーしました" : "コマンドをクリップボードにコピー")
                .animation(.easeInOut(duration: 0.3), value: showCopiedFeedback)
            }

            ProgressView(value: percentage, total: 100)
                .progressViewStyle(LinearProgressViewStyle(tint: getProjectColor(from: projectColor)))
        }
        .padding()
        .background(Color(nsColor: .controlBackgroundColor))
        .cornerRadius(8)
    }
}
