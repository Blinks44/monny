import Foundation
import Security
import Testing
@testable import monny

struct HelperContractTests {
    @Test func statusRoundTripAndUnknownVersionsFailClosed() throws {
        #expect(NSStringFromProtocol(BatteryHelperProtocol.self) == "MonnyBatteryHelperProtocol")
        #expect(try HelperStatus.decode(JSONEncoder().encode(HelperStatus.current)) == .current)
        var status = HelperStatus.current
        status.protocolVersion += 1
        #expect(throws: HelperConnectionError.versionMismatch) { try HelperStatus.decode(JSONEncoder().encode(status)) }
        status = .current
        status.helperVersion = "0.1"
        #expect(throws: HelperConnectionError.versionMismatch) { try status.validated() }
    }

    @Test func rejectsMalformedOversizedOrControllingReplies() {
        for data in [Data(), Data("{}".utf8), Data(repeating: 0, count: 4_097),
                     Data(#"{"protocolVersion":1,"helperVersion":"1.0","controlState":"holding","chargingSupport":"notImplemented"}"#.utf8)] {
            #expect(throws: HelperConnectionError.invalidReply) { try HelperStatus.decode(data) }
        }
    }

    @Test func peerRequirementsParseAndDoNotTrustTheOtherIdentifier() throws {
        for peer in [HelperSigning.Peer.app, .helper] {
            let text = try #require(HelperSigning.requirement(for: peer, identity: .appleTeam("ABCDEFGHIJ")))
            #expect(HelperSigning.parse(text) != nil)
            #expect(text.contains("anchor apple generic"))
            #expect(text.contains(peer.identifier))
            #expect(text.contains("com.apple.security.get-task-allow"))
        }
        // The test host is the app, so it cannot identify itself as the helper, even when signed.
        #expect(HelperSigning.currentIdentity(for: .helper) == nil)
    }

    @Test(arguments: ["", "short", "ABCDEFGHIJK", "abcDEFGHIJ", "ABCD\"FGHIJ", "ABCD EFGHI", "ABCDEFGHIé"])
    func refusesMalformedTeams(team: String) {
        #expect(HelperSigning.requirement(for: .app, identity: .appleTeam(team)) == nil)
    }

    @Test func pinnedRequirementsParseAndAdHocArtifactsAreRejected() throws {
        let identity = HelperSigning.Identity.certificate(String(repeating: "a", count: 40))
        for peer in [HelperSigning.Peer.app, .helper] {
            let text = try #require(HelperSigning.requirement(for: peer, identity: identity))
            #expect(HelperSigning.parse(text) != nil)
            #expect(text.contains("certificate leaf = H\""))
            #expect(text.contains(peer.identifier))
            #expect(HelperSigning.matches(at: Bundle.main.bundleURL, peer: peer, identity: identity) == false)
        }
    }

    @Test(arguments: ["", "abcd", String(repeating: "A", count: 40), String(repeating: "g", count: 40),
                      String(repeating: "a", count: 39) + "\"", String(repeating: "a", count: 41)])
    func refusesMalformedCertificatePins(hash: String) {
        #expect(HelperSigning.requirement(for: .helper, identity: .certificate(hash)) == nil)
    }

    @Test func embeddedHelperAndLaunchDaemonMatchTheContract() throws {
        let root = Bundle.main.bundleURL.appending(components: "Contents", "Library")
        let executable = root.appending(components: "HelperTools", HelperContract.executableName)
        #expect(FileManager.default.isExecutableFile(atPath: executable.path))
        let data = try Data(contentsOf: root.appending(components: "LaunchDaemons", HelperContract.plistName))
        let plist = try #require(PropertyListSerialization.propertyList(from: data, format: nil) as? [String: Any])
        #expect(plist["Label"] as? String == HelperContract.helperIdentifier)
        #expect(plist["BundleProgram"] as? String == "Contents/Library/HelperTools/MonnyBatteryHelper")
        #expect((plist["MachServices"] as? [String: Bool])?[HelperContract.helperIdentifier] == true)
        #expect(plist["UserName"] as? String == "root")
        #expect(plist["ProgramArguments"] == nil)
        #expect(plist["KeepAlive"] as? Bool == true)
    }

    @Test func lateCompletionsCannotReplaceTheFirstResult() async throws {
        let connection = HelperConnection()
        await connection.complete(.success(.current))
        await connection.complete(.failure(.connectionFailed))
        // A pre-resolved request returns without constructing or activating an XPC connection.
        #expect(try await connection.request(requirement: "unused") == .current)
    }

    @Test(arguments: [HelperConnectionError.cancelled, .timedOut, .connectionFailed])
    func earlyFailureIsPreservedBeforeTheWaiterExists(error: HelperConnectionError) async {
        let connection = HelperConnection()
        await connection.complete(.failure(error))
        await connection.complete(.success(.current))
        await #expect(throws: error) { try await connection.request(requirement: "unused") }
    }

    @Test func malformedRequirementFailsBeforeNativeXPC() async {
        let connection = HelperConnection()
        await #expect(throws: HelperConnectionError.signingUnavailable) {
            try await connection.request(requirement: "this is not a signing requirement")
        }
    }
}

