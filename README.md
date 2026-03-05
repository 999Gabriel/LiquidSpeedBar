# LiquidSpeedBar

Minimal macOS menu bar network speed app built in Swift.

## Features

- Live upload/download speed directly in the menu bar
- Emoji mood indicator + health score
- Mini activity graph in the menu bar and popover
- Copy diagnostics snapshot
- Buy Me a Coffee support button

## Development

```bash
swift run
```

```bash
swift build
```

## Download Options (3)

### 1) Direct DMG Download (.app inside)

Build a distributable `.dmg` and `.app.tar.gz` locally:

```bash
scripts/package-macos.sh
```

Output files:

- `dist/LiquidSpeedBar.app`
- `dist/LiquidSpeedBar-macOS-<version>.dmg`
- `dist/LiquidSpeedBar-macOS-<version>.app.tar.gz`

### 2) Install From Terminal (one command)

Users can install with:

```bash
curl -fsSL https://raw.githubusercontent.com/999Gabriel/LiquidSpeedBar/main/scripts/install.sh | bash
```

Installer behavior:
- If a GitHub release contains a `.app.tar.gz` asset, it installs that.
- If no release exists yet, it automatically falls back to building from source locally and then installs.

This installs `LiquidSpeedBar.app` to `/Applications`.

### 3) Mac App Store Distribution

App Store archive/export flow:

```bash
DEVELOPER_TEAM_ID=YOURTEAMID scripts/archive-appstore.sh
```

This generates an App Store export under `dist/appstore/export`.

## CI Release Automation

Tag a version (for example `v1.0.0`) and push it to trigger the GitHub Actions workflow that builds and uploads release assets:

```bash
git tag v1.0.0
git push origin v1.0.0
```

Workflow file: `.github/workflows/release-macos.yml`

## App Store Checklist

- Create app in App Store Connect
- Set bundle ID to match `PRODUCT_BUNDLE_IDENTIFIER`
- Configure signing + certificates in Xcode
- Run `scripts/archive-appstore.sh`
- Upload the exported package with Transporter
- Submit for review

## Support

Buy me a coffee: https://buymeacoffee.com/the999gabriel
