import AppKit
import SwiftUI

@main
struct LiquidSpeedBarApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @StateObject private var monitor = NetworkSpeedMonitor()

    var body: some Scene {
        MenuBarExtra {
            SpeedPopoverView(monitor: monitor)
                .frame(width: 390)
                .padding(14)
        } label: {
            MenuBarBubble(
                emoji: monitor.speedMood.emoji,
                downloadText: monitor.downloadMenuText,
                uploadText: monitor.uploadMenuText
            )
        }
        .menuBarExtraStyle(.window)

        Window("LiquidSpeedBar Dashboard", id: "dashboard") {
            NetworkDashboardWindow(monitor: monitor)
                .frame(minWidth: 880, minHeight: 560)
        }
        .defaultSize(width: 920, height: 600)
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
    }
}