private actor HelperFixture {
    var team: String? = "ABCDEFGHIJ"
    var registration = HelperRegistration.notRegistered
    var registerCalls = 0
    var unregisterCalls = 0
    var requests: [Bool] = []
    var failsRequest = false
    var requestFailure = HelperConnectionError.connectionFailed
    var failsRegister = false
    var registrationAfterRegister = HelperRegistration.requiresApproval
    var connectsAfterRegister = false
    var failsUnregister = false
    var reply = HelperStatus.current

    func configure(team: String? = "ABCDEFGHIJ", registration: HelperRegistration = .notRegistered,
                   failsRequest: Bool = false, failsRegister: Bool = false,
                   failsUnregister: Bool = false, reply: HelperStatus = .current,
                   requestFailure: HelperConnectionError = .connectionFailed,
                   registrationAfterRegister: HelperRegistration = .requiresApproval,
                   connectsAfterRegister: Bool = false) {
        self.team = team
        self.registration = registration
        self.failsRequest = failsRequest
        self.requestFailure = requestFailure
        self.failsRegister = failsRegister
        self.failsUnregister = failsUnregister
        self.reply = reply
        self.registrationAfterRegister = registrationAfterRegister
        self.connectsAfterRegister = connectsAfterRegister
    }

    func register() throws {
        registerCalls += 1
        if failsRegister { throw HelperConnectionError.connectionFailed }
        registration = registrationAfterRegister
        if connectsAfterRegister { failsRequest = false }
    }

    func unregister() throws {
        unregisterCalls += 1
        if failsUnregister { throw HelperConnectionError.connectionFailed }
        registration = .notRegistered
    }

    func request(removing: Bool) throws -> HelperStatus {
        requests.append(removing)
        if failsRequest { throw requestFailure }
        return reply
    }

    nonisolated var operations: HelperOperations {
        HelperOperations(signingIdentity: { await self.team.map { .appleTeam($0) } }, registration: { await self.registration },
                         register: { try await self.register() }, unregister: { try await self.unregister() },
                         request: { _, removing in try await self.request(removing: removing) })
    }
}

@MainActor
struct HelperLifecycleTests {
    @Test func restorationFailureStaysVisibleUntilFreshStatusConfirmsRecovery() async {
        let fixture = HelperFixture()
        var response = HelperStatus.current
        response.nativeLimitSessionAvailable = true
        response.nativeLimitSessionVersion = HelperContract.nativeLimitSessionVersion
        response.nativeChargeLimit = .available(.init(availableLimits: [80, 85, 100], configuredLimit: 80, enabled: true))
        response.controlState = .restorationRequired
        await fixture.configure(registration: .enabled, reply: response)
        let helper = BatteryHelper(operations: fixture.operations)
        await helper.refresh()
        #expect(helper.nativeFailed)
        #expect(!helper.canControlNativeLimit)
        response.controlState = .notControlling
        await fixture.configure(registration: .enabled, reply: response)
        await helper.retryConnection()
        #expect(helper.state == .connected)
        #expect(!helper.nativeFailed)
        #expect(helper.canControlNativeLimit)
        #expect(await fixture.registerCalls == 0)
    }

