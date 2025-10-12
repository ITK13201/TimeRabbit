# 履歴編集機能 設計書

## 概要
ユーザーが間違って打刻した際に、履歴データを編集できる機能を追加する。

## 要件

### 機能要件
1. **履歴レコードの編集**
   - 開始時間の編集
   - 終了時間の編集
   - プロジェクトの変更
   - レコードの削除

2. **編集可能な条件**
   - 完了済み（endTimeがある）レコードのみ編集可能
   - 進行中のレコードは編集不可（停止後に編集可能）

3. **バリデーション**
   - 開始時間 < 終了時間
   - 他のレコードとの時間重複チェック
   - 未来の時間の入力制限

### 非機能要件
1. **ユーザビリティ**
   - 直感的なUI/UX
   - エラーメッセージの適切な表示
   - 操作のキャンセル機能

2. **データ整合性**
   - 編集前後のデータ整合性保証
   - トランザクション処理

## UI/UX設計

### 編集トリガー
- **HistoryRowView**に編集ボタンを追加
- 長押しでコンテキストメニュー表示（編集・削除）

### 編集モーダル
```text
┌─────────────────────────────┐
│        履歴レコード編集       │
├─────────────────────────────┤
│ プロジェクト: [ドロップダウン] │
│ 開始時間:    [DatePicker]    │
│ 終了時間:    [DatePicker]    │
│ 作業時間:    [2時間30分]     │
├─────────────────────────────┤
│  [キャンセル]     [保存]     │
└─────────────────────────────┘
```

### 削除確認ダイアログ
```text
┌─────────────────────────────┐
│          確認              │
├─────────────────────────────┤
│ このレコードを削除しますか？  │
│ プロジェクト: Webアプリ開発   │
│ 時間: 14:00 〜 16:30        │
├─────────────────────────────┤
│  [キャンセル]     [削除]     │
└─────────────────────────────┘
```

## アーキテクチャ設計

### 1. ViewModel追加
```swift
// 新規ViewModel
@MainActor
class EditHistoryViewModel: BaseViewModel {
  @Published var editingRecord: TimeRecord?
  @Published var selectedProject: Project?
  @Published var startTime: Date
  @Published var endTime: Date
  @Published var showingEditSheet = false
  @Published var showingDeleteAlert = false
  
  // バリデーション
  var isValidTimeRange: Bool
  var calculatedDuration: TimeInterval
  
  // アクション
  func startEditing(_ record: TimeRecord)
  func saveChanges()
  func deleteRecord()
  func cancel()
}
```

### 2. Repository拡張
```swift
// TimeRecordRepositoryProtocolに追加
extension TimeRecordRepositoryProtocol {
  func updateTimeRecord(_ record: TimeRecord, 
                       startTime: Date, 
                       endTime: Date, 
                       project: Project) throws
  
  func validateTimeRange(startTime: Date, 
                        endTime: Date, 
                        excludingRecord: TimeRecord?) throws -> Bool
}
```

### 3. View構造
```
HistoryView
├── HistoryRowView (既存)
│   ├── 編集ボタン追加
│   └── コンテキストメニュー追加
├── EditHistorySheet (新規)
│   ├── ProjectPicker
│   ├── DateTimePicker (開始)
│   ├── DateTimePicker (終了)
│   └── 保存・キャンセルボタン
└── 削除確認Alert (新規)
```

## 実装フェーズ

### Phase 1: Repository層の拡張
1. `TimeRecordRepository`に更新メソッド追加
2. `MockTimeRecordRepository`にモック実装
3. バリデーション機能の実装

### Phase 2: EditHistoryViewModel作成
1. BaseViewModelを継承
2. 編集状態管理
3. バリデーション機能
4. CRUD操作

### Phase 3: UI実装
1. `HistoryRowView`に編集ボタン追加
2. `EditHistorySheet`作成
3. プロジェクト選択UI
4. 日時選択UI

### Phase 4: ViewModel統合
1. `HistoryViewModel`に編集機能統合
2. `EditHistoryViewModel`との連携
3. データ更新の連鎖処理

### Phase 5: テスト・調整
1. エッジケースのテスト
2. バリデーション確認
3. UI/UXの調整

## データフロー

### 編集開始
```
HistoryRowView
  ↓ (編集ボタンタップ)
HistoryViewModel
  ↓ (レコード情報を渡す)
EditHistoryViewModel
  ↓ (編集シート表示)
EditHistorySheet
```

### 保存処理
```
EditHistorySheet
  ↓ (保存ボタンタップ)
EditHistoryViewModel
  ↓ (バリデーション)
TimeRecordRepository
  ↓ (データ更新)
Database
  ↓ (更新通知)
HistoryViewModel
  ↓ (UI更新)
HistoryView
```

## バリデーション仕様

### 時間範囲チェック
- 開始時間 < 終了時間
- 開始時間・終了時間 ≤ 現在時刻
- 最小作業時間: 1分
- 最大作業時間: 24時間

### 重複チェック
- 同じ時間帯に他のレコードが存在しないこと
- 編集中のレコード自身は除外

### プロジェクトチェック
- 存在するプロジェクトのみ選択可能
- 削除済みプロジェクトの場合は警告表示

## エラーハンドリング

### バリデーションエラー
- `開始時間が終了時間より後です`
- `他のレコードと時間が重複しています`
- `未来の時間は設定できません`

### システムエラー
- `データの更新に失敗しました`
- `プロジェクト情報の取得に失敗しました`

## セキュリティ・制約

### 編集制限
- 完了済みレコードのみ編集可能
- 作成から72時間以内のレコードのみ編集可能（オプション）

### データ整合性
- トランザクション処理でデータ整合性を保証
- 楽観的排他制御（必要に応じて）

## 今後の拡張可能性

### 追加機能案
1. **バッチ編集**: 複数レコードの一括編集
2. **編集履歴**: 変更履歴の記録・表示
3. **承認機能**: 編集の承認フロー
4. **インポート/エクスポート**: CSV等での一括編集

### パフォーマンス最適化
1. **遅延読み込み**: 大量データの処理最適化
2. **キャッシュ戦略**: 編集頻度の高いデータのキャッシュ
3. **差分更新**: 変更箇所のみ更新

## 実装優先度

### High Priority
- [P1] Repository層の基本的な更新機能
- [P1] EditHistoryViewModel実装
- [P1] 基本的な編集UI（時間・プロジェクト）

### Medium Priority  
- [P2] 高度なバリデーション
- [P2] UX向上（コンテキストメニュー等）
- [P2] エラーハンドリング強化

### Low Priority
- [P3] 編集制限機能
- [P3] パフォーマンス最適化
- [P3] 将来の拡張機能

---

**作成日**: 2025-08-09  
**バージョン**: 1.0  
**ステータス**: 設計中