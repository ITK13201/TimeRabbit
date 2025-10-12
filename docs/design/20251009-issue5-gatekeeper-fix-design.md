# Issue #5: macOS Gatekeeper「壊れている」問題の解決 - Phase 1 & 2 実装設計書

## 概要

GitHub Releaseからダウンロードしたアプリが macOS Gatekeeper により「壊れているため開けません」と表示され起動できない問題に対して、Phase 1（リリースノート改善）とPhase 2（Ad-hoc署名改善）を実装する。

## 問題の詳細

### 現象
- GitHub Release (v1.0.0) からダウンロードした TimeRabbit.app を開こうとすると以下のエラーが発生
- エラーメッセージ: 「壊れているため開けません。ゴミ箱に入れる必要があります。」
- 右クリック→「開く」でも同様のエラー

### 根本原因
macOS は、インターネットからダウンロードしたファイルに隔離属性（quarantine attribute: `com.apple.quarantine`）を付与する。署名されていないアプリや ad-hoc 署名のみのアプリに対して、この属性があると Gatekeeper が「壊れている」と誤判定する。

### 現在の回避策
```bash
xattr -cr /path/to/TimeRabbit.app
```
この手動操作でユーザーがアプリを起動できるが、技術的知識が必要で UX が悪い。

## 技術的分析

### 現在のビルドプロセスの問題点

**release.yml (82-92行目):**
```yaml
xcodebuild archive \
  -project TimeRabbit.xcodeproj \
  -scheme TimeRabbit \
  -configuration Release \
  -archivePath ${{ runner.temp }}/TimeRabbit.xcarchive \
  CODE_SIGN_IDENTITY="-" \
  CODE_SIGNING_REQUIRED=NO \
  CODE_SIGNING_ALLOWED=NO
```

**問題点:**
1. `CODE_SIGN_IDENTITY="-"` により ad-hoc 署名すら適用されていない可能性
2. `CODE_SIGNING_REQUIRED=NO` / `CODE_SIGNING_ALLOWED=NO` で署名が完全に無効化
3. リリースノートに適切な警告・手順が不足

**exportOptions.plist:**
```xml
<key>method</key>
<string>mac-application</string>
<key>signingStyle</key>
<string>manual</string>
```

署名に関する明示的な指定が不足。

### macOS Gatekeeper の動作（参考）

| 署名状態 | 隔離属性あり | 隔離属性なし |
|---------|------------|------------|
| 未署名 | ❌ 「壊れている」エラー | ⚠️ 警告表示後に起動可能 |
| Ad-hoc 署名 | ❌ 「壊れている」エラー | ⚠️ 警告表示後に起動可能 |
| Developer ID 署名 | ⚠️ 「開発元が確認済み」警告のみ | ✅ 警告なしで起動 |

**重要:** Ad-hoc署名でもGatekeeper問題は解決しないため、Phase 1とPhase 2は併用が必須。

## 実装内容

### Phase 1: リリースノートの改善

**目的:**
- ユーザーに回避策を明確に伝える
- コストゼロ、実装容易
- 次回リリース（v1.0.1以降）から即座に効果

#### 実装詳細

**ファイル:** `.github/workflows/release.yml`

**変更箇所:** 114-160行目の「Generate release notes」ステップ

**変更内容:**

既存の release notes 生成部分を以下のように拡張：

```yaml
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

    ## ⚠️ macOS Gatekeeper Warning

    ### If you see "app is damaged and can't be opened" error:

    This application is not signed with an Apple Developer certificate. If macOS shows an error message saying the app is damaged, follow these steps:

    #### Solution 1: Remove quarantine attribute (Recommended)
    1. Open Terminal
    2. Run the following command:
       \`\`\`bash
       xattr -cr /Applications/TimeRabbit.app
       \`\`\`
       (Replace \`/Applications/TimeRabbit.app\` with the actual path to your app)
    3. Try opening the app again

    #### Solution 2: Use System Settings (macOS Ventura or later)
    1. Try to open the app (you will see an error)
    2. Go to **System Settings** → **Privacy & Security**
    3. Scroll down to the **Security** section
    4. Click **"Open Anyway"** next to the TimeRabbit message
    5. Click **"Open"** in the confirmation dialog

    #### Why does this happen?

    This is a macOS security feature for unsigned applications downloaded from the internet. The app is safe to use - you can verify the integrity using the SHA256 checksum provided below.

    ## Installation

    ### Option 1: Using ZIP file (Recommended)
    1. Download \`TimeRabbit-${{ steps.version.outputs.version }}.zip\`
    2. Extract the zip file
    3. Move \`TimeRabbit.app\` to your Applications folder
    4. **Important:** Follow the Gatekeeper warning instructions above before first launch

    ### Option 2: Using DMG file
    1. Download \`TimeRabbit-${{ steps.version.outputs.version }}.dmg\`
    2. Open the DMG file
    3. Drag \`TimeRabbit.app\` to the Applications folder
    4. **Important:** Follow the Gatekeeper warning instructions above before first launch

    ## Checksums

    \`\`\`
    $(cat ${{ runner.temp }}/export/TimeRabbit-${{ steps.version.outputs.version }}.zip.sha256)
    \`\`\`
    EOF

    cat release_notes.md
```

