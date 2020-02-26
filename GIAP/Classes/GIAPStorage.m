//
//  GIAPStorage.m
//  GIAP
//
//  Created by Tran Viet Thang on 2/12/20.
//

#import <Foundation/Foundation.h>
#import "GIAPStorage.h"
#import "GIAPStorage+Private.h"
#import "Constants.h"

@implementation GIAPStorage: NSObject

+ (instancetype)initWithToken:(NSString *)token
{
    GIAPStorage *instance = [[GIAPStorage alloc] init];
    instance.token = token;
    instance.userDefaults = [NSUserDefaults standardUserDefaults];
    
    return instance;
}

- (NSString *)getDistinctId
{
    return [self getUUIDForKey:@"deviceId"];
}

- (NSString *)resetDistinctId
{
    return [self resetUUIDForKey:@"deviceId"];
}

- (NSString *)getUUIDDeviceId
{
    return [self getUUIDForKey:@"uuidDeviceId"];
}

- (NSString *)resetUUIDDeviceId
{
    return [self resetUUIDForKey:@"uuidDeviceId"];
}

- (void)saveTaskQueue:(NSArray *)taskQueue
{
    NSString *storageKey = [self getPrefixedKeyForKey:@"taskQueue"];
    [self.userDefaults setObject:taskQueue forKey:storageKey];
}

- (NSArray *)getTaskQueue
{
    NSString *storageKey = [self getPrefixedKeyForKey:@"taskQueue"];
    return [self.userDefaults objectForKey:storageKey];
}

- (NSString *)getUUIDForKey:(NSString *)key
{
    NSString *storageKey = [self getPrefixedKeyForKey:key];
    NSString *item;
    
    item = [self.userDefaults stringForKey:storageKey];
    
    if (!item) {
        item = [[NSUUID UUID] UUIDString];
        [self.userDefaults setObject:item forKey:storageKey];
    }
    
    return item;
}

- (NSString *)resetUUIDForKey:(NSString *)key
{
    NSString *storageKey = [self getPrefixedKeyForKey:key];
    NSString *item = [[NSUUID UUID] UUIDString];
    [self.userDefaults setObject:item forKey:storageKey];
    return item;
}

- (NSString *)getPrefixedKeyForKey:(NSString *)key
{
    return [NSString stringWithFormat:@"%@_%@", self.token, key];
}

@end
