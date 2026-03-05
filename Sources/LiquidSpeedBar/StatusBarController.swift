import AppKit
import SwiftUI

private let buyMeACoffeeURL = URL(string: "https://buymeacoffee.com/the999gabriel")!
private let buyMeACoffeeButtonImageURL = URL(string: "https://cdn.buymeacoffee.com/buttons/v2/default-yellow.png")!

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
        popover.contentSize = NSSize(width: 276, height: 208)
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
        HStack(alignment: .center, spacing: 6) {
            Text(monitor.moodEmoji)
                .font(.system(size: 20))
                .frame(width: 22)

            VStack(alignment: .leading, spacing: -1) {
                SpeedLine(
                    icon: "arrow.down.forward.circle.fill",
                    value: monitor.downloadCompact,
                    tint: Color(red: 0.11, green: 0.48, blue: 0.95)
                )
                SpeedLine(
                    icon: "arrow.up.forward.circle.fill",
                    value: monitor.uploadCompact,
                    tint: Color(red: 0.09, green: 0.68, blue: 0.43)
                )
            }

            HealthPill(score: monitor.healthScore)

            MiniActivityGraph(
                download: monitor.downloadHistoryMbps,
                upload: monitor.uploadHistoryMbps,
                ceiling: monitor.graphCeilingMbps
            )
            .frame(width: 58, height: 18)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 2)
        .frame(minWidth: 156, alignment: .leading)
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

            SpeedRow(
                icon: "arrow.down.forward.circle.fill",
                label: "Download",
                value: monitor.downloadDetailed,
                tint: Color(red: 0.11, green: 0.48, blue: 0.95)
            )

            SpeedRow(
                icon: "arrow.up.forward.circle.fill",
                label: "Upload",
                value: monitor.uploadDetailed,
                tint: Color(red: 0.09, green: 0.68, blue: 0.43)
            )

            MiniActivityGraph(
                download: monitor.downloadHistoryMbps,
                upload: monitor.uploadHistoryMbps,
                ceiling: monitor.graphCeilingMbps
            )
            .frame(height: 74)

            HealthInsightCard(
                score: monitor.healthScore,
                state: monitor.healthState,
                insight: monitor.insightText
            )

            Link(destination: buyMeACoffeeURL) {
                BuyMeACoffeeButton()
            }
            .buttonStyle(.plain)

            Divider()

            HStack {
                Button("Copy Diagnostics") {
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(monitor.diagnosticsSnapshot, forType: .string)
                }
                .buttonStyle(.borderedProminent)

                Spacer(minLength: 0)

                Button("Quit") {
                    NSApplication.shared.terminate(nil)
                }
                .buttonStyle(.bordered)
            }
        }
        .font(.system(size: 12, weight: .medium, design: .rounded))
        .padding(12)
        .frame(width: 276)
    }
}

private struct BuyMeACoffeeButton: View {
    var body: some View {
        AsyncImage(url: buyMeACoffeeButtonImageURL) { phase in
            switch phase {
            case .success(let image):
                image
                    .resizable()
                    .interpolation(.high)
                    .scaledToFit()
            default:
                HStack(spacing: 6) {
                    Image(systemName: "cup.and.saucer.fill")
                    Text("Buy me a coffee")
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                }
                .foregroundStyle(.black)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color(red: 1.0, green: 0.87, blue: 0.24))
            }
        }
        .frame(width: 200, height: 43)
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .strokeBorder(.black.opacity(0.07), lineWidth: 0.7)
        }
        .shadow(color: .black.opacity(0.09), radius: 2, x: 0, y: 1)
    }
}

private struct SpeedLine: View {
    let icon: String
    let value: String
    let tint: Color

    var body: some View {
        HStack(spacing: 3) {
            Image(systemName: icon)
                .font(.system(size: 8.5, weight: .bold))
                .foregroundStyle(tint)

            Text(value)
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .monospacedDigit()
                .lineLimit(1)
        }
    }
}

