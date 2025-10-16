//
//  Utils.swift
//  TimeRabbit
//
//  Created by Takumi Ikeda on 2025/07/30.
//

import Foundation
import SwiftData
import SwiftUI

// MARK: - Date and Time Formatting Utilities

func formatDuration(_ duration: TimeInterval) -> String {
  let hours = Int(duration) / 3600
  let minutes = Int(duration) % 3600 / 60
  let seconds = Int(duration) % 60

  if hours > 0 {
    return String(format: "%d:%02d:%02d", hours, minutes, seconds)
  } else {
    return String(format: "%02d:%02d", minutes, seconds)
  }
}

func formatTime(_ date: Date) -> String {
  let formatter = DateFormatter()
  formatter.timeStyle = .short
  formatter.locale = Locale(identifier: "ja_JP")
  return formatter.string(from: date)
}

func formatTimeOnly(_ date: Date) -> String {
  let formatter = DateFormatter()
  formatter.dateFormat = "HH:mm"
  return formatter.string(from: date)
}

func formatDate(_ date: Date) -> String {
  let formatter = DateFormatter()
  formatter.dateStyle = .medium
  formatter.locale = Locale(identifier: "ja_JP")
  return formatter.string(from: date)
}

// MARK: - Color Utility

/// プロジェクトの色名をSwiftUIのColorに変換するユーティリティ関数
func getProjectColor(from colorName: String) -> Color {
  switch colorName {
  case "blue": return .blue
  case "green": return .green
  case "red": return .red
  case "orange": return .orange
  case "purple": return .purple
  case "pink": return .pink
  case "yellow": return .yellow
  default: return .blue
  }
}
