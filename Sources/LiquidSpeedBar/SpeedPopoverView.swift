import AppKit
import SwiftUI

private let glassAccentA = Color(red: 0.22, green: 0.54, blue: 0.98)
private let glassAccentB = Color(red: 0.15, green: 0.78, blue: 0.82)
private let cardBackground = Color.white.opacity(0.14)

struct MenuBarBubble: View {
    let emoji: String
    let downloadText: String
    let uploadText: String

    var body: some View {
        HStack(spacing: 6) {
            Text(emoji)
                .font(.system(size: 12))

            Text("↓\(downloadText)")
                .font(.system(size: 11, weight: .semibold, design: .rounded))
                .monospacedDigit()

            Text("↑\(uploadText)")
                .font(.system(size: 11, weight: .semibold, design: .rounded))
                .monospacedDigit()
        }
        .foregroundStyle(.primary)
        .padding(.horizontal, 10)
        .padding(.vertical, 4)
        .background {
            Capsule(style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay {
                    Capsule(style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [
                                    .white.opacity(0.46),
                                    Color(red: 0.35, green: 0.63, blue: 0.98).opacity(0.22),
                                    .white.opacity(0.10)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                }
        }
        .overlay {
            Capsule(style: .continuous)
                .strokeBorder(.white.opacity(0.56), lineWidth: 0.85)
        }
        .shadow(color: .black.opacity(0.12), radius: 5, x: 0, y: 1)
    }
}

struct SpeedPopoverView: View {
    @ObservedObject var monitor: NetworkSpeedMonitor
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            DashboardHero(monitor: monitor)

            HStack(spacing: 10) {
                MetricCard(
                    title: "Download",
                    value: monitor.downloadText,
                    symbol: "arrow.down.circle.fill",
                    tint: glassAccentA
                )

                MetricCard(
                    title: "Upload",
                    value: monitor.uploadText,
                    symbol: "arrow.up.circle.fill",
                    tint: glassAccentB
                )
            }

            MiniTrafficChart(
                download: monitor.downloadHistoryMbps,
                upload: monitor.uploadHistoryMbps,
                maxMbps: monitor.peakMbps
            )
            .frame(height: 124)

            HStack {
                Label("Interface \(monitor.activeInterfaceName)", systemImage: "network")
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundStyle(.secondary)

                Spacer(minLength: 0)

                Text("Updated \(monitor.lastUpdated, style: .time)")
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundStyle(.secondary)
            }

            HStack(spacing: 8) {
                Button {
                    openWindow(id: "dashboard")
                } label: {
                    Label("Open Dashboard", systemImage: "rectangle.inset.filled")
                }
                .buttonStyle(.borderedProminent)

                Button {
                    monitor.forceRefresh()
                } label: {
                    Label("Refresh", systemImage: "arrow.clockwise")
                }
                .buttonStyle(.bordered)

                Button {
                    NSApplication.shared.terminate(nil)
                } label: {
                    Label("Quit", systemImage: "xmark")
                }
                .buttonStyle(.bordered)
            }
            .tint(glassAccentA)
            .font(.system(size: 12, weight: .semibold, design: .rounded))
        }
        .padding(16)
        .background {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 0.18, green: 0.36, blue: 0.78),
                            Color(red: 0.15, green: 0.49, blue: 0.72),
                            Color(red: 0.14, green: 0.27, blue: 0.58)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay {
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .fill(.ultraThinMaterial.opacity(0.54))
                }
                .overlay {
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .strokeBorder(.white.opacity(0.44), lineWidth: 0.9)
                }
        }
    }
}

struct NetworkDashboardWindow: View {
    @ObservedObject var monitor: NetworkSpeedMonitor

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                DashboardHero(monitor: monitor)

