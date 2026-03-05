import AppKit
import Foundation
import SwiftUI

private let terminalGreen = Color(red: 0.62, green: 0.98, blue: 0.58)
private let terminalGreenSoft = Color(red: 0.44, green: 0.77, blue: 0.42)
private let terminalTextDim = Color(red: 0.56, green: 0.64, blue: 0.56)
private let terminalPanel = Color(red: 0.06, green: 0.09, blue: 0.07)

struct MenuBarBubble: View {
    let emoji: String
    let downloadText: String
    let uploadText: String

    var body: some View {
        HStack(spacing: 7) {
            Text(emoji)
                .font(.system(size: 12))

            Text("\u{2193}\(downloadText)")
                .font(.system(size: 11, weight: .bold, design: .monospaced))

            Text("\u{2191}\(uploadText)")
                .font(.system(size: 11, weight: .bold, design: .monospaced))
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 10)
        .padding(.vertical, 4)
        .background {
            ZStack {
                Capsule()
                    .fill(.ultraThinMaterial)

                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [
                                .white.opacity(0.52),
                                Color(red: 0.45, green: 0.68, blue: 0.92).opacity(0.28),
                                .white.opacity(0.18)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
        }
        .overlay {
            Capsule()
                .strokeBorder(.white.opacity(0.72), lineWidth: 0.9)
        }
        .shadow(color: .black.opacity(0.24), radius: 7, x: 0, y: 2)
        .compositingGroup()
    }
}

struct SpeedPopoverView: View {
    @ObservedObject var monitor: NetworkSpeedMonitor
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            CommandMenu(monitor: monitor, openDashboard: { openWindow(id: "dashboard") })

            Divider()
                .overlay(.white.opacity(0.2))

            TerminalDashboardPreview(monitor: monitor)
        }
        .padding(16)
        .background {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 0.06, green: 0.12, blue: 0.08),
                            Color(red: 0.02, green: 0.08, blue: 0.05),
                            Color(red: 0.03, green: 0.04, blue: 0.05)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay {
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .fill(.ultraThinMaterial.opacity(0.42))
                }
                .overlay {
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .strokeBorder(.white.opacity(0.34), lineWidth: 0.9)
                }
        }
    }
}

struct NetworkDashboardWindow: View {
    @ObservedObject var monitor: NetworkSpeedMonitor

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("LiquidSpeedBar // dashboard")
                        .font(.system(size: 22, weight: .bold, design: .monospaced))
                        .foregroundStyle(terminalGreen)

                    Text("iface \(monitor.activeInterfaceName) | updated \(monitor.lastUpdated, style: .time)")
                        .font(.system(size: 13, weight: .regular, design: .monospaced))
                        .foregroundStyle(terminalTextDim)
                }

                Spacer(minLength: 0)

                Text(monitor.speedMood.emoji)
                    .font(.system(size: 40))
            }

            HStack(spacing: 12) {
                DashMetric(title: "DOWN", value: monitor.downloadText, accent: terminalGreen)
                DashMetric(title: "UP", value: monitor.uploadText, accent: Color(red: 0.38, green: 0.93, blue: 0.82))
                DashMetric(title: "TOTAL", value: monitor.compactSpeedText, accent: Color(red: 0.81, green: 0.95, blue: 0.48))
                DashMetric(title: "MOOD", value: monitor.speedMood.description, accent: Color(red: 0.92, green: 0.97, blue: 0.72))
            }

            TerminalDashboardPreview(monitor: monitor)
                .frame(maxWidth: .infinity)

            HStack {
                Button(monitor.isPaused ? "$ resume" : "$ pause") {
                    monitor.toggleSampling()
                }
                .buttonStyle(.bordered)

                Button("$ reset-history") {
                    monitor.resetHistory()
                }
                .buttonStyle(.bordered)

                Spacer(minLength: 0)

                Button("$ quit") {
                    NSApplication.shared.terminate(nil)
                }
                .buttonStyle(.borderedProminent)
            }
            .tint(.white.opacity(0.24))
            .font(.system(size: 12, weight: .semibold, design: .monospaced))
        }
        .padding(20)
        .background {
            LinearGradient(
                colors: [
                    Color(red: 0.03, green: 0.06, blue: 0.04),
                    Color(red: 0.02, green: 0.04, blue: 0.03),
                    Color(red: 0.03, green: 0.03, blue: 0.05)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .overlay {
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .fill(.ultraThinMaterial.opacity(0.16))
                    .padding(8)
            }
            .ignoresSafeArea()
        }
    }
}

private struct CommandMenu: View {
    @ObservedObject var monitor: NetworkSpeedMonitor
    let openDashboard: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("menu")
                .font(.system(size: 11, weight: .bold, design: .monospaced))
                .foregroundStyle(terminalGreen)

