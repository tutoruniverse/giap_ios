//
//  GIAPTest.m
//  GIAP_Tests
//
//  Created by Tran Viet Thang on 2/25/20.
//  Copyright © 2020 uendno. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "GIAP/GIAP.h"
#import "GIAP/GIAPDevice.h"
#import "GIAP/GIAPStorage.h"
#import "GIAP/GIAPNetwork.h"

@interface GIAPTest : XCTestCase

@property (atomic) GIAP *giap;
@property (atomic, copy) NSMutableArray *taskQueue;
@property (atomic, copy) NSString *distinctId;
@property (atomic, copy) NSString *deviceUUID;

@end

@implementation GIAPTest

- (void)setUp {
    [GIAP destroy];
}

- (void)initGIAP
{
    self.giap = [GIAP initWithToken:@"token" serverUrl:[NSURL URLWithString:@"https://analytics-api.got-it.io"]];
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
}

- (void)test_taskQueue {
    XCTestExpectation *trackExpectation = [[XCTestExpectation alloc] initWithDescription:@"Track"];
    XCTestExpectation *aliasExpectation = [[XCTestExpectation alloc] initWithDescription:@"Alias"];
    XCTestExpectation *identifyExpectation = [[XCTestExpectation alloc] initWithDescription:@"Identify"];
    XCTestExpectation *setPropertiesExpectation = [[XCTestExpectation alloc] initWithDescription:@"Set Properties"];
    
    [trackExpectation setExpectedFulfillmentCount:2];
    
    id storageMock = [OCMockObject mockForClass:[GIAPStorage class]];
    [[[storageMock stub] andReturn:nil] getTaskQueue];
    [[[storageMock stub] andReturn:@"distinct_id"] getDistinctId];
    [[[storageMock stub] andReturn:@"device_id"] getUUIDDeviceId];
    [[[storageMock stub] andReturn:storageMock] initWithToken:[OCMArg any]];
    
    id deviceMock = [OCMockObject mockForClass:[GIAPDevice class]];
    [[[deviceMock stub] andReturn:@{}] getDeviceProperties];
    
    [[[deviceMock stub] andReturn:deviceMock] initWithToken:[OCMArg any]];
    
    id networkMock = [OCMockObject mockForClass:[GIAPNetwork class]];
    [[[networkMock stub] andDo:^(NSInvocation *invocation) {
        void (^__unsafe_unretained callback)(NSDictionary *response, NSError *error);
        [invocation getArgument:&callback atIndex:3];
        callback(@{}, nil);
        [trackExpectation fulfill];
        
    }] emitEvents:[OCMArg any] completionHandler:[OCMArg any]];
    
    [[[networkMock stub] andDo:^(NSInvocation *invocation) {
        void (^__unsafe_unretained callback)(NSDictionary *response, NSError *error);
        [invocation getArgument:&callback atIndex:4];
        callback(@{}, nil);
        [aliasExpectation fulfill];
    }] createAliasForUserId:[OCMArg any] withDistinctId:[OCMArg any] completionHandler:[OCMArg any]];
    
    [[[networkMock stub] andDo:^(NSInvocation *invocation) {
        void (^__unsafe_unretained callback)(NSDictionary *response, NSError *error);
        [invocation getArgument:&callback atIndex:4];
        callback(@{}, nil);
        [identifyExpectation fulfill];
    }] identifyWithUserId:[OCMArg any] fromDistinctId:[OCMArg any] completionHandler:[OCMArg any]];
    
    [[[networkMock stub] andDo:^(NSInvocation *invocation) {
        void (^__unsafe_unretained callback)(NSDictionary *response, NSError *error);
        [invocation getArgument:&callback atIndex:4];
        callback(@{}, nil);
        [setPropertiesExpectation fulfill];
    }] updateProfileWithId:[OCMArg any] updateData:[OCMArg any] completionHandler:[OCMArg any]];
    
    [[[networkMock stub] andReturn:networkMock] initWithToken:[OCMArg any] serverUrl:[OCMArg any]];
    
    [self initGIAP];
    
    [[deviceMock expect] initWithToken:[OCMArg any]];
    [[networkMock expect] initWithToken:[OCMArg any] serverUrl:[OCMArg any]];
    
    [self.giap track:@"Visit" properties:@{
        @"economy_group": @1
    }];
    
    [self.giap track:@"Sign Up" properties:@{
        @"email": @"test@gotitapp.co"
    }];
    
    [self.giap alias:@"1"];
    
    [self.giap setProfileProperties:@{
        @"full_name": @"Test"
    }];
    
    [self.giap track:@"Ask" properties:@{
        @"problem_text": @"Hello"
    }];
    
    [self waitForExpectations:[NSArray arrayWithObjects:trackExpectation, aliasExpectation, setPropertiesExpectation, nil] timeout:10];
}

