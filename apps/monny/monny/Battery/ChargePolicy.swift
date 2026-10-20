import Foundation

/// App-side decisions only. This type performs no I/O and is not yet connected to a helper.
/// A future helper must acknowledge commands and restore macOS control when its lease expires.
nonisolated struct ChargePolicy: Sendable {
    enum Mode: Sendable, Hashable { case charge, discharge }
    enum Capability: Sendable { case unavailable, chargeOnly, chargeAndDischarge }
    enum Action: Sendable { case macOS, charge, hold, discharge }
    enum Reason: Sendable {
        case disabled, unavailable, invalidSettings, invalidReading, onBattery
        case chargingToLimit, atLimit, dischargingToLimit, tooHot
    }

    struct Decision: Sendable, Equatable {
        var action: Action
        var reason: Reason
    }

    struct Settings: Sendable, Equatable {
        var isEnabled = false
        var mode = Mode.charge
        /// Fractions: limit 0.8...1, sailing range 0...0.1 (zero means off).
        var limit = 0.8
        var sailingRange = 0.0
        /// °C; nil means heat protection is off.
        var heatThreshold: Double?

        var isValid: Bool {
            limit.isFinite && (0.8...1).contains(limit)
                && sailingRange.isFinite && (0...0.1).contains(sailingRange)
                && (heatThreshold.map { $0.isFinite && (30...45).contains($0) } ?? true)
        }
    }

    struct Reading: Sendable {
        var level: Double
        /// Physical connection, not the macOS power source (which changes during forced discharge).
        var isAdapterConnected: Bool
        var temperature: Double?
        /// Elapsed monotonic time since sampling; the caller must not reuse stale observations.
        var age: Duration = .zero
    }

    /// Covers the sampler's 10 s background cadence with room for scheduling jitter.
    static let maximumReadingAge: Duration = .seconds(30)
    private var previousSettings: Settings?
    private var reachedLimit = false
    private var heatPaused = false

    /// Missing capability/reading or inactive policy always releases control to macOS.
    /// Changing settings starts a new episode; a previous hold cannot carry into another mode.
    mutating func update(settings: Settings, reading: Reading?, capability: Capability) -> Decision {
        guard settings.isEnabled else { return release(.disabled) }
        guard settings.isValid else { return release(.invalidSettings) }
        guard capability != .unavailable,
              settings.mode != .discharge || capability == .chargeAndDischarge else {
            return release(.unavailable)
        }
        guard let reading, reading.level.isFinite, (0...1).contains(reading.level),
              reading.age >= .zero, reading.age <= Self.maximumReadingAge else {
            return release(.invalidReading)
        }
        guard reading.isAdapterConnected else { return release(.onBattery) }
        if settings != previousSettings {
            reachedLimit = false
            heatPaused = false
            previousSettings = settings
        }

        if let threshold = settings.heatThreshold {
            guard let temperature = reading.temperature, temperature.isFinite,
                  (1...150).contains(temperature) else { return release(.invalidReading) }
            // Two degrees prevent oscillation at the threshold. Heat protection keeps adapter
            // power connected even in Discharge mode; it only inhibits battery charging.
            if temperature > threshold { heatPaused = true }
            if temperature <= threshold - 2 { heatPaused = false }
            if heatPaused { return Decision(action: .hold, reason: .tooHot) }
        }

        switch settings.mode {
        case .discharge:
            if reading.level <= settings.limit { reachedLimit = true }
            return reachedLimit ? Decision(action: .hold, reason: .atLimit)
                : Decision(action: .discharge, reason: .dischargingToLimit)
        case .charge:
            // With sailing off, one percentage point of hysteresis avoids toggling on noise.
            let lower = settings.limit - max(settings.sailingRange, 0.01)
            if reading.level >= settings.limit { reachedLimit = true }
            if reading.level <= lower { reachedLimit = false }
            return reachedLimit ? Decision(action: .hold, reason: .atLimit)
                : Decision(action: .charge, reason: .chargingToLimit)
        }
    }

    private mutating func release(_ reason: Reason) -> Decision {
        previousSettings = nil
        reachedLimit = false
        heatPaused = false
        return Decision(action: .macOS, reason: reason)
    }
}
