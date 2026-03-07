# Direct Distribution Security (Developer ID + Notarization)

This guide is for DMG / direct-download releases (outside the Mac App Store).

## Prerequisites

1. Apple Developer account with a valid `Developer ID Application` certificate
2. Xcode command line tools
3. Notarization credentials configured in one of these ways:

- Keychain profile (recommended):

```bash
xcrun notarytool store-credentials "LiquidSpeedBarNotary" \
  --apple-id "YOUR_APPLE_ID" \
  --team-id "YOUR_TEAM_ID" \
  --password "APP_SPECIFIC_PASSWORD"
```

- Or environment variables:
  - `NOTARY_APPLE_ID`
  - `NOTARY_APP_PASSWORD`
  - `NOTARY_TEAM_ID`

## Build a trusted release artifact

```bash
DEVELOPER_ID_APPLICATION="Developer ID Application: Your Name (TEAMID)" \
NOTARY_KEYCHAIN_PROFILE="LiquidSpeedBarNotary" \
scripts/package-macos.sh
```

This produces:

- `dist/LiquidSpeedBar.app` (signed, stapled)
- `dist/LiquidSpeedBar-macOS-<version>.dmg` (signed, notarized, stapled)
- `dist/LiquidSpeedBar-macOS-<version>.app.tar.gz`

## Verify on any machine

```bash
scripts/verify-gatekeeper.sh /Applications/LiquidSpeedBar.app
```

## Local-only test build (not for end users)

```bash
ALLOW_UNSIGNED_RELEASE=1 SKIP_NOTARIZATION=1 scripts/package-macos.sh
```
