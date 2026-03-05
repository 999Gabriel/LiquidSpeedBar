# LiquidSpeedBar

A modern macOS menu bar network speed detector built in Swift.

It shows live network throughput in your menu bar with mood emojis that reflect connection quality:

- 😴 very slow
- 🙂 steady
- 😄 fast
- 🚀 very fast
- 🤯 blazing fast

## Design Direction

- Liquid-glass style bubble directly in the menu bar label
- Native Apple-style dashboard using materials, rounded cards, and subtle gradients
- Live chart for download/upload traffic and clean utility actions

## Features

- Real-time upload and download tracking
- Primary interface detection (with IPv4/IPv6 fallback)
- Menu bar label with emoji + arrows (`↓ download`, `↑ upload`)
- Emoji mood indicator based on current speed
- Click popover with live dashboard summary and controls
- Dedicated full dashboard window

## Requirements

- macOS 14+
- Xcode 16+ (or Swift 6.2 toolchain)

## Run

```bash
swift run
```

## Build

```bash
swift build
```

## Open in Xcode

```bash
open Package.swift
```

Then run the `LiquidSpeedBar` executable target.

## Notes

The app runs as a menu-bar utility (`LSUIElement` behavior achieved via `NSApp.setActivationPolicy(.accessory)`) and does not show a Dock icon.

## License

MIT
