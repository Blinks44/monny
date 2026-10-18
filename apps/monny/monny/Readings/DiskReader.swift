import Foundation
import IOKit

nonisolated struct DiskUsage: Sendable, Equatable {
    var free: Int64
    var total: Int64
    /// Bytes per second; `nil` until two samples exist.
    var readRate: Double?
    var writeRate: Double?

    var usedFraction: Double { total > 0 ? Double(total - free) / Double(total) : 0 }
}

/// Free space of the startup volume and read/write throughput summed over all block storage drivers.
nonisolated struct DiskReader {
    private var counter = RateCounter()
    private var space: (free: Int64, total: Int64, time: ContinuousClock.Instant)?

    mutating func read() -> DiskUsage? {
        // "Available for important usage" includes purgeable space like Finder, but costs ~50 ms,
        // so it is refreshed every 30 s; throughput is read every pass.
        let now = ContinuousClock.now
        if space.map({ now - $0.time > .seconds(30) }) ?? true, let fresh = Self.volumeSpace() {
            space = (fresh.free, fresh.total, now)
        }
        guard let space else { return nil }
        let rates = transferredBytes().flatMap { counter.rates(for: [$0.read, $0.written]) }
        return DiskUsage(free: space.free, total: space.total, readRate: rates?[0], writeRate: rates?[1])
    }

    private static func volumeSpace() -> (free: Int64, total: Int64)? {
        let keys: Set<URLResourceKey> = [.volumeAvailableCapacityForImportantUsageKey, .volumeTotalCapacityKey]
        guard let values = try? URL(fileURLWithPath: "/").resourceValues(forKeys: keys),
              let free = values.volumeAvailableCapacityForImportantUsage,
              let total = values.volumeTotalCapacity else { return nil }
        return (free, Int64(total))
    }

    private func transferredBytes() -> (read: UInt64, written: UInt64)? {
        var iterator: io_iterator_t = 0
        guard IOServiceGetMatchingServices(kIOMainPortDefault, IOServiceMatching("IOBlockStorageDriver"), &iterator) == KERN_SUCCESS
        else { return nil }
        defer { IOObjectRelease(iterator) }
        var read: UInt64 = 0
        var written: UInt64 = 0
        while case let entry = IOIteratorNext(iterator), entry != 0 {
            defer { IOObjectRelease(entry) }
            guard let stats = IORegistryEntryCreateCFProperty(entry, "Statistics" as CFString, kCFAllocatorDefault, 0)?
                .takeRetainedValue() as? [String: Any] else { continue }
            read += (stats["Bytes (Read)"] as? NSNumber)?.uint64Value ?? 0
            written += (stats["Bytes (Write)"] as? NSNumber)?.uint64Value ?? 0
        }
        return (read, written)
    }
}
