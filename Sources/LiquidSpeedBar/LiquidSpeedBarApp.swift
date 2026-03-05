import AppKit
import SwiftUI

@main
struct LiquidSpeedBarApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @StateObject private var monitor = NetworkSpeedMonitor()

    var body: some Scene {
        MenuBarExtra {
            SpeedPopoverView(monitor: monitor)
                .frame(width: 340)
                .padding(14)
        } label: {
            MenuBarBubble(emoji: monitor.speedMood.emoji, speedText: monitor.compactSpeedText)
        }
        .menuBarExtraStyle(.window)
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
    }
}