**主な追加内容:**
1. ⚠️ macOS Gatekeeper Warning セクション
2. 2つの解決策を明記（ターミナル方式とシステム設定方式）
3. エラーが発生する理由の説明
4. Installation手順にGatekeeper警告への言及を追加

### Phase 2: Ad-hoc 署名の改善

**目的:**
- 適切な ad-hoc 署名を適用してビルドの一貫性を向上
- 署名プロセスの可視化と検証

**注意:** このフェーズだけではGatekeeper問題は解決しない。Phase 1と併用必須。

#### 実装詳細

##### 2.1 release.yml の署名設定修正

**ファイル:** `.github/workflows/release.yml`

**変更箇所 1:** 82-92行目の「Build Release」ステップ

**変更前:**
```yaml
- name: Build Release
  run: |
    set -o pipefail
    xcodebuild archive \
      -project TimeRabbit.xcodeproj \
      -scheme TimeRabbit \
      -configuration Release \
      -archivePath ${{ runner.temp }}/TimeRabbit.xcarchive \
      CODE_SIGN_IDENTITY="-" \
      CODE_SIGNING_REQUIRED=NO \
      CODE_SIGNING_ALLOWED=NO
```

**変更後:**
```yaml
- name: Build Release
  run: |
    set -o pipefail
    xcodebuild archive \
      -project TimeRabbit.xcodeproj \
      -scheme TimeRabbit \
      -configuration Release \
      -archivePath ${{ runner.temp }}/TimeRabbit.xcarchive \
      CODE_SIGN_IDENTITY="-"
```

**変更点:**
- `CODE_SIGNING_REQUIRED=NO` を削除
- `CODE_SIGNING_ALLOWED=NO` を削除
- `CODE_SIGN_IDENTITY="-"` を保持（ad-hoc署名）

##### 2.2 署名検証ステップの追加

**追加位置:** 「Export app」ステップ（94-99行目）の直後

**新規ステップ:**
```yaml
- name: Verify code signature
  run: |
    echo "=== Verifying code signature ==="
    codesign -dv --verbose=4 ${{ runner.temp }}/export/TimeRabbit.app 2>&1 || true
    echo ""
    echo "=== Verifying signature validity ==="
    codesign --verify --verbose=4 ${{ runner.temp }}/export/TimeRabbit.app 2>&1 || true
    echo ""
    echo "=== Checking executable ==="
    file ${{ runner.temp }}/export/TimeRabbit.app/Contents/MacOS/TimeRabbit
```

**目的:**
- ビルド後の署名状態を確認
- CI/CDログで署名情報を可視化
- 問題があれば早期発見

**期待される出力例:**
```
Identifier=dev.i-tk.TimeRabbit
Format=app bundle with Mach-O thin (arm64)
CodeDirectory v=20500 size=... flags=0x2(adhoc) hashes=...
Signature=adhoc
```

##### 2.3 exportOptions.plist の改善

**ファイル:** `exportOptions.plist`

**変更前:**
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
    <key>uploadBitcode</key>
    <false/>
    <key>uploadSymbols</key>
    <false/>
    <key>compileBitcode</key>
    <false/>
</dict>
</plist>
```

**変更後:**
```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>method</key>
    <string>mac-application</string>
    <key>signingStyle</key>
    <string>manual</string>
    <key>signingCertificate</key>
    <string>-</string>
    <key>stripSwiftSymbols</key>
    <true/>
    <key>uploadBitcode</key>
    <false/>
    <key>uploadSymbols</key>
    <false/>
    <key>compileBitcode</key>
    <false/>
</dict>
</plist>
```

**変更点:**
- `<key>signingCertificate</key><string>-</string>` を追加（ad-hoc署名の明示）

## 実装手順

### ステップ 1: ブランチ作成

```bash
git checkout develop
git pull origin develop
git checkout -b bugfix/#5-gatekeeper-phase1-2
```

### ステップ 2: Phase 1 実装

1. `.github/workflows/release.yml` を開く
2. 114-160行目の「Generate release notes」ステップを上記の変更内容で置き換え
3. 保存

### ステップ 3: Phase 2 実装

1. `.github/workflows/release.yml` の「Build Release」ステップを修正
2. 「Verify code signature」ステップを「Export app」の直後に追加
3. `exportOptions.plist` に `signingCertificate` キーを追加
4. 保存

### ステップ 4: 変更をコミット

```bash
git add .github/workflows/release.yml exportOptions.plist
git commit -m "#5 bugfix: Improve Gatekeeper handling with release notes and ad-hoc signing