                HStack(spacing: 12) {
                    MetricCard(
                        title: "Download",
                        value: monitor.downloadText,
                        symbol: "arrow.down.circle.fill",
                        tint: glassAccentA
                    )

                    MetricCard(
                        title: "Upload",
                        value: monitor.uploadText,
                        symbol: "arrow.up.circle.fill",
                        tint: glassAccentB
                    )

                    MetricCard(
                        title: "Total",
                        value: monitor.compactSpeedText,
                        symbol: "speedometer",
                        tint: Color(red: 0.40, green: 0.82, blue: 0.96)
                    )
                }

                VStack(alignment: .leading, spacing: 10) {
                    Text("Live Traffic")
                        .font(.system(size: 15, weight: .semibold, design: .rounded))

                    MiniTrafficChart(
                        download: monitor.downloadHistoryMbps,
                        upload: monitor.uploadHistoryMbps,
                        maxMbps: monitor.peakMbps
                    )
                    .frame(height: 220)
                }
                .padding(14)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(cardBackground, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .strokeBorder(.white.opacity(0.26), lineWidth: 0.8)
                }

                HStack {
                    Label("Interface \(monitor.activeInterfaceName)", systemImage: "network")
                    Spacer(minLength: 0)
                    Text("Updated \(monitor.lastUpdated, style: .time)")
                }
                .font(.system(size: 13, weight: .medium, design: .rounded))
                .foregroundStyle(.secondary)

                HStack(spacing: 8) {
                    Button {
                        monitor.forceRefresh()
                    } label: {
                        Label("Refresh Now", systemImage: "arrow.clockwise")
                    }
                    .buttonStyle(.borderedProminent)

                    Button {
                        monitor.toggleSampling()
                    } label: {
                        Label(monitor.isPaused ? "Resume" : "Pause", systemImage: monitor.isPaused ? "play.fill" : "pause.fill")
                    }
                    .buttonStyle(.bordered)

                    Button {
                        monitor.resetHistory()
                    } label: {
                        Label("Reset History", systemImage: "trash")
                    }
                    .buttonStyle(.bordered)

                    Spacer(minLength: 0)

                    Button {
                        NSApplication.shared.terminate(nil)
                    } label: {
                        Label("Quit", systemImage: "xmark")
                    }
                    .buttonStyle(.bordered)
                }
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .tint(glassAccentA)
            }
            .padding(20)
        }
        .background {
            LinearGradient(
                colors: [
                    Color(red: 0.89, green: 0.94, blue: 1.0),
                    Color(red: 0.85, green: 0.92, blue: 0.98),
                    Color(red: 0.90, green: 0.94, blue: 0.99)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
        }
    }
}

private struct DashboardHero: View {
    @ObservedObject var monitor: NetworkSpeedMonitor

    var body: some View {
        HStack(spacing: 12) {
            Text(monitor.speedMood.emoji)
                .font(.system(size: 40))

            VStack(alignment: .leading, spacing: 4) {
                Text(monitor.compactSpeedText)
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .contentTransition(.numericText())

                Text(monitor.speedMood.description)
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: 0)

            VStack(alignment: .trailing, spacing: 3) {
                Text("↓ \(monitor.downloadMenuText)/s")
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundStyle(glassAccentA)
                    .monospacedDigit()

                Text("↑ \(monitor.uploadMenuText)/s")
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundStyle(glassAccentB)
                    .monospacedDigit()
            }
        }
        .padding(14)
        .background(cardBackground, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .strokeBorder(.white.opacity(0.32), lineWidth: 0.85)
        }
    }
}

private struct MetricCard: View {
    let title: String
    let value: String
    let symbol: String
    let tint: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            Label {
                Text(title)
            } icon: {
                Image(systemName: symbol)
            }
            .font(.system(size: 12, weight: .medium, design: .rounded))
            .foregroundStyle(.secondary)

            Text(value)
                .font(.system(size: 20, weight: .semibold, design: .rounded))
                .lineLimit(1)
                .minimumScaleFactor(0.75)
                .contentTransition(.numericText())

