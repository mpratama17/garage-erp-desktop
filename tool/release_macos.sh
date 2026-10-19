#!/bin/sh
# Build rilis macOS + bungkus jadi .dmg (seret ke Applications).
# Pakai: sh tool/release_macos.sh   -> hasil di dist/Garage-ERP-<versi>.dmg
set -e
cd "$(dirname "$0")/.."

flutter test
flutter build macos --release

APP="build/macos/Build/Products/Release/Garage ERP.app"
VER=$(grep '^version:' pubspec.yaml | cut -d' ' -f2)
STAGE=$(mktemp -d)
cp -R "$APP" "$STAGE/"
ln -s /Applications "$STAGE/Applications"

mkdir -p dist
hdiutil create -volname "Garage ERP" -srcfolder "$STAGE" -ov -format UDZO "dist/Garage-ERP-$VER.dmg"
rm -rf "$STAGE"

echo "Arsitektur: $(lipo -archs "$APP/Contents/MacOS/Garage ERP")"
echo "Selesai: dist/Garage-ERP-$VER.dmg"
