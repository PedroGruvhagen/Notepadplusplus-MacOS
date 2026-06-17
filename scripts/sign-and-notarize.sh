#!/usr/bin/env bash
#
# sign-and-notarize.sh
#
# Build, Developer ID sign, notarize, staple, and package Notepad++ for macOS
# as a distributable, Gatekeeper-friendly DMG.
#
# This script contains NO credentials. It reads your Apple signing details from
# scripts/signing.env (which is gitignored) or from your shell environment.
# Copy scripts/signing.env.example to scripts/signing.env and fill it in.
#
# Required variables:
#   SIGN_IDENTITY    Full "Developer ID Application" identity, e.g.
#                    "Developer ID Application: Your Name (TEAMID)".
#                    List yours with: security find-identity -v -p codesigning
#   NOTARY_PROFILE   Name of a notarytool keychain profile. Create once with:
#                      xcrun notarytool store-credentials "<name>" \
#                        --apple-id "you@example.com" --team-id "TEAMID" \
#                        --password "<app-specific-password>"
#
# Optional variables:
#   BUNDLE_ID        Override CFBundleIdentifier of the built app.
#   SCHEME           Xcode scheme (default: "Notepad++").
#   CONFIGURATION    Build configuration (default: Release).
#
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

# Load local, gitignored config if present.
if [ -f "scripts/signing.env" ]; then
  # shellcheck disable=SC1091
  source "scripts/signing.env"
fi

SCHEME="${SCHEME:-Notepad++}"
CONFIGURATION="${CONFIGURATION:-Release}"
PROJECT="Notepad++.xcodeproj"
BUILD_DIR="$ROOT/build"
RELEASE_DIR="$ROOT/releases"
ENTITLEMENTS="Notepad++/Notepad__.entitlements"

if [ -z "${SIGN_IDENTITY:-}" ]; then
  echo "ERROR: SIGN_IDENTITY is not set." >&2
  echo "       Copy scripts/signing.env.example to scripts/signing.env and fill it in," >&2
  echo "       or export SIGN_IDENTITY in your shell." >&2
  exit 1
fi
if [ -z "${NOTARY_PROFILE:-}" ]; then
  echo "ERROR: NOTARY_PROFILE is not set." >&2
  echo "       Create one with: xcrun notarytool store-credentials ..." >&2
  exit 1
fi

echo "==> Cleaning previous build"
rm -rf "$BUILD_DIR"
mkdir -p "$RELEASE_DIR"

echo "==> Building universal $CONFIGURATION (arm64 + x86_64), unsigned"
xcodebuild \
  -project "$PROJECT" \
  -scheme "$SCHEME" \
  -configuration "$CONFIGURATION" \
  -derivedDataPath "$BUILD_DIR" \
  -arch arm64 -arch x86_64 ONLY_ACTIVE_ARCH=NO \
  CODE_SIGN_IDENTITY="" CODE_SIGNING_REQUIRED=NO CODE_SIGNING_ALLOWED=NO \
  build

APP="$BUILD_DIR/Build/Products/$CONFIGURATION/$SCHEME.app"
[ -d "$APP" ] || { echo "ERROR: built app not found at $APP" >&2; exit 1; }

VERSION="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' "$APP/Contents/Info.plist" 2>/dev/null || echo "dev")"

if [ -n "${BUNDLE_ID:-}" ]; then
  echo "==> Setting bundle identifier to $BUNDLE_ID"
  /usr/libexec/PlistBuddy -c "Set :CFBundleIdentifier $BUNDLE_ID" "$APP/Contents/Info.plist"
fi

echo "==> Signing nested code (inside-out), then the app, with hardened runtime"
# Sign any embedded dylibs/frameworks first, then seal the app bundle.
while IFS= read -r -d '' item; do
  codesign --force --options runtime --timestamp --sign "$SIGN_IDENTITY" "$item"
done < <(find "$APP/Contents" \( -name "*.dylib" -o -name "*.framework" \) -print0 2>/dev/null)

codesign --force --options runtime --timestamp \
  --entitlements "$ENTITLEMENTS" \
  --sign "$SIGN_IDENTITY" "$APP"

echo "==> Verifying signature"
codesign --verify --deep --strict --verbose=2 "$APP"
spctl --assess --type execute --verbose=2 "$APP" || true

echo "==> Notarizing app (this waits for Apple)"
ZIP="$BUILD_DIR/$SCHEME.zip"
ditto -c -k --keepParent "$APP" "$ZIP"
xcrun notarytool submit "$ZIP" --keychain-profile "$NOTARY_PROFILE" --wait

echo "==> Stapling app"
xcrun stapler staple "$APP"

echo "==> Building DMG"
DMG="$RELEASE_DIR/Notepad++_${VERSION}.dmg"
STAGING="$BUILD_DIR/dmg"
rm -rf "$STAGING"; mkdir -p "$STAGING"
cp -R "$APP" "$STAGING/"
ln -s /Applications "$STAGING/Applications"
hdiutil create -volname "Notepad++" -srcfolder "$STAGING" -ov -format UDZO "$DMG"

echo "==> Signing, notarizing, and stapling DMG"
codesign --force --sign "$SIGN_IDENTITY" "$DMG"
xcrun notarytool submit "$DMG" --keychain-profile "$NOTARY_PROFILE" --wait
xcrun stapler staple "$DMG"

echo "==> Done"
echo "    Signed + notarized: $DMG"
spctl --assess --type open --context context:primary-signature --verbose=2 "$DMG" || true
