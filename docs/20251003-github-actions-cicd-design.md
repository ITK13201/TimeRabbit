# GitHub Actions CI/CD 設計書

## 概要

TimeRabbitプロジェクトにGitHub Actionsを使用したCI/CDパイプラインを構築し、自動テスト、ビルド、リリースを実現する。

**作成日**: 2025/10/03
**対象バージョン**: TimeRabbit v1.x

## 背景・目的

### 背景
- 現在、テストとビルドは手動で実行されている
- リリース作成も手動で行われており、時間がかかる
- コードの品質を継続的に保証する仕組みが必要

### 目的
- **自動テスト**: Pull Request作成時とmainブランチへのpush時に自動テスト実行
- **自動ビルド**: タグpush時に本番用アプリケーションを自動ビルド
- **自動リリース**: GitHubのリリースページから署名済みアプリケーションをダウンロード可能にする
- **品質保証**: コードの品質を自動的にチェック
- **開発効率化**: 手動作業を削減し、開発者がコーディングに集中できる環境を構築

## 要件

### 機能要件

#### 1. CI (Continuous Integration)
- **トリガー**: Pull Request作成・更新時、mainブランチへのpush時
- **実行内容**:
  - ソースコードのチェックアウト
  - Xcodeバージョンの設定
  - 依存関係の解決
  - ユニットテストの実行（TimeRabbitTests）
  - UIテストの除外（実行時間短縮のため）
  - テスト結果のレポート

#### 2. CD (Continuous Delivery/Deployment)
- **トリガー**: セマンティックバージョニングタグのpush（例: v1.0.0, v1.2.3）
- **実行内容**:
  - ソースコードのチェックアウト
  - 本番用ビルド（Release設定）
  - アプリケーションの署名（Apple Developer証明書）
  - DMGファイルの作成（配布用）
  - GitHubリリースの自動作成
  - 成果物のアップロード

#### 3. リリース成果物
- **TimeRabbit.app**: 署名済みアプリケーション（zipファイル）
- **TimeRabbit.dmg**: インストーラー形式（オプション）
- **リリースノート**: 自動生成（コミットログから）
- **チェックサム**: SHA256ハッシュ値

### 非機能要件

#### 1. パフォーマンス
- CIワークフロー: 5分以内に完了
- CDワークフロー: 10分以内に完了
- キャッシュ活用によるビルド時間の短縮

#### 2. セキュリティ
- 最小権限の原則に基づくトークン権限設定
- 成果物の整合性検証（SHA256チェックサム）
- ワークフローの権限管理

#### 3. 可用性
- ビルド失敗時の通知（GitHub標準機能）
- ワークフロー実行履歴の保持
- エラー時の詳細ログ出力

#### 4. 保守性
- ワークフローのコメント記載
- 再利用可能なアクション定義
- バージョン管理されたワークフロー設定

## アーキテクチャ設計

### ワークフロー構成

```
┌─────────────────────────────────────────────────────────┐
│                  GitHub Repository                       │
└───────────────────┬─────────────────────────────────────┘
                    │
        ┌───────────┴───────────┐
        │                       │
        ▼                       ▼
┌───────────────┐      ┌────────────────┐
│  Pull Request │      │  Tag Push      │
│  Main Push    │      │  (v*.*.*)      │
└───────┬───────┘      └────────┬───────┘
        │                       │
        ▼                       ▼
┌───────────────┐      ┌────────────────────────┐
│   CI Workflow │      │  Release Workflow      │
├───────────────┤      ├────────────────────────┤
│ - Checkout    │      │ Job 1: Test            │
│ - Setup Xcode │      │ - Checkout             │
│ - Run Tests   │      │ - Setup Xcode          │
│ - Report      │      │ - Run Tests            │
└───────────────┘      │ - Report               │
                       │                        │
                       │ Job 2: Build (needs: test)│
                       │ - Checkout             │
                       │ - Setup Xcode          │
                       │ - Build Release        │
                       │ - Sign App             │
                       │ - Create DMG           │
                       │ - Upload               │
                       └────────┬───────────────┘
                                │
                                ▼
                       ┌────────────────┐
                       │ GitHub Release │
                       │ - App (zip)    │
                       │ - DMG          │
                       │ - Notes        │
                       └────────────────┘
```

