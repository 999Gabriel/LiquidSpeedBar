import Darwin
import Foundation

@MainActor
final class NetworkSpeedMonitor: ObservableObject {
    @Published private(set) var downloadBytesPerSecond: Double = 0
    @Published private(set) var uploadBytesPerSecond: Double = 0
    @Published private(set) var downloadHistoryMbps: [Double] = []
    @Published private(set) var uploadHistoryMbps: [Double] = []
    @Published private(set) var lastUpdated: Date = .now

    private var previousSample: ByteSample?
    private var timer: Timer?
    private let sampleInterval: TimeInterval = 1.0
    private let historyLimit: Int = 34

    var downloadCompact: String {
        Self.formatCompact(bytesPerSecond: downloadBytesPerSecond)
    }

    var uploadCompact: String {
        Self.formatCompact(bytesPerSecond: uploadBytesPerSecond)
    }

    var downloadDetailed: String {
        Self.formatDetailed(bytesPerSecond: downloadBytesPerSecond)
    }

    var uploadDetailed: String {
        Self.formatDetailed(bytesPerSecond: uploadBytesPerSecond)
    }

    var graphCeilingMbps: Double {
        max(6.0, downloadHistoryMbps.max() ?? 0, uploadHistoryMbps.max() ?? 0)
    }

    var healthScore: Int {
        let down = downloadBytesPerSecond * 8.0 / 1_000_000.0
        let up = uploadBytesPerSecond * 8.0 / 1_000_000.0
        let total = down + up

        let throughputScore = min(70.0, total / 120.0 * 70.0)

        let uploadBalanceRatio: Double
        if down < 0.5 {
            uploadBalanceRatio = 1.0
        } else {
            uploadBalanceRatio = min(max(up / down, 0), 1)
        }
        let balanceScore = uploadBalanceRatio * 15.0

        let variation = shortTermVariation
        let stabilityScore = max(0.0, 15.0 - min(variation * 18.0, 15.0))

        let totalScore = throughputScore + balanceScore + stabilityScore
        return Int(min(max(totalScore.rounded(), 0), 100))
    }

    var healthState: String {
        switch healthScore {
        case ..<35:
            return "Poor"
        case ..<60:
            return "Fair"
        case ..<80:
            return "Good"
        case ..<92:
            return "Great"
        default:
            return "Excellent"
        }
    }

    var insightText: String {
        let down = downloadBytesPerSecond * 8.0 / 1_000_000.0
        let up = uploadBytesPerSecond * 8.0 / 1_000_000.0
        let total = down + up
        let variation = shortTermVariation

        if total < 1.0 {
            return "Connection crawl detected."
        }

        if down > 10.0, up < down * 0.15 {
            return "Upload bottleneck detected."
        }

        if variation > 0.8 {
            return "High speed volatility detected."
        }

        if total > 80.0, variation < 0.25 {
            return "Connection is fast and stable."
        }

        return "Connection is healthy overall."
    }

    var diagnosticsSnapshot: String {
        let iso = ISO8601DateFormatter().string(from: lastUpdated)
        return """
        LiquidSpeedBar Diagnostics
        Time: \(iso)
        Download: \(downloadDetailed)
        Upload: \(uploadDetailed)
        Health: \(healthScore)/100 (\(healthState))
        Insight: \(insightText)
        """
    }

    var moodEmoji: String {
        let totalMbps = (downloadBytesPerSecond + uploadBytesPerSecond) * 8.0 / 1_000_000.0

        switch totalMbps {
        case ..<1.0:
            return "😞"
        case ..<8.0:
            return "🙂"
        case ..<40.0:
            return "😊"
        case ..<150.0:
            return "😎"
        default:
            return "🥳"
        }
    }

    var moodText: String {
        let totalMbps = (downloadBytesPerSecond + uploadBytesPerSecond) * 8.0 / 1_000_000.0

        switch totalMbps {
        case ..<1.0:
            return "Very slow network"
        case ..<8.0:
            return "Usable connection"
        case ..<40.0:
            return "Good speed"
        case ..<150.0:
            return "Fast connection"
        default:
            return "Excellent speed"
        }
    }

    init() {
        sampleNow()
        startSampling()
    }

