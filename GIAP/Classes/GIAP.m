

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

- (void)incrementProfileProperty:(NSString *)propertyName value:(NSNumber *)value
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
        @"type": @"profile_updates_increment_property",
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
                @"value": values
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
                @"value": values
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
    NSTimeInterval epochInterval = [[NSDate date] timeIntervalSince1970];
    NSNumber *epochMiliseconds = @(round(epochInterval * 1000));
    
    NSMutableDictionary *taskdata = [data mutableCopy];
    [taskdata setValue:epochMiliseconds forKey:@"time"];
    [self.taskQueue addObject:taskdata];
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
            NSMutableDictionary *taskData = [[task valueForKey:@"data"] mutableCopy];
            
            // Add event to the batch
            NSNumber *time = [task valueForKey:@"time"];
            [taskData setValue:time forKey:@"$time"];
            [taskData setValue:self.distinctId forKey:@"$distinct_id"];
            [currentEventBatch addObject:taskData];
        }
        
        dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
        __block BOOL shouldContinue = NO;
        
        if ([currentEventBatch count] > 0) {
            [self.network emitEvents:currentEventBatch completionHandler:^(NSDictionary *response, NSError *error) {
                if (self.delegate) {
                    [self.delegate giap:self didEmitEvents:currentEventBatch withResponse:response andError:error];
                }
                
                if (error) {
                    shouldContinue = NO;
                } else {
                    [self.taskQueue removeObjectsInRange:NSMakeRange(0, [currentEventBatch count])];
                    shouldContinue = YES;
                }
                
                dispatch_semaphore_signal(semaphore);
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
                    
                    if (error) {
                        shouldContinue = NO;
                    } else {
                        [self.taskQueue removeObjectAtIndex:0];
                        shouldContinue = YES;
                    }
                    
                    dispatch_semaphore_signal(semaphore);
                }];
                
            } else if ([taskType isEqualToString:@"identify"]) {
                // Identify
                NSString *userId = [taskData valueForKey:@"user_id"];
                
                [self.network identifyWithUserId:userId fromDistinctId:self.distinctId completionHandler:^(NSDictionary *response, NSError *error) {
                    if (self.delegate) {
                        [self.delegate giap:self didIdentifyUserId:userId withCurrentDistinctId:self.distinctId withResponse:response andError:error];
                    }
                    
                    if (error) {
                        shouldContinue = NO;
                    } else {
                        if ([response valueForKey:@"distinct_id"]) {
                            self.distinctId = userId;
                        }
                        [self.taskQueue removeObjectAtIndex:0];
                        shouldContinue = YES;
                    }
                    
                    dispatch_semaphore_signal(semaphore);
                }];
                
                
            } else if ([taskType isEqualToString:@"profile_updates"]) {
                // Profile updates
                [self.network updateProfileWithId:self.distinctId updateData:taskData completionHandler:^(NSDictionary *response, NSError *error) {
                    if (self.delegate) {
                        [self.delegate giap:self didUpdateProfile:self.distinctId withProperties:taskData withResponse:response andError:error];
                    }
                    
                    if (error) {
                        shouldContinue = NO;
                    } else {
                        [self.taskQueue removeObjectAtIndex:0];
                        shouldContinue = YES;
                    }
                    
                    dispatch_semaphore_signal(semaphore);
                }];
                
            } else if ([taskType isEqualToString:@"profile_updates_increment_property"]) {
                // Increment a property
                NSString *propertyName = [taskData valueForKey:@"name"];
                NSNumber *value =[taskData valueForKey:@"value"];
                
                [self.network incrementPropertyForProfile:self.distinctId propertyName:propertyName value:value completionHandler:^(NSDictionary *response, NSError *error) {
                    if (self.delegate) {
                        [self.delegate giap:self didIncrementPropertyForProfile:self.distinctId propertyName:propertyName value:value withResponse:response andError:error];
                    }
                    
                    if (error) {
                        shouldContinue = NO;
                    } else {
                        [self.taskQueue removeObjectAtIndex:0];
                        shouldContinue = YES;
                    }
                    
                    dispatch_semaphore_signal(semaphore);
                }];
            } else if ([taskType isEqualToString:@"profile_updates_append_to_property"]) {
                // Append to a property
                NSString *propertyName = [taskData valueForKey:@"name"];
                NSArray *values =[taskData valueForKey:@"values"];
                
                [self.network appendToPropertyForProfile:self.distinctId propertyName:propertyName values:values completionHandler:^(NSDictionary *response, NSError *error) {
                    if (self.delegate) {
                        [self.delegate giap:self didAppendToPropertyForProfile:self.distinctId propertyName:propertyName values:values withResponse:response andError:error];
                    }
                    
                    if (error) {
                        shouldContinue = NO;
                    } else {
                        [self.taskQueue removeObjectAtIndex:0];
                        shouldContinue = YES;
                    }
                    
                    dispatch_semaphore_signal(semaphore);
                }];
            } else if ([taskType isEqualToString:@"profile_updates_remove_from_property"]) {
                // Remove from a property
                NSString *propertyName = [taskData valueForKey:@"name"];
                NSArray *values =[taskData valueForKey:@"values"];
                
                [self.network removeFromPropertyForProfile:self.distinctId propertyName:propertyName values:values completionHandler:^(NSDictionary *response, NSError *error) {
                    if (self.delegate) {
                        [self.delegate giap:self didRemoveFromPropertyForProfile:self.distinctId propertyName:propertyName values:values withResponse:response andError:error];
                    }
                    
                    if (error) {
                        shouldContinue = NO;
                    } else {
                        [self.taskQueue removeObjectAtIndex:0];
                        shouldContinue = YES;
                    }
                    
                    dispatch_semaphore_signal(semaphore);
                }];
            } else if ([taskType isEqualToString:@"reset"]) {
                // Reset
                self.distinctId = [self.storage resetDistinctId];
                
                if (self.delegate) {
                    [self.delegate giap:self didResetWithDistinctId:self.distinctId];
                }
                
                [self.taskQueue removeObjectAtIndex:0];
                shouldContinue = YES;
                dispatch_semaphore_signal(semaphore);
            } else {
                shouldContinue = NO;
                dispatch_semaphore_signal(semaphore);
            }
        } else {
            shouldContinue = NO;
            dispatch_semaphore_signal(semaphore);
        }
        
        dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
        
        if (shouldContinue) {
            [self keepFlushing];
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
