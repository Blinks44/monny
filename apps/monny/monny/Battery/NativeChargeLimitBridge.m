#import "NativeChargeLimitBridge.h"
#import <dlfcn.h>
#import <objc/runtime.h>
#import <math.h>

// Signatures were independently verified on the installed runtime (BAT-010).
// All private API use stays here; missing/changed methods fail unavailable.
@protocol MonnyNativeLimitGetters
- (id)initWithClientName:(NSString *)name;
- (BOOL)isMCLSupported;
- (unsigned char)getMCLLimitWithError:(NSError **)error;
- (unsigned long long)isMCLCurrentlyEnabled:(NSError **)error;
- (NSArray<NSNumber *> *)availableChargeLimitsWithError:(NSError **)error;
@end

@protocol MonnyNativeLimitSetters <MonnyNativeLimitGetters>
- (BOOL)setMCLLimit:(unsigned char)limit error:(NSError **)error;
- (BOOL)enableMCL:(NSError **)error;
- (BOOL)disableMCL:(NSError **)error;
@end

static BOOL methodMatches(Class type, SEL selector, const char *result, NSArray<NSString *> *arguments) {
    Method method = class_getInstanceMethod(type, selector);
    if (!method || method_getNumberOfArguments(method) != arguments.count + 2) return NO;
    char *returned = method_copyReturnType(method);
    BOOL matches = returned && strcmp(returned, result) == 0;
    free(returned);
    for (NSUInteger index = 0; index < arguments.count; index++) {
        char *actual = method_copyArgumentType(method, (unsigned int)index + 2);
        matches = matches && actual && strcmp(actual, arguments[index].UTF8String) == 0;
        free(actual);
    }
    return matches;
}

static BOOL gettersMatch(Class type) {
    return type && [type isSubclassOfClass:[NSObject class]] &&
        methodMatches(type, @selector(initWithClientName:), "@", @[@"@"]) &&
        methodMatches(type, @selector(isMCLSupported), "B", @[]) &&
        methodMatches(type, @selector(getMCLLimitWithError:), "C", @[@"^@"]) &&
        methodMatches(type, @selector(isMCLCurrentlyEnabled:), "Q", @[@"^@"]) &&
        methodMatches(type, @selector(availableChargeLimitsWithError:), "@", @[@"^@"]);
}

static BOOL settersMatch(Class type) {
    return gettersMatch(type) &&
        methodMatches(type, @selector(setMCLLimit:error:), "B", @[@"C", @"^@"]) &&
        methodMatches(type, @selector(enableMCL:), "B", @[@"^@"]) &&
        methodMatches(type, @selector(disableMCL:), "B", @[@"^@"]);
}

static BOOL loadFramework(void) {
    static void *framework;
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        // Retain the system framework for the process lifetime; no shared client state.
        framework = dlopen("/System/Library/PrivateFrameworks/PowerUI.framework/Versions/A/PowerUI", RTLD_NOW | RTLD_LOCAL);
    });
    return framework != NULL;
}

MonnyNativeLimitSnapshot MonnyReadNativeChargeLimit(void) {
    @autoreleasepool {
        MonnyNativeLimitSnapshot report = {.status = MonnyNativeLimitFrameworkUnavailable};
        if (!loadFramework()) return report;
        report.status = MonnyNativeLimitInterfaceUnavailable;
        Class type = NSClassFromString(@"PowerUISmartChargeClient");
        if (!gettersMatch(type)) return report;
        @try {
            id<MonnyNativeLimitGetters> client = [(id<MonnyNativeLimitGetters>)[type alloc] initWithClientName:@"MonnyReadOnlyDiagnostics"];
            if (!client || !gettersMatch(object_getClass(client))) return report;
            report.status = MonnyNativeLimitUnsupported;
            if (![client isMCLSupported]) return report;
            report.status = MonnyNativeLimitQueryFailed;
            NSError *error = nil;
            id limits = [client availableChargeLimitsWithError:&error];
            if (error) return report;
            report.configuredLimit = [client getMCLLimitWithError:&error];
            if (error) return report;
            report.enabled = [client isMCLCurrentlyEnabled:&error];
            if (error) return report;
            report.status = MonnyNativeLimitInvalidReply;
            if (![limits isKindOfClass:[NSArray class]] || [limits count] < 1 || [limits count] > 21) return report;
            for (id value in limits) {
                if (![value isKindOfClass:[NSNumber class]] || CFGetTypeID((__bridge CFTypeRef)value) == CFBooleanGetTypeID()) return report;
                double number = [value doubleValue];
                if (!isfinite(number) || trunc(number) != number || number < 80 || number > 100) return report;
                report.limits[report.count++] = (uint8_t)number;
            }
            report.status = MonnyNativeLimitAvailable;
        } @catch (NSException *exception) {
            report.status = MonnyNativeLimitQueryFailed;
        }
        return report;
    }
}

