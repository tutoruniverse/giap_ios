//
//  GIAPDevice.m
//  GIAP
//
//  Created by Tran Viet Thang on 2/11/20.
//

#import <SystemConfiguration/SystemConfiguration.h>
#include <sys/sysctl.h>

#import <Foundation/Foundation.h>
#import "GIAPDevice.h"
#import "Constants.h"

@implementation GIAPDevice: NSObject

+ (instancetype)initWithToken:(NSString *)token
{
    return [[GIAPDevice alloc] initWithToken:token];
}

- (instancetype)initWithToken:(NSString *)token
{
    NSString *label = [NSString stringWithFormat:@"ai.gotit.giap.%@.%p", token, (void *)self];
    self.serialQueue = dispatch_queue_create([label UTF8String], DISPATCH_QUEUE_SERIAL);
    
    self.consistentProperties = [self getConsistentProperties];
    
    self.telephonyInfo = [[CTTelephonyNetworkInfo alloc] init];
    
    // cellular info
    [self setCurrentRadio];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(setCurrentRadio)
                                                 name:CTRadioAccessTechnologyDidChangeNotification
                                               object:nil];
    
    // wifi
    if ((self.reachability = SCNetworkReachabilityCreateWithName(NULL, "analytics-api.got-it.ai")) != NULL) {
        SCNetworkReachabilityContext context = {0, (__bridge void*)self, NULL, NULL, NULL};
        if (SCNetworkReachabilitySetCallback(self.reachability, GIAPReachabilityCallback, &context)) {
            if (!SCNetworkReachabilitySetDispatchQueue(self.reachability, self.serialQueue)) {
                // cleanup callback if setting dispatch queue failed
                SCNetworkReachabilitySetCallback(self.reachability, NULL, NULL);
            }
        }
    }
    
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    if (!SCNetworkReachabilitySetCallback(self.reachability, NULL, NULL)) {
        NSLog(@"%@ error unsetting reachability callback", self);
    }
    if (!SCNetworkReachabilitySetDispatchQueue(self.reachability, NULL)) {
        NSLog(@"%@ error unsetting reachability dispatch queue", self);
    }
    
    CFRelease(_reachability);
    self.reachability = NULL;
}

- (NSDictionary *)getDeviceProperties
{
    NSMutableDictionary *p = [NSMutableDictionary dictionary];
    
    [p addEntriesFromDictionary:self.consistentProperties];
    
    [p setValue:self.radio forKey:@"$radio"];
    [p setValue:self.carrier forKey:@"$carrier"];
    [p setValue:@(self.wifi) forKey:@"$wifi"];
    
    return p;
}

- (NSString *)getIDFA
{
    NSString *ifa = nil;

    Class ASIdentifierManagerClass = NSClassFromString(@"ASIdentifierManager");
    if (ASIdentifierManagerClass) {
        SEL sharedManagerSelector = NSSelectorFromString(@"sharedManager");
        id sharedManager = ((id (*)(id, SEL))[ASIdentifierManagerClass methodForSelector:sharedManagerSelector])(ASIdentifierManagerClass, sharedManagerSelector);
        SEL advertisingTrackingEnabledSelector = NSSelectorFromString(@"isAdvertisingTrackingEnabled");
        BOOL isTrackingEnabled = ((BOOL (*)(id, SEL))[sharedManager methodForSelector:advertisingTrackingEnabledSelector])(sharedManager, advertisingTrackingEnabledSelector);
        if (isTrackingEnabled) {
            SEL advertisingIdentifierSelector = NSSelectorFromString(@"advertisingIdentifier");
            NSUUID *uuid = ((NSUUID* (*)(id, SEL))[sharedManager methodForSelector:advertisingIdentifierSelector])(sharedManager, advertisingIdentifierSelector);
            ifa = [uuid UUIDString];
        }
    }

    return ifa;
}

- (NSString *)getIdentifierForVendor
{
    return [[UIDevice currentDevice].identifierForVendor UUIDString];
}

- (NSDictionary *) getConsistentProperties
{
    NSMutableDictionary *p = [NSMutableDictionary dictionary];
    
    // Use setValue semantics to avoid adding keys where value can be nil.
    [p setValue:[[NSBundle mainBundle] infoDictionary][@"CFBundleVersion"] forKey:@"$app_build_number"];
    [p setValue:[[NSBundle mainBundle] infoDictionary][@"CFBundleShortVersionString"] forKey:@"$app_version_string"];
    
    CTCarrier *carrier = [self.telephonyInfo subscriberCellularProvider];
    [p setValue:carrier.carrierName forKey:@"$carrier"];
    
    id deviceModel = [self deviceModel] ? : [NSNull null];
    CGSize size = [UIScreen mainScreen].bounds.size;
    UIDevice *device = [UIDevice currentDevice];
    
    [p addEntriesFromDictionary:@{
        @"$lib": @"GIAP-iOS",
        @"$lib_version": VERSION,
        @"$manufacturer": @"Apple",
        @"$model": deviceModel,
        @"$os":  [device systemName],
        @"$os_version": [device systemVersion],
        @"$screen_height": @((NSInteger)size.height),
        @"$screen_width": @((NSInteger)size.width)
    }];
    
    return p;
}

- (NSString *)deviceModel
{
    NSString *results = nil;
    size_t size;
    sysctlbyname("hw.machine", NULL, &size, NULL, 0);
    char answer[size];
    sysctlbyname("hw.machine", answer, &size, NULL, 0);
    if (size) {
        results = @(answer);
    } else {
        NSLog(@"%@Failed fetch hw.machine from sysctl.", self);
    }
    return results;
}

- (void)setCurrentRadio
{
    dispatch_async(self.serialQueue, ^{
        NSString *radio = self.telephonyInfo.currentRadioAccessTechnology;
        
        if (!radio) {
            radio = nil;
        } else if ([radio hasPrefix:@"CTRadioAccessTechnology"]) {
            radio = [radio substringFromIndex:23];
        }
        
        CTCarrier *carrier = [self.telephonyInfo subscriberCellularProvider];
        
        self.carrier = carrier.carrierName;
        self.radio = radio;
    });
}

static void GIAPReachabilityCallback(SCNetworkReachabilityRef target, SCNetworkReachabilityFlags flags, void *info)
{
    GIAPDevice *device = (__bridge GIAPDevice *)info;
    if (device && [device isKindOfClass:[GIAPDevice class]]) {
        [device reachabilityChanged:flags];
    }
}

- (void)reachabilityChanged:(SCNetworkReachabilityFlags)flags
{
    // this should be run in the serial queue. the reason we don't dispatch_async here
    // is because it's only ever called by the reachability callback, which is already
    // set to run on the serial queue. see SCNetworkReachabilitySetDispatchQueue in init
    self.wifi = (flags & kSCNetworkReachabilityFlagsReachable) && !(flags & kSCNetworkReachabilityFlagsIsWWAN);
}

@end
