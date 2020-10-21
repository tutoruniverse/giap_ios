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
#import "GIAP/Constants.h"

@interface GIAPTest : XCTestCase

@property (atomic) GIAP *giap;

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
    XCTestExpectation *increasePropertiesExpectation = [[XCTestExpectation alloc] initWithDescription:@"Increase Property"];
    XCTestExpectation *appendToPropertiesExpectation = [[XCTestExpectation alloc] initWithDescription:@"Append To Property"];
    XCTestExpectation *removeFromPropertiesExpectation = [[XCTestExpectation alloc] initWithDescription:@"Remove From Property"];
    
    [trackExpectation setExpectedFulfillmentCount:2];
    
    id storageMock = [OCMockObject mockForClass:[GIAPStorage class]];
    [[[storageMock stub] andReturn:nil] getTaskQueue];
    [[[storageMock stub] andReturn:@"distinct_id"] getDistinctId];
    [[[storageMock stub] andDo:^(NSInvocation *invocation) {
        
    }] setDistinctId:[OCMArg any]];
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
    
    [[[networkMock stub] andDo:^(NSInvocation *invocation) {
        void (^__unsafe_unretained callback)(NSDictionary *response, NSError *error);
        [invocation getArgument:&callback atIndex:5];
        callback(@{}, nil);
        [increasePropertiesExpectation fulfill];
    }] increasePropertyForProfile:[OCMArg any] propertyName:[OCMArg any] value:[OCMArg any] completionHandler:[OCMArg any]];
    
    [[[networkMock stub] andDo:^(NSInvocation *invocation) {
        void (^__unsafe_unretained callback)(NSDictionary *response, NSError *error);
        [invocation getArgument:&callback atIndex:5];
        callback(@{}, nil);
        [appendToPropertiesExpectation fulfill];
    }] appendToPropertyForProfile:[OCMArg any] propertyName:[OCMArg any] values:[OCMArg any] completionHandler:[OCMArg any]];
    
    [[[networkMock stub] andDo:^(NSInvocation *invocation) {
        void (^__unsafe_unretained callback)(NSDictionary *response, NSError *error);
        [invocation getArgument:&callback atIndex:5];
        callback(@{}, nil);
        [removeFromPropertiesExpectation fulfill];
    }] removeFromPropertyForProfile:[OCMArg any] propertyName:[OCMArg any] values:[OCMArg any] completionHandler:[OCMArg any]];
    
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
    
    [self.giap increaseProfileProperty:@"count" value:[NSNumber numberWithInt:1]];
    [self.giap appendToProfileProperty:@"tags" values:[NSArray arrayWithObjects:@"red", @"blue", nil]];
    [self.giap removeFromProfileProperty:@"tags" values:[NSArray arrayWithObjects:@"red", nil]];
    
    [self waitForExpectations:[NSArray arrayWithObjects:trackExpectation, aliasExpectation, setPropertiesExpectation, increasePropertiesExpectation, appendToPropertiesExpectation, removeFromPropertiesExpectation, nil] timeout:10];
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
        @"time": @1582727998000,
        @"version": VERSION
    }, @{
        @"type": @"event",
        @"data": @{
                @"$name": @"Visit"
        },
        @"time": @1582727998000,
        @"version": VERSION
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

-(void)test_noFlushOnBackground_applicationGoesToBackground
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
    
    self.giap.flushOnBackground = NO;
    
    [self.giap track:@"Visit" properties:@{
        @"economy_group": @1
    }];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:UIApplicationWillResignActiveNotification object:nil];
    
    sleep(2);
    [self waitForExpectations:[NSArray arrayWithObjects:notTrackExpectation, saveExpectation, nil] timeout:1];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:UIApplicationDidBecomeActiveNotification object:nil];
    
    [self waitForExpectations:[NSArray arrayWithObjects:trackExpectation, nil] timeout:10];
}

-(void)test_flushOnBackground_applicationGoesToBackground
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
    
    self.giap.flushOnBackground = YES;
    
    [self.giap track:@"Visit" properties:@{
        @"economy_group": @1
    }];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:UIApplicationWillResignActiveNotification object:nil];
    
    sleep(2);
    [self waitForExpectations:[NSArray arrayWithObjects:trackExpectation, nil] timeout:1];
}

