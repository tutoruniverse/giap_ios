

#include "GIAP.h"
#include "GIAP+Private.h"
#include "Constants.h"

@implementation GIAP

static GIAP *instance;

+ (nullable instancetype) initWithToken:(NSString *)token serverUrl:(NSURL *)serverUrl
{
    return [[GIAP alloc] initWithToken:token serverUrl:serverUrl];
}

+ (nullable instancetype) sharedInstance{
    return instance;
}


- (nullable instancetype) initWithToken:(NSString *)token serverUrl:(NSURL *)serverUrl
{
    if (instance != nil) {
        NSException *e = [NSException
                          exceptionWithName:@"DuplcatedInitialization"
                          reason:@"GIAP can be initialized only once"
                          userInfo:nil];
        @throw e;
    }
    
    // Utilities
    self.network = [GIAPNetwork initWithToken:token serverUrl:serverUrl];
    self.device = [GIAPDevice initWithToken:token];
    self.storage = [[GIAPStorage alloc] init];
    
    // Identity
    self.distinctId = [self.storage getDistinctId];
    self.deviceId = [self getDeviceId];
    
    // Task queue
    NSArray *archivedTaskQueue = [self.storage getTaskQueue];
    if (archivedTaskQueue) {
        self.taskQueue = [archivedTaskQueue mutableCopy];
    } else {
        self.taskQueue = [NSMutableArray array];
    }
    self.flushing = NO;
    
    // Serial queue
    NSString *label = [NSString stringWithFormat:@"ai.gotit.giap.%@.%p", token, (void *)self];
    self.serialQueue = dispatch_queue_create([label UTF8String], DISPATCH_QUEUE_SERIAL);
    
    // Flush timer
    [self startFlushTimer];
    
    // Application lifecycle events
    NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
    
    [notificationCenter addObserver:self
                           selector:@selector(applicationWillTerminate:)
                               name:UIApplicationWillTerminateNotification
                             object:nil];
    [notificationCenter addObserver:self
                           selector:@selector(applicationWillResignActive:)
                               name:UIApplicationWillResignActiveNotification
                             object:nil];
    [notificationCenter addObserver:self
                           selector:@selector(applicationDidBecomeActive:)
                               name:UIApplicationDidBecomeActiveNotification
                             object:nil];
    
    instance = self;
    return nil;
}

- (void)alias:(NSString *)userId
{
    [self addToQueue:@{
        @"type": @"alias",
        @"data": @{
                @"user_id": userId
        }
    }];
    
    [self identify:userId];
    [self flushQueue];
}

- (void)identify:(NSString *)userId
{
    [self addToQueue:@{
        @"type": @"identify",
        @"data": @{
                @"user_id": userId
        }
    }];
    
    [self flushQueue];
}

- (void)track:(NSString *)eventName properties:(NSDictionary *)properties
{
    NSMutableDictionary *p = [NSMutableDictionary dictionary];
    
    [p addEntriesFromDictionary:[self.device getDeviceProperties]];
    [p addEntriesFromDictionary:@{
        @"_name": eventName,
        @"_device_id": self.deviceId
    }];
    
    if (properties) {
        [p addEntriesFromDictionary:properties];
    }
    
    [self addToQueue:@{
        @"type": @"event",
        @"data": p
    }];
}

- (void)setProfileProperties:(NSDictionary *)properties;
{
    [self addToQueue:@{
        @"type": @"profile_updates",
        @"data": properties
    }];
    
    [self flushQueue];
}

- (void)reset
{
    [self addToQueue:@{
        @"type": @"reset",
        @"data": @{
                @"distinct_id": self.distinctId,
                @"device_id": self.deviceId
        }
    }];
    
    [self flushQueue];
}

- (void)addToQueue:(NSDictionary *)data
{
    NSTimeInterval epochInterval = [[NSDate date] timeIntervalSince1970];
    NSNumber *epochSeconds = @(round(epochInterval));
    
    NSMutableDictionary *taskdata = [data mutableCopy];
    [taskdata setValue:epochSeconds forKey:@"time"];
    [self.taskQueue addObject:taskdata];
    
    NSLog(@"%@ Add to queue: %@", self, taskdata);
}

- (void)startFlushTimer
{
    [self stopFlushTimer];
    dispatch_async(dispatch_get_main_queue(), ^{
        if (FLUSH_INTERVAL > 0) {
            self.timer = [NSTimer scheduledTimerWithTimeInterval:FLUSH_INTERVAL
                                                          target:self
                                                        selector:@selector(flushQueue)
                                                        userInfo:nil
                                                         repeats:YES];
        }
    });
}

- (void)stopFlushTimer
{
    dispatch_async(dispatch_get_main_queue(), ^{
        if (self.timer) {
            [self.timer invalidate];
            self.timer = nil;
        }
    });
}

- (void)keepFlushing
{
    self.flushing = NO;
    
    if ([self.taskQueue count] > 0) {
        [self flushQueue];
    }
}

- (BOOL)shouldShiftEventFromQueue:(NSArray *)queue
{
    if ([queue count] > 0) {
        return [[[queue objectAtIndex:0] valueForKey:@"type"] isEqualToString:@"event"];
    }
    
    return false;
}

