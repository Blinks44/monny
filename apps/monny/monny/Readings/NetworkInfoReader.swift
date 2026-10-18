import CoreWLAN
import Foundation
import SystemConfiguration

/// The primary connection, read on demand by the Network page (public APIs, no privileges).
/// The Wi-Fi network name needs Location Services, which Monny does not ask for, so it is not shown.
nonisolated struct NetworkInfo: Sendable, Equatable {
    var interface: String?
    var isWiFi: Bool
    var localAddress: String?
    var router: String?
    var dns: [String]
    var wifi: WiFi?

    nonisolated struct WiFi: Sendable, Equatable {
        /// dBm
        var rssi: Int
        /// Mb/s
        var transmitRate: Double
        var channel: Int?
        /// For example "5 GHz".
        var band: String?
        /// For example "802.11ax".
        var phyMode: String?
    }

    static func read() -> NetworkInfo {
        let store = SCDynamicStoreCreate(nil, "Monny" as CFString, nil, nil)
        let ipv4 = store.flatMap { SCDynamicStoreCopyValue($0, "State:/Network/Global/IPv4" as CFString) } as? [String: Any]
        let dnsState = store.flatMap { SCDynamicStoreCopyValue($0, "State:/Network/Global/DNS" as CFString) } as? [String: Any]
        let interface = ipv4?["PrimaryInterface"] as? String
        let wifiInterface = CWWiFiClient.shared().interface()
        let isWiFi = interface != nil && interface == wifiInterface?.interfaceName
        return NetworkInfo(
            interface: interface,
            isWiFi: isWiFi,
            localAddress: interface.flatMap(address(of:)),
            router: ipv4?["Router"] as? String,
            dns: dnsState?["ServerAddresses"] as? [String] ?? [],
            wifi: isWiFi ? wifiInterface.flatMap(wifi(of:)) : nil)
    }

    private static func wifi(of interface: CWInterface) -> WiFi? {
        guard interface.powerOn() else { return nil }
        let band: String? = switch interface.wlanChannel()?.channelBand {
        case .band2GHz: "2.4 GHz"
        case .band5GHz: "5 GHz"
        case .band6GHz: "6 GHz"
        default: nil
        }
        let phy: String? = switch interface.activePHYMode() {
        case .mode11a: "802.11a"
        case .mode11b: "802.11b"
        case .mode11g: "802.11g"
        case .mode11n: "802.11n"
        case .mode11ac: "802.11ac"
        case .mode11ax: "802.11ax"
        default: nil
        }
        return WiFi(rssi: interface.rssiValue(), transmitRate: interface.transmitRate(),
                    channel: interface.wlanChannel()?.channelNumber, band: band, phyMode: phy)
    }

    /// The first IPv4 address of `interface`.
    private static func address(of interface: String) -> String? {
        var list: UnsafeMutablePointer<ifaddrs>?
        guard getifaddrs(&list) == 0, let first = list else { return nil }
        defer { freeifaddrs(list) }
        for entry in sequence(first: first, next: { $0.pointee.ifa_next }) {
            let item = entry.pointee
            guard String(cString: item.ifa_name) == interface, let address = item.ifa_addr,
                  address.pointee.sa_family == UInt8(AF_INET) else { continue }
            var host = [CChar](repeating: 0, count: Int(NI_MAXHOST))
            guard getnameinfo(address, socklen_t(address.pointee.sa_len), &host, socklen_t(host.count), nil, 0, NI_NUMERICHOST) == 0
            else { continue }
            return String(decoding: host.prefix { $0 != 0 }.map { UInt8(bitPattern: $0) }, as: UTF8.self)
        }
        return nil
    }
}
