//
//  GIAP.h
//  GIAP
//
//  Created by Tran Viet Thang on 2/7/20.
//

#ifndef GIAP_h
#define GIAP_h

@protocol GIAPDelegate;

#endif /* GIAP_h */

@interface GIAP : NSObject

@property (atomic, readonly) NSString * _Nonnull token;

@property (atomic, readonly) NSString * _Nonnull distinctId;

@property (atomic, readonly) NSString * _Nonnull deviceId;

@property (atomic) BOOL flushOnBackground;

@property (atomic, weak) id<GIAPDelegate> _Nullable delegate;

#pragma mark Methods

+ (nullable instancetype)initWithToken:(NSString * _Nonnull)token serverUrl:(NSURL * _Nonnull)serverUrl;

+ (nullable instancetype)sharedInstance;

+ (void)destroy;

- (void)track:(nonnull NSString *)eventName properties:(nullable NSDictionary*) properties;

- (void)alias:(nonnull NSString *)userId;

- (void)identify:(nonnull NSString *)userId;

- (void)setProfileProperties:(nonnull NSDictionary *)properties;
- (void)increaseProfileProperty:(nonnull NSString *)propertyName value:(nonnull NSNumber *)value;
- (void)appendToProfileProperty:(nonnull NSString *)propertyName values:(nonnull NSArray *)values;
- (void)removeFromProfileProperty:(nonnull NSString *)propertyName values:(nonnull NSArray *)values;

- (void)reset;
- (void)flushQueue;

@end

@protocol GIAPDelegate <NSObject>

@optional

- (void)giap:(nonnull GIAP *)giap didEmitEvents:(nonnull NSArray *)events withResponse:(nullable NSDictionary *)response andError:(nullable NSError *)error;
- (void)giap:(nonnull GIAP *)giap didCreateAliasForUserId:(nonnull NSString *)userId withDistinctId:(nonnull NSString *)distinctId withResponse:(nullable NSDictionary *)response andError:(nullable NSError *)error;
- (void)giap:(nonnull GIAP *)giap didIdentifyUserId:(nonnull NSString *)userId withCurrentDistinctId:(nonnull NSString *)distinctId withResponse:(nullable NSDictionary *)response andError:(nullable NSError *)error;
- (void)giap:(nonnull GIAP *)giap didUpdateProfile:(nonnull NSString *)distinctId withProperties:(nonnull NSDictionary *)properties withResponse:(nullable NSDictionary *)response andError:(nullable NSError *)error;
- (void)giap:(nonnull GIAP *)giap didIncreasePropertyForProfile:(nonnull NSString *)distinctId propertyName:(nonnull NSString *)propertyName value:(nonnull NSNumber *)value withResponse:(nullable NSDictionary *)response andError:(nullable NSError *)error;
- (void)giap:(nonnull GIAP *)giap didAppendToPropertyForProfile:(nonnull NSString *)distinctId propertyName:(nonnull NSString *)propertyName values:(nonnull NSArray *)values withResponse:(nullable NSDictionary *)response andError:(nullable NSError *)error;
- (void)giap:(nonnull GIAP *)giap didRemoveFromPropertyForProfile:(nonnull NSString *)distinctId propertyName:(nonnull NSString *)propertyName values:(nonnull NSArray *)values withResponse:(nullable NSDictionary *)response andError:(nullable NSError *)error;
- (void)giap:(nonnull GIAP *)giap didResetWithDistinctId:(nonnull NSString *)distinctId;
@end