### ディレクトリ構成

```
TimeRabbit/
├── .github/
│   └── workflows/
│       ├── ci.yml           # CI ワークフロー
│       └── release.yml      # CD/リリース ワークフロー
├── scripts/
│   ├── build-release.sh     # リリースビルドスクリプト
│   ├── create-dmg.sh        # DMG作成スクリプト
│   └── notarize.sh          # 公証スクリプト（オプション）
└── (既存のプロジェクトファイル)
```

## 詳細設計

### CI ワークフロー (ci.yml)

#### トリガー条件

```yaml
on:
  pull_request:
    branches: [ main ]
  push:
    branches: [ main ]
```

#### ジョブ定義

```yaml
jobs:
  test:
    name: Run Tests
    runs-on: macos-14  # macOS Sonoma

    steps:
      - name: Checkout code
        uses: actions/checkout@v4

      - name: Select Xcode version
        run: sudo xcode-select -s /Applications/Xcode_15.4.app

      - name: Show Xcode version
        run: xcodebuild -version

      - name: Cache derived data
        uses: actions/cache@v4
        with:
          path: ~/Library/Developer/Xcode/DerivedData
          key: ${{ runner.os }}-derived-data-${{ hashFiles('**/*.swift') }}
          restore-keys: |
            ${{ runner.os }}-derived-data-

      - name: Run unit tests
        run: |
          xcodebuild test \
            -project TimeRabbit.xcodeproj \
            -scheme TimeRabbit \
            -destination 'platform=macOS' \
            -testPlan TimeRabbitTests \
            -enableCodeCoverage YES \
            | tee test-output.log \
            | xcpretty

      - name: Upload test results
        if: always()
        uses: actions/upload-artifact@v4
        with:
          name: test-results
          path: test-output.log

      - name: Check test results
        if: failure()
        run: cat test-output.log
```

**設計ポイント**:
- `macos-14`: macOS Sonoma（最新の安定版）
- `xcpretty`: テスト出力を見やすく整形
- `actions/cache`: DerivedDataをキャッシュしてビルド時間短縮
- `always()`: テスト失敗時もログをアップロード
- `enableCodeCoverage`: コードカバレッジ測定

### CD/リリース ワークフロー (release.yml)

#### トリガー条件

```yaml
on:
  push:
    tags:
      - 'v*.*.*'  # v1.0.0, v1.2.3 など
```

#### ジョブ定義

**2段階構成**:
1. **test ジョブ**: テストを実行し、成功を確認
2. **build-and-release ジョブ**: testジョブ成功後にビルドとリリース作成

**Job 1: Test**

