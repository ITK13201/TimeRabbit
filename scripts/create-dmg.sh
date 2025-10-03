#!/bin/bash
set -e

APP_PATH="$1"
OUTPUT_DMG="$2"

if [ -z "$APP_PATH" ] || [ -z "$OUTPUT_DMG" ]; then
  echo "Usage: $0 <app_path> <output_dmg>"
  exit 1
fi

echo "Creating DMG from: $APP_PATH"
echo "Output DMG: $OUTPUT_DMG"

# 一時ディレクトリ作成
TMP_DIR=$(mktemp -d)
trap "rm -rf $TMP_DIR" EXIT

# アプリケーションをコピー
echo "Copying application..."
cp -R "$APP_PATH" "$TMP_DIR/"

# Applications フォルダへのシンボリックリンクを作成
echo "Creating symlink to Applications..."
ln -s /Applications "$TMP_DIR/Applications"

# DMG作成
echo "Creating DMG..."
hdiutil create -volname "TimeRabbit" \
  -srcfolder "$TMP_DIR" \
  -ov -format UDZO \
  "$OUTPUT_DMG"

echo "DMG created successfully: $OUTPUT_DMG"
