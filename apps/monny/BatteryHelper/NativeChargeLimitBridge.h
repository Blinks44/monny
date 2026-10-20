#import <Foundation/Foundation.h>

// Isolated runtime bridge. Mutation entry points remain disconnected from the production helper.
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

// Call only through a journal-backed transaction on the helper executor, never from UI/diagnostics.
MonnyNativeLimitStatus MonnySetNativeChargeLimit(uint8_t limit);
MonnyNativeLimitStatus MonnySetNativeChargeLimitEnabled(BOOL enabled);