private struct SpeedRow: View {
    let icon: String
    let label: String
    let value: String
    let tint: Color

    var body: some View {
        HStack {
            Label {
                Text(label)
            } icon: {
                Image(systemName: icon)
                    .foregroundStyle(tint)
            }

            Spacer(minLength: 10)

            Text(value)
                .monospacedDigit()
        }
    }
}

private struct MiniActivityGraph: View {
    let download: [Double]
    let upload: [Double]
    let ceiling: Double

    var body: some View {
        GeometryReader { proxy in
            let size = proxy.size

            ZStack {
                RoundedRectangle(cornerRadius: 5, style: .continuous)
                    .fill(Color.black.opacity(0.06))

                linePath(values: download, in: size, maxValue: ceiling)
                    .stroke(
                        Color(red: 0.11, green: 0.48, blue: 0.95),
                        style: StrokeStyle(lineWidth: 1.3, lineCap: .round, lineJoin: .round)
                    )

                linePath(values: upload, in: size, maxValue: ceiling)
                    .stroke(
                        Color(red: 0.09, green: 0.68, blue: 0.43),
                        style: StrokeStyle(lineWidth: 1.3, lineCap: .round, lineJoin: .round)
                    )
            }
        }
    }

    private func linePath(values: [Double], in size: CGSize, maxValue: Double) -> Path {
        let points = Array(values.suffix(34))
        guard points.count > 1 else {
            return Path()
        }

        let width = max(size.width - 4, 1)
        let height = max(size.height - 4, 1)
        let stepX = width / CGFloat(points.count - 1)
        let cap = max(maxValue, 0.1)

        var path = Path()
        for index in points.indices {
            let normalized = min(max(points[index] / cap, 0), 1)
            let x = 2 + CGFloat(index) * stepX
            let y = 2 + height - CGFloat(normalized) * height
            let point = CGPoint(x: x, y: y)

            if index == points.startIndex {
                path.move(to: point)
            } else {
                path.addLine(to: point)
            }
        }

        return path
    }
}

private struct HealthPill: View {
    let score: Int

    var body: some View {
        Text("\(score)")
            .font(.system(size: 9.5, weight: .bold, design: .rounded))
            .foregroundStyle(.white)
            .padding(.horizontal, 5)
            .padding(.vertical, 2)
            .background(
                Capsule(style: .continuous)
                    .fill(colorForScore(score))
            )
    }
}

private struct HealthInsightCard: View {
    let score: Int
    let state: String
    let insight: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("Health \(score)/100")
                    .font(.system(size: 12, weight: .bold, design: .rounded))

                Spacer(minLength: 0)

                Text(state)
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                    .padding(.horizontal, 7)
                    .padding(.vertical, 3)
                    .background(
                        Capsule(style: .continuous)
                            .fill(colorForScore(score).opacity(0.18))
                    )
            }

            GeometryReader { proxy in
                let width = proxy.size.width
                let fill = max(0, min(CGFloat(score) / 100.0, 1.0)) * width

                ZStack(alignment: .leading) {
                    Capsule(style: .continuous)
                        .fill(Color.black.opacity(0.08))

                    Capsule(style: .continuous)
                        .fill(colorForScore(score))
                        .frame(width: fill)
                }
            }
            .frame(height: 8)

            Text(insight)
                .font(.system(size: 11, weight: .medium, design: .rounded))
                .foregroundStyle(.secondary)
        }
        .padding(9)
        .background(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(Color.black.opacity(0.03))
        )
    }
}

private func colorForScore(_ score: Int) -> Color {
    switch score {
    case ..<35:
        return Color(red: 0.91, green: 0.35, blue: 0.29)
    case ..<60:
        return Color(red: 0.93, green: 0.66, blue: 0.19)
    case ..<80:
        return Color(red: 0.24, green: 0.62, blue: 0.98)
    default:
        return Color(red: 0.16, green: 0.72, blue: 0.42)
    }
}
