import Darwin
import Foundation
import SystemConfiguration

@MainActor
final class NetworkSpeedMonitor: ObservableObject {
    struct Mood {
        let emoji: String
        let description: String
    }

    @Published private(set) var downloadBytesPerSecond: Double = 0
    @Published private(set) var uploadBytesPerSecond: Double = 0
    @Published private(set) var lastUpdated: Date = .now
    @Published private(set) var activeInterfaceName: String = "auto"
    @Published private(set) var downloadHistoryMbps: [Double] = []
    @Published private(set) var uploadHistoryMbps: [Double] = []
    @Published private(set) var isPaused: Bool = false

    private let samplingInterval: TimeInterval = 1.0
    private let historyLimit = 90
    private var timer: Timer?
    private var previousSample: NetworkByteSample?

    var totalBytesPerSecond: Double {
        downloadBytesPerSecond + uploadBytesPerSecond
    }

    var downloadMbps: Double {
        downloadBytesPerSecond * 8.0 / 1_000_000.0
    }

    var uploadMbps: Double {
        uploadBytesPerSecond * 8.0 / 1_000_000.0
    }

    var totalMbps: Double {
        downloadMbps + uploadMbps
    }

    var peakMbps: Double {
        max(10.0, downloadHistoryMbps.max() ?? 0, uploadHistoryMbps.max() ?? 0)
    }

    var compactSpeedText: String {
        Self.format(bytesPerSecond: totalBytesPerSecond)
    }

    var downloadText: String {
        Self.format(bytesPerSecond: downloadBytesPerSecond)
    }

    var uploadText: String {
        Self.format(bytesPerSecond: uploadBytesPerSecond)
    }

    var downloadMenuText: String {
        Self.formatMenuRate(bytesPerSecond: downloadBytesPerSecond)
    }

    var uploadMenuText: String {
        Self.formatMenuRate(bytesPerSecond: uploadBytesPerSecond)
    }

    var speedMood: Mood {
        switch totalMbps {
        case ..<2:
            return Mood(emoji: "😴", description: "Network is sleepy")
        case ..<15:
            return Mood(emoji: "🙂", description: "Steady and chill")
        case ..<80:
            return Mood(emoji: "😄", description: "Smooth and happy")
        case ..<250:
            return Mood(emoji: "🚀", description: "Flying fast")
        default:
            return Mood(emoji: "🤯", description: "Blazing speed")
        }
    }

    init() {
        sampleNow()
        startSampling()
    }

    func toggleSampling() {
        if isPaused {
            resumeSampling()
        } else {
            pauseSampling()
        }
    }

    func resetHistory() {
        downloadHistoryMbps.removeAll()
        uploadHistoryMbps.removeAll()
    }

    func forceRefresh() {
        sampleNow()
    }

    private func pauseSampling() {
        timer?.invalidate()
        timer = nil
        isPaused = true
    }

    private func resumeSampling() {
        guard isPaused else {
            return
        }

        isPaused = false
        previousSample = nil
        sampleNow()
        startSampling()
    }

