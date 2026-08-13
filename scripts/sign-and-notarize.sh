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

# Sparkle.framework carries its own nested executable code (XPC services, the
# Autoupdate installer binary, and the Updater.app progress-UI helper) that a
# plain `find -name "*.dylib" -o -name "*.framework"` loop never reaches, since
# none of those items match either pattern. Because the app is built fully
# unsigned above (CODE_SIGNING_ALLOWED=NO), they ship unsigned unless signed
# explicitly here, which fails `codesign --verify --deep --strict` below and
# notarization. Sparkle's own docs require signing these inside-out, before
# the framework that contains them, so a later signature over the framework
# bundle seals correctly-signed children instead of re-sealing unsigned ones.
SPARKLE_FRAMEWORK="$APP/Contents/Frameworks/Sparkle.framework"
if [ -d "$SPARKLE_FRAMEWORK" ]; then
  SPARKLE_VERSIONED="$SPARKLE_FRAMEWORK/Versions/Current"
  for nested in \
    "$SPARKLE_VERSIONED/XPCServices/Downloader.xpc" \
    "$SPARKLE_VERSIONED/XPCServices/Installer.xpc" \
    "$SPARKLE_VERSIONED/Autoupdate" \
    "$SPARKLE_VERSIONED/Updater.app"
  do
    if [ ! -e "$nested" ]; then
      echo "ERROR: expected Sparkle component missing: $nested" >&2
      echo "       Sparkle's internal layout may have changed; update this script." >&2
      exit 1
    fi
    codesign --force --options runtime --timestamp --sign "$SIGN_IDENTITY" "$nested"
  done
fi

# Sign any remaining embedded dylibs/frameworks (including Sparkle.framework
# itself, now that its nested code above is already signed), then seal the app.
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

echo "==> Signing update artifact for Sparkle and updating appcast.xml"
# sign_update ships inside the Sparkle SPM package's own artifacts, resolved into this
# release build's own -derivedDataPath ($BUILD_DIR) above, same as Xcode resolves it for
# interactive builds. It signs the exact DMG bytes with the file-based EdDSA private key at
# scripts/sparkle_eddsa_private.key (gitignored, mode 600, generated once by
# scripts/generate-sparkle-keys.swift; no Keychain involved, see
# lore/pages/auto-update-sparkle.md) and prints the sparkle:edSignature + length enclosure
# attributes Sparkle's appcast needs.
SIGN_UPDATE="$BUILD_DIR/SourcePackages/artifacts/sparkle/Sparkle/bin/sign_update"
if [ ! -x "$SIGN_UPDATE" ]; then
  echo "ERROR: sign_update tool not found at $SIGN_UPDATE" >&2
  echo "       Expected inside the Sparkle SPM package artifacts under \$BUILD_DIR after the build above." >&2
  exit 1
fi

ED_KEY_FILE="$ROOT/scripts/sparkle_eddsa_private.key"
if [ ! -f "$ED_KEY_FILE" ]; then
  echo "ERROR: Sparkle EdDSA private key not found at $ED_KEY_FILE" >&2
  echo "       Generate it once with: swift scripts/generate-sparkle-keys.swift" >&2
  exit 1
fi

