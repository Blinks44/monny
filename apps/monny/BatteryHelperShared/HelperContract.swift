import Foundation

nonisolated enum HelperContract {
    static let appIdentifier = "blinks44.monny"
    static let helperIdentifier = "blinks44.monny.battery-helper"
    static let executableName = "MonnyBatteryHelper"
    static let plistName = helperIdentifier + ".plist"
    static let protocolVersion = 1
    static let helperVersion = "1.0"
    static let nativeLimitSessionVersion = 3
    static let adapterVerificationVersion = 1
    static let adapterBytePulseVersion = 1
    static let adapterByteObservationVersion = 2
    static let adapterRestartVerificationVersion = 1
    static let adapterSleepVerificationVersion = 1
    static let adapterRemovalVerificationVersion = 1
}

/// Fixed charging actions and explicit engineering verification only; no arbitrary keys, paths, PIDs or shell commands.
@objc(MonnyBatteryHelperProtocol) nonisolated protocol BatteryHelperProtocol {
    func readStatus(withReply reply: @escaping @Sendable (Data) -> Void)
    func readAdapterDiagnostics(withReply reply: @escaping @Sendable (Data) -> Void)
    func readChargeDiagnostics(withReply reply: @escaping @Sendable (Data) -> Void)
    func prepareAdapterRemoval(withReply reply: @escaping @Sendable (Data) -> Void)
    func prepareAdapterSleep(withReply reply: @escaping @Sendable (Data) -> Void)
    func cancelAdapterSleep(withReply reply: @escaping @Sendable (Data) -> Void)
    func verifyAdapterRestart(withReply reply: @escaping @Sendable (Data) -> Void)
    func observeAdapterByte(withReply reply: @escaping @Sendable (Data) -> Void)
    func verifyAdapterBytePulse(withReply reply: @escaping @Sendable (Data) -> Void)
    func verifyAdapterIsolation(withReply reply: @escaping @Sendable (Data) -> Void)
    func verifyNativeChargeLimit(_ limit: Int, withReply reply: @escaping @Sendable (Data) -> Void)
    func applyNativeChargeLimit(_ limit: Int, withReply reply: @escaping @Sendable (Data) -> Void)
    func restoreNativeChargeLimit(withReply reply: @escaping @Sendable (Data) -> Void)
    func prepareForRemoval(withReply reply: @escaping @Sendable (Data) -> Void)
}

