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
NOTARY_PROFILE="${NOTARY_PROFILE:-}"
NOTARY_KEY_PATH="${NOTARY_KEY_PATH:-}"
NOTARY_KEY_ID="${NOTARY_KEY_ID:-}"
NOTARY_ISSUER="${NOTARY_ISSUER:-}"
APPLE_ID="${APPLE_ID:-}"
APPLE_APP_PASSWORD="${APPLE_APP_PASSWORD:-}"
APPLE_TEAM_ID="${APPLE_TEAM_ID:-}"

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
        --notary-profile|--keychain-profile)
            NOTARY_PROFILE="$2"
            shift 2
            ;;
        --api-key-path)
            NOTARY_KEY_PATH="$2"
            shift 2
            ;;
        --api-key-id)
            NOTARY_KEY_ID="$2"
            shift 2
            ;;
        --api-issuer)
            NOTARY_ISSUER="$2"
            shift 2
            ;;
        --apple-id)
            APPLE_ID="$2"
            shift 2
            ;;
        --password)
            APPLE_APP_PASSWORD="$2"
            shift 2
            ;;
        --team-id)
            APPLE_TEAM_ID="$2"
            shift 2
            ;;
        --help|-h)
            echo "Usage: ./scripts/build-and-package.sh [options]"
            echo ""
            echo "Options:"
            echo "  --identity <name>              Codesigning identity (e.g., 'Developer ID Application: Your Name (TEAM_ID)')"
            echo "  --skip-notarization            Build and package without submitting to Apple notarytool"
            echo "  --notary-profile <name>        Keychain profile name configured via 'xcrun notarytool store-credentials'"
            echo "  --api-key-path <path>          Path to App Store Connect API AuthKey_XXXX.p8"
            echo "  --api-key-id <id>              App Store Connect API Key ID"
            echo "  --api-issuer <uuid>            App Store Connect API Issuer UUID"
            echo "  --apple-id <email>             Apple Developer ID account email"
            echo "  --password <app-password>      Apple ID app-specific password"
            echo "  --team-id <team-id>            Apple Developer 10-character Team ID"
            echo "  --help, -h                     Display this help message"
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
rm -rf "${EXPORTED_APP}"
# --norsrc drops Finder resource forks that make codesign reject the bundle.
ditto --norsrc "${ARCHIVE_APP_PATH}" "${EXPORTED_APP}"

# Ensure DefaultCompanions asset hierarchy (Aquarium species & Cat sequences) is included in the application bundle
echo "    Copying DefaultCompanions asset hierarchy into .app bundle..."
mkdir -p "${EXPORTED_APP}/Contents/Resources/DefaultCompanions"
rsync -a --exclude='.DS_Store' "${PROJECT_ROOT}/Animatto/DefaultCompanions/" "${EXPORTED_APP}/Contents/Resources/DefaultCompanions/"

# Determine Version & Build
VERSION=$(/usr/libexec/PlistBuddy -c "Print :CFBundleShortVersionString" "${EXPORTED_APP}/Contents/Info.plist" 2>/dev/null || echo "1.0.0")
BUILD_NUMBER=$(/usr/libexec/PlistBuddy -c "Print :CFBundleVersion" "${EXPORTED_APP}/Contents/Info.plist" 2>/dev/null || echo "1")
DMG_NAME="Animatto-v${VERSION}.dmg"
DMG_PATH="${DIST_DIR}/${DMG_NAME}"

echo "    Detected Version: ${VERSION} (Build ${BUILD_NUMBER})"

# 3. Codesigning & Entitlements Check
echo "==> [3/6] Applying and verifying code signature..."
ENTITLEMENTS="${PROJECT_ROOT}/Animatto/Animatto.entitlements"

# Clean AppleDouble files, Finder info, and quarantine before signing.
dot_clean -m "${EXPORTED_APP}" || true
find "${EXPORTED_APP}" -name '._*' -delete
find "${EXPORTED_APP}" -name '.DS_Store' -delete
xattr -cr "${EXPORTED_APP}"

if [ "${SIGNING_IDENTITY}" = "-" ]; then
    echo "    Notice: No Developer ID Application identity supplied; applying local ad-hoc signature with Hardened Runtime..."
    if [ -f "${ENTITLEMENTS}" ]; then
        codesign --force --deep --options runtime --entitlements "${ENTITLEMENTS}" --sign - "${EXPORTED_APP}"
    else
        codesign --force --deep --options runtime --sign - "${EXPORTED_APP}"
    fi
else
    echo "    Signing application bundle with Developer ID: ${SIGNING_IDENTITY}..."
    if [ -f "${ENTITLEMENTS}" ]; then
        codesign --force --deep --options runtime --entitlements "${ENTITLEMENTS}" --sign "${SIGNING_IDENTITY}" "${EXPORTED_APP}"
    else
        codesign --force --deep --options runtime --sign "${SIGNING_IDENTITY}" "${EXPORTED_APP}"
    fi
