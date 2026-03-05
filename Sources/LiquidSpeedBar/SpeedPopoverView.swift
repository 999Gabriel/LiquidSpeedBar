import AppKit
import SwiftUI

struct MenuBarBubble: View {
    let emoji: String
    let speedText: String

    var body: some View {
        HStack(spacing: 6) {
            Text(emoji)
            Text(speedText)
                .font(.system(size: 12, weight: .semibold, design: .rounded))
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 4)
        .foregroundStyle(.primary)
        .background(.ultraThinMaterial, in: Capsule())
        .overlay {
            Capsule()
                .strokeBorder(.white.opacity(0.3), lineWidth: 0.8)
        }
        .shadow(color: .black.opacity(0.16), radius: 6, x: 0, y: 2)
    }
}

struct SpeedPopoverView: View {
    @ObservedObject var monitor: NetworkSpeedMonitor

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 12) {
                Text(monitor.speedMood.emoji)
                    .font(.system(size: 36))

                VStack(alignment: .leading, spacing: 4) {
                    Text(monitor.compactSpeedText)
                        .font(.system(size: 29, weight: .bold, design: .rounded))
                    Text(monitor.speedMood.description)
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .foregroundStyle(.secondary)
                }

                Spacer(minLength: 0)
            }
            .padding(12)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .strokeBorder(.white.opacity(0.30), lineWidth: 0.8)
            }

            HStack(spacing: 12) {
                MetricTile(
                    title: "Download",
                    value: monitor.downloadText,
                    symbol: "arrow.down.circle.fill",
                    color: Color(red: 0.17, green: 0.65, blue: 0.88)
                )

                MetricTile(
                    title: "Upload",
                    value: monitor.uploadText,
                    symbol: "arrow.up.circle.fill",
                    color: Color(red: 0.16, green: 0.76, blue: 0.52)
                )
            }

            HStack {
                Text("Updated \(monitor.lastUpdated, style: .time)")
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundStyle(.secondary)

                Spacer(minLength: 0)

                Button("Quit") {
                    NSApplication.shared.terminate(nil)
                }
                .buttonStyle(.borderedProminent)
                .tint(.white.opacity(0.28))
                .foregroundStyle(.primary)
            }
        }
        .padding(16)
        .background {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 0.10, green: 0.22, blue: 0.45),
                            Color(red: 0.05, green: 0.42, blue: 0.38),
                            Color(red: 0.09, green: 0.14, blue: 0.28)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay {
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .fill(.ultraThinMaterial)
                }
                .overlay {
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .strokeBorder(.white.opacity(0.32), lineWidth: 0.9)
                }
        }
    }
}

private struct MetricTile: View {
    let title: String
    let value: String
    let symbol: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Label {
                Text(title)
            } icon: {
                Image(systemName: symbol)
            }
            .font(.system(size: 12, weight: .medium, design: .rounded))
            .foregroundStyle(.secondary)

            Text(value)
                .font(.system(size: 18, weight: .semibold, design: .rounded))
                .lineLimit(1)
                .minimumScaleFactor(0.8)
                .foregroundStyle(.white)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(color.opacity(0.25), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(.white.opacity(0.25), lineWidth: 0.8)
        }
    }
}