    private func startSampling() {
        guard timer == nil else {
            return
        }

        timer = Timer.scheduledTimer(withTimeInterval: sampleInterval, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.sampleNow()
            }
        }
    }

    private func sampleNow() {
        let sample = ByteSample.capture()

        defer {
            previousSample = sample
            lastUpdated = sample.timestamp
        }

        guard let previousSample else {
            appendHistory(downloadMbps: 0, uploadMbps: 0)
            return
        }

        let elapsed = sample.timestamp.timeIntervalSince(previousSample.timestamp)
        guard elapsed > 0 else {
            return
        }

        let downloadDelta = sample.receivedBytes >= previousSample.receivedBytes ? sample.receivedBytes - previousSample.receivedBytes : 0
        let uploadDelta = sample.sentBytes >= previousSample.sentBytes ? sample.sentBytes - previousSample.sentBytes : 0

        downloadBytesPerSecond = Double(downloadDelta) / elapsed
        uploadBytesPerSecond = Double(uploadDelta) / elapsed

        appendHistory(
            downloadMbps: downloadBytesPerSecond * 8.0 / 1_000_000.0,
            uploadMbps: uploadBytesPerSecond * 8.0 / 1_000_000.0
        )
    }

    private func appendHistory(downloadMbps: Double, uploadMbps: Double) {
        downloadHistoryMbps.append(max(downloadMbps, 0))
        uploadHistoryMbps.append(max(uploadMbps, 0))

        if downloadHistoryMbps.count > historyLimit {
            downloadHistoryMbps.removeFirst(downloadHistoryMbps.count - historyLimit)
        }

        if uploadHistoryMbps.count > historyLimit {
            uploadHistoryMbps.removeFirst(uploadHistoryMbps.count - historyLimit)
        }
    }

    private var shortTermVariation: Double {
        let downRecent = Array(downloadHistoryMbps.suffix(10))
        let upRecent = Array(uploadHistoryMbps.suffix(10))
        let count = min(downRecent.count, upRecent.count)
        guard count >= 4 else {
            return 0
        }

        var totals: [Double] = []
        totals.reserveCapacity(count)
        for index in 0..<count {
            totals.append(downRecent[index] + upRecent[index])
        }

        let mean = totals.reduce(0, +) / Double(totals.count)
        guard mean > 0.01 else {
            return 1.0
        }

        let variance = totals
            .map { pow($0 - mean, 2) }
            .reduce(0, +) / Double(totals.count)
        let stddev = sqrt(variance)
        return stddev / mean
    }

    private static func formatCompact(bytesPerSecond: Double) -> String {
        let units = ["B", "K", "M", "G"]
        var value = max(0, bytesPerSecond)
        var unitIndex = 0

        while value >= 1000, unitIndex < units.count - 1 {
            value /= 1000
            unitIndex += 1
        }

        if unitIndex == 0 {
            return String(format: "%.0fB", value)
        }

        if value >= 100 {
            return String(format: "%.0f%@", value, units[unitIndex])
        }

        return String(format: "%.1f%@", value, units[unitIndex])
    }

    private static func formatDetailed(bytesPerSecond: Double) -> String {
        let units = ["B/s", "KB/s", "MB/s", "GB/s"]
        var value = max(0, bytesPerSecond)
        var unitIndex = 0

        while value >= 1000, unitIndex < units.count - 1 {
            value /= 1000
            unitIndex += 1
        }

        if unitIndex == 0 {
            return String(format: "%.0f %@", value, units[unitIndex])
        }

        return String(format: "%.1f %@", value, units[unitIndex])
    }
}

private struct ByteSample {
    let timestamp: Date
    let receivedBytes: UInt64
    let sentBytes: UInt64

    static func capture() -> ByteSample {
        var addressPointer: UnsafeMutablePointer<ifaddrs>?
        guard getifaddrs(&addressPointer) == 0, let firstAddress = addressPointer else {
            return ByteSample(timestamp: Date(), receivedBytes: 0, sentBytes: 0)
        }

        defer {
            freeifaddrs(addressPointer)
        }

        var totalReceived: UInt64 = 0
        var totalSent: UInt64 = 0

        var pointer: UnsafeMutablePointer<ifaddrs>? = firstAddress
        while let current = pointer {
            let interface = current.pointee
            pointer = interface.ifa_next

            guard let cName = interface.ifa_name else {
                continue
            }

            let name = String(cString: cName)
            if name.hasPrefix("lo") || name.hasPrefix("awdl") || name.hasPrefix("llw") || name.hasPrefix("utun") {
                continue
            }

            let flags = Int32(interface.ifa_flags)
            let isUp = (flags & Int32(IFF_UP)) != 0
            let isLoopback = (flags & Int32(IFF_LOOPBACK)) != 0
            guard isUp, !isLoopback else {
                continue
            }

            guard let data = interface.ifa_data?.assumingMemoryBound(to: if_data.self) else {
                continue
            }

            totalReceived += UInt64(data.pointee.ifi_ibytes)
            totalSent += UInt64(data.pointee.ifi_obytes)
        }

        return ByteSample(timestamp: Date(), receivedBytes: totalReceived, sentBytes: totalSent)
    }
}
