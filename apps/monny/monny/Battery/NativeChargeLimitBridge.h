#import <Foundation/Foundation.h>
#import <stdbool.h>

// The macOS 26.4+ charge limit (System Settings › Battery › Charge Limit) through the private
// PowerUI client. Every call checks the runtime signatures and fails instead of guessing.
// Calls are synchronous; ChargeLimitStore makes them off the main actor, one at a time.
typedef struct {
    bool available;
    bool enabled;
    uint8_t limit;
    uint8_t count;
    uint8_t limits[21];
} MonnyChargeLimitState;

MonnyChargeLimitState MonnyReadChargeLimit(void);
bool MonnySetChargeLimit(uint8_t limit);
bool MonnySetChargeLimitEnabled(bool enabled);
