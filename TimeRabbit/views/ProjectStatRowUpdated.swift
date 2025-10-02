//
//  ProjectStatRowUpdated.swift
//  TimeRabbit
//
//  Created by Takumi Ikeda on 2025/08/09.
//

import Foundation
import SwiftData
import SwiftUI

struct ProjectStatRowUpdated: View {
  let projectName: String
  let jobName: String
  let projectColor: String
  let duration: TimeInterval
  let percentage: Double

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
          Text("\(Int(percentage))%")
            .font(.caption)
            .foregroundColor(.secondary)
        }
      }

      ProgressView(value: percentage, total: 100)
        .progressViewStyle(LinearProgressViewStyle(tint: getProjectColor(from: projectColor)))
    }
    .padding()
    .background(Color(nsColor: .controlBackgroundColor))
    .cornerRadius(8)
  }
}