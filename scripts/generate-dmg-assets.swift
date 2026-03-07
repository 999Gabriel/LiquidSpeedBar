#!/usr/bin/env swift

import AppKit

let outputDirectory = CommandLine.arguments.dropFirst().first ?? "build/dmg"
let outputURL = URL(fileURLWithPath: outputDirectory, isDirectory: true)

let width = 640.0
let height = 420.0
let arrowCenter = CGPoint(x: 320, y: 210)

try FileManager.default.createDirectory(at: outputURL, withIntermediateDirectories: true)

func color(_ hex: UInt32, alpha: CGFloat = 1.0) -> NSColor {
    let red = CGFloat((hex >> 16) & 0xff) / 255.0
    let green = CGFloat((hex >> 8) & 0xff) / 255.0
    let blue = CGFloat(hex & 0xff) / 255.0
    return NSColor(calibratedRed: red, green: green, blue: blue, alpha: alpha)
}

func pngData(from image: NSImage, size: NSSize) -> Data? {
    guard let tiff = image.tiffRepresentation,
          let bitmap = NSBitmapImageRep(data: tiff) else {
        return nil
    }
    bitmap.size = size
    return bitmap.representation(using: .png, properties: [:])
}

func savePNG(_ image: NSImage, to url: URL, size: NSSize) throws {
    guard let data = pngData(from: image, size: size) else {
        throw NSError(domain: "LiquidSpeedBarDMGAssets", code: 1)
    }
    try data.write(to: url)
}

func drawBackground() -> NSImage {
    let size = NSSize(width: width, height: height)
    let image = NSImage(size: size)

    image.lockFocus()

    let bounds = NSRect(origin: .zero, size: size)
    let gradient = NSGradient(colors: [
        color(0xF7FAFF),
        color(0xEAF2FF),
        color(0xF3EFFF),
    ])!
    gradient.draw(in: bounds, angle: -35)

    color(0xFFFFFF, alpha: 0.55).setFill()
    NSBezierPath(roundedRect: NSRect(x: 48, y: 54, width: 232, height: 312), xRadius: 42, yRadius: 42).fill()

    color(0xFFFFFF, alpha: 0.35).setFill()
    NSBezierPath(ovalIn: NSRect(x: 352, y: 44, width: 236, height: 144)).fill()

    color(0xDDE9FF, alpha: 0.55).setFill()
    NSBezierPath(ovalIn: NSRect(x: 312, y: 234, width: 250, height: 124)).fill()

    color(0xFFFFFF, alpha: 0.7).setStroke()
    let divider = NSBezierPath()
    divider.lineWidth = 2
    divider.move(to: CGPoint(x: 320, y: 92))
    divider.line(to: CGPoint(x: 320, y: 328))
    divider.stroke()

    let arrowPath = NSBezierPath()
    arrowPath.lineWidth = 18
    arrowPath.lineCapStyle = .round
    arrowPath.lineJoinStyle = .round
    arrowPath.move(to: CGPoint(x: arrowCenter.x - 54, y: arrowCenter.y))
    arrowPath.line(to: CGPoint(x: arrowCenter.x + 26, y: arrowCenter.y))
    arrowPath.line(to: CGPoint(x: arrowCenter.x - 6, y: arrowCenter.y + 28))
    arrowPath.move(to: CGPoint(x: arrowCenter.x + 26, y: arrowCenter.y))
    arrowPath.line(to: CGPoint(x: arrowCenter.x - 6, y: arrowCenter.y - 28))

    NSGraphicsContext.current?.saveGraphicsState()
    let shadow = NSShadow()
    shadow.shadowBlurRadius = 18
    shadow.shadowOffset = .zero
    shadow.shadowColor = color(0xBFCBDF, alpha: 0.28)
    shadow.set()
    color(0xFFFFFF, alpha: 0.9).setStroke()
    arrowPath.stroke()
    NSGraphicsContext.current?.restoreGraphicsState()

    let accent = NSBezierPath()
    accent.lineWidth = 4
    accent.move(to: CGPoint(x: 140, y: 344))
    accent.curve(to: CGPoint(x: 248, y: 372),
                 controlPoint1: CGPoint(x: 166, y: 366),
                 controlPoint2: CGPoint(x: 218, y: 378))
    color(0xD7E5FF, alpha: 0.85).setStroke()
    accent.stroke()

    image.unlockFocus()
    return image
}

func drawArrow() -> NSImage {
    let size = NSSize(width: 140, height: 72)
    let image = NSImage(size: size)

    image.lockFocus()

    let path = NSBezierPath()
    path.lineWidth = 16
    path.lineCapStyle = .round
    path.lineJoinStyle = .round
    path.move(to: CGPoint(x: 18, y: 36))
    path.line(to: CGPoint(x: 112, y: 36))
    path.line(to: CGPoint(x: 82, y: 58))
    path.move(to: CGPoint(x: 112, y: 36))
    path.line(to: CGPoint(x: 82, y: 14))

    NSGraphicsContext.current?.saveGraphicsState()
    let shadow = NSShadow()
    shadow.shadowBlurRadius = 14
    shadow.shadowOffset = .zero
    shadow.shadowColor = color(0xA8B8D2, alpha: 0.26)
    shadow.set()
    color(0xFFFFFF, alpha: 0.96).setStroke()
    path.stroke()
    NSGraphicsContext.current?.restoreGraphicsState()

    image.unlockFocus()
    return image
}

let background = drawBackground()
let arrow = drawArrow()

try savePNG(background, to: outputURL.appendingPathComponent("background.png"), size: NSSize(width: width, height: height))
try savePNG(arrow, to: outputURL.appendingPathComponent("arrow.png"), size: NSSize(width: 140, height: 72))
