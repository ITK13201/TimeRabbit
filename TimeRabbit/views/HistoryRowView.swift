//
//  HistoryRowView.swift
//  TimeRabbit
//
//  Created by Takumi Ikeda on 2025/08/09.
//

import Foundation
import SwiftData
import SwiftUI

struct HistoryRowView: View {
  let record: TimeRecord
  let onEdit: (TimeRecord) -> Void
  let onDelete: (TimeRecord) -> Void

  var body: some View {
    HStack(spacing: 12) {
      // プロジェクト色
      Circle()
        .fill(getProjectColor(from: record.displayProjectColor))
        .frame(width: 12, height: 12)

      // プロジェクト名
      Text(record.displayProjectName)
        .font(.headline)
        .frame(minWidth: 120, alignment: .leading)

      Spacer()

      // 時間情報
      VStack(alignment: .trailing, spacing: 2) {
        HStack(spacing: 4) {
          Text(formatTimeOnly(record.startTime))
          Text("〜")
            .foregroundColor(.secondary)
          Text(formatTimeOnly(record.endTime ?? Date()))
        }
        .font(.subheadline)
        .foregroundColor(.primary)

        Text(formatDuration(record.duration))
          .font(.caption)
          .fontWeight(.medium)
          .foregroundColor(.secondary)
      }
      
      // 編集ボタン
      if record.endTime != nil {
        Button(action: {
          onEdit(record)
        }) {
          Image(systemName: "pencil")
            .font(.system(size: 14, weight: .medium))
            .foregroundColor(.secondary)
            .frame(width: 40, height: 40)
            .background(Color.secondary.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .buttonStyle(PlainButtonStyle())
        .contentShape(Rectangle())
      }
    }
    .padding(.horizontal, 16)
    .padding(.vertical, 12)
    .background(Color(nsColor: .controlBackgroundColor))
    .cornerRadius(8)
    .contextMenu {
      if record.endTime != nil {
        Button("編集") {
          onEdit(record)
        }
        
        Divider()
        
        Button("削除", role: .destructive) {
          onDelete(record)
        }
      }
    }
  }
}