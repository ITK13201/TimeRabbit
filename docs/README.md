# TimeRabbit Documentation

このディレクトリにはTimeRabbitプロジェクトの設計書・運用ドキュメントが格納されています。

---

## 📚 ドキュメント構成

```
docs/
├── guides/          # ガイド（入門・概要）
├── reference/       # リファレンス（詳細仕様）
├── design/          # 設計書（時系列）
└── operations/      # 運用ドキュメント
```

---

## 🚀 入門ガイド

プロジェクトを初めて触る方は、こちらから読み始めてください。

| ドキュメント | 説明 | 対象 |
|-------------|------|------|
| **[guides/getting-started.md](guides/getting-started.md)** | クイックスタートガイド | 新規開発者 |
| **[guides/project-overview.md](guides/project-overview.md)** | プロジェクト全体概要 | 全員 |

---

## 📖 ガイド

アーキテクチャと開発フローの理解のためのガイドドキュメント。

| ドキュメント | 説明 |
|-------------|------|
| **[guides/getting-started.md](guides/getting-started.md)** | 環境構築から最初の機能開発まで |
| **[guides/project-overview.md](guides/project-overview.md)** | プロジェクト全体概要・構成・技術スタック |
| **[guides/architecture-guide.md](guides/architecture-guide.md)** | アーキテクチャ詳細（MVVM、Repository、DI） |
| **[guides/development-guide.md](guides/development-guide.md)** | 開発フロー（Git、CI/CD、テスト、リリース） |

---

## 📋 リファレンス

詳細な技術仕様とデータモデルのリファレンスドキュメント。

| ドキュメント | 説明 |
|-------------|------|
| **[reference/data-models.md](reference/data-models.md)** | データモデル詳細（Project、Job、TimeRecord） |
| **[reference/tech-stack.md](reference/tech-stack.md)** | 技術スタック詳細（Swift、SwiftUI、SwiftData） |
| **[reference/design-patterns.md](reference/design-patterns.md)** | 設計パターンカタログ |
| **[reference/directory-structure.md](reference/directory-structure.md)** | ディレクトリ構成詳細 |

---

## 🎨 設計書

時系列で管理される設計ドキュメント（実装済み機能の詳細設計）。

### アーキテクチャ設計

| ファイル | 説明 | ステータス |
|---------|------|-----------|
| [design/20250926-view-viewmodel-1to1-design.md](design/20250926-view-viewmodel-1to1-design.md) | 1:1 View-ViewModel MVVM設計 | 実装完了 |
| [design/20250930-project-job-model-redesign.md](design/20250930-project-job-model-redesign.md) | Project/Jobモデルの再設計 | 実装完了 |
| [design/20251008-project-job-systemid-design.md](design/20251008-project-job-systemid-design.md) | 統一識別子システム設計（UUID `id`） | 実装完了 |

### 機能設計

| ファイル | 説明 | ステータス |
|---------|------|-----------|
| [design/20250926-history-edit-feature-design.md](design/20250926-history-edit-feature-design.md) | 履歴編集機能の設計 | 実装完了 |
| [design/20251003-statistics-command-export-feature.md](design/20251003-statistics-command-export-feature.md) | 統計画面のコマンドエクスポート機能 | 実装完了 |

### バグ修正設計

| ファイル | 説明 | ステータス |
|---------|------|-----------|
| [design/20251009-issue5-gatekeeper-fix-design.md](design/20251009-issue5-gatekeeper-fix-design.md) | Gatekeeper対応の設計 | 実装完了 |

---

## ⚙️ 運用ドキュメント

CI/CD、リリース、デプロイに関するドキュメント。

| ドキュメント | 説明 |
|-------------|------|
| **[operations/ci-cd.md](operations/ci-cd.md)** | GitHub Actions CI/CD設計 |
| **[operations/release-procedure.md](operations/release-procedure.md)** | リリース・デプロイ手順書 |

---

## 🔍 ドキュメントの読み方

### 新規開発者向けの推奨順序

1. **[guides/getting-started.md](guides/getting-started.md)** - まずはここから！
2. **[guides/project-overview.md](guides/project-overview.md)** - プロジェクト全体像を把握
3. **[guides/architecture-guide.md](guides/architecture-guide.md)** - アーキテクチャを理解
4. **[guides/development-guide.md](guides/development-guide.md)** - 開発フローを学ぶ
5. **[reference/](reference/)** - 必要に応じて参照

### 機能開発時の参照順序

1. **[guides/development-guide.md](guides/development-guide.md)** - 開発フロー確認
2. **[guides/architecture-guide.md](guides/architecture-guide.md)** - アーキテクチャパターン確認
3. **[reference/data-models.md](reference/data-models.md)** - データモデル確認
4. **[design/](design/)** - 類似機能の設計書を参考

---

## 📝 ドキュメント作成ガイドライン

### ファイル命名規則

**設計書（時系列管理）:**
```
YYYYMMDD-{topic}-{type}.md
```
- 例: `20251008-project-job-systemid-design.md`

**継続更新ドキュメント:**
```
{topic}.md
```
- 例: `release-procedure.md`

### 配置先

| カテゴリ | 配置先 | 例 |
|---------|-------|---|
| 入門・ガイド | `guides/` | 新機能の使い方、開発フロー |
| リファレンス | `reference/` | データモデル、技術仕様 |
| 設計書 | `design/` | 機能設計、アーキテクチャ設計 |
| 運用 | `operations/` | デプロイ手順、CI/CD設定 |

---

## 関連ドキュメント

- **[../CLAUDE.md](../CLAUDE.md)** - Claude Code向けプロジェクトガイド
- **[../README.md](../README.md)** - プロジェクトREADME

---

**質問・フィードバックは [GitHub Issues](https://github.com/ITK13201/TimeRabbit/issues) へ**