fi

# Verify signature
echo "    Verifying application signature integrity..."
codesign --verify --deep --strict --verbose=2 "${EXPORTED_APP}"
codesign -dvvv "${EXPORTED_APP}" 2>&1 | grep -E "Authority|Identifier|Format|flags=|TeamIdentifier|CDHash" | sed 's/^/    /'
echo "    ✓ Application code signature verified."

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

BACKGROUND_IMG="${PROJECT_ROOT}/scripts/assets/dmg_background.tiff"
if [ ! -f "${BACKGROUND_IMG}" ]; then
    python3 "${PROJECT_ROOT}/scripts/generate_dmg_background.py"
fi

if command -v create-dmg >/dev/null 2>&1; then
    echo "    Using create-dmg with custom background and visual layout..."
    rm -f "${DMG_PATH}"
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

# Sign the DMG container
echo "    Applying code signature to DMG container..."
xattr -cr "${DMG_PATH}"
if [ "${SIGNING_IDENTITY}" != "-" ]; then
    codesign --force --sign "${SIGNING_IDENTITY}" "${DMG_PATH}"
else
    codesign --force --sign - "${DMG_PATH}"
fi
echo "    Verifying DMG code signature..."
codesign --verify --verbose=2 "${DMG_PATH}"
codesign -dvvv "${DMG_PATH}" 2>&1 | grep -E "Authority|Identifier|Format|CDHash" | sed 's/^/    /'
echo "    ✓ Created and signed DMG at: ${DMG_PATH}"

# 5. Notarization & Stapling (Optional / Automated when credentials provided)
echo "==> [5/6] Apple Notarization & Gatekeeper assessment..."

NOTARIZED=false

if [ "${SKIP_NOTARIZATION}" = false ]; then
    if [ -n "${NOTARY_PROFILE}" ]; then
        echo "    Submitting ${DMG_PATH} to Apple Notary service using keychain profile '${NOTARY_PROFILE}'..."
        xcrun notarytool submit "${DMG_PATH}" --keychain-profile "${NOTARY_PROFILE}" --wait
        NOTARIZED=true
    elif [ -n "${NOTARY_KEY_PATH}" ] && [ -n "${NOTARY_KEY_ID}" ] && [ -n "${NOTARY_ISSUER}" ]; then
        echo "    Submitting ${DMG_PATH} to Apple Notary service using App Store Connect API Key '${NOTARY_KEY_ID}'..."
        xcrun notarytool submit "${DMG_PATH}" --key "${NOTARY_KEY_PATH}" --key-id "${NOTARY_KEY_ID}" --issuer "${NOTARY_ISSUER}" --wait
        NOTARIZED=true
    elif [ -n "${APPLE_ID}" ] && [ -n "${APPLE_APP_PASSWORD}" ] && [ -n "${APPLE_TEAM_ID}" ]; then
        echo "    Submitting ${DMG_PATH} to Apple Notary service using Apple ID credentials for team '${APPLE_TEAM_ID}'..."
        xcrun notarytool submit "${DMG_PATH}" --apple-id "${APPLE_ID}" --password "${APPLE_APP_PASSWORD}" --team-id "${APPLE_TEAM_ID}" --wait
        NOTARIZED=true
    fi
fi

if [ "${NOTARIZED}" = true ]; then
    echo "    Stapling notarization ticket to DMG..."
    xcrun stapler staple "${DMG_PATH}"
    xcrun stapler validate "${DMG_PATH}"
    
    echo "    Running Gatekeeper assessment..."
    spctl -a -vvv -t install "${DMG_PATH}"
    echo "    ✓ Gatekeeper assessment passed."
else
    echo "    ℹ Live notarization skipped (no notary credentials supplied or --skip-notarization specified)."
    echo "    ℹ To notarize in CI/CD or locally once Apple Developer credentials are available:"
    echo "      1. Via Stored Keychain Profile:"
    echo "         xcrun notarytool store-credentials \"AC_PROFILE\" --apple-id \"developer@example.com\" --team-id \"TEAM_ID\" --password \"app-specific-password\""
    echo "         ./scripts/build-and-package.sh --identity \"Developer ID Application: Your Name (TEAM_ID)\" --notary-profile \"AC_PROFILE\""
    echo "      2. Via App Store Connect API Key (GitHub Secrets):"
    echo "         ./scripts/build-and-package.sh --identity \"Developer ID Application: ...\" --api-key-path \"AuthKey.p8\" --api-key-id \"KEY_ID\" --api-issuer \"ISSUER_UUID\""
    echo "      3. Manual verification check:"
    echo "         spctl -a -vvv -t install \"${DMG_PATH}\""
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
