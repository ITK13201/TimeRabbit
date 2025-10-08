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
| [20251003-github-actions-cicd-design.md](operations/20251003-github-actions-cicd-design.md) | GitHub Actions CI/CD設計 | 実装完了 |
| [20251008-release-deployment-procedure.md](operations/20251008-release-deployment-procedure.md) | リリース・デプロイ手順書 | 設計完了 |

---

## ドキュメント作成ガイドライン

### ファイル命名規則

```
YYYYMMDD-{topic}-{type}.md
```

- **YYYYMMDD**: 作成日（例: 20251008）
- **topic**: トピック名（kebab-case）
- **type**: `design`, `procedure`, `guideline` など

**例**:
- `20251008-project-job-systemid-design.md`
- `20251008-release-deployment-procedure.md`

### 配置先

| カテゴリ | 配置先 | 例 |
|---------|-------|---|
| 機能設計 | `development/features/` | 新機能の設計書 |
| アーキテクチャ設計 | `development/architecture/` | データモデル、設計パターン |
| CI/CD・リリース | `operations/` | デプロイ手順、ワークフロー設計 |

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