nonisolated struct HelperStatus: Codable, Sendable, Equatable {
    enum ControlState: String, Codable, Sendable { case notControlling, restorationRequired, nativeLimit }
    enum Support: String, Codable, Sendable { case notImplemented }

    var protocolVersion: Int
    var helperVersion: String
    var controlState: ControlState
    var chargingSupport: Support
    var adapterRemovalVerificationAvailable: Bool?
    var adapterRemovalVerificationVersion: Int?
    var adapterSleepVerificationAvailable: Bool?
    var adapterSleepVerificationVersion: Int?
    var helperInstance: UUID?
    var lifecycleDiagnostics: HelperLifecycleDiagnostics?
    var adapterStartupRecovery: AdapterStartupRecovery?
    var adapterRestartVerificationAvailable: Bool?
    var adapterRestartVerificationVersion: Int?
    // Additive fields preserve status/removal compatibility with the original helper.
    var adapterByteObservationAvailable: Bool?
    var adapterByteObservationVersion: Int?
    var adapterByteObservation: AdapterByteObservationReport?
    var adapterBytePulseAvailable: Bool?
    var adapterBytePulseVersion: Int?
    var adapterBytePulse: AdapterBytePulseReport?
    var adapterVerificationAvailable: Bool?
    var adapterVerificationVersion: Int?
    var adapterVerification: AdapterVerificationReport?
    var adapterDiagnosticsAvailable: Bool?
    var adapterDiagnostics: AdapterCapabilityProbe?
    var chargeDiagnosticsAvailable: Bool?
    var chargeDiagnostics: ChargeCapabilityProbe?
    var nativeLimitDiagnosticsAvailable: Bool?
    var nativeChargeLimit: NativeChargeLimit?
    var nativeLimitSessionAvailable: Bool?
    var nativeLimitSessionVersion: Int?
    var activeNativeLimit: Int?
    var nativeVerificationAvailable: Bool?
    var nativeVerification: NativeLimitVerification?

    static let current = HelperStatus(protocolVersion: HelperContract.protocolVersion,
                                      helperVersion: HelperContract.helperVersion,
                                      controlState: .notControlling, chargingSupport: .notImplemented, adapterByteObservationAvailable: false, adapterBytePulseAvailable: false, adapterVerificationAvailable: false, adapterDiagnosticsAvailable: true, chargeDiagnosticsAvailable: true, nativeLimitDiagnosticsAvailable: true)

    static func decode(_ data: Data) throws -> Self {
        guard data.count <= 4_096 else { throw HelperConnectionError.invalidReply }
        let status: Self
        do { status = try JSONDecoder().decode(Self.self, from: data) }
        catch { throw HelperConnectionError.invalidReply }
        return try status.validated()
    }

    func validated() throws -> Self {
        guard protocolVersion == HelperContract.protocolVersion,
              helperVersion == HelperContract.helperVersion else { throw HelperConnectionError.versionMismatch }
        if let lifecycleDiagnostics {
            guard helperInstance != nil, lifecycleDiagnostics.isValid else { throw HelperConnectionError.invalidReply }
        }
        if let adapterStartupRecovery {
            guard helperInstance != nil, adapterStartupRecovery.isValid else { throw HelperConnectionError.invalidReply }
        }
        if adapterRemovalVerificationAvailable == true {
            guard helperInstance != nil, lifecycleDiagnostics != nil,
                  adapterRemovalVerificationVersion == HelperContract.adapterRemovalVerificationVersion else { throw HelperConnectionError.invalidReply }
        }
        if adapterSleepVerificationAvailable == true {
            guard helperInstance != nil, lifecycleDiagnostics != nil,
                  adapterSleepVerificationVersion == HelperContract.adapterSleepVerificationVersion else { throw HelperConnectionError.invalidReply }
        }
        if adapterRestartVerificationAvailable == true {
            guard helperInstance != nil, adapterStartupRecovery != nil,
                  adapterRestartVerificationVersion == HelperContract.adapterRestartVerificationVersion else { throw HelperConnectionError.invalidReply }
        }
        guard [adapterVerification != nil, adapterBytePulse != nil, adapterByteObservation != nil, nativeVerification != nil].filter({ $0 }).count <= 1 else { throw HelperConnectionError.invalidReply }
        if let adapterByteObservation {
            guard adapterByteObservationAvailable == true,
                  adapterByteObservationVersion == HelperContract.adapterByteObservationVersion,
                  adapterByteObservation.isValid, controlState != .nativeLimit,
                  (controlState == .restorationRequired) == (adapterByteObservation.byteEvidence.outcome == .restorationRequired)
            else { throw HelperConnectionError.invalidReply }
        }
        if let adapterBytePulse {
            guard adapterBytePulseAvailable == true,
                  adapterBytePulseVersion == HelperContract.adapterBytePulseVersion,
                  adapterBytePulse.isValid, controlState != .nativeLimit,
                  (controlState == .restorationRequired) == (adapterBytePulse.outcome == .restorationRequired)
            else { throw HelperConnectionError.invalidReply }
        }
        if let adapterVerification {
            guard adapterVerificationAvailable == true,
                  adapterVerificationVersion == HelperContract.adapterVerificationVersion,
                  adapterVerification.isValid,
                  controlState != .nativeLimit,
                  (controlState == .restorationRequired) == (adapterVerification.outcome == .restorationRequired)
            else { throw HelperConnectionError.invalidReply }
        }
        if let adapterDiagnostics {
            guard adapterDiagnosticsAvailable == true, adapterDiagnostics.isValid else { throw HelperConnectionError.invalidReply }
        }
        if let chargeDiagnostics {
            guard chargeDiagnosticsAvailable == true, chargeDiagnostics.isValid else { throw HelperConnectionError.invalidReply }
        }
        if let nativeChargeLimit {
            guard nativeLimitDiagnosticsAvailable == true, nativeChargeLimit.isValid else { throw HelperConnectionError.invalidReply }
        }
        if let nativeVerification {
            guard nativeVerificationAvailable == true, nativeVerification.isValid,
                  (controlState == .restorationRequired) == (nativeVerification.outcome == .restorationRequired)
            else { throw HelperConnectionError.invalidReply }
        } else if controlState == .restorationRequired && nativeLimitSessionAvailable != true && adapterVerification == nil && adapterBytePulse == nil && adapterByteObservation == nil {
            throw HelperConnectionError.invalidReply
        }
        if controlState == .nativeLimit {
            guard nativeLimitSessionAvailable == true, let activeNativeLimit,
                  case .available(let snapshot) = nativeChargeLimit,
                  snapshot.enabled, snapshot.configuredLimit == activeNativeLimit,
                  snapshot.availableLimits.contains(activeNativeLimit)
            else { throw HelperConnectionError.invalidReply }
        } else if activeNativeLimit != nil { throw HelperConnectionError.invalidReply }
        return self
    }
}

nonisolated enum HelperConnectionError: Error, Sendable, Equatable {
    case signingUnavailable, connectionFailed, timedOut, cancelled, invalidReply, versionMismatch
}
