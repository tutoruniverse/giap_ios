//
//  GIAPDevice.h
//  GIAP
//
//  Created by Tran Viet Thang on 2/11/20.
//

#ifndef GIAPDevice_h
#define GIAPDevice_h


#endif /* GIAPDevice_h */

#import <CoreTelephony/CTTelephonyNetworkInfo.h>
#import <CoreTelephony/CTCarrier.h>
#import <SystemConfiguration/SystemConfiguration.h>

@interface GIAPDevice : NSObject

@property (nonatomic) dispatch_queue_t serialQueue;
@property (nonatomic, assign) SCNetworkReachabilityRef reachability;
@property (nonatomic, strong) CTTelephonyNetworkInfo *telephonyInfo;
@property (atomic, copy) NSString *radio;
@property (atomic, copy) NSString *carrier;
@property (atomic) bool wifi;
@property (atomic, copy) NSDictionary *consistentProperties;

+ (instancetype)initWithToken:(NSString *)token;
- (NSDictionary *) getDeviceProperties;
- (NSString *)getIDFA;
- (NSString *)getIdentifierForVendor;

@end
