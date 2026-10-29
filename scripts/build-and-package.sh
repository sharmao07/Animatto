#!/usr/bin/env bash
# ==============================================================================
# Animatto — macOS Release Packaging & Verification Script
# ==============================================================================
# This script builds the Animatto macOS application, verifies code signatures,
# packages a distributable DMG with an Applications symlink, calculates SHA-256
# checksums, and documents the Apple Notarization / Gatekeeper verification workflow.
#
# Usage:
#   ./scripts/build-and-package.sh [options]
#
# Options:
#   --skip-notarization    Build, sign locally (or ad-hoc), and generate DMG without notarization
#   --identity <name>      Codesigning identity (e.g., "Developer ID Application: Your Name (TEAM_ID)")
#   --notary-profile <key> Keychain profile name configured via `xcrun notarytool store-credentials`
#   --help                 Display this help message
# ==============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

SCHEME="Animatto"
CONFIGURATION="Release"
BUILD_DIR="${PROJECT_ROOT}/build"
DIST_DIR="${PROJECT_ROOT}/dist"
ARCHIVE_PATH="${BUILD_DIR}/${SCHEME}.xcarchive"
APP_NAME="Animatto.app"
EXPORTED_APP="${BUILD_DIR}/${APP_NAME}"

SIGNING_IDENTITY="-"
SKIP_NOTARIZATION=false
NOTARY_PROFILE=""

# Parse Arguments
while [[ $# -gt 0 ]]; do
    case "$1" in
        --skip-notarization)
            SKIP_NOTARIZATION=true
            shift
            ;;
        --identity)
            SIGNING_IDENTITY="$2"
            shift 2
            ;;
        --notary-profile)
            NOTARY_PROFILE="$2"
            shift 2
            ;;
        --help|-h)
            echo "Usage: ./scripts/build-and-package.sh [--skip-notarization] [--identity <name>] [--notary-profile <profile>]"
            exit 0
            ;;
        *)
            echo "Unknown argument: $1"
            exit 1
            ;;
    esac
done

echo "=========================================================="
echo " Starting Animatto Packaging & Release Verification"
echo " Configuration: ${CONFIGURATION}"
echo " Root:          ${PROJECT_ROOT}"
echo "=========================================================="

# Clean build and dist directories
rm -rf "${BUILD_DIR}" "${DIST_DIR}"
mkdir -p "${BUILD_DIR}" "${DIST_DIR}"

# 1. Archive the App
echo "==> [1/6] Archiving application with xcodebuild..."
xcodebuild archive \
    -project "${PROJECT_ROOT}/Animatto.xcodeproj" \
    -scheme "${SCHEME}" \
    -configuration "${CONFIGURATION}" \
    -archivePath "${ARCHIVE_PATH}" \
    CODE_SIGNING_ALLOWED=NO \
    -derivedDataPath "${BUILD_DIR}/DerivedData" \
    -quiet

# 2. Extract .app bundle from archive
echo "==> [2/6] Extracting .app bundle..."
ARCHIVE_APP_PATH="${ARCHIVE_PATH}/Products/Applications/${APP_NAME}"
if [ ! -d "${ARCHIVE_APP_PATH}" ]; then
    echo "Error: Archive failed to produce ${APP_NAME} at ${ARCHIVE_APP_PATH}"
    exit 1
fi
cp -R "${ARCHIVE_APP_PATH}" "${EXPORTED_APP}"

# Determine Version & Build
VERSION=$(/usr/libexec/PlistBuddy -c "Print :CFBundleShortVersionString" "${EXPORTED_APP}/Contents/Info.plist" 2>/dev/null || echo "1.0.0")
BUILD_NUMBER=$(/usr/libexec/PlistBuddy -c "Print :CFBundleVersion" "${EXPORTED_APP}/Contents/Info.plist" 2>/dev/null || echo "1")
DMG_NAME="Animatto-v${VERSION}.dmg"
DMG_PATH="${DIST_DIR}/${DMG_NAME}"

echo "    Detected Version: ${VERSION} (Build ${BUILD_NUMBER})"

# 3. Codesigning & Entitlements Check
echo "==> [3/6] Applying and verifying code signature..."
ENTITLEMENTS="${PROJECT_ROOT}/Animatto/Animatto.entitlements"

# Clean extended attributes/quarantine/detritus before signing
xattr -cr "${EXPORTED_APP}"

if [ "${SIGNING_IDENTITY}" = "-" ]; then
    echo "    Notice: No Developer ID Application identity supplied; applying local ad-hoc signature."
    if [ -f "${ENTITLEMENTS}" ]; then
        codesign --force --deep --entitlements "${ENTITLEMENTS}" --sign - "${EXPORTED_APP}"
    else
        codesign --force --deep --sign - "${EXPORTED_APP}"
    fi
else
    echo "    Signing with identity: ${SIGNING_IDENTITY}..."
    if [ -f "${ENTITLEMENTS}" ]; then
        codesign --force --deep --options runtime --entitlements "${ENTITLEMENTS}" --sign "${SIGNING_IDENTITY}" "${EXPORTED_APP}"
    else
        codesign --force --deep --options runtime --sign "${SIGNING_IDENTITY}" "${EXPORTED_APP}"
    fi