- (void)flushQueue
{
    dispatch_async(self.serialQueue, ^{
        if (self.flushing) {
            return;
        }
        
        self.flushing = YES;
        
        NSMutableArray *currentEventBatch = [NSMutableArray array];
        NSMutableArray *queueCopyForFlushing = [self.taskQueue mutableCopy];
        
        while ([self shouldShiftEventFromQueue:queueCopyForFlushing]) {
            NSDictionary *task = [queueCopyForFlushing objectAtIndex:0];
            [queueCopyForFlushing removeObjectAtIndex:0];
            NSMutableDictionary *taskData = [task valueForKey:@"data"];
            
            // Add event to the batch
            NSNumber *time = [task valueForKey:@"time"];
            [taskData setValue:time forKey:@"_time"];
            [taskData setValue:self.distinctId forKey:@"_distinct_id"];
            [currentEventBatch addObject:taskData];
        }
        
        if ([currentEventBatch count] > 0) {
            [self.network emitEvents:currentEventBatch completionHandler:^(NSError *error) {
                if (self.delegate) {
                    [self.delegate giap:self didEmitEvents:currentEventBatch withError:error];
                }
                
                if (error) {
                    self.flushing = NO;
                } else {
                    [self.taskQueue removeObjectsInRange:NSMakeRange(0, [currentEventBatch count])];
                    [self keepFlushing];
                }
                
            }];
        } else if ([queueCopyForFlushing count] > 0) {
            NSDictionary *task = [queueCopyForFlushing objectAtIndex:0];
            [queueCopyForFlushing removeObjectAtIndex:0];
            NSString *taskType = [task valueForKey:@"type"];
            NSMutableDictionary *taskData = [task valueForKey:@"data"];
            
         
            if ([taskType isEqualToString:@"alias"]) {
                // Alias
                NSString *userId = [taskData valueForKey:@"user_id"];
                NSString *distinctId = [taskData valueForKey:@"distinct_id"];
                [self.network createAliasForUserId:userId withDistinctId:distinctId completionHandler:^(NSError *error) {
                    if (self.delegate) {
                        [self.delegate giap:self didCreateAliasForUserId:userId withDistinctId:distinctId withError:error];
                    }
                    
                    if (error) {
                        self.flushing = NO;
                    } else {
                        [self.taskQueue removeObjectAtIndex:0];
                        [self keepFlushing];
                    }
                }];
            } else if ([taskType isEqualToString:@"identify"]) {
                // Identify
                NSString *userId = [taskData valueForKey:@"user_id"];
                
                [self.network identifyWithUserId:userId fromDistinctId:self.distinctId completionHandler:^(NSString *distinctId, NSError *error) {
                    if (self.delegate) {
                        [self.delegate giap:self didIdentifyUserId:userId withCurrentDistinctId:self.distinctId withError:error];
                    }
                    
                    if (error) {
                        self.flushing = NO;
                    } else {
                        [self.taskQueue removeObjectAtIndex:0];
                        [self keepFlushing];
                    }
                }];
                
                self.distinctId = userId;
            } else if ([taskType isEqualToString:@"profile_updates"]) {
                // Profile updates
                [self.network updateProfileWithId:self.distinctId updateData:taskData completionHandler:^(NSError *error) {
                    if (self.delegate) {
                        [self.delegate giap:self didUpdateProfile:self.distinctId withProperties:taskData withError:error];
                    }
                    
                    if (error) {
                        NSLog(@"%@ Failed in setting profile properties %@: %@", self, taskData, [error localizedDescription]);
                        self.flushing = NO;
                    } else {
                        NSLog(@"%@ Done setting profile properties %@", self, taskData);
                        [self.taskQueue removeObjectAtIndex:0];
                        [self keepFlushing];
                    }
                }];
            } else if ([taskType isEqualToString:@"reset"]) {
                 // Reset
                self.distinctId = [self.storage getDistinctId];

                if (self.delegate) {
                    [self.delegate giap:self didResetWithDistinctId:self.distinctId];
                }
                
                [self keepFlushing];
            } else {
                self.flushing = NO;
            }
        } else {
            self.flushing = NO;
        }
    });
}

- (NSString *)getDeviceId
{
    NSString *deviceId;
    
    // Try with IDFA
    deviceId = [self.device getIDFA];
    
    // If IDFA is not available, try with identifierForVendor
    if (!deviceId && NSClassFromString(@"UIDevice")) {
        deviceId = [self.device getIdentifierForVendor];
    }
    
    // If identifierForVendor is not available, use UUID
    if (!deviceId) {
        deviceId = [self.storage getUUIDDeviceId];
    }
    
    return deviceId;
}

- (void)applicationWillResignActive:(NSNotification *)notification
{
    [self stopFlushTimer];
    dispatch_async(self.serialQueue, ^{
        [self.storage saveTaskQueue:self.taskQueue];
    });
    [self.storage saveTaskQueue:self.taskQueue];
}

- (void)applicationWillTerminate:(NSNotification *)notification
{
    dispatch_async(self.serialQueue, ^{
        [self.storage saveTaskQueue:self.taskQueue];
    });
}

- (void)applicationDidBecomeActive:(NSNotificationCenter *)notification
{
    [self startFlushTimer];
}

@end
