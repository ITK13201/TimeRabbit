# TimeRabbit Documentation

このディレクトリにはTimeRabbitプロジェクトの設計書・運用ドキュメントが格納されています。

## ディレクトリ構造

```
docs/
├── README.md                    # このファイル
├── development/                 # 開発設計書
│   ├── features/               # 機能設計書
│   └── architecture/           # アーキテクチャ設計書
└── operations/                  # 運用設計書
```

---

## 📁 development/ - 開発設計書

アプリケーションの機能設計とアーキテクチャ設計に関するドキュメント

### features/ - 機能設計書

個別機能の設計・実装に関するドキュメント

| ファイル | 説明 | ステータス |
|---------|------|-----------|
| [20250926-history-edit-feature-design.md](development/features/20250926-history-edit-feature-design.md) | 履歴編集機能の設計 | 実装完了 |
| [20251003-statistics-command-export-feature.md](development/features/20251003-statistics-command-export-feature.md) | 統計画面のコマンドエクスポート機能 | 実装完了 |

### architecture/ - アーキテクチャ設計書

システムアーキテクチャ・データモデルに関するドキュメント

| ファイル | 説明 | ステータス |
|---------|------|-----------|
| [20250926-view-viewmodel-1to1-design.md](development/architecture/20250926-view-viewmodel-1to1-design.md) | 1:1 View-ViewModel MVVM設計 | 実装完了 |
| [20250930-project-job-model-redesign.md](development/architecture/20250930-project-job-model-redesign.md) | Project/Jobモデルの再設計 | 実装完了 |
| [20251008-project-job-systemid-design.md](development/architecture/20251008-project-job-systemid-design.md) | 統一識別子システム設計（UUID `id`） | 実装完了 |

---

## 📁 operations/ - 運用設計書

CI/CD、リリース、デプロイに関するドキュメント

| ファイル | 説明 | ステータス |
|---------|------|-----------|
| [github-actions-cicd.md](operations/github-actions-cicd.md) | GitHub Actions CI/CD設計 | 実装完了 |
| [release-deployment-procedure.md](operations/release-deployment-procedure.md) | リリース・デプロイ手順書 | 設計完了 |

---

## ドキュメント作成ガイドライン

### ファイル命名規則

**特定の開発タイミングに紐づくドキュメント（日時付き）**:
```
YYYYMMDD-{topic}-{type}.md
```
- **YYYYMMDD**: 作成日（例: 20251008）
- **topic**: トピック名（kebab-case）
- **type**: `design`, `feature` など

**継続的に更新されるドキュメント（日時なし）**:
```
{topic}.md
```
- **topic**: トピック名（kebab-case）

**例**:
- `20251008-project-job-systemid-design.md`（特定の設計）
- `release-deployment-procedure.md`（継続更新される手順書）
- `github-actions-cicd.md`（継続更新されるCI/CD設定）

### 配置先

| カテゴリ | 配置先 | 命名 | 例 |
|---------|-------|-----|---|
| 機能設計 | `development/features/` | 日時付き | 新機能の設計書 |
| アーキテクチャ設計 | `development/architecture/` | 日時付き | データモデル、設計パターン変更 |
| 運用・手順書 | `operations/` | 日時なし | デプロイ手順、CI/CD設定 |

### テンプレート

各設計書は以下のセクションを含めることを推奨：

```markdown
# {Title}

**作成日**: YYYY/MM/DD
**ステータス**: 設計中 | 設計完了 | 実装完了
**関連Issue**: #{issue_number} または N/A

## 目次
...

## 概要
...

## 設計詳細
...

## 実装手順
...
```

---

## 関連ドキュメント

- [CLAUDE.md](../CLAUDE.md): プロジェクト全体のガイド（Claude Code向け）
- [README.md](../README.md): プロジェクトREADME（存在する場合）
