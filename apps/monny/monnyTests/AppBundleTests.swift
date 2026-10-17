import Foundation
import Testing

/// Guards the bundle identity that signing, the battery helper and saved settings depend on.
struct AppBundleTests {
    @Test func hostAppIdentity() {
        let bundle = Bundle.main
        #expect(bundle.bundleIdentifier == "blinks44.monny")
        #expect(bundle.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String == "Monny")
    }
}
