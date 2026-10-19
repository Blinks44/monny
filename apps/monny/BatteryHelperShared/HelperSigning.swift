import CryptoKit
import Foundation
import Security

/// Native peer requirements bind the actual process, not a PID/path supplied by a caller.
nonisolated enum HelperSigning {
    enum Peer {
        case app, helper
        var identifier: String { self == .app ? HelperContract.appIdentifier : HelperContract.helperIdentifier }
    }

    enum Identity: Equatable, Sendable {
        case appleTeam(String)
        /// Security's requirement language uses the SHA-1 fingerprint of the complete DER certificate.
        /// This pins the certificate, never its user-chosen name or a claimed Team ID.
        case certificate(String)
    }

    static func requirement(for peer: Peer, identity: Identity) -> String? {
        let signer: String
        switch identity {
        case .appleTeam(let team):
            guard team.utf8.count == 10, team.utf8.allSatisfy({ (65...90).contains($0) || (48...57).contains($0) }) else { return nil }
            signer = "anchor apple generic and certificate leaf[subject.OU] = \"\(team)\""
        case .certificate(let hash):
            guard hash.utf8.count == 40, hash.utf8.allSatisfy({ (48...57).contains($0) || (97...102).contains($0) }) else { return nil }
            signer = "certificate leaf = H\"\(hash)\""
        }
        return "\(signer) and identifier \"\(peer.identifier)\" and !entitlement[\"com.apple.security.get-task-allow\"] exists"
    }

    static func currentIdentity(for peer: Peer) -> Identity? {
        var code: SecCode?
        var staticCode: SecStaticCode?
        guard SecCodeCopySelf([], &code) == errSecSuccess, let code,
              SecCodeCopyStaticCode(code, [], &staticCode) == errSecSuccess, let staticCode,
              let identity = validatedIdentity(of: staticCode, peer: peer),
              let text = requirement(for: peer, identity: identity), let requirement = parse(text),
              SecCodeCheckValidity(code, [], requirement) == errSecSuccess else { return nil }
        return identity
    }

    static func identity(at url: URL, peer: Peer) -> Identity? {
        var code: SecStaticCode?
        guard SecStaticCodeCreateWithPath(url as CFURL, [], &code) == errSecSuccess, let code else { return nil }
        return validatedIdentity(of: code, peer: peer)
    }

    static func matches(at url: URL, peer: Peer, identity: Identity) -> Bool {
        var code: SecStaticCode?
        guard let text = requirement(for: peer, identity: identity), let requirement = parse(text),
              SecStaticCodeCreateWithPath(url as CFURL, [], &code) == errSecSuccess, let code else { return false }
        return SecStaticCodeCheckValidity(code, SecCSFlags(rawValue: kSecCSCheckAllArchitectures | kSecCSStrictValidate), requirement) == errSecSuccess
    }

    private static func validatedIdentity(of code: SecStaticCode, peer: Peer) -> Identity? {
        guard SecStaticCodeCheckValidity(code, SecCSFlags(rawValue: kSecCSCheckAllArchitectures | kSecCSStrictValidate), nil) == errSecSuccess else { return nil }
        var info: CFDictionary?
        guard SecCodeCopySigningInformation(code, SecCSFlags(rawValue: kSecCSSigningInformation), &info) == errSecSuccess,
              let values = info as? [String: Any],
              let certificates = values[kSecCodeInfoCertificates as String] as? [SecCertificate],
              let leaf = certificates.first else { return nil } // Ad-hoc signatures have no certificate.
        let identity: Identity
        if let team = values[kSecCodeInfoTeamIdentifier as String] as? String {
            // Never fall back to certificate pinning if an Apple-team identity fails validation.
            identity = .appleTeam(team)
        } else {
            // The alternate path supports a single self-signed certificate, not an arbitrary CA chain.
            guard certificates.count == 1 else { return nil }
            let digest = Insecure.SHA1.hash(data: SecCertificateCopyData(leaf) as Data)
            let digits = Array("0123456789abcdef".utf8)
            let hash = String(decoding: digest.flatMap { [digits[Int($0 >> 4)], digits[Int($0 & 15)]] }, as: UTF8.self)
            identity = .certificate(hash)
        }
        guard let text = requirement(for: peer, identity: identity), let requirement = parse(text),
              SecStaticCodeCheckValidity(code, SecCSFlags(rawValue: kSecCSCheckAllArchitectures | kSecCSStrictValidate), requirement) == errSecSuccess else { return nil }
        return identity
    }

    static func parse(_ text: String) -> SecRequirement? {
        var requirement: SecRequirement?
        guard SecRequirementCreateWithString(text as CFString, [], &requirement) == errSecSuccess else { return nil }
        return requirement
    }
}
