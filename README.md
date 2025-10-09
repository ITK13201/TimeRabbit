# TimeRabbit

macOS向けのシンプルで直感的な時間記録アプリケーション。プロジェクトと作業区分ごとに時間を追跡し、日次統計を確認できます。

[![Release](https://img.shields.io/github/v/release/ITK13201/TimeRabbit)](https://github.com/ITK13201/TimeRabbit/releases/latest)
[![CI](https://github.com/ITK13201/TimeRabbit/actions/workflows/ci.yml/badge.svg)](https://github.com/ITK13201/TimeRabbit/actions/workflows/ci.yml)
[![License](https://img.shields.io/github/license/ITK13201/TimeRabbit)](LICENSE)

## 特徴

- **プロジェクト管理**: カラーコード付きでプロジェクトを作成・管理
- **作業区分**: 5つの固定作業カテゴリ（開発、保守、POサポート・コンサル、デザイン、その他）
- **時間記録**: プロジェクトと作業区分の組み合わせで時間を記録
- **日次統計**: プロジェクト×作業区分ごとの時間内訳とパーセンテージ
- **データエクスポート**: 統計データをMarkdown形式でコピー可能
- **履歴管理**: 過去の作業記録の表示・編集
- **データ永続化**: SwiftDataによる安全なローカルデータ保存

## スクリーンショット

（TODO: スクリーンショットを追加）

## システム要件

- macOS 14.0以降
- Apple Silicon (arm64) または Intel (x86_64)

## インストール

### 方法1: リリースパッケージからインストール（推奨）

1. [最新リリース](https://github.com/ITK13201/TimeRabbit/releases/latest)から`TimeRabbit-X.X.X.zip`または`TimeRabbit-X.X.X.dmg`をダウンロード
2. ZIPファイルを展開するか、DMGファイルをマウント
3. `TimeRabbit.app`をApplicationsフォルダに移動
4. **重要**: 初回起動時にGatekeeperの警告が表示される場合は、以下の手順を実行してください

#### macOS Gatekeeperの警告について

このアプリケーションはApple Developer証明書で署名されていないため、初回起動時に警告が表示される場合があります。

**解決方法1: 隔離属性の削除（推奨）**
```bash
xattr -cr /Applications/TimeRabbit.app
```

**解決方法2: システム設定から開く（macOS Ventura以降）**
1. アプリを開こうとする（エラーが表示される）
2. **システム設定** → **プライバシーとセキュリティ** を開く
3. **セキュリティ**セクションまでスクロール
4. TimeRabbitの隣にある**「このまま開く」**をクリック
5. 確認ダイアログで**「開く」**をクリック

### 方法2: ソースからビルド

```bash
# リポジトリをクローン
git clone https://github.com/ITK13201/TimeRabbit.git
cd TimeRabbit

# Xcodeでプロジェクトを開く
open TimeRabbit.xcodeproj

# または、コマンドラインからビルド
xcodebuild -project TimeRabbit.xcodeproj -scheme TimeRabbit -destination 'platform=macOS' build
```

**要件:**
- Xcode 16.1以降
- macOS 15以降（ビルド環境）

## 使い方

### プロジェクトの作成

1. 左サイドバーの**「案件を追加」**ボタンをクリック
2. プロジェクトID（3-20文字）と名前を入力
3. カラーを選択
4. **「追加」**をクリック

### 時間記録の開始

1. サイドバーでプロジェクトを選択
2. 作業区分（開発、保守など）を選択
3. **「開始」**ボタンをクリック
4. 作業完了後、**「停止」**ボタンをクリック

### 統計の確認

1. メイン画面の**「統計」**タブを選択
2. 日付ピッカーで確認したい日付を選択
3. プロジェクト×作業区分ごとの時間とパーセンテージが表示されます
4. 各行の**「コピー」**ボタンで、Markdown形式のコマンドをクリップボードにコピー可能

### 履歴の確認・編集

1. メイン画面の**「履歴」**タブを選択
2. 日付ピッカーで確認したい日付を選択
3. 記録をクリックして詳細を表示
4. **「編集」**ボタンで開始時刻、終了時刻、プロジェクト、作業区分を変更可能

## 開発

### プロジェクト構成

TimeRabbitは**1:1 View-ViewModel MVVM パターン**とリポジトリレイヤーを採用しています：

```
TimeRabbit/
├── TimeRabbitApp.swift         # アプリエントリーポイント
├── Models.swift                # SwiftDataモデル（Project, Job, TimeRecord）
├── repositories/               # データ永続化層
│   ├── ProjectRepository.swift
│   ├── TimeRecordRepository.swift
│   ├── JobRepository.swift
│   └── Mock*.swift            # テスト・プレビュー用
├── viewmodels/                # プレゼンテーション層
│   ├── base/
│   │   ├── BaseViewModel.swift
│   │   └── ViewModelFactory.swift
│   └── *.swift                # 各画面のViewModel
└── views/                     # UI層
    └── *.swift                # SwiftUIビュー
```

詳細なアーキテクチャ情報は[CLAUDE.md](CLAUDE.md)を参照してください。

### ビルド

```bash
# プロジェクトをビルド
xcodebuild -project TimeRabbit.xcodeproj -scheme TimeRabbit -destination 'platform=macOS' build

# ユニットテストを実行
xcodebuild test -project TimeRabbit.xcodeproj -scheme TimeRabbit -destination 'platform=macOS' -testPlan TimeRabbitTests
```

### Git Commit規約

すべてのコミットメッセージは以下の形式に従います：

```
#[issue_number] [type]: [message]
```

**タイプ:**
- `feature`: 新機能実装
- `bugfix`: バグ修正
- `hotfix`: 緊急修正
- `docs`: ドキュメント変更
- `refactor`: リファクタリング
- `test`: テスト関連
- `chore`: ビルドプロセスやツールの変更

**例:**
```
#5 bugfix: Fix macOS Gatekeeper error with improved release notes
#12 feature: Add project color customization
```

### Issue・PR規約

- **すべてのGitHub IssueとPull Requestは日本語で記載してください**
- コミットメッセージは英語規約に従います

## ライセンス

このプロジェクトはMITライセンスの下で公開されています。詳細は[LICENSE](LICENSE)ファイルを参照してください。

## 貢献

貢献を歓迎します！以下の手順でご協力ください：

1. このリポジトリをフォーク
2. 機能ブランチを作成（`git checkout -b feature/#XX-amazing-feature`）
3. 変更をコミット（`git commit -m '#XX feature: Add amazing feature'`）
4. ブランチをプッシュ（`git push origin feature/#XX-amazing-feature`）
5. Pull Requestを作成（日本語で記載）

詳細な開発ガイドラインは[CLAUDE.md](CLAUDE.md)を参照してください。

## サポート

- **バグ報告**: [Issues](https://github.com/ITK13201/TimeRabbit/issues)で報告してください（日本語可）
- **機能リクエスト**: [Issues](https://github.com/ITK13201/TimeRabbit/issues)で提案してください（日本語可）
- **ドキュメント**: [docs/](docs/)ディレクトリに詳細なドキュメントがあります

## 開発者

[@ITK13201](https://github.com/ITK13201)

## 謝辞

このプロジェクトは以下の技術を使用して構築されています：
- [SwiftUI](https://developer.apple.com/xcode/swiftui/) - UI框架
- [SwiftData](https://developer.apple.com/xcode/swiftdata/) - データ永続化
- [GitHub Actions](https://github.com/features/actions) - CI/CD

---

TimeRabbitで効率的な時間管理を始めましょう！
