#import <Foundation/Foundation.h>

// Isolated native runtime bridge; called off the main actor by the setting controller.
typedef NS_ENUM(uint8_t, MonnyNativeLimitStatus) {
    MonnyNativeLimitAvailable,
    MonnyNativeLimitFrameworkUnavailable,
    MonnyNativeLimitInterfaceUnavailable,
    MonnyNativeLimitUnsupported,
    MonnyNativeLimitQueryFailed,
    MonnyNativeLimitInvalidReply,
    MonnyNativeLimitInvalidTarget,
    MonnyNativeLimitOperationFailed
};

typedef struct {
    MonnyNativeLimitStatus status;
    uint8_t count;
    uint8_t limits[21];
    uint8_t configuredLimit;
    uint64_t enabled;
} MonnyNativeLimitSnapshot;

MonnyNativeLimitSnapshot MonnyReadNativeChargeLimit(void);

// Serialized by NativeChargeLimitStore; no privileged process or SMC writer.
MonnyNativeLimitStatus MonnySetNativeChargeLimit(uint8_t limit);
MonnyNativeLimitStatus MonnySetNativeChargeLimitEnabled(BOOL enabled);
