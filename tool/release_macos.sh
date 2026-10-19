#!/bin/sh
# Build rilis macOS + bungkus jadi .dmg (seret ke Applications).
# Pakai: sh tool/release_macos.sh   -> hasil di dist/Workshop-ERP-<versi>.dmg
set -e
cd "$(dirname "$0")/.."

flutter test
flutter build macos --release

APP="build/macos/Build/Products/Release/Workshop ERP.app"
VER=$(grep '^version:' pubspec.yaml | cut -d' ' -f2)
STAGE=$(mktemp -d)
cp -R "$APP" "$STAGE/"
ln -s /Applications "$STAGE/Applications"

mkdir -p dist
hdiutil create -volname "Workshop ERP" -srcfolder "$STAGE" -ov -format UDZO "dist/Workshop-ERP-$VER.dmg"
rm -rf "$STAGE"

echo "Arsitektur: $(lipo -archs "$APP/Contents/MacOS/Workshop ERP")"
echo "Selesai: dist/Workshop-ERP-$VER.dmg"