-(void)testQueueSizeLimit
{
    XCTestExpectation *trackExpectation = [[XCTestExpectation alloc] initWithDescription:@"Track"];
    
    id storageMock = [OCMockObject mockForClass:[GIAPStorage class]];
    NSMutableArray *queue =[NSMutableArray array];
    
    for(int i = 0; i < QUEUE_SIZE_LIMIT; i++) {
        [queue addObject:@{
            @"type": @"event",
            @"data": @{
                    @"$name": @"Visit"
            },
            @"time": @1582727998000,
            @"version": VERSION
        }];
    }
    
    [[[storageMock stub] andReturn:queue] getTaskQueue];
    [[[storageMock stub] andReturn:@"distinct_id"] getDistinctId];
    [[[storageMock stub] andReturn:@"device_id"] getUUIDDeviceId];
    [[[storageMock stub] andReturn:storageMock] initWithToken:[OCMArg any]];
    
    id networkMock = [OCMockObject mockForClass:[GIAPNetwork class]];
    [[[networkMock stub] andDo:^(NSInvocation *invocation) {
        void (^__unsafe_unretained callback)(NSDictionary *response, NSError *error);
        [invocation getArgument:&callback atIndex:3];
        callback(@{}, nil);
        NSArray *events;
        [invocation getArgument:&events atIndex:2];
        XCTAssertEqual([events count], QUEUE_SIZE_LIMIT);
        [trackExpectation fulfill];
    }] emitEvents:[OCMArg any] completionHandler:[OCMArg any]];
    [[[networkMock stub] andReturn:networkMock] initWithToken:[OCMArg any] serverUrl:[OCMArg any]];
    
    [self initGIAP];
    
    [self.giap track:@"Visit" properties:nil];
    
    
    [self waitForExpectations:[NSArray arrayWithObjects:trackExpectation, nil] timeout:10];
}

-(void)testDisable
{
    XCTestExpectation *track1Expectation = [[XCTestExpectation alloc] initWithDescription:@"Track 1"];
    XCTestExpectation *track2Expectation = [[XCTestExpectation alloc] initWithDescription:@"Track 2"];
    XCTestExpectation *saveQueueExpectation = [[XCTestExpectation alloc] initWithDescription:@"Save queue"];
    [track2Expectation setInverted:YES];
    int times = 1;
    
    id storageMock = [OCMockObject mockForClass:[GIAPStorage class]];
    [[[storageMock stub] andReturn:nil] getTaskQueue];
    [[[storageMock stub] andReturn:@"distinct_id"] getDistinctId];
    [[[storageMock stub] andReturn:@"device_id"] getUUIDDeviceId];
    [[[storageMock stub] andReturn:storageMock] initWithToken:[OCMArg any]];
    [[[storageMock stub] andDo:^(NSInvocation *invocation) {
        NSArray *queue;
        [invocation getArgument:&queue atIndex:2];
        if (queue == nil) {
            [saveQueueExpectation fulfill];
        }
    }] saveTaskQueue:[OCMArg any]];
    
    id networkMock = [OCMockObject mockForClass:[GIAPNetwork class]];
    [[[networkMock stub] andDo:^(NSInvocation *invocation) {
        void (^__unsafe_unretained callback)(NSDictionary *response, NSError *error);
         [invocation getArgument:&callback atIndex:3];
        if (times == 1) {
            callback(@{
                @"error_code": @40101
            }, nil);
            [track1Expectation fulfill];
        } else {
            callback(@{}, nil);
            [track2Expectation fulfill];
        }
        
    }] emitEvents:[OCMArg any] completionHandler:[OCMArg any]];
    [[[networkMock stub] andReturn:networkMock] initWithToken:[OCMArg any] serverUrl:[OCMArg any]];
    
    [self initGIAP];
       
    [self.giap track:@"Visit" properties:nil];
    
    [self waitForExpectations:[NSArray arrayWithObjects:track1Expectation, nil] timeout:10];
    
    [self.giap track:@"Visit" properties:nil];
    
    [self waitForExpectations:[NSArray arrayWithObjects:track2Expectation, saveQueueExpectation, nil] timeout:10];
    
}

-(void)testWrongVersion
{
    XCTestExpectation *trackExpectation = [[XCTestExpectation alloc] initWithDescription:@"Track"];
    [trackExpectation setInverted:YES];
    
    id storageMock = [OCMockObject mockForClass:[GIAPStorage class]];
    [[[storageMock stub] andReturn:[NSArray arrayWithObjects:@{
        @"type": @"event",
        @"data": @{
                @"$name": @"Visit"
        },
        @"time": @1582727998000,
        @"version": @"old"
    }, @{
        @"type": @"event",
        @"data": @{
                @"$name": @"Visit"
        },
        @"time": @1582727998000,
        @"version": @"old"
    }, nil]] getTaskQueue];
    [[[storageMock stub] andReturn:@"distinct_id"] getDistinctId];
    [[[storageMock stub] andReturn:@"device_id"] getUUIDDeviceId];
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
    
    [self waitForExpectations:[NSArray arrayWithObjects:trackExpectation, nil] timeout:10];

}
       
@end
