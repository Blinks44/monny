import Foundation

nonisolated enum HelperContract {
    static let appIdentifier = "blinks44.monny"
    static let helperIdentifier = "blinks44.monny.battery-helper"
    static let executableName = "MonnyBatteryHelper"
    static let plistName = helperIdentifier + ".plist"
    static let protocolVersion = 1
    static let helperVersion = "1.0"
}

/// No arbitrary keys, paths, shell commands or charging writes cross this interface.
@objc(MonnyBatteryHelperProtocol) nonisolated protocol BatteryHelperProtocol {
    func readStatus(withReply reply: @escaping @Sendable (Data) -> Void)
    func readChargeDiagnostics(withReply reply: @escaping @Sendable (Data) -> Void)
    func verifyNativeChargeLimit(_ limit: Int, withReply reply: @escaping @Sendable (Data) -> Void)
    func prepareForRemoval(withReply reply: @escaping @Sendable (Data) -> Void)
}

nonisolated struct HelperStatus: Codable, Sendable, Equatable {
    enum ControlState: String, Codable, Sendable { case notControlling, restorationRequired }
    enum Support: String, Codable, Sendable { case notImplemented }

    var protocolVersion: Int
    var helperVersion: String
    var controlState: ControlState
    var chargingSupport: Support
    // Additive fields preserve status/removal compatibility with the original helper.
    var chargeDiagnosticsAvailable: Bool?
    var chargeDiagnostics: ChargeCapabilityProbe?
    var nativeLimitDiagnosticsAvailable: Bool?
    var nativeChargeLimit: NativeChargeLimit?
    var nativeVerificationAvailable: Bool?
    var nativeVerification: NativeLimitVerification?

    static let current = HelperStatus(protocolVersion: HelperContract.protocolVersion,
                                      helperVersion: HelperContract.helperVersion,
                                      controlState: .notControlling, chargingSupport: .notImplemented, chargeDiagnosticsAvailable: true, nativeLimitDiagnosticsAvailable: true)

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
        } else if controlState != .notControlling { throw HelperConnectionError.invalidReply }
        return self
    }
}

nonisolated enum HelperConnectionError: Error, Sendable, Equatable {
    case signingUnavailable, connectionFailed, timedOut, cancelled, invalidReply, versionMismatch
}