    @Test func explicitRetryCanReconnectAnApprovedMissingJobWithoutRemovingIt() async {
        let fixture = HelperFixture()
        await fixture.configure(registration: .enabled, failsRequest: true,
                                registrationAfterRegister: .enabled, connectsAfterRegister: true)
        let helper = BatteryHelper(operations: fixture.operations)
        await helper.refresh()
        #expect(helper.state == .failed)
        #expect(await fixture.registerCalls == 0)
        await helper.retryConnection()
        #expect(helper.state == .connected)
        #expect(await fixture.registerCalls == 1)
        #expect(await fixture.unregisterCalls == 0)
        #expect(await fixture.requests == [false, false, false])
    }

    @Test func failedExplicitRegistrationDoesNotLoopOrUnregister() async {
        let fixture = HelperFixture()
        await fixture.configure(registration: .enabled, failsRequest: true, failsRegister: true)
        let helper = BatteryHelper(operations: fixture.operations)
        await helper.retryConnection()
        #expect(helper.state == .failed)
        #expect(await fixture.registerCalls == 1)
        #expect(await fixture.unregisterCalls == 0)
        #expect(await fixture.requests == [false, false])
    }

    @Test(arguments: [HelperConnectionError.invalidReply, .versionMismatch, .cancelled])
    func explicitRetryDoesNotRegisterForUntrustedOrCancelledReplies(error: HelperConnectionError) async {
        let fixture = HelperFixture()
        await fixture.configure(registration: .enabled, failsRequest: true, requestFailure: error)
        let helper = BatteryHelper(operations: fixture.operations)
        await helper.retryConnection()
        #expect(await fixture.registerCalls == 0)
        #expect(await fixture.unregisterCalls == 0)
    }

    @Test(arguments: [HelperRegistration.notRegistered, .requiresApproval])
    func connectionRetryDoesNotInstallOrOverrideConsent(registration: HelperRegistration) async {
        let fixture = HelperFixture()
        await fixture.configure(registration: registration)
        let helper = BatteryHelper(operations: fixture.operations)
        await helper.retryConnection()
        #expect(await fixture.registerCalls == 0)
        #expect(await fixture.unregisterCalls == 0)
        #expect(await fixture.requests.isEmpty)
    }

    @Test func refreshNeverRegistersAndInstallWaitsForApproval() async {
        let fixture = HelperFixture()
        let helper = BatteryHelper(operations: fixture.operations)
        await helper.refresh()
        #expect(helper.state == .notInstalled)
        #expect(helper.canInstall)
        #expect(await fixture.registerCalls == 0)
        await helper.install()
        #expect(helper.state == .needsApproval)
        #expect(helper.canInstall == false)
        #expect(await fixture.registerCalls == 1)
        #expect(await fixture.requests.isEmpty)
    }

    @Test func unsignedBuildCannotRegisterOrConnect() async {
        let fixture = HelperFixture()
        await fixture.configure(team: nil)
        let helper = BatteryHelper(operations: fixture.operations)
        await helper.refresh()
        await helper.install()
        #expect(helper.state == .unavailable)
        #expect(helper.canInstall == false)
        #expect(await fixture.registerCalls == 0)
        #expect(await fixture.requests.isEmpty)
    }

    @Test func approvedHelperReportsVersionWithoutEnablingControl() async {
        let fixture = HelperFixture()
        await fixture.configure(registration: .enabled)
        let helper = BatteryHelper(operations: fixture.operations)
        await helper.refresh()
        #expect(helper.state == .connected)
        #expect(helper.status?.helperVersion == HelperContract.helperVersion)
        #expect(helper.status?.chargingSupport == .notImplemented)
        #expect(await fixture.requests == [false])
    }

