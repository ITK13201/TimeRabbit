# TimeRabbit ディレクトリ構成

**最終更新**: 2025年10月12日

---

## プロジェクト全体構成

```text
TimeRabbit/
├── .github/                    # GitHub Actions CI/CD
│   └── workflows/
│       ├── ci.yml             # テストCI（PR/main pushで実行）
│       └── release.yml        # リリース自動化（タグpushで実行）
│
├── assets/                     # アプリアイコン素材
│   └── icon_*.png             # 各種サイズのアイコン
│
├── docs/                       # 設計ドキュメント
│   ├── development/           # 開発設計書
│   │   ├── architecture/      # アーキテクチャ設計（日付prefix）
│   │   ├── features/          # 機能設計（日付prefix）
│   │   └── bugfixes/          # バグ修正設計（日付prefix）
│   └── operations/            # 運用ドキュメント
│       ├── github-actions-cicd.md
│       └── release-deployment-procedure.md
│
├── scripts/                    # ビルドスクリプト
│   └── create-dmg.sh          # DMG作成スクリプト
│
├── TimeRabbit/                 # メインアプリケーション
│   ├── Assets.xcassets/       # アプリアセット
│   ├── TimeRabbitApp.swift    # アプリエントリーポイント
│   ├── Models.swift           # SwiftDataモデル
│   ├── Utils.swift            # ユーティリティ関数
│   │
│   ├── services/              # アプリケーション共通サービス
│   │   ├── DateService.swift  # 日付状態管理サービス
│   │   └── Logger.swift       # OSLogベースのロギングシステム
│   │
│   ├── repositories/          # データ永続化層
│   │   ├── ProjectRepository.swift
│   │   ├── TimeRecordRepository.swift
│   │   ├── JobRepository.swift
│   │   ├── MockProjectRepository.swift
│   │   ├── MockTimeRecordRepository.swift
│   │   └── MockJobRepository.swift
│   │
│   ├── viewmodels/            # プレゼンテーション層
│   │   ├── base/
│   │   │   ├── BaseViewModel.swift      # 共通ViewModel基盤
│   │   │   └── ViewModelFactory.swift   # 依存性注入ファクトリ
│   │   ├── ContentViewModel.swift
│   │   ├── MainContentViewModel.swift
│   │   ├── StatisticsViewModel.swift
│   │   ├── HistoryViewModel.swift
│   │   ├── EditHistoryViewModel.swift
│   │   ├── ProjectRowViewModel.swift
│   │   └── AddProjectViewModel.swift
│   │
│   └── views/                 # UI層
│       ├── ContentView.swift
│       ├── MainContentView.swift
│       ├── StatisticsView.swift
│       ├── HistoryView.swift
│       ├── HistoryRowView.swift
│       ├── EditHistorySheetView.swift
│       ├── ProjectRowView.swift
│       ├── AddProjectSheetView.swift
│       └── ProjectStatRowUpdated.swift
│
├── TimeRabbitTests/            # ユニットテスト（実行対象）
│   ├── TimeRabbitTests.swift
│   ├── EditHistoryViewModelTests.swift
│   ├── EditHistoryViewModelSimpleTests.swift
│   ├── MainContentViewModelTests.swift
│   └── StatisticsViewModelCommandTests.swift
│
├── TimeRabbitUITests/          # UIテスト（実行除外）
│
├── .swiftformat                # SwiftFormat設定ファイル
├── .gitignore                  # Git除外設定
├── TimeRabbitTests.xctestplan # テストプラン（UnitTestsのみ）
├── exportOptions.plist         # Xcodeエクスポート設定
├── CLAUDE.md                   # Claude Code向けガイド
└── README.md                   # プロジェクトREADME
```

---

## 主要ディレクトリの詳細

### `.github/workflows/` - CI/CD

- **ci.yml**: PR・main pushでユニットテストを実行
- **release.yml**: タグpushでビルド・リリースを自動化

### `docs/` - ドキュメント

#### `development/` - 開発設計書
- **architecture/**: アーキテクチャ設計書（日付prefix形式）
  - 例: `20251008-project-job-systemid-design.md`
- **features/**: 機能設計書（日付prefix形式）
  - 例: `20251003-statistics-command-export-feature.md`
- **bugfixes/**: バグ修正設計書（日付prefix形式）
  - 例: `20251009-issue5-gatekeeper-fix-design.md`

#### `operations/` - 運用ドキュメント
- **github-actions-cicd.md**: CI/CD設定詳細
- **release-deployment-procedure.md**: リリース手順書

### `TimeRabbit/` - メインアプリケーション

#### ルートレベル
- **TimeRabbitApp.swift**: アプリケーションエントリーポイント
- **Models.swift**: SwiftDataモデル定義（Project, Job, TimeRecord）
- **Utils.swift**: ユーティリティ関数（日時フォーマット、カラー管理）

#### `services/` - アプリケーション共通サービス
- **DateService.swift**: 画面間の日付状態共有サービス（Statistics/History間で同期）
- **Logger.swift**: OSLogベースの構造化ロギング（AppLogger）

#### `repositories/` - データ永続化層
- **本体実装**: `ProjectRepository`, `TimeRecordRepository`, `JobRepository`
- **Mock実装**: テスト・プレビュー用のMock版

#### `viewmodels/` - プレゼンテーション層
- **base/**: 共通基盤
  - `BaseViewModel.swift`: エラーハンドリング、ローディング状態管理
  - `ViewModelFactory.swift`: 依存性注入ファクトリ
- **各画面用ViewModel**: 1:1対応の各ViewModel

#### `views/` - UI層
- SwiftUIビュー（各ViewModelと1:1対応）

### `TimeRabbitTests/` - テスト

- **実行対象**: ユニットテストのみ（UITests除外）
- **テストプラン**: `TimeRabbitTests.xctestplan`で管理
- **Swift Testing Framework使用**

---

## ファイル命名規則

### 設計ドキュメント

**日付prefix形式（特定の開発タイミング）:**
```
YYYYMMDD-{topic}-{type}.md
```
- 例: `20251008-project-job-systemid-design.md`

**日付なし（継続更新）:**
```
{topic}.md
```
- 例: `release-deployment-procedure.md`

### コードファイル

- **ViewModel**: `{画面名}ViewModel.swift`
- **View**: `{画面名}View.swift` または `{画面名}SheetView.swift`
- **Repository**: `{モデル名}Repository.swift`
- **Mock**: `Mock{モデル名}Repository.swift`

---

## 関連ドキュメント

- [architecture-overview.md](architecture-overview.md): アーキテクチャ詳細
- [design-philosophy.md](design-philosophy.md): 設計思想
- [data-models.md](data-models.md): データモデル詳細
