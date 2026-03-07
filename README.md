<p align="center">
  <img src="source/liquidspeedbar.png" alt="LiquidSpeedBar App Icon" width="128" height="128" />
</p>

<h1 align="center">LiquidSpeedBar</h1>

<p align="center">
  A lightweight macOS menu bar utility for live network speed monitoring.
</p>

## Overview

LiquidSpeedBar shows live download and upload speeds directly in the menu bar, with a compact activity graph and connection health score.

The app also includes mood emojis in the UI to reflect current connection quality.

## Features

- Live upload and download speed in the menu bar
- Compact activity graph for traffic trend visualization
- Health score with bottleneck and stability insight
- Diagnostics snapshot copy action
- Buy Me a Coffee button in the popover
- Custom app icon generated from `source/liquidspeedbar.png`

## Run Locally

```bash
swift run
```

## Build

```bash
swift build
```

## Distribution (3 Options)

### 1. DMG Download (.app inside)

Create a signed and notarized DMG + app archive:

```bash
DEVELOPER_ID_APPLICATION="Developer ID Application: Your Name (TEAMID)" \
NOTARY_KEYCHAIN_PROFILE="LiquidSpeedBarNotary" \
scripts/package-macos.sh
```

Generated outputs:

- `dist/LiquidSpeedBar.app`
- `dist/LiquidSpeedBar-macOS-<version>.dmg`
- `dist/LiquidSpeedBar-macOS-<version>.app.tar.gz`

Unsigned local test build only:

```bash
ALLOW_UNSIGNED_RELEASE=1 SKIP_NOTARIZATION=1 scripts/package-macos.sh
```

### 2. Terminal Install

Users can install with a single command:

```bash
curl -fsSL https://raw.githubusercontent.com/999Gabriel/LiquidSpeedBar/main/scripts/install.sh | bash
```

Installer behavior:

- Uses latest `.app.tar.gz` release asset when available
- Falls back to source build if no release asset exists
- Keeps Gatekeeper verification intact (no quarantine bypass)

Installs to `/Applications/LiquidSpeedBar.app`.

### 3. Mac App Store Submission

Generate archive/export package:

```bash
DEVELOPER_TEAM_ID=YOURTEAMID scripts/archive-appstore.sh
```

Output path:

- `dist/appstore/export`

## Release Automation

Tag and push to publish release assets through GitHub Actions:

```bash
git tag v1.0.1
git push origin v1.0.1
```

Workflow file:

- `.github/workflows/release-macos.yml`

For signed/notarized tag releases, configure these GitHub repository secrets:

- `DEVELOPER_ID_APPLICATION` (for example `Developer ID Application: Your Name (TEAMID)`)
- `MACOS_CERTIFICATE_P12_BASE64` (base64-encoded Developer ID Application `.p12`)
- `MACOS_CERTIFICATE_PASSWORD`
- `NOTARY_APPLE_ID`
- `NOTARY_APP_PASSWORD` (app-specific password)
- `NOTARY_TEAM_ID`

Manual run for an existing tag:

```bash
gh workflow run release-macos.yml --repo 999Gabriel/LiquidSpeedBar --ref v1.0.1
```

Manual workflow dispatch without a tag builds unsigned test artifacts only.

## Gatekeeper Diagnostics

Run trust checks on any machine:

```bash
scripts/verify-gatekeeper.sh /Applications/LiquidSpeedBar.app
```

Or run the raw commands:

```bash
spctl -a -vvv --type exec "/Applications/LiquidSpeedBar.app"
codesign -dv --verbose=4 "/Applications/LiquidSpeedBar.app"
xattr -l "/Applications/LiquidSpeedBar.app"
xcrun stapler validate "/Applications/LiquidSpeedBar.app"
```

Detailed direct distribution setup:

- `DIRECT_DISTRIBUTION.md`

## App Store Checklist

- Create app in App Store Connect
- Match bundle ID with `PRODUCT_BUNDLE_IDENTIFIER`
- Configure signing certificates and team in Xcode
- Run `scripts/archive-appstore.sh`
- Upload exported package with Transporter
- Submit for review

## Support

Buy Me a Coffee:

- https://buymeacoffee.com/the999gabriel