    @Test func removalRequiresAnAcknowledgementBeforeUnregistering() async {
        let fixture = HelperFixture()
        await fixture.configure(registration: .enabled)
        let helper = BatteryHelper(operations: fixture.operations)
        await helper.refresh()
        await helper.remove()
        #expect(helper.state == .notInstalled)
        #expect(helper.status == nil)
        #expect(await fixture.requests == [false, true])
        #expect(await fixture.unregisterCalls == 1)
    }

    @Test func unresponsiveHelperIsNeverReportedAsRemoved() async {
        let fixture = HelperFixture()
        await fixture.configure(registration: .enabled, failsRequest: true)
        let helper = BatteryHelper(operations: fixture.operations)
        await helper.refresh()
        await helper.remove()
        #expect(helper.state == .failed)
        #expect(helper.failure == .removal)
        #expect(await fixture.unregisterCalls == 0)
    }

    @Test func incompatibleHelperCannotBeRemovedBySkippingTheHandshake() async {
        let fixture = HelperFixture()
        var status = HelperStatus.current
        status.protocolVersion = 2
        await fixture.configure(registration: .enabled, reply: status)
        let helper = BatteryHelper(operations: fixture.operations)
        await helper.refresh()
        #expect(helper.state == .incompatible)
        await helper.remove()
        #expect(helper.state == .incompatible)
        #expect(await fixture.unregisterCalls == 0)
    }

    @Test func cancelsAnUnapprovedRegistrationWithoutAConnection() async {
        let fixture = HelperFixture()
        await fixture.configure(registration: .requiresApproval)
        let helper = BatteryHelper(operations: fixture.operations)
        await helper.refresh()
        await helper.remove()
        #expect(helper.state == .notInstalled)
        #expect(await fixture.requests.isEmpty)
        #expect(await fixture.unregisterCalls == 1)
    }

    @Test func registrationAndRemovalErrorsStayVisible() async {
        let fixture = HelperFixture()
        await fixture.configure(failsRegister: true)
        let helper = BatteryHelper(operations: fixture.operations)
        await helper.refresh()
        await helper.install()
        #expect(helper.state == .failed)
        #expect(helper.failure == .installation)
        await fixture.configure(registration: .enabled, failsUnregister: true)
        await helper.refresh()
        await helper.remove()
        #expect(helper.state == .failed)
        #expect(helper.failure == .removal)
        #expect(helper.registration == .enabled)
    }
    @Test(arguments: [HelperConnectionError.connectionFailed, .timedOut])
    func statusOnlyHelperCanBeUnregisteredWhenTransportIsUnavailable(error: HelperConnectionError) async {
        let fixture = HelperFixture()
        await fixture.configure(registration: .enabled, failsRequest: true, requestFailure: error)
        var operations = fixture.operations
        operations.requiresRemovalAcknowledgement = false
        let helper = BatteryHelper(operations: operations)
        await helper.refresh()
        #expect(helper.state == .failed)
        await helper.remove()
        #expect(helper.state == .notInstalled)
        #expect(helper.status == nil)
        #expect(await fixture.unregisterCalls == 1)
    }

    @Test(arguments: [HelperConnectionError.invalidReply, .versionMismatch, .cancelled])
    func statusOnlyRecoveryStillRejectsInvalidOrIncompatibleReplies(error: HelperConnectionError) async {
        let fixture = HelperFixture()
        await fixture.configure(registration: .enabled, failsRequest: true, requestFailure: error)
        var operations = fixture.operations
        operations.requiresRemovalAcknowledgement = false
        let helper = BatteryHelper(operations: operations)
        await helper.refresh()
        await helper.remove()
        #expect(helper.state != .notInstalled)
        #expect(await fixture.unregisterCalls == 0)
    }

    @Test func failedSystemUnregisterIsNotReportedAsSuccessfulOfflineRecovery() async {
        let fixture = HelperFixture()
        await fixture.configure(registration: .enabled, failsRequest: true, failsUnregister: true)
        var operations = fixture.operations
        operations.requiresRemovalAcknowledgement = false
        let helper = BatteryHelper(operations: operations)
        await helper.refresh()
        await helper.remove()
        #expect(helper.state == .failed)
        #expect(helper.failure == .removal)
        #expect(await fixture.unregisterCalls == 1)
    }

}