            RoundedRectangle(cornerRadius: 2, style: .continuous)
                .fill(tint)
                .frame(width: 28, height: 3)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(cardBackground, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(.white.opacity(0.26), lineWidth: 0.8)
        }
    }
}

private struct MiniTrafficChart: View {
    let download: [Double]
    let upload: [Double]
    let maxMbps: Double

    var body: some View {
        GeometryReader { proxy in
            let size = proxy.size
            let ceiling = max(maxMbps, 1.0)

            ZStack {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(cardBackground)

                GridLines()
                    .stroke(.white.opacity(0.14), style: StrokeStyle(lineWidth: 0.8, dash: [4, 5]))
                    .padding(10)

                if download.count > 1 {
                    linePath(values: download, in: size, maxValue: ceiling)
                        .stroke(
                            LinearGradient(colors: [glassAccentA, glassAccentA.opacity(0.4)], startPoint: .leading, endPoint: .trailing),
                            style: StrokeStyle(lineWidth: 2.3, lineCap: .round, lineJoin: .round)
                        )
                }

                if upload.count > 1 {
                    linePath(values: upload, in: size, maxValue: ceiling)
                        .stroke(
                            LinearGradient(colors: [glassAccentB, glassAccentB.opacity(0.35)], startPoint: .leading, endPoint: .trailing),
                            style: StrokeStyle(lineWidth: 2.1, lineCap: .round, lineJoin: .round)
                        )
                }

                VStack {
                    HStack {
                        Text("\(Int(ceiling.rounded())) Mbps")
                            .font(.system(size: 10, weight: .medium, design: .rounded))
                            .foregroundStyle(.secondary)
                        Spacer(minLength: 0)
                        LegendPill(label: "Download", color: glassAccentA)
                        LegendPill(label: "Upload", color: glassAccentB)
                    }
                    .padding(.horizontal, 12)
                    .padding(.top, 8)

                    Spacer(minLength: 0)
                }
            }
            .overlay {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .strokeBorder(.white.opacity(0.24), lineWidth: 0.8)
            }
        }
    }

    private func linePath(values: [Double], in size: CGSize, maxValue: Double) -> Path {
        let trimmed = Array(values.suffix(80))
        guard trimmed.count > 1 else {
            return Path()
        }

        let width = max(size.width - 20, 1)
        let height = max(size.height - 20, 1)
        let stepX = width / CGFloat(trimmed.count - 1)

        var path = Path()

        for index in trimmed.indices {
            let clamped = min(max(trimmed[index], 0), maxValue)
            let x = 10 + CGFloat(index) * stepX
            let y = 10 + height - (CGFloat(clamped / maxValue) * height)
            let point = CGPoint(x: x, y: y)

            if index == trimmed.startIndex {
                path.move(to: point)
            } else {
                path.addLine(to: point)
            }
        }

        return path
    }
}

private struct GridLines: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let rows = 4
        let columns = 6

        for row in 0...rows {
            let y = rect.minY + (rect.height / CGFloat(rows)) * CGFloat(row)
            path.move(to: CGPoint(x: rect.minX, y: y))
            path.addLine(to: CGPoint(x: rect.maxX, y: y))
        }

        for column in 0...columns {
            let x = rect.minX + (rect.width / CGFloat(columns)) * CGFloat(column)
            path.move(to: CGPoint(x: x, y: rect.minY))
            path.addLine(to: CGPoint(x: x, y: rect.maxY))
        }

        return path
    }
}

private struct LegendPill: View {
    let label: String
    let color: Color

    var body: some View {
        HStack(spacing: 5) {
            Circle()
                .fill(color)
                .frame(width: 6, height: 6)
            Text(label)
                .font(.system(size: 10, weight: .medium, design: .rounded))
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 7)
        .padding(.vertical, 4)
        .background(.white.opacity(0.24), in: Capsule())
    }
}
