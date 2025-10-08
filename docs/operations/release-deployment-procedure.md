# TimeRabbit リリース・デプロイ手順設計書

**作成日**: 2025/10/08
**ステータス**: 設計完了
**関連Issue**: N/A

## 目次
1. [概要](#概要)
2. [ブランチ戦略](#ブランチ戦略)
3. [リリースフロー](#リリースフロー)
4. [バージョニング規約](#バージョニング規約)
5. [デプロイ手順（詳細）](#デプロイ手順詳細)
6. [ロールバック手順](#ロールバック手順)
7. [Issue管理](#issue管理)
8. [チェックリスト](#チェックリスト)

---

## 概要

TimeRabbitは以下の自動化されたCI/CDパイプラインを持っています：

- **CI** (`ci.yml`): PRとmainブランチへのpushで自動テスト実行
- **Release** (`release.yml`): バージョンタグ（`v*.*.*`）のpushで自動ビルド・リリース

このドキュメントでは、開発からリリースまでの完全なフローを定義します。

---

## ブランチ戦略

### ブランチ構成

```
main (production)
  ↑
develop (development)
  ↑
feature/*, bugfix/*, hotfix/* (作業ブランチ)
```

### ブランチの役割

| ブランチ | 役割 | 保護設定 | CI実行 |
|---------|------|---------|--------|
| `main` | 本番環境。リリース用タグはここから作成 | 直接pushは禁止 | ✅ |
| `develop` | 開発統合ブランチ。新機能はここにマージ | 直接pushは推奨しない | ✅ |
| `feature/*` | 新機能開発 | - | PR時のみ |
| `bugfix/*` | バグ修正 | - | PR時のみ |
| `hotfix/*` | 緊急修正（mainから直接ブランチ） | - | PR時のみ |

---

## リリースフロー

### 通常リリース（feature/bugfix）

```
1. feature/bugfixブランチで開発
   ↓
2. developへPR作成・レビュー・マージ
   ↓
3. developで十分にテスト
   ↓
4. developからmainへPR作成・レビュー・マージ
   ↓
5. mainでバージョンタグ作成
   ↓
6. GitHub Actionsが自動ビルド・リリース
   ↓
7. 関連Issueをクローズ
```

### 緊急リリース（hotfix）

```
1. mainからhotfix/*ブランチ作成
   ↓
2. 修正実施
   ↓
3. mainへPR作成・レビュー・マージ
   ↓
4. mainでバージョンタグ作成（パッチバージョンup）
   ↓
5. GitHub Actionsが自動ビルド・リリース
   ↓
6. mainの変更をdevelopへマージ（同期）
   ↓
7. 関連Issueをクローズ
```

---

## バージョニング規約

### Semantic Versioning

`v{MAJOR}.{MINOR}.{PATCH}` 形式を採用

| 要素 | 説明 | 例 |
|-----|------|---|
| MAJOR | 破壊的変更 | v1.0.0 → v2.0.0 |
| MINOR | 後方互換性のある機能追加 | v1.0.0 → v1.1.0 |
| PATCH | バグ修正 | v1.0.0 → v1.0.1 |

### 初回リリース

- 現在のタグ: `v0.0.0`（プレースホルダー）
- 初回リリース: `v0.1.0` を推奨

### バージョン決定ガイドライン

| 変更内容 | バージョン |
|---------|-----------|
| 新機能追加 | MINOR++ |
| バグ修正のみ | PATCH++ |
| データモデル変更（破壊的） | MAJOR++ |
| 緊急修正 | PATCH++ |

---

## デプロイ手順（詳細）

### 前提条件

- [x] developブランチが最新状態
- [x] すべてのテストが成功
- [x] CLAUDE.mdが最新状態
- [x] コミットメッセージがconventionに準拠

### Step 1: developブランチの準備

```bash
# 1. developブランチを最新化
git checkout develop
git pull origin develop

# 2. テストを実行して確認
xcodebuild test \
  -project TimeRabbit.xcodeproj \
  -scheme TimeRabbit \
  -destination 'platform=macOS' \
  -testPlan TimeRabbitTests
```

### Step 2: developからmainへのPull Request作成

```bash
# 1. developブランチをリモートにpush（最新の状態を確認）
git push origin develop

# 2. GitHubでPRを作成
gh pr create \
  --base main \
  --head develop \
  --title "Release v0.1.0" \
  --body "$(cat <<'EOF'
## Release Summary

リリース予定バージョン: v0.1.0

## Changes

- #2 feature: Unify identifier naming with UUID-based id for all models
- docs: Reorganize documentation structure

## Checklist

- [x] すべてのテストが成功
- [x] CLAUDE.mdが最新
- [x] ドキュメントが更新されている
- [x] 関連Issueが対応済み

## Related Issues

Closes #2

EOF
)"

# 3. PRのURLを確認
# 出力されたURLでPRの内容を確認・レビュー
```

### Step 3: PRのマージとmainブランチの更新

```bash
# 1. PR承認後、マージ（GitHubのUIまたはCLIで）
gh pr merge --merge --delete-branch=false

# 2. ローカルのmainブランチを更新
git checkout main
git pull origin main
```

### Step 4: バージョンタグの作成

```bash
# 1. 次のバージョン番号を決定（例: v0.1.0）
VERSION="v0.1.0"

# 2. タグを作成（annotated tag推奨）
git tag -a $VERSION -m "Release $VERSION

Changes:
- #2 feature: Unify identifier naming with UUID-based id for all models
- Additional improvements and bug fixes

See release notes for full details."

# 3. タグをリモートにpush
git push origin $VERSION
```

### Step 5: GitHub Actionsの監視

```bash
# GitHubのActionsタブで進行状況を確認
# https://github.com/[username]/TimeRabbit/actions
```

**Workflow実行内容**:
1. **test job**: Unit tests実行（TimeRabbitTests）
2. **build-and-release job**（testが成功した場合のみ）:
   - Releaseビルド作成
   - ZIP・DMG生成
   - SHA256チェックサム生成
   - GitHub Releaseの作成
   - アーティファクトのアップロード

### Step 6: リリースの確認

```bash
# GitHub Releasesページで確認
# https://github.com/[username]/TimeRabbit/releases

# リリースノート確認項目:
# ✅ バージョン番号が正しい
# ✅ Changesセクションにコミットが含まれている
# ✅ Installation手順が記載されている
# ✅ ZIP・DMG・SHA256ファイルがアップロードされている
```

### Step 7: 関連Issueのクローズ

リリースが完了したら、関連するIssueをクローズします。

**方法1: PRで自動クローズ（推奨）**

PR作成時に `Closes #XX` をPR本文に含めることで、PRマージ時に自動的にIssueがクローズされます。

```bash
# Step 2で作成したPRに既に含まれている
## Related Issues

Closes #2
```

**方法2: 手動でクローズ**

```bash
# GitHub CLIでクローズ
gh issue close 2 --comment "Released in v0.1.0"

# または、GitHubのUIでIssueをクローズ
```

**Issueクローズ時の注意事項**:
- リリースバージョン番号をコメントに記載
- 複数Issueが関連する場合は、すべてクローズ
- リリースノートのリンクを追加すると良い

### Step 8: developブランチへの同期

```bash
# mainの変更をdevelopに反映
git checkout develop
git merge main --no-ff
git push origin develop
```

---

## ロールバック手順

### リリース後に問題が発覚した場合

#### Option 1: 新バージョンでhotfix

```bash
# 1. mainからhotfixブランチ作成
git checkout main
git checkout -b hotfix/fix-critical-issue

# 2. 修正実施・テスト

# 3. コミット
git add .
git commit -m "#XX hotfix: Fix critical issue description"

# 4. mainへマージ
git checkout main
git merge hotfix/fix-critical-issue --no-ff
git push origin main

# 5. パッチバージョンをリリース
git tag -a v0.1.1 -m "Hotfix release v0.1.1"
git push origin v0.1.1

# 6. developへ同期
git checkout develop
git merge main --no-ff
git push origin develop
```

#### Option 2: リリースの削除（非推奨）

```bash
# GitHubのReleaseページから手動削除
# タグも削除する場合:
git tag -d v0.1.0
git push origin :refs/tags/v0.1.0
```

---

## Issue管理

### Issue作成ガイドライン

開発作業を開始する前に、GitHub Issueを作成することを推奨します。

**Issueテンプレート例**:

```markdown
## 概要
[機能の概要や問題の説明]

## 目的
[この変更を行う理由]

## 実装内容
- [ ] タスク1
- [ ] タスク2
- [ ] タスク3

## 関連ドキュメント
- 設計書: docs/development/...
```

### Issueとブランチの命名規則

| Issue種別 | ブランチ名 | 例 |
|----------|-----------|---|
| 新機能 | `feature/#XX-description` | `feature/#5-add-export-feature` |
| バグ修正 | `bugfix/#XX-description` | `bugfix/#10-fix-crash-on-startup` |
| 緊急修正 | `hotfix/#XX-description` | `hotfix/#15-fix-data-loss` |

### PRとIssueの紐付け

PRには必ず関連Issueを記載します。

**PR本文に記載**:
```markdown
## Related Issues

Closes #5
Fixes #10
Relates to #3
```

**キーワード**:
- `Closes #XX`: PRマージ時にIssueを自動クローズ
- `Fixes #XX`: 同上（バグ修正の場合）
- `Relates to #XX`: 参照のみ（クローズしない）

### リリース時のIssue処理

1. **developへのマージ時**: Issueはまだオープンのまま
2. **mainへのPR作成時**: PR本文に `Closes #XX` を記載
3. **mainへのマージ時**: Issueが自動的にクローズ
4. **リリース完了後**: クローズされたIssueにリリースバージョンをコメント

```bash
# リリース完了後に実行
gh issue comment 2 --body "Released in [v0.1.0](https://github.com/[username]/TimeRabbit/releases/tag/v0.1.0)"
```

---

## チェックリスト

### リリース前チェックリスト

- [ ] すべての関連Issueが対応済み（developにマージ済み）
- [ ] developブランチですべてのテストが成功
- [ ] CLAUDE.mdが最新の変更を反映している
- [ ] コミットメッセージが規約に準拠している
- [ ] バージョン番号が適切に決定されている
- [ ] リリースPRの本文に `Closes #XX` が含まれている

### リリース手順チェックリスト

- [ ] developからmainへPRを作成
- [ ] PRのレビュー・承認
- [ ] PRをマージ（Issueが自動クローズされる）
- [ ] mainでテストが成功することを確認
- [ ] バージョンタグを作成・push
- [ ] GitHub Actionsのワークフローが成功
- [ ] GitHub Releaseが正しく作成されている
- [ ] ZIP・DMG・SHA256が正しくアップロードされている
- [ ] mainの変更をdevelopに同期
- [ ] クローズされたIssueにリリースバージョンをコメント

### リリース後チェックリスト

- [ ] リリースノートが正確である
- [ ] アプリが正常に起動する（ローカルでZIP/DMGをダウンロードしてテスト）
- [ ] 主要機能が動作する
- [ ] 関連Issueがすべてクローズされている
- [ ] 問題が発生した場合のロールバック手順を確認

---

## 補足情報

### 署名なしビルドについて

TimeRabbitは現在、Apple Developer Programに登録していないため、**署名なしビルド**を配布しています。

**ユーザーへの影響**:
- 初回起動時にGatekeeperの警告が表示される
- **回避方法**: アプリを右クリック → "開く" を選択

**将来的な改善**:
- Apple Developer Program加入後、公証（Notarization）を実施することで警告を回避可能

### 自動化の範囲

| 作業 | 自動/手動 |
|-----|----------|
| テスト実行 | ✅ 自動 |
| ビルド作成 | ✅ 自動 |
| ZIP/DMG生成 | ✅ 自動 |
| リリースノート生成 | ✅ 自動 |
| GitHub Release作成 | ✅ 自動 |
| Issueクローズ（PRマージ時） | ✅ 自動 |
| バージョン決定 | ❌ 手動 |
| タグ作成 | ❌ 手動 |
| PR作成・マージ | ❌ 手動 |
| Issueへのコメント | ❌ 手動 |

---

## トラブルシューティング

### GitHub Actionsが失敗する場合

#### test jobが失敗
```bash
# ローカルで同じコマンドを実行して原因調査
xcodebuild test \
  -project TimeRabbit.xcodeproj \
  -scheme TimeRabbit \
  -destination 'platform=macOS' \
  -testPlan TimeRabbitTests \
  -enableCodeCoverage YES
```

#### build-and-release jobが失敗
- Xcode version不一致: workflows内のXcodeバージョンを確認
- export失敗: exportOptions.plistの設定を確認
- Permission不足: GitHub Actionsの`permissions: contents: write`を確認

### タグを間違えてpushした場合

```bash
# ローカルのタグを削除
git tag -d v0.1.0

# リモートのタグを削除
git push origin :refs/tags/v0.1.0

# GitHub Releaseを手動削除

# 正しいタグを再作成
git tag -a v0.1.0 -m "Release v0.1.0"
git push origin v0.1.0
```

---

## 参考資料

- [Semantic Versioning 2.0.0](https://semver.org/)
- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [Xcode Build Settings Reference](https://developer.apple.com/documentation/xcode/build-settings-reference)
