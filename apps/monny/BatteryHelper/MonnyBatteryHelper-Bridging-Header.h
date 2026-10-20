#import <IOKit/IOMessage.h>

// IOKit's function-like message macros are not imported by Swift. Preserve SDK values in C.
static const natural_t MonnyCanSystemSleep = kIOMessageCanSystemSleep;
static const natural_t MonnySystemWillSleep = kIOMessageSystemWillSleep;
static const natural_t MonnySystemHasPoweredOn = kIOMessageSystemHasPoweredOn;

#import "NativeChargeLimitBridge.h"