fi

# Verify signature
echo "    Verifying signature integrity..."
codesign --verify --deep --strict --verbose=2 "${EXPORTED_APP}"
echo "    ✓ Code signature verified."

# 4. Create DMG
echo "==> [4/6] Packaging into disk image (${DMG_NAME})..."
DMG_STAGING="${BUILD_DIR}/dmg_staging"
rm -rf "${DMG_STAGING}"
mkdir -p "${DMG_STAGING}"

cp -R "${EXPORTED_APP}" "${DMG_STAGING}/"

# Copy installation instructions text file if present
if [ -f "${PROJECT_ROOT}/How to install.txt" ]; then
    echo "    Including 'How to install.txt' in DMG..."
    cp "${PROJECT_ROOT}/How to install.txt" "${DMG_STAGING}/"
fi

# Include companion character packs if explicitly requested via --include-companion-packs
INCLUDE_COMPANIONS=false
for arg in "$@"; do
    if [ "$arg" = "--include-companion-packs" ]; then
        INCLUDE_COMPANIONS=true
    fi
done

if [ "$INCLUDE_COMPANIONS" = true ] && [ -d "${PROJECT_ROOT}/some characters" ]; then
    echo "    Including 'some characters' folder in DMG staging..."
    cp -R "${PROJECT_ROOT}/some characters" "${DMG_STAGING}/"
fi

BACKGROUND_IMG="${PROJECT_ROOT}/scripts/assets/dmg_background.tiff"
if [ ! -f "${BACKGROUND_IMG}" ]; then
    python3 "${PROJECT_ROOT}/scripts/generate_dmg_background.py"
fi

if command -v create-dmg >/dev/null 2>&1; then
    echo "    Using create-dmg with custom background and visual layout..."
    rm -f "${DMG_PATH}"
    if [ -d "${DMG_STAGING}/some characters" ]; then
        create-dmg \
            --volname "Animatto" \
            --background "${BACKGROUND_IMG}" \
            --window-pos 200 100 \
            --window-size 1024 710 \
            --icon-size 100 \
            --icon "${APP_NAME}" 205 310 \
            --app-drop-link 819 310 \
            --icon "How to install.txt" 288 525 \
            --icon "some characters" 736 525 \
            --format UDZO \
            --overwrite \
            "${DMG_PATH}" \
            "${DMG_STAGING}"
    else
        create-dmg \
            --volname "Animatto" \
            --background "${BACKGROUND_IMG}" \
            --window-pos 200 100 \
            --window-size 1024 710 \
            --icon-size 100 \
            --icon "${APP_NAME}" 205 310 \
            --app-drop-link 819 310 \
            --icon "How to install.txt" 288 525 \
            --format UDZO \
            --overwrite \
            "${DMG_PATH}" \
            "${DMG_STAGING}"
    fi
else
    echo "    create-dmg not found; falling back to standard hdiutil..."
    ln -s /Applications "${DMG_STAGING}/Applications"
    hdiutil create \
        -volname "Animatto" \
        -srcfolder "${DMG_STAGING}" \
        -ov \
        -format UDZO \
        "${DMG_PATH}" \
        -quiet
fi

echo "    ✓ Created DMG at: ${DMG_PATH}"

# 5. Notarization & Stapling (Optional / Automated when credentials provided)
echo "==> [5/6] Apple Notarization & Gatekeeper assessment..."
if [ "${SKIP_NOTARIZATION}" = true ] || [ -z "${NOTARY_PROFILE}" ]; then
    echo "    ℹ Notarization skipped (no --notary-profile supplied or --skip-notarization specified)."
    echo "    ℹ To notarize in CI/CD with Apple Developer credentials:"
    echo "        xcrun notarytool submit \"${DMG_PATH}\" --keychain-profile \"<PROFILE>\" --wait"
    echo "        xcrun stapler staple \"${DMG_PATH}\""
    echo "        spctl -a -vvv -t install \"${DMG_PATH}\""
else
    echo "    Submitting ${DMG_PATH} to Apple Notary service using profile '${NOTARY_PROFILE}'..."
    xcrun notarytool submit "${DMG_PATH}" --keychain-profile "${NOTARY_PROFILE}" --wait
    
    echo "    Stapling notarization ticket to DMG..."
    xcrun stapler staple "${DMG_PATH}"
    
    echo "    Running Gatekeeper assessment..."
    spctl -a -vvv -t install "${DMG_PATH}"
    echo "    ✓ Gatekeeper assessment passed."
fi

# 6. Generate Release Checksums
echo "==> [6/6] Generating release checksums..."
SHA256_FILE="${DIST_DIR}/SHA256SUMS.txt"
rm -f "${SHA256_FILE}"
(cd "${DIST_DIR}" && shasum -a 256 "${DMG_NAME}" > "${SHA256_FILE}")

echo "=========================================================="
echo " Release Packaging Succeeded!"
echo " DMG:      ${DMG_PATH}"
echo " Assets in ${DIST_DIR}:"
ls -la "${DIST_DIR}"
echo ""
echo " Checksums:"
cat "${SHA256_FILE}"
echo "=========================================================="
