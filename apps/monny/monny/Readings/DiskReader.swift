import Foundation
import IOKit

nonisolated struct DiskUsage: Sendable, Equatable {
    var free: Int64
    var total: Int64
    /// Bytes per second; `nil` until two samples exist.
    var readRate: Double?
    var writeRate: Double?

    var usedFraction: Double { total > 0 ? Double(total - free) / Double(total) : 0 }
    /// Mounted volumes shown in Finder, startup volume first.
    var volumes: [Volume] = []

    nonisolated struct Volume: Sendable, Equatable, Identifiable {
        var url: URL
        var name: String
        /// For example "APFS".
        var format: String?
        var isInternal: Bool
        var isNetwork: Bool
        var free: Int64
        var total: Int64
        var id: URL { url }
        var usedFraction: Double { total > 0 ? Double(total - free) / Double(total) : 0 }
    }
}

/// Free space of the startup volume and read/write throughput summed over all block storage drivers.
nonisolated struct DiskReader {
    private var counter = RateCounter()
    private var space: (free: Int64, total: Int64, volumes: [DiskUsage.Volume], time: ContinuousClock.Instant)?

    mutating func read() -> DiskUsage? {
        // "Available for important usage" includes purgeable space like Finder, but costs ~50 ms,
        // so it is refreshed every 30 s; throughput is read every pass.
        let now = ContinuousClock.now
        if space.map({ now - $0.time > .seconds(30) }) ?? true, let fresh = Self.volumeSpace() {
            space = (fresh.free, fresh.total, Self.volumes(rootFree: fresh.free), now)
        }
        guard let space else { return nil }
        let rates = transferredBytes().flatMap { counter.rates(for: [$0.read, $0.written]) }
        return DiskUsage(free: space.free, total: space.total, readRate: rates?[0], writeRate: rates?[1], volumes: space.volumes)
    }

    private static func volumeSpace() -> (free: Int64, total: Int64)? {
        let keys: Set<URLResourceKey> = [.volumeAvailableCapacityForImportantUsageKey, .volumeTotalCapacityKey]
        guard let values = try? URL(fileURLWithPath: "/").resourceValues(forKeys: keys),
              let free = values.volumeAvailableCapacityForImportantUsage,
              let total = values.volumeTotalCapacity else { return nil }
        return (free, Int64(total))
    }

    /// Volumes Finder shows; the startup volume uses the "important usage" free space read above.
    private static func volumes(rootFree: Int64) -> [DiskUsage.Volume] {
        let keys: [URLResourceKey] = [.volumeLocalizedNameKey, .volumeLocalizedFormatDescriptionKey, .volumeIsInternalKey,
                                      .volumeIsLocalKey, .volumeAvailableCapacityKey, .volumeTotalCapacityKey, .volumeIsRootFileSystemKey]
        let urls = FileManager.default.mountedVolumeURLs(includingResourceValuesForKeys: keys, options: [.skipHiddenVolumes]) ?? []
        let volumes = urls.compactMap { url -> DiskUsage.Volume? in
            guard let values = try? url.resourceValues(forKeys: Set(keys)), let total = values.volumeTotalCapacity, total > 0
            else { return nil }
            let isRoot = values.volumeIsRootFileSystem ?? false
            return DiskUsage.Volume(url: url, name: values.volumeLocalizedName ?? url.lastPathComponent,
                                    format: values.volumeLocalizedFormatDescription, isInternal: values.volumeIsInternal ?? false,
                                    isNetwork: !(values.volumeIsLocal ?? true),
                                    free: isRoot ? rootFree : Int64(values.volumeAvailableCapacity ?? 0), total: Int64(total))
        }
        return volumes.sorted { ($0.url.path == "/" ? 0 : 1, $0.name) < ($1.url.path == "/" ? 0 : 1, $1.name) }
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