- Phase 1: Add comprehensive Gatekeeper warning to release notes
  - Document two workaround methods (xattr and System Settings)
  - Explain why the error occurs
- Phase 2: Improve ad-hoc signing process
  - Remove CODE_SIGNING_REQUIRED=NO and CODE_SIGNING_ALLOWED=NO
  - Add signature verification step for visibility
  - Explicitly set signingCertificate in exportOptions.plist"
```

### ステップ 5: プッシュとPR作成

```bash
git push origin bugfix/#5-gatekeeper-phase1-2

gh pr create --base develop --head bugfix/#5-gatekeeper-phase1-2 \
  --title "#5 Improve Gatekeeper handling (Phase 1 & 2)" \
  --body "Closes #5

## Summary
Implements Phase 1 and Phase 2 of the Gatekeeper fix to address the \"app is damaged\" error users experience when downloading from GitHub Releases.

## Changes

### Phase 1: Release Notes Enhancement
- Added ⚠️ macOS Gatekeeper Warning section to release notes
- Documented two workaround methods:
  1. Terminal: \`xattr -cr\` command
  2. System Settings: \"Open Anyway\" button
- Explained why the error occurs (unsigned app + quarantine attribute)
- Updated Installation section to reference Gatekeeper warning

### Phase 2: Ad-hoc Signing Improvement
- Removed \`CODE_SIGNING_REQUIRED=NO\` and \`CODE_SIGNING_ALLOWED=NO\` from build step
- Added signature verification step for CI/CD visibility
- Explicitly set \`signingCertificate\` in exportOptions.plist

## Testing

- [ ] Release notes markdown syntax verified
- [ ] Will test in next release (v1.0.1 or later)
- [ ] Signature verification step will show ad-hoc signing details in CI logs

## Impact

**User Impact:**
- Users will have clear instructions to resolve Gatekeeper errors
- Two different methods provided (technical and non-technical users)

**Developer Impact:**
- Better visibility into signing status via CI/CD logs
- Slightly cleaner build configuration

## Notes

- Phase 2 alone does NOT solve Gatekeeper issues (ad-hoc signing still triggers errors)
- Phase 1 is the primary solution for users
- Phase 3 (Developer ID + Notarization) remains a future consideration

## Related Documentation

- Design document: \`docs/development/bugfixes/20251009-issue5-gatekeeper-fix-design.md\`"
```

### ステップ 6: PR レビューとマージ

1. CI/CD テストが通過することを確認
2. コードレビュー
3. develop ブランチにマージ

### ステップ 7: 次回リリースで検証

1. develop → main へPR作成・マージ
2. バージョンタグを作成（例: `v1.0.1`）
3. GitHub Actions が自動ビルド・リリース
4. リリースページで以下を確認:
   - ⚠️ macOS Gatekeeper Warning セクションが表示される
   - 回避策の手順が明確
   - Installation 手順が更新されている
5. CI/CDログで署名検証ステップの出力を確認

## テスト計画

### Phase 1 テスト

#### ローカルテスト（リリースノート生成確認）

```bash
# 最新のタグを取得
PREVIOUS_TAG=$(git describe --abbrev=0 --tags)

# 変更ログを確認
git log ${PREVIOUS_TAG}..HEAD --pretty=format:"- %s" --no-merges

# release notes 生成のシミュレーション（マークダウン構文確認）
cat << 'EOF'
## ⚠️ macOS Gatekeeper Warning

### If you see "app is damaged and can't be opened" error:
...
EOF
```

#### 次回リリースでの検証項目

- [ ] GitHub Release ページにアクセス
- [ ] リリースノートに「⚠️ macOS Gatekeeper Warning」セクションが表示される
- [ ] Solution 1（xattr方式）が記載されている
- [ ] Solution 2（System Settings方式）が記載されている
- [ ] 理由の説明セクションが表示される
- [ ] Installation 手順が更新されている
- [ ] マークダウンの書式が正しくレンダリングされている

### Phase 2 テスト

#### CI/CDログでの確認

次回リリース時のGitHub Actionsログで以下を確認：

- [ ] 「Build Release」ステップが成功
- [ ] 「Verify code signature」ステップが実行される
- [ ] 署名情報が表示される（期待値: `Signature=adhoc`）
- [ ] エラーが発生していない

#### 期待される出力例

