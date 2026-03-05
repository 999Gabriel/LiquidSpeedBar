import AppKit
import SwiftUI

@main
struct LiquidSpeedBarApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @StateObject private var monitor = NetworkSpeedMonitor()

    var body: some Scene {
        MenuBarExtra {
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 8) {
                    Text(monitor.moodEmoji)
                        .font(.system(size: 20))

                    Text(monitor.moodText)
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                }

                HStack {
                    Text("Download")
                    Spacer(minLength: 10)
                    Text(monitor.downloadDetailed)
                        .monospacedDigit()
                }
                .font(.system(size: 12, weight: .medium, design: .rounded))

                HStack {
                    Text("Upload")
                    Spacer(minLength: 10)
                    Text(monitor.uploadDetailed)
                        .monospacedDigit()
                }
                .font(.system(size: 12, weight: .medium, design: .rounded))

                Text("Updated \(monitor.lastUpdated, style: .time)")
                    .font(.system(size: 11, weight: .regular, design: .rounded))
                    .foregroundStyle(.secondary)

                Divider()

                Button("Quit") {
                    NSApplication.shared.terminate(nil)
                }
                .buttonStyle(.bordered)
            }
            .padding(12)
            .frame(width: 240)
        } label: {
            MenuBarCompactLabel(
                emoji: monitor.moodEmoji,
                downloadCompact: monitor.downloadCompact,
                uploadCompact: monitor.uploadCompact
            )
        }
        .menuBarExtraStyle(.window)
    }
}

private struct MenuBarCompactLabel: View {
    let emoji: String
    let downloadCompact: String
    let uploadCompact: String

    var body: some View {
        HStack(spacing: 4) {
            Text(emoji)
                .font(.system(size: 12))
            Text("↓\(downloadCompact)")
            Text("↑\(uploadCompact)")
        }
        .font(.system(size: 11, weight: .semibold, design: .rounded))
        .monospacedDigit()
        .lineLimit(1)
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
    }
}