// One synchronous write with fresh validation; the store verifies actual read-back.
static MonnyNativeLimitStatus writeNativeClient(id<MonnyNativeLimitSetters> client, BOOL changingLimit,
                                               uint8_t limit, BOOL enabled) {
    if (!client || !settersMatch(object_getClass(client))) return MonnyNativeLimitInterfaceUnavailable;
    if (changingLimit && (limit < 80 || limit > 100)) return MonnyNativeLimitInvalidTarget;
    if (![client isMCLSupported]) return MonnyNativeLimitUnsupported;
    NSError *error = nil;
    // Use fresh getter validation before a write; no cached diagnostic snapshot is consulted.
    id limits = [client availableChargeLimitsWithError:&error];
    if (error) return MonnyNativeLimitQueryFailed;
    if (![limits isKindOfClass:[NSArray class]] || [limits count] < 1 || [limits count] > 21) return MonnyNativeLimitInvalidReply;
    NSMutableSet *seen = [NSMutableSet set];
    for (id item in limits) {
        if (![item isKindOfClass:[NSNumber class]] || CFGetTypeID((__bridge CFTypeRef)item) == CFBooleanGetTypeID()) return MonnyNativeLimitInvalidReply;
        double value = [item doubleValue];
        if (!isfinite(value) || trunc(value) != value || value < 80 || value > 100 || [seen containsObject:item]) return MonnyNativeLimitInvalidReply;
        [seen addObject:item];
    }
    unsigned char currentLimit = [client getMCLLimitWithError:&error];
    if (error) return MonnyNativeLimitQueryFailed;
    unsigned long long currentEnabled = [client isMCLCurrentlyEnabled:&error];
    if (error) return MonnyNativeLimitQueryFailed;
    if (![seen containsObject:@(currentLimit)] || currentEnabled > 1) return MonnyNativeLimitInvalidReply;
    if (changingLimit && ![seen containsObject:@(limit)]) return MonnyNativeLimitInvalidTarget;
    BOOL acknowledged = changingLimit ? [client setMCLLimit:limit error:&error]
        : (enabled ? [client enableMCL:&error] : [client disableMCL:&error]);
    // A failure may still have changed settings; the surrounding transaction owns read-back/recovery.
    return acknowledged && !error ? MonnyNativeLimitAvailable : MonnyNativeLimitOperationFailed;
}

static MonnyNativeLimitStatus writeNative(BOOL changingLimit, uint8_t limit, BOOL enabled) {
    @autoreleasepool {
        if (!loadFramework()) return MonnyNativeLimitFrameworkUnavailable;
        Class type = NSClassFromString(@"PowerUISmartChargeClient");
        if (!settersMatch(type)) return MonnyNativeLimitInterfaceUnavailable;
        @try {
            id<MonnyNativeLimitSetters> client = [(id<MonnyNativeLimitSetters>)[type alloc] initWithClientName:@"MonnyChargeControl"];
            return writeNativeClient(client, changingLimit, limit, enabled);
        } @catch (NSException *exception) {
            return MonnyNativeLimitOperationFailed;
        }
    }
}

MonnyNativeLimitStatus MonnySetNativeChargeLimit(uint8_t limit) {
    return writeNative(YES, limit, NO);
}

MonnyNativeLimitStatus MonnySetNativeChargeLimitEnabled(BOOL enabled) {
    return writeNative(NO, 0, enabled);
}
