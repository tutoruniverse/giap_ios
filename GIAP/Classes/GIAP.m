

#include "GIAP.h"
#include "GIAP+Private.h"
#include "Constants.h"

@implementation GIAP

void myExceptionHandler(NSException *exception)
{
    [[GIAP sharedInstance] handleException:exception];
}

static GIAP *instance;

+ (nullable instancetype) initWithToken:(NSString *)token serverUrl:(NSURL *)serverUrl
{
    return [[GIAP alloc] initWithToken:token serverUrl:serverUrl];
}

+ (nullable instancetype) sharedInstance{
    return instance;
}

+ (void)destroy
{
    instance = nil;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
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
    
    NSSetUncaughtExceptionHandler(&myExceptionHandler);
    
    // Utilities
    self.network = [GIAPNetwork initWithToken:token serverUrl:serverUrl];
    self.device = [GIAPDevice initWithToken:token];
    self.storage = [GIAPStorage initWithToken:token];
    
    // Identity
    self.distinctId = [self.storage getDistinctId];
    self.deviceId = [self getDeviceId];
    self.flushOnBackground = FLUSH_ON_BACKGROUND;
    
    
    // Task queue
    NSArray *archivedTaskQueue = [self.storage getTaskQueue];
    if (archivedTaskQueue) {
        self.taskQueue = [archivedTaskQueue mutableCopy];
    } else {
        self.taskQueue = [NSMutableArray array];
    }
    self.flushing = NO;
    self.disabled = NO;
    
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
    return instance;
}