BUILD_NUMBER="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleVersion' "$APP/Contents/Info.plist")"
MIN_SYSTEM_VERSION="$(/usr/libexec/PlistBuddy -c 'Print :LSMinimumSystemVersion' "$APP/Contents/Info.plist" 2>/dev/null || echo "15.5")"
SIGN_UPDATE_OUTPUT="$("$SIGN_UPDATE" --ed-key-file "$ED_KEY_FILE" "$DMG")"
ED_SIGNATURE="$(printf '%s' "$SIGN_UPDATE_OUTPUT" | sed -nE 's/.*sparkle:edSignature="([^"]*)".*/\1/p')"
DMG_LENGTH="$(printf '%s' "$SIGN_UPDATE_OUTPUT" | sed -nE 's/.*length="([^"]*)".*/\1/p')"
if [ -z "$ED_SIGNATURE" ] || [ -z "$DMG_LENGTH" ]; then
  echo "ERROR: could not parse sign_update output: $SIGN_UPDATE_OUTPUT" >&2
  exit 1
fi

DOWNLOAD_URL="https://github.com/PedroGruvhagen/Notepadplusplus-MacOS/releases/download/v${VERSION}/Notepad++_${VERSION}.dmg"
PUB_DATE="$(LC_TIME=C date -u +"%a, %d %b %Y %H:%M:%S +0000")"

APPCAST_PATH="$ROOT/appcast.xml" \
APPCAST_VERSION="$VERSION" \
APPCAST_BUILD="$BUILD_NUMBER" \
APPCAST_URL="$DOWNLOAD_URL" \
APPCAST_SIGNATURE="$ED_SIGNATURE" \
APPCAST_LENGTH="$DMG_LENGTH" \
APPCAST_PUB_DATE="$PUB_DATE" \
APPCAST_MIN_SYSTEM_VERSION="$MIN_SYSTEM_VERSION" \
python3 - <<'PYEOF'
import os
import xml.etree.ElementTree as ET

SPARKLE_NS = "http://www.andymatuschak.org/xml-namespaces/sparkle"
ET.register_namespace("sparkle", SPARKLE_NS)
ET.register_namespace("dc", "http://purl.org/dc/elements/1.1/")

path = os.environ["APPCAST_PATH"]
version = os.environ["APPCAST_VERSION"]
build = os.environ["APPCAST_BUILD"]
url = os.environ["APPCAST_URL"]
signature = os.environ["APPCAST_SIGNATURE"]
length = os.environ["APPCAST_LENGTH"]
pub_date = os.environ["APPCAST_PUB_DATE"]
min_system_version = os.environ["APPCAST_MIN_SYSTEM_VERSION"]

tree = ET.parse(path)
root = tree.getroot()
channel = root.find("channel")
if channel is None:
    raise SystemExit(f"ERROR: {path} has no <channel> element")

# Idempotent: drop any existing item for this build number before inserting, so re-running
# the release script for the same version (e.g. after fixing a signing problem) replaces
# rather than duplicates it.
for item in list(channel.findall("item")):
    enclosure = item.find("enclosure")
    existing_build = enclosure.get(f"{{{SPARKLE_NS}}}version") if enclosure is not None else None
    if existing_build == build:
        channel.remove(item)

item = ET.Element("item")
title = ET.SubElement(item, "title")
title.text = f"Version {version}"
pub_date_el = ET.SubElement(item, "pubDate")
pub_date_el.text = pub_date
min_version_el = ET.SubElement(item, f"{{{SPARKLE_NS}}}minimumSystemVersion")
min_version_el.text = min_system_version
enclosure = ET.SubElement(item, "enclosure")
enclosure.set("url", url)
enclosure.set(f"{{{SPARKLE_NS}}}version", build)
enclosure.set(f"{{{SPARKLE_NS}}}shortVersionString", version)
enclosure.set("length", length)
enclosure.set("type", "application/octet-stream")
enclosure.set(f"{{{SPARKLE_NS}}}edSignature", signature)

# Newest first: Sparkle picks the first item in document order whose version it accepts.
first_item = channel.find("item")
if first_item is not None:
    index = list(channel).index(first_item)
    channel.insert(index, item)
else:
    channel.append(item)

ET.indent(tree, space="    ")
tree.write(path, encoding="utf-8", xml_declaration=True)
with open(path, "a", encoding="utf-8") as f:
    f.write("\n")
PYEOF

echo "==> appcast.xml updated for $VERSION (build $BUILD_NUMBER)"

echo "==> Done"
echo "    Signed + notarized: $DMG"
echo "    Upload to GitHub Releases at: $DOWNLOAD_URL"
echo "    Then commit the updated appcast.xml so SUFeedURL serves it."
spctl --assess --type open --context context:primary-signature --verbose=2 "$DMG" || true
