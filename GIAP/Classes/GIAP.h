//
//  GIAP.h
//  GIAP
//
//  Created by Tran Viet Thang on 2/7/20.
//

#ifndef GIAP_h
#define GIAP_h


#endif /* GIAP_h */

@interface GIAP : NSObject

@property (atomic, readonly) NSString * _Nonnull token;

@property (atomic, readonly) NSString * _Nonnull distinctId;

@property (atomic, readonly) NSString * _Nonnull deviceId;

#pragma mark Methods

+ (nullable instancetype) initWithToken:(NSString * _Nonnull)token serverUrl:(NSURL * _Nonnull)serverUrl;

+ (nullable instancetype) sharedInstance;

- (void)track:(nonnull NSString *)eventName properties:(nullable NSDictionary*) properties;

- (void)alias:(nonnull NSString *)userId;

- (void)identify:(nonnull NSString *)userId;

- (void)setProfileProperties:(nonnull NSDictionary *)properties;

- (void)reset;

@end