-(void)test_getTaskQueueFromStorage
{
    XCTestExpectation *trackExpectation = [[XCTestExpectation alloc] initWithDescription:@"Track"];
    
    id storageMock = [OCMockObject mockForClass:[GIAPStorage class]];
    [[[storageMock stub] andReturn:[NSArray arrayWithObjects:@{
        @"type": @"event",
        @"data": @{
                @"$name": @"Visit"
        },
        @"time": @1582727998000
    }, @{
        @"type": @"event",
        @"data": @{
                @"$name": @"Visit"
        },
        @"time": @1582727998000
    }, nil]] getTaskQueue];
    [[[storageMock stub] andReturn:@"distinct_id"] getDistinctId];
    [[[storageMock stub] andReturn:@"device_id"] getUUIDDeviceId];
    [[[storageMock stub] andReturn:storageMock] initWithToken:[OCMArg any]];
    
    id deviceMock = [OCMockObject mockForClass:[GIAPDevice class]];
    [[[deviceMock stub] andReturn:@{}] getDeviceProperties];
    [[[deviceMock stub] andReturn:deviceMock] initWithToken:[OCMArg any]];
    
    id networkMock = [OCMockObject mockForClass:[GIAPNetwork class]];
    [[[networkMock stub] andDo:^(NSInvocation *invocation) {
        void (^__unsafe_unretained callback)(NSDictionary *response, NSError *error);
        NSArray *events;
        [invocation getArgument:&events atIndex:2];
        [invocation getArgument:&callback atIndex:3];
        callback(@{}, nil);
        
        if ([events count] == 2) {
            [trackExpectation fulfill];
        }
        
    }] emitEvents:[OCMArg any] completionHandler:[OCMArg any]];
    [[[networkMock stub] andReturn:networkMock] initWithToken:[OCMArg any] serverUrl:[OCMArg any]];
    
    [self initGIAP];
    
    [self waitForExpectations:[NSArray arrayWithObjects:trackExpectation, nil] timeout:10];
}

-(void)test_applicationTerminated
{
    XCTestExpectation *saveExpectation = [[XCTestExpectation alloc] initWithDescription:@"Save"];
    
    id storageMock = [OCMockObject mockForClass:[GIAPStorage class]];
    [[[storageMock stub] andReturn:nil] getTaskQueue];
    [[[storageMock stub] andReturn:@"distinct_id"] getDistinctId];
    [[[storageMock stub] andReturn:@"device_id"] getUUIDDeviceId];
    [[[storageMock stub] andDo:^(NSInvocation *invocation) {
        [saveExpectation fulfill];
    }] saveTaskQueue:[OCMArg any]];
    [[[storageMock stub] andReturn:storageMock] initWithToken:[OCMArg any]];
    
    
    [self initGIAP];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:UIApplicationWillTerminateNotification object:nil];
    
    [self waitForExpectations:[NSArray arrayWithObjects:saveExpectation, nil] timeout:10];
}

-(void)test_applicationGoesToBackground
{
    XCTestExpectation *saveExpectation = [[XCTestExpectation alloc] initWithDescription:@"Save"];
    XCTestExpectation *trackExpectation = [[XCTestExpectation alloc] initWithDescription:@"Track"];
    XCTestExpectation *notTrackExpectation = [[XCTestExpectation alloc] initWithDescription:@"Track"];
    [notTrackExpectation setInverted:YES];
    
    id storageMock = [OCMockObject mockForClass:[GIAPStorage class]];
    [[[storageMock stub] andReturn:nil] getTaskQueue];
    [[[storageMock stub] andReturn:@"distinct_id"] getDistinctId];
    [[[storageMock stub] andReturn:@"device_id"] getUUIDDeviceId];
    [[[storageMock stub] andDo:^(NSInvocation *invocation) {
        [saveExpectation fulfill];
    }] saveTaskQueue:[OCMArg any]];
    [[[storageMock stub] andReturn:storageMock] initWithToken:[OCMArg any]];
    
    id networkMock = [OCMockObject mockForClass:[GIAPNetwork class]];
    [[[networkMock stub] andDo:^(NSInvocation *invocation) {
        void (^__unsafe_unretained callback)(NSDictionary *response, NSError *error);
        [invocation getArgument:&callback atIndex:3];
        callback(@{}, nil);
        [trackExpectation fulfill];
    }] emitEvents:[OCMArg any] completionHandler:[OCMArg any]];
    [[[networkMock stub] andReturn:networkMock] initWithToken:[OCMArg any] serverUrl:[OCMArg any]];
    
    [self initGIAP];
    
    [self.giap track:@"Visit" properties:@{
        @"economy_group": @1
    }];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:UIApplicationWillResignActiveNotification object:nil];
    
    sleep(2);
    [self waitForExpectations:[NSArray arrayWithObjects:notTrackExpectation, saveExpectation, nil] timeout:1];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:UIApplicationDidBecomeActiveNotification object:nil];
    
    [self waitForExpectations:[NSArray arrayWithObjects:trackExpectation, nil] timeout:10];
}

@end