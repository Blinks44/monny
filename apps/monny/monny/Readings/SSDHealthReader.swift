import Foundation
import IOKit

nonisolated struct SSDHealth: Sendable, Equatable {
    /// NVMe "Percentage Used": the vendor's estimate of life used, 0...1 (may exceed 1).
    var wear: Double
    /// False when the drive raises a critical warning or its spare falls below the threshold.
    var isVerified: Bool
    /// Bytes written by the host over the drive's life.
    var bytesWritten: Int64

    var health: Double { max(1 - wear, 0) }
}

/// Health of the internal NVMe SSD from its SMART log through Apple's public NVMe SMART user
/// client (`NVMeSMARTLibExternal.h`). Works without privileges; reads take a few milliseconds.
nonisolated enum SSDHealthReader {
    static func read() -> SSDHealth? {
        var iterator: io_iterator_t = 0
        let matching = [kIOPropertyMatchKey: [kIOPropertyNVMeSMARTCapableKey: true]] as CFDictionary
        guard IOServiceGetMatchingServices(kIOMainPortDefault, matching, &iterator) == KERN_SUCCESS else { return nil }
        defer { IOObjectRelease(iterator) }
        // The first capable controller; on a Mac with only its internal SSD that is the one. Which
        // controller comes first with an external NVMe drive attached has not been checked.
        let service = IOIteratorNext(iterator)
        guard service != 0 else { return nil }
        defer { IOObjectRelease(service) }
        return smartData(service).map(health)
    }

    static func health(_ data: NVMeSMARTData) -> SSDHealth {
        // Data units are thousands of 512-byte blocks; the low 64 bits cover 9 ZB.
        SSDHealth(wear: Double(data.PERCENTAGE_USED) / 100,
                  isVerified: data.CRITICAL_WARNING == 0 && data.AVAILABLE_SPARE >= data.AVAILABLE_SPARE_THRESHOLD,
                  bytesWritten: Int64(clamping: data.DATA_UNITS_WRITTEN.0.multipliedReportingOverflow(by: 512_000).partialValue))
    }

    private static func smartData(_ service: io_service_t) -> NVMeSMARTData? {
        var plugIn: UnsafeMutablePointer<UnsafeMutablePointer<IOCFPlugInInterface>?>?
        var score: Int32 = 0
        guard IOCreatePlugInInterfaceForService(service, uuid(userClientType), uuid(plugInInterface), &plugIn, &score) == KERN_SUCCESS,
              let plugIn, let plugInVTable = plugIn.pointee?.pointee else { return nil }
        defer { IODestroyPlugInInterface(plugIn) }
        var interface: LPVOID?
        guard plugInVTable.QueryInterface(plugIn, CFUUIDGetUUIDBytes(uuid(smartInterface)), &interface) == S_OK,
              let interface else { return nil }
        let smart = interface.assumingMemoryBound(to: UnsafeMutablePointer<IONVMeSMARTInterface>.self).pointee
        defer { _ = smart.pointee.Release(interface) }
        var data = NVMeSMARTData()
        guard smart.pointee.SMARTReadData(interface, &data) == kIOReturnSuccess else { return nil }
        return data
    }

    // The header's UUIDs are C macros that Swift cannot import.
    private static let userClientType: [UInt8] = [0xAA, 0x0F, 0xA6, 0xF9, 0xC2, 0xD6, 0x45, 0x7F, 0xB1, 0x0B, 0x59, 0xA1, 0x32, 0x53, 0x29, 0x2F]
    private static let smartInterface: [UInt8] = [0xCC, 0xD1, 0xDB, 0x19, 0xFD, 0x9A, 0x4D, 0xAF, 0xBF, 0x95, 0x12, 0x45, 0x4B, 0x23, 0x0A, 0xB6]
    private static let plugInInterface: [UInt8] = [0xC2, 0x44, 0xE8, 0x58, 0x10, 0x9C, 0x11, 0xD4, 0x91, 0xD4, 0x00, 0x50, 0xE4, 0xC6, 0x42, 0x6F]

    private static func uuid(_ b: [UInt8]) -> CFUUID {
        CFUUIDGetConstantUUIDWithBytes(nil, b[0], b[1], b[2], b[3], b[4], b[5], b[6], b[7],
                                       b[8], b[9], b[10], b[11], b[12], b[13], b[14], b[15])
    }
}
