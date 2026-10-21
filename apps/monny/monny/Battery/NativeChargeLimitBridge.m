#import "NativeChargeLimitBridge.h"
#import <dlfcn.h>
#import <objc/runtime.h>

// PowerUISmartChargeClient signatures as verified on macOS 27.0.1 (research/battery-control.md).
@protocol MonnyChargeLimitClient
- (id)initWithClientName:(NSString *)name;
- (BOOL)isMCLSupported;
- (unsigned char)getMCLLimitWithError:(NSError **)error;
- (unsigned long long)isMCLCurrentlyEnabled:(NSError **)error;
- (NSArray<NSNumber *> *)availableChargeLimitsWithError:(NSError **)error;
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

/// The client class when the framework loads and every method has the verified signature.
static Class clientClass(void) {
    static Class type;
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        if (!dlopen("/System/Library/PrivateFrameworks/PowerUI.framework/Versions/A/PowerUI", RTLD_NOW | RTLD_LOCAL)) return;
        Class candidate = NSClassFromString(@"PowerUISmartChargeClient");
        if (candidate &&
            methodMatches(candidate, @selector(initWithClientName:), "@", @[@"@"]) &&
            methodMatches(candidate, @selector(isMCLSupported), "B", @[]) &&
            methodMatches(candidate, @selector(getMCLLimitWithError:), "C", @[@"^@"]) &&
            methodMatches(candidate, @selector(isMCLCurrentlyEnabled:), "Q", @[@"^@"]) &&
            methodMatches(candidate, @selector(availableChargeLimitsWithError:), "@", @[@"^@"]) &&
            methodMatches(candidate, @selector(setMCLLimit:error:), "B", @[@"C", @"^@"]) &&
            methodMatches(candidate, @selector(enableMCL:), "B", @[@"^@"]) &&
            methodMatches(candidate, @selector(disableMCL:), "B", @[@"^@"])) {
            type = candidate;
        }
    });
    return type;
}

static id<MonnyChargeLimitClient> makeClient(void) {
    Class type = clientClass();
    if (!type) return nil;
    id client = [[type alloc] initWithClientName:@"Monny"];
    return [client isKindOfClass:type] ? client : nil;
}

MonnyChargeLimitState MonnyReadChargeLimit(void) {
    MonnyChargeLimitState state = {0};
    @autoreleasepool {
        @try {
            id<MonnyChargeLimitClient> client = makeClient();
            if (!client || ![client isMCLSupported]) return state;
            NSError *error = nil;
            id limits = [client availableChargeLimitsWithError:&error];
            if (error || ![limits isKindOfClass:[NSArray class]] || [limits count] == 0 || [limits count] > 21) return state;
            for (id value in limits) {
                if (![value isKindOfClass:[NSNumber class]]) return state;
                NSInteger limit = [value integerValue];
                if (limit < 0 || limit > 100) return state;
                state.limits[state.count++] = (uint8_t)limit;
            }
            state.limit = [client getMCLLimitWithError:&error];
            if (error) return state;
            unsigned long long enabled = [client isMCLCurrentlyEnabled:&error];
            if (error || enabled > 1) return state;
            state.enabled = enabled == 1;
            state.available = true;
        } @catch (NSException *exception) {
            state.available = false;
        }
    }
    return state;
}

bool MonnySetChargeLimit(uint8_t limit) {
    @autoreleasepool {
        @try {
            NSError *error = nil;
            id<MonnyChargeLimitClient> client = makeClient();
            return client && [client setMCLLimit:limit error:&error] && !error;
        } @catch (NSException *exception) {
            return false;
        }
    }
}

bool MonnySetChargeLimitEnabled(bool enabled) {
    @autoreleasepool {
        @try {
            NSError *error = nil;
            id<MonnyChargeLimitClient> client = makeClient();
            if (!client) return false;
            BOOL done = enabled ? [client enableMCL:&error] : [client disableMCL:&error];
            return done && !error;
        } @catch (NSException *exception) {
            return false;
        }
    }
}