```yaml
jobs:
  build-and-release:
    name: Build and Release
    runs-on: macos-14

    steps:
      - name: Checkout code
        uses: actions/checkout@v4

      - name: Extract version from tag
        id: version
        run: |
          VERSION=${GITHUB_REF#refs/tags/v}
          echo "version=$VERSION" >> $GITHUB_OUTPUT
          echo "Version: $VERSION"

      - name: Select Xcode version
        run: sudo xcode-select -s /Applications/Xcode_15.4.app

      - name: Show Xcode version
        run: xcodebuild -version

      - name: Cache derived data
        uses: actions/cache@v4
        with:
          path: ~/Library/Developer/Xcode/DerivedData
          key: ${{ runner.os }}-derived-data-release-${{ hashFiles('**/*.swift') }}
          restore-keys: |
            ${{ runner.os }}-derived-data-release-

      - name: Build Release
        run: |
          xcodebuild archive \
            -project TimeRabbit.xcodeproj \
            -scheme TimeRabbit \
            -configuration Release \
            -archivePath ${{ runner.temp }}/TimeRabbit.xcarchive \
            CODE_SIGN_IDENTITY="-" \
            CODE_SIGN_STYLE="Manual"

      - name: Export app
        run: |
          xcodebuild -exportArchive \
            -archivePath ${{ runner.temp }}/TimeRabbit.xcarchive \
            -exportPath ${{ runner.temp }}/export \
            -exportOptionsPlist exportOptions.plist

      - name: Create ZIP archive
        run: |
          cd ${{ runner.temp }}/export
          zip -r TimeRabbit-${{ steps.version.outputs.version }}.zip TimeRabbit.app
          shasum -a 256 TimeRabbit-${{ steps.version.outputs.version }}.zip > TimeRabbit-${{ steps.version.outputs.version }}.zip.sha256

      - name: Create DMG (optional)
        run: |
          ./scripts/create-dmg.sh \
            ${{ runner.temp }}/export/TimeRabbit.app \
            ${{ runner.temp }}/export/TimeRabbit-${{ steps.version.outputs.version }}.dmg

      - name: Generate release notes
        id: release_notes
        run: |
          # 前回のタグからの変更を取得
          PREVIOUS_TAG=$(git describe --abbrev=0 --tags $(git rev-list --tags --skip=1 --max-count=1) 2>/dev/null || echo "")
          if [ -z "$PREVIOUS_TAG" ]; then
            CHANGES=$(git log --pretty=format:"- %s" --no-merges)
          else
            CHANGES=$(git log ${PREVIOUS_TAG}..HEAD --pretty=format:"- %s" --no-merges)
          fi

          cat << EOF > release_notes.md
          ## Changes

          $CHANGES

          ## Installation

          1. Download \`TimeRabbit-${{ steps.version.outputs.version }}.zip\`
          2. Extract the zip file
          3. Move \`TimeRabbit.app\` to your Applications folder
          4. Launch TimeRabbit

          ## Checksums

          \`\`\`
          $(cat ${{ runner.temp }}/export/TimeRabbit-${{ steps.version.outputs.version }}.zip.sha256)
          \`\`\`
          EOF

          cat release_notes.md

      - name: Create GitHub Release
        uses: softprops/action-gh-release@v2
        with:
          name: TimeRabbit v${{ steps.version.outputs.version }}
          body_path: release_notes.md
          draft: false
          prerelease: false
          files: |
            ${{ runner.temp }}/export/TimeRabbit-${{ steps.version.outputs.version }}.zip
            ${{ runner.temp }}/export/TimeRabbit-${{ steps.version.outputs.version }}.zip.sha256
            ${{ runner.temp }}/export/TimeRabbit-${{ steps.version.outputs.version }}.dmg
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
```

**設計ポイント**:
- タグからバージョン番号を抽出
- Releaseビルド（最適化有効）
- ZIP + SHA256チェックサム
- DMG作成（オプション）
- 前回タグからの変更履歴を自動生成
- `softprops/action-gh-release`: GitHubリリース作成の標準アクション

### exportOptions.plist

リリースビルドのエクスポート設定:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>method</key>
    <string>mac-application</string>
    <key>signingStyle</key>
    <string>manual</string>
    <key>stripSwiftSymbols</key>
    <true/>
    <key>teamID</key>
    <string>YOUR_TEAM_ID</string>
    <key>uploadBitcode</key>
    <false/>
    <key>uploadSymbols</key>
    <false/>
</dict>
</plist>
```

### スクリプト設計

#### scripts/create-dmg.sh

```bash
#!/bin/bash
set -e

APP_PATH="$1"
OUTPUT_DMG="$2"

if [ -z "$APP_PATH" ] || [ -z "$OUTPUT_DMG" ]; then
  echo "Usage: $0 <app_path> <output_dmg>"
  exit 1
fi

# 一時ディレクトリ作成
TMP_DIR=$(mktemp -d)
trap "rm -rf $TMP_DIR" EXIT

# アプリケーションをコピー
cp -R "$APP_PATH" "$TMP_DIR/"

