//
//  GIAPStorage.m
//  GIAP_Tests
//
//  Created by Tran Viet Thang on 2/25/20.
//  Copyright © 2020 uendno. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "GIAP/GIAPStorage.h"

@interface GIAPStorageTest: XCTestCase
@property (atomic) GIAPStorage *storage;
@end

@implementation GIAPStorageTest

- (void)setUp {
    [self resetUserDefaults];
    self.storage = [GIAPStorage initWithToken:@"token"];
}

- (void)tearDown {
    [self resetUserDefaults];
}

- (void)resetUserDefaults
{
    NSUserDefaults * defs = [NSUserDefaults standardUserDefaults];
    NSDictionary * dict = [defs dictionaryRepresentation];
    for (id key in dict) {
        [defs removeObjectForKey:key];
    }
    [defs synchronize];
}

- (void)test_getDistinctId
{
    NSString *distinctId = [self.storage getDistinctId];
    XCTAssertNotNil(distinctId);
    self.storage = [GIAPStorage initWithToken:@"token"];
    NSString *newDistinctId = [self.storage getDistinctId];
    XCTAssertEqual(distinctId, newDistinctId);
}

- (void)test_resetDistinctId
{
    NSString *distinctId = [self.storage getDistinctId];
    XCTAssertNotNil(distinctId);
    [self.storage resetDistinctId];
    NSString *newDistinctId = [self.storage getDistinctId];
    XCTAssertNotEqual(distinctId, newDistinctId);
}

- (void)test_getUUIDDeviceId
{
    NSString *distinctId = [self.storage getUUIDDeviceId];
    XCTAssertNotNil(distinctId);
    self.storage = [GIAPStorage initWithToken:@"token"];
    NSString *newDistinctId = [self.storage getUUIDDeviceId];
    XCTAssertEqual(distinctId, newDistinctId);
}

- (void)test_resetUUIDDeviceId
{
    NSString *distinctId = [self.storage getUUIDDeviceId];
    XCTAssertNotNil(distinctId);
    [self.storage resetUUIDDeviceId
     ];
    NSString *newDistinctId = [self.storage getUUIDDeviceId];
    XCTAssertNotEqual(distinctId, newDistinctId);
}

-(void)test_changeToken
{
    NSString *distinctId = [self.storage getDistinctId];
    XCTAssertNotNil(distinctId);
    self.storage = [GIAPStorage initWithToken:@"anotherToken"];
    NSString *newDistinctId = [self.storage getDistinctId];
    XCTAssertNotEqual(distinctId, newDistinctId);
}

-(void)test_saveAndGetTaskQueue
{
    NSArray *taskQueue = [self.storage getTaskQueue];
    XCTAssertNil(taskQueue);
    NSArray *savedTaskQueue = [NSArray arrayWithObjects:@{}, @{}, nil];
    [self.storage saveTaskQueue:savedTaskQueue];
    XCTAssertEqual([[self.storage getTaskQueue] count], 2);
}

@end
