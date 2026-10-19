import Testing
@testable import monny

/// How the NVMe SMART log maps to SSD health.
struct SSDHealthTests {
    private func smart(used: UInt8 = 3, spare: UInt8 = 100, threshold: UInt8 = 10, warning: UInt8 = 0, unitsWritten: UInt64 = 0) -> NVMeSMARTData {
        var data = NVMeSMARTData()
        data.PERCENTAGE_USED = used
        data.AVAILABLE_SPARE = spare
        data.AVAILABLE_SPARE_THRESHOLD = threshold
        data.CRITICAL_WARNING = warning
        data.DATA_UNITS_WRITTEN.0 = unitsWritten
        return data
    }

    @Test func healthyDrive() {
        let health = SSDHealthReader.health(smart(unitsWritten: 80_000_000))
        #expect(health.wear == 0.03)
        #expect(health.health == 0.97)
        #expect(health.isVerified)
        // One data unit is 1000 blocks of 512 bytes.
        #expect(health.bytesWritten == 40_960_000_000_000)
    }

    @Test func warningOrLowSpareFails() {
        #expect(!SSDHealthReader.health(smart(warning: 0x04)).isVerified)
        #expect(!SSDHealthReader.health(smart(spare: 5)).isVerified)
    }

    @Test func wearPastRatedLifeShowsNoHealthLeft() {
        let health = SSDHealthReader.health(smart(used: 120))
        #expect(health.wear == 1.2)
        #expect(health.health == 0)
    }
}