    private func startSampling() {
        guard timer == nil else {
            return
        }

        timer = Timer.scheduledTimer(withTimeInterval: samplingInterval, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.sampleNow()
            }
        }
    }

    private func sampleNow() {
        let preferredInterface = PreferredInterfaceResolver.resolve()
        let sample = NetworkByteSample.capture(preferredInterface: preferredInterface)

        defer {
            previousSample = sample
            lastUpdated = sample.timestamp
            activeInterfaceName = sample.interfaceName ?? "aggregate"
        }

        guard let previousSample else {
            appendHistory(downloadMbps: 0, uploadMbps: 0)
            return
        }

        let elapsed = sample.timestamp.timeIntervalSince(previousSample.timestamp)
        guard elapsed > 0 else {
            return
        }

        let downloadDelta = sample.receivedBytes >= previousSample.receivedBytes
            ? sample.receivedBytes - previousSample.receivedBytes
            : 0
        let uploadDelta = sample.sentBytes >= previousSample.sentBytes
            ? sample.sentBytes - previousSample.sentBytes
            : 0

        downloadBytesPerSecond = Double(downloadDelta) / elapsed
        uploadBytesPerSecond = Double(uploadDelta) / elapsed

        appendHistory(downloadMbps: downloadMbps, uploadMbps: uploadMbps)
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

    static func format(bytesPerSecond: Double) -> String {
        let safeValue = max(bytesPerSecond, 0)
        let units = ["B/s", "KB/s", "MB/s", "GB/s"]

        var value = safeValue
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

    static func formatMenuRate(bytesPerSecond: Double) -> String {
        let safeValue = max(bytesPerSecond, 0)
        let units = ["B", "K", "M", "G"]

        var value = safeValue
        var unitIndex = 0

        while value >= 1000, unitIndex < units.count - 1 {
            value /= 1000
            unitIndex += 1
        }

        if unitIndex == 0 {
            return String(format: "%.0f%@", value, units[unitIndex])
        }

        if value >= 100 {
            return String(format: "%.0f%@", value, units[unitIndex])
        }

        return String(format: "%.1f%@", value, units[unitIndex])
    }
}

private struct NetworkByteSample {
    let timestamp: Date
    let interfaceName: String?
    let receivedBytes: UInt64
    let sentBytes: UInt64

    static func capture(preferredInterface: String?) -> NetworkByteSample {
        let countersByInterface = InterfaceCounterCollector.collect()

        let interfaceName: String?
        let counters: InterfaceCounter

        if let preferredInterface, let preferredCounters = countersByInterface[preferredInterface] {
            interfaceName = preferredInterface
            counters = preferredCounters
        } else {
            interfaceName = nil
            counters = InterfaceCounterCollector.aggregate(countersByInterface)
        }

        return NetworkByteSample(
            timestamp: Date(),
            interfaceName: interfaceName,
            receivedBytes: counters.receivedBytes,
            sentBytes: counters.sentBytes
        )
    }
}

private struct InterfaceCounter {
    var receivedBytes: UInt64
    var sentBytes: UInt64
}

private enum InterfaceCounterCollector {
    static func collect() -> [String: InterfaceCounter] {
        var addressPointer: UnsafeMutablePointer<ifaddrs>?
        guard getifaddrs(&addressPointer) == 0, let firstAddress = addressPointer else {
            return [:]
        }

        defer {
            freeifaddrs(addressPointer)
        }

        var countersByInterface: [String: InterfaceCounter] = [:]
        var pointer: UnsafeMutablePointer<ifaddrs>? = firstAddress

        while let currentPointer = pointer {
            let interface = currentPointer.pointee
            pointer = interface.ifa_next

            guard let cName = interface.ifa_name else {
                continue
            }

            let name = String(cString: cName)
            let flags = Int32(interface.ifa_flags)
            let isUp = (flags & Int32(IFF_UP)) != 0
            let isLoopback = (flags & Int32(IFF_LOOPBACK)) != 0

            guard isUp, !isLoopback else {
                continue
            }

            guard let data = interface.ifa_data?.assumingMemoryBound(to: if_data.self) else {
                continue
            }

            let receivedBytes = UInt64(data.pointee.ifi_ibytes)
            let sentBytes = UInt64(data.pointee.ifi_obytes)

            if let existing = countersByInterface[name] {
                countersByInterface[name] = InterfaceCounter(
                    receivedBytes: max(existing.receivedBytes, receivedBytes),
                    sentBytes: max(existing.sentBytes, sentBytes)
                )
            } else {
                countersByInterface[name] = InterfaceCounter(
                    receivedBytes: receivedBytes,
                    sentBytes: sentBytes
                )
            }
        }

        return countersByInterface
    }

    static func aggregate(_ countersByInterface: [String: InterfaceCounter]) -> InterfaceCounter {
        var totals = InterfaceCounter(receivedBytes: 0, sentBytes: 0)

        for (name, counters) in countersByInterface {
            guard !name.hasPrefix("awdl"), !name.hasPrefix("llw"), !name.hasPrefix("utun") else {
                continue
            }

            totals.receivedBytes += counters.receivedBytes
            totals.sentBytes += counters.sentBytes
        }

        return totals
    }
}

private enum PreferredInterfaceResolver {
    static func resolve() -> String? {
        if let interface = primaryInterface(for: "State:/Network/Global/IPv4") {
            return interface
        }

        return primaryInterface(for: "State:/Network/Global/IPv6")
    }

    private static func primaryInterface(for key: String) -> String? {
        guard let store = SCDynamicStoreCreate(nil, "LiquidSpeedBar" as CFString, nil, nil) else {
            return nil
        }

        guard
            let dictionary = SCDynamicStoreCopyValue(store, key as CFString) as? [String: Any],
            let interface = dictionary["PrimaryInterface"] as? String
        else {
            return nil
        }

        return interface
    }
}
