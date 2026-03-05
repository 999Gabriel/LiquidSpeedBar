import AppKit
import SwiftUI

@MainActor
final class StatusBarController: NSObject {
    private let monitor = NetworkSpeedMonitor()
    private let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    private let popover = NSPopover()

    override init() {
        super.init()
        configureStatusItem()
        configurePopover()
    }

    private func configureStatusItem() {
        guard let button = statusItem.button else {
            return
        }

        button.title = ""
        button.image = nil
        button.target = self
        button.action = #selector(togglePopover)
        button.sendAction(on: [.leftMouseUp])

        let rootView = StatusBarCompactView(monitor: monitor)
            .allowsHitTesting(false)
        let hostingView = NSHostingView(rootView: rootView)
        hostingView.translatesAutoresizingMaskIntoConstraints = false
        button.addSubview(hostingView)

        NSLayoutConstraint.activate([
            hostingView.leadingAnchor.constraint(equalTo: button.leadingAnchor, constant: 2),
            hostingView.trailingAnchor.constraint(equalTo: button.trailingAnchor, constant: -2),
            hostingView.centerYAnchor.constraint(equalTo: button.centerYAnchor)
        ])
    }

    private func configurePopover() {
        popover.behavior = .transient
        popover.animates = true
        popover.contentSize = NSSize(width: 240, height: 150)
        popover.contentViewController = NSHostingController(rootView: StatusPopoverView(monitor: monitor))
    }

    @objc
    private func togglePopover() {
        guard let button = statusItem.button else {
            return
        }

        if popover.isShown {
            popover.performClose(nil)
        } else {
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
        }
    }
}

private struct StatusBarCompactView: View {
    @ObservedObject var monitor: NetworkSpeedMonitor

    var body: some View {
        HStack(alignment: .center, spacing: 4) {
            Text(monitor.moodEmoji)
                .font(.system(size: 16))
                .frame(width: 18)

            VStack(alignment: .leading, spacing: -2) {
                Text("↓\(monitor.downloadCompact)")
                Text("↑\(monitor.uploadCompact)")
            }
            .font(.system(size: 10, weight: .bold, design: .rounded))
            .monospacedDigit()
            .lineLimit(1)
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 1)
        .foregroundStyle(.black.opacity(0.92))
        .background(
            RoundedRectangle(cornerRadius: 7, style: .continuous)
                .fill(Color.white)
        )
        .overlay {
            RoundedRectangle(cornerRadius: 7, style: .continuous)
                .strokeBorder(.black.opacity(0.06), lineWidth: 0.6)
        }
        .fixedSize()
    }
}

private struct StatusPopoverView: View {
    @ObservedObject var monitor: NetworkSpeedMonitor

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Text(monitor.moodEmoji)
                    .font(.system(size: 22))

                Text(monitor.moodText)
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
            }

            HStack {
                Text("Download")
                Spacer(minLength: 10)
                Text(monitor.downloadDetailed)
                    .monospacedDigit()
            }

            HStack {
                Text("Upload")
                Spacer(minLength: 10)
                Text(monitor.uploadDetailed)
                    .monospacedDigit()
            }

            Divider()

            Button("Quit") {
                NSApplication.shared.terminate(nil)
            }
            .buttonStyle(.bordered)
        }
        .font(.system(size: 12, weight: .medium, design: .rounded))
        .padding(12)
        .frame(width: 240)
    }
}