- (void)alias:(NSString *)userId
{
    if (!userId || [userId isEqualToString:@""]) {
        NSException *e = [NSException
                          exceptionWithName:@"InvalidArgument"
                          reason:@"userId can not be nil or empty"
                          userInfo:nil];
        @throw e;
    }
    
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
    if (!userId || [userId isEqualToString:@""]) {
        NSException *e = [NSException
                          exceptionWithName:@"InvalidArgument"
                          reason:@"userId can not be nil or empty"
                          userInfo:nil];
        @throw e;
    }
    
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
    if (!eventName) {
        NSException *e = [NSException
                          exceptionWithName:@"InvalidArgument"
                          reason:@"eventName can not be nil"
                          userInfo:nil];
        @throw e;
    }
    
    
    NSMutableDictionary *p = [NSMutableDictionary dictionary];
    
    [p addEntriesFromDictionary:[self.device getDeviceProperties]];
    [p addEntriesFromDictionary:@{
        @"$name": eventName,
        @"$device_id": self.deviceId
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
    if (!properties) {
        NSException *e = [NSException
                          exceptionWithName:@"InvalidArgument"
                          reason:@"properties can not be nil"
                          userInfo:nil];
        @throw e;
    }
    
    [self addToQueue:@{
        @"type": @"profile_updates",
        @"data": properties
    }];
    
    [self flushQueue];
}

- (void)increaseProfileProperty:(NSString *)propertyName value:(NSNumber *)value
{
    if (!propertyName) {
        NSException *e = [NSException
                          exceptionWithName:@"InvalidArgument"
                          reason:@"propertyName can not be nil"
                          userInfo:nil];
        @throw e;
    }
    
    if (!value) {
        NSException *e = [NSException
                          exceptionWithName:@"InvalidArgument"
                          reason:@"value can not be nil"
                          userInfo:nil];
        @throw e;
    }
    
    [self addToQueue:@{
        @"type": @"profile_updates_increase_property",
        @"data": @{
                @"name": propertyName,
                @"value": value
        }
    }];
    
    [self flushQueue];
}

- (void)appendToProfileProperty:(NSString *)propertyName values:(NSArray *)values
{
    if (!propertyName) {
        NSException *e = [NSException
                          exceptionWithName:@"InvalidArgument"
                          reason:@"propertyName can not be nil"
                          userInfo:nil];
        @throw e;
    }
    
    if (!values) {
        NSException *e = [NSException
                          exceptionWithName:@"InvalidArgument"
                          reason:@"values can not be nil"
                          userInfo:nil];
        @throw e;
    }
    
    [self addToQueue:@{
        @"type": @"profile_updates_append_to_property",
        @"data": @{
                @"name": propertyName,
                @"values": values
        }
    }];
    
    [self flushQueue];
}

- (void)removeFromProfileProperty:(NSString *)propertyName values:(NSArray *)values
{
    if (!propertyName) {
        NSException *e = [NSException
                          exceptionWithName:@"InvalidArgument"
                          reason:@"propertyName can not be nil"
                          userInfo:nil];
        @throw e;
    }
    
    if (!values) {
        NSException *e = [NSException
                          exceptionWithName:@"InvalidArgument"
                          reason:@"values can not be nil"
                          userInfo:nil];
        @throw e;
    }
    
    [self addToQueue:@{
        @"type": @"profile_updates_remove_from_property",
        @"data": @{
                @"name": propertyName,
                @"values": values
        }
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

- (void)handleException:(NSException *)exception
{
    [self.storage saveTaskQueue:self.taskQueue];
}

- (void)addToQueue:(NSDictionary *)data
{
    if (self.disabled) {
        return;
    }
    
    NSTimeInterval epochInterval = [[NSDate date] timeIntervalSince1970];
    NSNumber *epochMiliseconds = @(round(epochInterval * 1000));
    
    NSMutableDictionary *taskdata = [data mutableCopy];
    [taskdata setValue:epochMiliseconds forKey:@"time"];
    [taskdata setValue:VERSION forKey:@"version"];
    [self.taskQueue addObject:taskdata];
    
    if ([self.taskQueue count] > QUEUE_SIZE_LIMIT) {
        [self.taskQueue removeObjectAtIndex:0];
    }
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

- (void)handleTaskResult:(NSDictionary *)response error:(NSError *)error
{
    [self handleTaskResult:response error:error numberOfTasksToRemove:1];
}

- (void)handleTaskResult:(NSDictionary *)response error:(NSError *)error numberOfTasksToRemove:(unsigned long)numberOfTasksToRemove
{
    if (error) {
        self.flushing = NO;
    } else {
        NSNumber *errorCode = [response valueForKey:@"error_code"];
        if ([errorCode isEqualToNumber:[NSNumber numberWithLong:40101]]) {
            self.disabled = YES;
            [self stopFlushTimer];
            [self.storage saveTaskQueue:nil];
        } else {
            [self.taskQueue removeObjectsInRange:NSMakeRange(0, numberOfTasksToRemove)];
            [self keepFlushing];
        }
    }
}

- (void)flushQueue
{
    dispatch_async(self.serialQueue, ^{
        if (self.flushing) {
            return;
        }
        
        self.flushing = YES;
        
        while([self.taskQueue count] > 0 && ![[[self.taskQueue objectAtIndex:0] valueForKey:@"version"] isEqualToString:VERSION]) {
            [self.taskQueue removeObjectAtIndex:0];
        }
        
        NSMutableArray *currentEventBatch = [NSMutableArray array];
        NSMutableArray *queueCopyForFlushing = [self.taskQueue mutableCopy];
        
        while ([self shouldShiftEventFromQueue:queueCopyForFlushing]) {
            NSDictionary *task = [queueCopyForFlushing objectAtIndex:0];
            [queueCopyForFlushing removeObjectAtIndex:0];
            NSMutableDictionary *taskData = [[task valueForKey:@"data"] mutableCopy];
            
            // Add event to the batch
            NSNumber *time = [task valueForKey:@"time"];
            [taskData setValue:time forKey:@"$time"];
            [taskData setValue:self.distinctId forKey:@"$distinct_id"];
            [currentEventBatch addObject:taskData];
        }
        
        if ([currentEventBatch count] > 0) {
            [self.network emitEvents:currentEventBatch completionHandler:^(NSDictionary *response, NSError *error) {
                if (self.delegate) {
                    [self.delegate giap:self didEmitEvents:currentEventBatch withResponse:response andError:error];
                }
                
                [self handleTaskResult:response error:error numberOfTasksToRemove:[currentEventBatch count]];
            }];
        } else if ([queueCopyForFlushing count] > 0) {
            NSDictionary *task = [queueCopyForFlushing objectAtIndex:0];
            [queueCopyForFlushing removeObjectAtIndex:0];
            NSString *taskType = [task valueForKey:@"type"];
            NSMutableDictionary *taskData = [task valueForKey:@"data"];
            
            
            if ([taskType isEqualToString:@"alias"]) {
                // Alias
                NSString *userId = [taskData valueForKey:@"user_id"];
                
                [self.network createAliasForUserId:userId withDistinctId:self.distinctId completionHandler:^(NSDictionary *response, NSError *error) {
                    if (self.delegate) {
                        [self.delegate giap:self didCreateAliasForUserId:userId withDistinctId:self.distinctId withResponse:response andError:error];
                    }
                    
                    [self handleTaskResult:response error:error];
                }];
                
            } else if ([taskType isEqualToString:@"identify"]) {
                // Identify
                NSString *userId = [taskData valueForKey:@"user_id"];
                
                [self.network identifyWithUserId:userId fromDistinctId:self.distinctId completionHandler:^(NSDictionary *response, NSError *error) {
                    if (self.delegate) {
                        [self.delegate giap:self didIdentifyUserId:userId withCurrentDistinctId:self.distinctId withResponse:response andError:error];
                    }
                    
                    self.distinctId = userId;
                    [self.storage setDistinctId:userId];
                    
                    [self handleTaskResult:response error:error];
                }];
                
                
            } else if ([taskType isEqualToString:@"profile_updates"]) {
                // Profile updates
                [self.network updateProfileWithId:self.distinctId updateData:taskData completionHandler:^(NSDictionary *response, NSError *error) {
                    if (self.delegate) {
                        [self.delegate giap:self didUpdateProfile:self.distinctId withProperties:taskData withResponse:response andError:error];
                    }
                    
                    [self handleTaskResult:response error:error];
                }];
                
            } else if ([taskType isEqualToString:@"profile_updates_increase_property"]) {
                // Increase a property
                NSString *propertyName = [taskData valueForKey:@"name"];
                NSNumber *value =[taskData valueForKey:@"value"];
                
                if (propertyName && value) {
                    [self.network increasePropertyForProfile:self.distinctId propertyName:propertyName value:value completionHandler:^(NSDictionary *response, NSError *error) {
                        if (self.delegate) {
                            [self.delegate giap:self didIncreasePropertyForProfile:self.distinctId propertyName:propertyName value:value withResponse:response andError:error];
                        }
                        
                        [self handleTaskResult:response error:error];
                    }];
                } else {
                    [self.taskQueue removeObjectAtIndex:0];
                    [self keepFlushing];
                }
            } else if ([taskType isEqualToString:@"profile_updates_append_to_property"]) {
                // Append to a property
                NSString *propertyName = [taskData valueForKey:@"name"];
                NSArray *values = [taskData valueForKey:@"values"];
                
                if (propertyName && values) {
                    [self.network appendToPropertyForProfile:self.distinctId propertyName:propertyName values:values completionHandler:^(NSDictionary *response, NSError *error) {
                        if (self.delegate) {
                            [self.delegate giap:self didAppendToPropertyForProfile:self.distinctId propertyName:propertyName values:values withResponse:response andError:error];
                        }
                        
                        [self handleTaskResult:response error:error];
                    }];
                } else {
                    [self.taskQueue removeObjectAtIndex:0];
                    [self keepFlushing];
                }
            } else if ([taskType isEqualToString:@"profile_updates_remove_from_property"]) {
                // Remove from a property
                NSString *propertyName = [taskData valueForKey:@"name"];
                NSArray *values = [taskData valueForKey:@"values"];
                
                if (propertyName && values) {
                    [self.network removeFromPropertyForProfile:self.distinctId propertyName:propertyName values:values completionHandler:^(NSDictionary *response, NSError *error) {
                        if (self.delegate) {
                            [self.delegate giap:self didRemoveFromPropertyForProfile:self.distinctId propertyName:propertyName values:values withResponse:response andError:error];
                        }
                        
                        [self handleTaskResult:response error:error];
                    }];
                } else {
                    [self.taskQueue removeObjectAtIndex:0];
                    [self keepFlushing];
                }
            } else if ([taskType isEqualToString:@"reset"]) {
                // Reset
                self.distinctId = [self.storage resetDistinctId];
                
                if (self.delegate) {
                    [self.delegate giap:self didResetWithDistinctId:self.distinctId];
                }
                
                [self.taskQueue removeObjectAtIndex:0];
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
    
    if (self.flushOnBackground) {
        [self flushQueue];
    } else {
        dispatch_async(self.serialQueue, ^{
            [self.storage saveTaskQueue:self.taskQueue];
        });
        [self.storage saveTaskQueue:self.taskQueue];
    }
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