            CommandRow(title: "$ open --dashboard", symbol: "rectangle.inset.filled.and.person.filled") {
                openDashboard()
            }

            CommandRow(title: monitor.isPaused ? "$ net --resume" : "$ net --pause", symbol: "pause.circle.fill") {
                monitor.toggleSampling()
            }

            CommandRow(title: "$ net --refresh", symbol: "arrow.clockwise.circle.fill") {
                monitor.forceRefresh()
            }

            CommandRow(title: "$ net --reset-history", symbol: "trash.circle.fill") {
                monitor.resetHistory()
            }

            CommandRow(title: "$ quit", symbol: "xmark.circle.fill") {
                NSApplication.shared.terminate(nil)
            }
        }
    }
}

private struct TerminalDashboardPreview: View {
    @ObservedObject var monitor: NetworkSpeedMonitor

    var body: some View {
        let ceiling = max(monitor.peakMbps, 1.0)

        VStack(alignment: .leading, spacing: 6) {
            Text("dashboard/live")
                .font(.system(size: 11, weight: .bold, design: .monospaced))
                .foregroundStyle(terminalGreen)

            Text("iface: \(monitor.activeInterfaceName)")
                .font(.system(size: 12, weight: .regular, design: .monospaced))
                .foregroundStyle(terminalTextDim)

            Text("rx \(barString(value: monitor.downloadMbps, maxValue: ceiling, width: 26)) \(String(format: "%6.1f", monitor.downloadMbps)) Mbps")
                .font(.system(size: 12, weight: .regular, design: .monospaced))
                .foregroundStyle(terminalGreen)

            Text("tx \(barString(value: monitor.uploadMbps, maxValue: ceiling, width: 26)) \(String(format: "%6.1f", monitor.uploadMbps)) Mbps")
                .font(.system(size: 12, weight: .regular, design: .monospaced))
                .foregroundStyle(Color(red: 0.40, green: 0.91, blue: 0.83))

            Text("rxh \(sparkline(values: monitor.downloadHistoryMbps, maxValue: ceiling, width: 46))")
                .font(.system(size: 11, weight: .regular, design: .monospaced))
                .foregroundStyle(terminalGreenSoft)

            Text("txh \(sparkline(values: monitor.uploadHistoryMbps, maxValue: ceiling, width: 46))")
                .font(.system(size: 11, weight: .regular, design: .monospaced))
                .foregroundStyle(Color(red: 0.36, green: 0.85, blue: 0.78))
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(terminalPanel, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(.white.opacity(0.18), lineWidth: 0.8)
        }
    }
}

private struct DashMetric: View {
    let title: String
    let value: String
    let accent: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.system(size: 11, weight: .bold, design: .monospaced))
                .foregroundStyle(accent)

            Text(value)
                .font(.system(size: 15, weight: .semibold, design: .monospaced))
                .lineLimit(1)
                .minimumScaleFactor(0.72)
                .foregroundStyle(.white)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(terminalPanel, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(accent.opacity(0.28), lineWidth: 0.8)
        }
    }
}

private struct CommandRow: View {
    let title: String
    let symbol: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: symbol)
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(terminalGreen)

                Text(title)
                    .font(.system(size: 12, weight: .semibold, design: .monospaced))
                    .foregroundStyle(.white)

                Spacer(minLength: 0)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background(terminalPanel.opacity(0.92), in: RoundedRectangle(cornerRadius: 11, style: .continuous))
        }
        .buttonStyle(.plain)
        .overlay {
            RoundedRectangle(cornerRadius: 11, style: .continuous)
                .strokeBorder(.white.opacity(0.12), lineWidth: 0.8)
        }
    }
}

private func barString(value: Double, maxValue: Double, width: Int) -> String {
    let safeMax = max(maxValue, 0.0001)
    let normalized = min(max(value / safeMax, 0), 1)
    let filled = Int((normalized * Double(width)).rounded())
    let empty = max(width - filled, 0)

    return "[" + String(repeating: "#", count: filled) + String(repeating: ".", count: empty) + "]"
}

private func sparkline(values: [Double], maxValue: Double, width: Int) -> String {
    guard width > 0 else {
        return ""
    }

    let windowed = Array(values.suffix(width))
    if windowed.isEmpty {
        return String(repeating: ".", count: width)
    }

    let safeMax = max(maxValue, 0.0001)
    let palette: [Character] = [".", ":", "-", "=", "+", "*", "%", "#", "@"]

    var chars = String()

    for value in windowed {
        let normalized = min(max(value / safeMax, 0), 1)
        let index = min(Int((normalized * Double(palette.count - 1)).rounded()), palette.count - 1)
        chars.append(palette[index])
    }

    if chars.count < width {
        chars = String(repeating: ".", count: width - chars.count) + chars
    }

    return chars
}
