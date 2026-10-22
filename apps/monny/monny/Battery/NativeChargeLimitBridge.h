#import <Foundation/Foundation.h>
#import <stdbool.h>

// The macOS 26.4+ charge limit and Optimized Battery Charging (System Settings › Battery) through
// the private PowerUI client. Every call checks the runtime signatures and fails instead of guessing.
// Calls are synchronous; ChargeLimitStore makes them off the main actor, one at a time.
typedef struct {
    bool available;
    bool enabled;
    uint8_t limit;
    uint8_t count;
    uint8_t limits[21];
    /// Optimized Battery Charging, read only when its methods have the verified signatures.
    bool optimizedKnown;
    bool optimized;
} MonnyChargeLimitState;

MonnyChargeLimitState MonnyReadChargeLimit(void);
bool MonnySetChargeLimit(uint8_t limit);
bool MonnySetChargeLimitEnabled(bool enabled);
bool MonnySetOptimizedCharging(bool enabled);
