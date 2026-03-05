# LiquidSpeedBar

A modern macOS menu bar network speed detector built in Swift.

It shows live network throughput in your menu bar with mood emojis that reflect connection quality:

- 😴 very slow
- 🙂 steady
- 😄 fast
- 🚀 very fast
- 🤯 blazing fast

## Design Direction

- Liquid-glass style bubble in the menu bar label
- Glassy popover with gradient background and rounded metric cards
- Rounded typography and minimal controls for a clean native feel

## Features

- Real-time upload and download tracking
- Primary interface detection (with IPv4/IPv6 fallback)
- Compact speed badge in the menu bar
- Emoji mood indicator based on current speed
- Quit action from the popover

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
