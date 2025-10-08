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
7. [チェックリスト](#チェックリスト)

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
2. developへPR作成・マージ
   ↓
3. developで十分にテスト
   ↓
4. developからmainへPR作成・マージ
   ↓
5. mainでバージョンタグ作成
   ↓
6. GitHub Actionsが自動ビルド・リリース
```

### 緊急リリース（hotfix）

```
1. mainからhotfix/*ブランチ作成
   ↓
2. 修正実施
   ↓
3. mainへPR作成・マージ
   ↓
4. mainでバージョンタグ作成（パッチバージョンup）
   ↓
5. GitHub Actionsが自動ビルド・リリース
   ↓
6. mainの変更をdevelopへマージ（同期）
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

### Step 1: developからmainへのマージ

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

# 3. mainブランチへ切り替え
git checkout main
git pull origin main

# 4. developをmainにマージ
git merge develop --no-ff

# 5. mainにpush
git push origin main
```

### Step 2: バージョンタグの作成

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

### Step 3: GitHub Actionsの監視

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

### Step 4: リリースの確認

```bash
# GitHub Releasesページで確認
# https://github.com/[username]/TimeRabbit/releases

# リリースノート確認項目:
# ✅ バージョン番号が正しい
# ✅ Changesセクションにコミットが含まれている
# ✅ Installation手順が記載されている
# ✅ ZIP・DMG・SHA256ファイルがアップロードされている
```

### Step 5: developブランチへの同期

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

## チェックリスト

### リリース前チェックリスト

- [ ] すべての関連Issueがクローズされている
- [ ] developブランチですべてのテストが成功
- [ ] CLAUDE.mdが最新の変更を反映している
- [ ] コミットメッセージが規約に準拠している
- [ ] バージョン番号が適切に決定されている
- [ ] リリースノートのドラフトを準備している

### リリース手順チェックリスト

- [ ] developをmainにマージ
- [ ] mainでテストが成功することを確認
- [ ] バージョンタグを作成・push
- [ ] GitHub Actionsのワークフローが成功
- [ ] GitHub Releaseが正しく作成されている
- [ ] ZIP・DMG・SHA256が正しくアップロードされている
- [ ] mainの変更をdevelopに同期

### リリース後チェックリスト

- [ ] リリースノートが正確である
- [ ] アプリが正常に起動する（ローカルでZIP/DMGをダウンロードしてテスト）
- [ ] 主要機能が動作する
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
| バージョン決定 | ❌ 手動 |
| タグ作成 | ❌ 手動 |
| ブランチマージ | ❌ 手動 |

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
