# LiquidSpeedBar → Mac App Store submission guide

This repo is now prepared for App Store archive/export.

## 1) One-time Apple setup (in App Store Connect + Developer portal)

1. Create app record in App Store Connect
   - Platform: macOS
   - Bundle ID: `com.the999gabriel.liquidspeedbar` (or your custom ID)
2. Accept latest Apple agreements/tax/banking in App Store Connect
3. Ensure your Apple Developer account has App Manager/Admin permissions

## 2) Local signing setup (Xcode)

1. Open project in Xcode
2. Target → Signing & Capabilities
3. Select your Team
4. Keep signing style as Automatic
5. Ensure App Sandbox is enabled with outgoing network client access (already configured in `Config/AppStore.entitlements`)

## 3) Build App Store archive/export from CLI

```bash
cd /Users/gabriel/LiquidSpeedBar
DEVELOPER_TEAM_ID=YOURTEAMID scripts/archive-appstore.sh
```

Output:
- Archive: `dist/appstore/LiquidSpeedBar.xcarchive`
- Export: `dist/appstore/export/`

## 4) Upload build to App Store Connect

Use either:
- Transporter app (drag the exported package), or
- Xcode Organizer upload flow

## 5) Fill App Store listing fields

Required minimum items:
- App name: LiquidSpeedBar
- Subtitle (optional but recommended)
- Description
- Keywords
- Support URL
- Privacy Policy URL
- Category
- Copyright
- 1+ screenshot(s)
- Age rating questionnaire

## 6) Submit for review

1. Select uploaded build
2. Complete export compliance + content rights
3. Submit for review

---

## Notes for this project

- Open-source and donation links are allowed.
- You may include your Buy Me a Coffee link in the app UI and metadata as long as it does not bypass Apple IAP for unlocking in-app digital features.
- This app currently does not sell in-app digital content/features, so this is usually fine.
