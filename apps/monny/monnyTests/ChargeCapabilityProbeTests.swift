import Foundation
import Testing
@testable import monny

struct ChargeCapabilityProbeTests {
    @Test func onlyReviewedCandidatesAreReadOnceAndNoControlSupportIsInferred() {
        var requested: [String] = []
        let metadata = SMCKeyMetadata(type: "ui8 ", size: 1, attributes: 0xFF)
        let report = ChargeCapabilityProbe.inspect { key in
            requested.append(key)
            return .readable(metadata: metadata, value: SMCValue(type: "ui8 ", bytes: [0]))
        }
        #expect(requested == ["CH0B", "CH0C", "CHTE", "bfF0", "bfD0", "bfE0"])
        #expect(report.entries.map(\.key) == requested)
        #expect(report.controlSupport == .unverified)
    }

    @Test func partialAndDeniedReadsPreserveMetadataWithoutHidingOtherKeys() {
        let metadata = SMCKeyMetadata(type: "ui8 ", size: 1, attributes: 0)
        let report = ChargeCapabilityProbe.inspect { key in
            switch key {
            case "CH0B": .unavailable(.kernel(-1), metadata: metadata)
            case "bfF0": .readable(metadata: metadata, value: SMCValue(type: "ui8 ", bytes: [80]))
            default: .unavailable(.smc(0x84))
            }
        }
        #expect(report.entries.count == 6)
        #expect(report.entries.first?.inspection == .unavailable(.kernel(-1), metadata: metadata))
        #expect(report.entries[3].inspection == .readable(metadata: metadata, value: SMCValue(type: "ui8 ", bytes: [80])))
        #expect(report.entries.last?.inspection == .unavailable(.smc(0x84)))
        #expect(report.controlSupport == .unverified)
    }

    @Test func unavailableConnectionDoesNotProduceFakeValues() {
        let report = ChargeCapabilityProbe.inspect { _ in .unavailable(.connectionUnavailable) }
        #expect(report.entries.allSatisfy { $0.inspection == .unavailable(.connectionUnavailable) })
        #expect(report.controlSupport == .unverified)
    }

    @Test(arguments: [UInt32(0), 33, .max])
    func emptyOrOversizedMetadataIsRejected(size: UInt32) {
        #expect(SMCKeyMetadata(type: "ui8 ", size: size, attributes: 0xFF).isValid == false)
    }

    @Test(arguments: ["", "ui8", "ui8  ", "\0\0\0\0", "é123", "\n123"])
    func malformedTypesAreRejected(type: String) {
        #expect(SMCKeyMetadata(type: type, size: 1, attributes: 0).isValid == false)
    }

    @Test func unknownPrintableTypeIsEvidenceNotAnInventedNumber() {
        let metadata = SMCKeyMetadata(type: "hex_", size: 32, attributes: 0)
        #expect(metadata.isValid)
        #expect(SMCValue(type: metadata.type, bytes: Array(repeating: 0, count: 32)).number == nil)
    }

    @Test func integerTypeSizesMustMatchBeforeDecoding() {
        for value in [SMCValue(type: "ui8 ", bytes: [0, 1]),
                      SMCValue(type: "ui16", bytes: [1]),
                      SMCValue(type: "ui32", bytes: [1, 2, 3]),
                      SMCValue(type: "ui32", bytes: [1, 2, 3, 4, 5])] {
            #expect(value.number == nil)
        }
    }
}
