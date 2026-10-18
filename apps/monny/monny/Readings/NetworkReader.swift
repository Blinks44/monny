import Darwin

nonisolated struct NetworkRates: Sendable, Equatable {
    /// Bytes per second.
    var download: Double
    var upload: Double
}

/// Throughput of physical interfaces (Wi-Fi, Ethernet, cellular) from 64-bit interface counters.
/// `getifaddrs` is not used: its `if_data` counters are 32-bit and wrap at 4 GB.
nonisolated struct NetworkReader {
    private var counter = RateCounter()

    mutating func read() -> NetworkRates? {
        guard let totals = Self.totals(), let rates = counter.rates(for: [totals.received, totals.sent]) else { return nil }
        return NetworkRates(download: rates[0], upload: rates[1])
    }

    static func totals() -> (received: UInt64, sent: UInt64)? {
        var mib: [Int32] = [CTL_NET, PF_ROUTE, 0, 0, NET_RT_IFLIST2, 0]
        var length = 0
        guard sysctl(&mib, UInt32(mib.count), nil, &length, nil, 0) == 0, length > 0 else { return nil }
        var buffer = [UInt8](repeating: 0, count: length)
        guard sysctl(&mib, UInt32(mib.count), &buffer, &length, nil, 0) == 0 else { return nil }
        var received: UInt64 = 0
        var sent: UInt64 = 0
        buffer.withUnsafeBytes { bytes in
            var offset = 0
            while offset + MemoryLayout<if_msghdr>.size <= length {
                let header = bytes.loadUnaligned(fromByteOffset: offset, as: if_msghdr.self)
                guard header.ifm_msglen > 0 else { break }
                if Int32(header.ifm_type) == RTM_IFINFO2, offset + MemoryLayout<if_msghdr2>.size <= length {
                    let message = bytes.loadUnaligned(fromByteOffset: offset, as: if_msghdr2.self)
                    let isLoopback = message.ifm_flags & IFF_LOOPBACK != 0
                    let type = Int32(message.ifm_data.ifi_type)
                    if !isLoopback && (type == IFT_ETHER || type == IFT_CELLULAR) {
                        received += message.ifm_data.ifi_ibytes
                        sent += message.ifm_data.ifi_obytes
                    }
                }
                offset += Int(header.ifm_msglen)
            }
        }
        return (received, sent)
    }
}
