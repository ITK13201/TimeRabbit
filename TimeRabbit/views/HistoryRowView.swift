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
                .fill(getProjectColor(from: self.record.displayProjectColor))
                .frame(width: 12, height: 12)

            // プロジェクト名と作業区分
            VStack(alignment: .leading, spacing: 4) {
                Text(self.record.displayProjectName)
                    .font(.headline)
                Text(self.record.displayJobName)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .frame(minWidth: 120, alignment: .leading)

            Spacer()

            // 時間情報
            VStack(alignment: .trailing, spacing: 2) {
                HStack(spacing: 4) {
                    Text(formatTimeOnly(self.record.startTime))
                    Text("〜")
                        .foregroundColor(.secondary)
                    Text(formatTimeOnly(self.record.endTime ?? Date()))
                }
                .font(.subheadline)
                .foregroundColor(.primary)

                Text(formatDuration(self.record.duration))
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
            }

            // 編集ボタン
            Button(action: {
                self.onEdit(self.record)
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
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(self.record.endTime == nil ? Color.green.opacity(0.1) : Color(nsColor: .controlBackgroundColor))
        .cornerRadius(8)
        .contextMenu {
            Button("編集") {
                self.onEdit(self.record)
            }

            // 作業中のレコードは削除不可
            if self.record.endTime != nil {
                Divider()

                Button("削除", role: .destructive) {
                    self.onDelete(self.record)
                }
            }
        }
    }
}