```
=== Verifying code signature ===
Executable=/tmp/.../export/TimeRabbit.app/Contents/MacOS/TimeRabbit
Identifier=dev.i-tk.TimeRabbit
Format=app bundle with Mach-O thin (arm64)
CodeDirectory v=20500 size=... flags=0x2(adhoc) hashes=...
Signature=adhoc
Info.plist entries=...

=== Verifying signature validity ===
TimeRabbit.app: valid on disk

=== Checking executable ===
Mach-O 64-bit executable arm64
```

## 受け入れ基準

### Phase 1 受け入れ基準（必須）

- ✅ リリースノートに「⚠️ macOS Gatekeeper Warning」セクションが表示される
- ✅ 2つの回避策が明確に記載されている
  - Solution 1: `xattr -cr` コマンド
  - Solution 2: System Settings の「Open Anyway」
- ✅ エラーが発生する理由が説明されている
- ✅ Installation 手順にGatekeeper警告への参照が含まれる
- ✅ マークダウン書式が正しくレンダリングされる
- ✅ ユーザーが手順に従って問題を解決できる

### Phase 2 受け入れ基準（推奨）

- ✅ ビルドが成功する
- ✅ `CODE_SIGNING_REQUIRED=NO` と `CODE_SIGNING_ALLOWED=NO` が削除されている
- ✅ 署名検証ステップが実行される
- ✅ CI/CDログで署名情報が確認できる
- ✅ Ad-hoc 署名が適用されている（`Signature=adhoc`）
- ✅ `exportOptions.plist` に `signingCertificate` が設定されている

## リスクと対策

### リスク 1: ユーザーがターミナル操作に不慣れ

**影響度:** 中

**対策:**
- Solution 2（System Settings方式）を提供
- 両方の手順を具体的かつ分かりやすく記載
- 将来的にFAQページやスクリーンショット付きガイドを検討

### リスク 2: Phase 2でビルドが失敗する可能性

**影響度:** 低

**対策:**
- 署名検証ステップは `|| true` で失敗を許容（情報収集が目的）
- CI/CDでテスト実行後にビルドするため、基本的な問題は事前に検出可能
- 問題が発生した場合は `CODE_SIGNING_REQUIRED=NO` を戻す選択肢を残す

### リスク 3: リリースノートが長すぎる

**影響度:** 低

**対策:**
- 重要な情報を冒頭に配置（Changes → Gatekeeper Warning → Installation）
- マークダウンの見出しで構造化し、読みやすくする
- 将来的に外部ドキュメントへのリンクを検討

## 今後の展望（Phase 3）

Phase 1とPhase 2の実装後、ユーザーフィードバックと利用状況に応じて以下を検討：

### Phase 3: Developer ID 署名 + 公証（将来検討）

**条件:**
- ユーザー数が一定以上に増加
- ユーザーから強い要望がある
- 予算確保（$99/年）

**メリット:**
- Gatekeeper問題を根本的に解決
- ユーザーがダブルクリックで起動可能
- 「開発元が確認済み」として認識

**必要な作業:**
- Apple Developer Program 登録
- Developer ID Application 証明書取得
- CI/CDへの証明書統合
- 公証プロセスの実装
- リリースノートの更新

## 関連ドキュメント

- Issue #5: https://github.com/ITK13201/TimeRabbit/issues/5
- Apple - Notarizing macOS Software: https://developer.apple.com/documentation/security/notarizing_macos_software_before_distribution
- GitHub Actions - Encrypted Secrets: https://docs.github.com/en/actions/security-guides/encrypted-secrets
- TimeRabbit - Release Deployment Procedure: `docs/operations/release-deployment-procedure.md`
- TimeRabbit - CI/CD Design: `docs/operations/github-actions-cicd.md`

## まとめ

### 実装する内容

✅ **Phase 1（必須・主要施策）:**
- リリースノートに包括的なGatekeeper警告を追加
- ユーザーが自力で解決できる2つの方法を提供

✅ **Phase 2（推奨・補助施策）:**
- Ad-hoc署名プロセスの改善と標準化
- 署名検証ステップの追加で可視性向上

### 期待される効果

1. **ユーザー体験の改善:**
   - 明確な手順により、ユーザーが自力でアプリを起動可能
   - 「なぜエラーが出るのか」の説明により、不安を軽減

2. **開発プロセスの改善:**
   - 署名状態の可視化により、問題の早期発見が可能
   - ビルドプロセスがより標準的に

3. **コスト効率:**
   - 実装コスト: ゼロ
   - 年間コスト: ゼロ
   - 即座に展開可能

### 次のステップ

1. 本設計書のレビュー
2. ブランチ作成と実装
3. PR作成・レビュー・マージ
4. 次回リリース（v1.0.1）で検証
5. ユーザーフィードバック収集
6. 必要に応じてPhase 3を検討