# Applications フォルダへのシンボリックリンクを作成
ln -s /Applications "$TMP_DIR/Applications"

# DMG作成
hdiutil create -volname "TimeRabbit" \
  -srcfolder "$TMP_DIR" \
  -ov -format UDZO \
  "$OUTPUT_DMG"

echo "DMG created: $OUTPUT_DMG"
```

## コード署名とセキュリティ

### 署名なしビルド（採用方針）

**採用理由**:
- Apple Developer Programへの登録を行わない方針
- 個人プロジェクト・オープンソースプロジェクトとして配布
- コスト削減（年間12,980円の費用が不要）

**現状のアプローチ**:
- Ad-hocコード署名（`CODE_SIGN_IDENTITY="-"`）
- 開発者証明書不要
- ユーザーは初回起動時に「開く」を選択する必要あり

**メリット**:
- セットアップが簡単
- 証明書管理不要
- すぐに実装可能
- 継続的なコスト不要

**デメリットと対策**:
| デメリット | 対策 |
|----------|------|
| macOSのGatekeeperで警告が表示される | リリースノートに明確な起動手順を記載 |
| 初回起動時に追加手順が必要 | スクリーンショット付きのインストールガイドを提供 |
| 企業での使用に制限がある場合がある | 対象ユーザーを個人開発者・個人ユーザーに限定 |

**ユーザー向けの起動手順**:
1. ダウンロードしたアプリケーションを右クリック
2. 「開く」を選択
3. 警告ダイアログで「開く」ボタンをクリック
4. 以降は通常通りダブルクリックで起動可能

### 将来の選択肢（参考）

もし将来的にApple Developer Programに登録する場合:
- Developer ID Application証明書の取得
- 公証（Notarization）の実施
- より信頼性の高い配布が可能

**注**: 現時点では実装しない

## 実装状況

### Phase 1: CI実装 ✅ 完了
- [x] ci.ymlワークフロー作成
- [x] Pull Request時の自動テスト実行
- [x] mainブランチpush時の自動テスト実行
- [x] テスト結果の可視化（アーティファクトとしてアップロード）

**実装内容**:
- `.github/workflows/ci.yml`
- macOS 14ランナー使用
- Xcode 15.4指定
- キャッシュ機能有効（DerivedData）
- テスト結果を30日間保存

### Phase 2: 署名なしリリース ✅ 完了
- [x] release.ymlワークフロー作成
  - [x] testジョブの実装
  - [x] build-and-releaseジョブの実装（needs: test）
- [x] exportOptions.plist作成
- [x] create-dmg.shスクリプト作成
- [x] タグpush時の自動テスト→ビルド→リリース
- [x] GitHubリリースページへのアップロード
- [x] インストールガイドをリリースノートに含める

**実装内容**:
- `.github/workflows/release.yml`
- 2段階ジョブ構成（test → build-and-release）
- `exportOptions.plist`（署名なし設定）
- `scripts/create-dmg.sh`（DMG作成スクリプト）
- 自動生成リリースノート（前回タグからの変更履歴）
- ZIP + SHA256チェックサム + DMG

**成果物**:
- `TimeRabbit-{version}.zip`
- `TimeRabbit-{version}.zip.sha256`
- `TimeRabbit-{version}.dmg`

**注**: Apple Developer Programへの登録は行わない方針のため、署名付きビルドは実装しません。

## モニタリングと運用

### 成功の指標
- CI実行時間: 5分以内
- CD実行時間: 10分以内
- テスト成功率: 95%以上
- リリース頻度: 月1回以上

### 障害対応
- ビルド失敗時: GitHub Actionsのログを確認
- テスト失敗時: 失敗したテストケースを特定し修正
- 署名エラー: 証明書の有効期限確認

### メンテナンス
- 四半期ごとにXcodeバージョンの更新検討
- 年1回、ワークフロー全体の見直し
- GitHub Actionsの新機能チェック

## 制約事項

### 署名なしビルドの制約
1. **Gatekeeperの警告**
   - 初回起動時に「開発元を確認できません」と表示
   - ユーザーは右クリック→「開く」で実行可能
   - 対策: リリースノートに詳細な手順を記載

2. **配布の制限**
   - App Storeでの配布不可
   - 企業配布には不向き
   - 対策: GitHubリリースページでの個人向け配布に限定

3. **自動更新機能**
   - Sparkleなどの自動更新フレームワークが使用しづらい
   - 対策: 手動での更新を前提とする

**許容範囲**:
これらの制約は個人プロジェクト・オープンソースプロジェクトとしては許容範囲内であり、
Apple Developer Programへの登録コストを回避するメリットが上回ると判断

### GitHub Actionsの制約
1. **実行時間制限**
   - ジョブあたり最大6時間
   - 通常のビルドでは問題なし

2. **ストレージ制限**
   - アーティファクト保存期間: 90日（デフォルト）
   - リリースファイルは無期限

3. **並列実行制限**
   - Freeプラン: 1ジョブ並列実行
   - 通常は問題なし

## リスクと対策

### リスク1: ビルド環境の変更
**リスク**: Xcodeバージョン更新でビルドが失敗
**対策**:
- Xcodeバージョンを明示的に指定
- 定期的なテスト実行

### リスク2: macOSのセキュリティポリシー変更
**リスク**: 将来のmacOSで署名なしアプリの実行がさらに制限される可能性
**対策**:
- macOSのセキュリティアップデートを定期的に確認
- 必要に応じてApple Developer Program登録を再検討
- コミュニティのフィードバックを収集

### リスク3: テストの不安定性
**リスク**: テストが不定期に失敗
**対策**:
- リトライ機能の実装
- Flaky testの特定と修正

## 将来の拡張性

### 可能な拡張機能
1. **コードカバレッジレポート**
   - Codecovとの連携
   - カバレッジバッジの表示

2. **静的解析**
   - SwiftLintの導入
   - SwiftFormatの自動適用

3. **依存関係の自動更新**
   - Dependabotの活用
   - 定期的な依存関係チェック

4. **Beta配布**
   - TestFlightへの自動アップロード
   - Beta版の自動配布

5. **パフォーマンステスト**
   - ビルド時間の測定
   - アプリ起動時間の測定

6. **通知の強化**
   - Slackへのビルド結果通知
   - Discord/Teamsとの連携

## 参考資料

- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [Xcode Build Settings Reference](https://developer.apple.com/documentation/xcode)
- [Code Signing Guide](https://developer.apple.com/support/code-signing/)
- [Notarization Guide](https://developer.apple.com/documentation/security/notarizing_macos_software_before_distribution)
- [action-gh-release](https://github.com/softprops/action-gh-release)

## 付録

### A. タグの作成とpush方法

```bash
# バージョンタグを作成
git tag -a v1.0.0 -m "Release version 1.0.0"

# タグをリモートにpush
git push origin v1.0.0

# 全てのタグをpush
git push --tags
```

### B. ローカルでのリリースビルドテスト

```bash
# Releaseビルドを実行
xcodebuild archive \
  -project TimeRabbit.xcodeproj \
  -scheme TimeRabbit \
  -configuration Release \
  -archivePath ~/Desktop/TimeRabbit.xcarchive

# エクスポート
xcodebuild -exportArchive \
  -archivePath ~/Desktop/TimeRabbit.xcarchive \
  -exportPath ~/Desktop/export \
  -exportOptionsPlist exportOptions.plist
```

### C. トラブルシューティング

**問題**: ビルドが失敗する
**解決策**:
1. ローカル環境でビルドが成功するか確認
2. Xcodeバージョンを確認
3. ワークフローログの詳細を確認

**問題**: テストがタイムアウトする
**解決策**:
1. テストプランでUITestsが含まれていないか確認
2. タイムアウト時間を延長

**問題**: リリースが作成されない
**解決策**:
1. タグ形式が正しいか確認（v*.*.*）
2. GITHUB_TOKENの権限を確認
3. リポジトリ設定でActionsが有効か確認
