//
//  GIAPNetworkTest.m
//  GIAP_Tests
//
//  Created by Tran Viet Thang on 2/25/20.
//  Copyright © 2020 uendno. All rights reserved.
//

#import "GIAP/GIAPNetwork.h"

@interface GIAPNetworkTest : XCTestCase

@property (atomic) GIAPNetwork *network;
@property (atomic) NSURLRequest* testRequest;

@end

@implementation GIAPNetworkTest

- (void)setUp {
    self.network = [GIAPNetwork initWithToken:@"token" serverUrl:[NSURL URLWithString:@"https://analytics-api.got-it.io"]];
    
    [HTTPStubs stubRequestsPassingTest:^BOOL(NSURLRequest *request) {
        self.testRequest = request;
        return YES;
    } withStubResponse:^HTTPStubsResponse*(NSURLRequest *request) {
        NSDictionary *res = @{};
        return [HTTPStubsResponse responseWithJSONObject:res statusCode:200 headers:nil];
    }];
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
}

- (void)test_emitEvents {
    XCTestExpectation *expectation = [[XCTestExpectation alloc] initWithDescription:@"Send event"];
    NSMutableArray *events = [NSMutableArray array];
    [events addObject:@{
        @"name": @"1"
    }];
    
    [self.network emitEvents:events completionHandler:^(NSDictionary *response, NSError *error) {
        NSLog(@"%@", response);
        [expectation fulfill];
    }];
    
    [self waitForExpectations:[NSArray arrayWithObject:expectation] timeout:10];
    NSDictionary* requestBody = [self parseHTTPBodyStream:self.testRequest.HTTPBodyStream];
    
    XCTAssertTrue([self.testRequest.HTTPMethod isEqualToString:@"POST"]);
    XCTAssertTrue([[self.testRequest.URL path] isEqualToString:@"/events"]);
    XCTAssertTrue( [requestBody isEqualToDictionary:@{
        @"events": events
    }]);
}

- (void)test_updateProfile {
    XCTestExpectation *expectation = [[XCTestExpectation alloc] initWithDescription:@"Update profile"];
    
    NSDictionary *updateData = @{
        @"name": @"Dumb"
    };
    
    [self.network updateProfileWithId:@"2" updateData:updateData completionHandler:^(NSDictionary *response, NSError *error) {
        [expectation fulfill];
    }];
    
    [self waitForExpectations:[NSArray arrayWithObject:expectation] timeout:10];
    NSDictionary* requestBody = [self parseHTTPBodyStream:self.testRequest.HTTPBodyStream];
    
    XCTAssertTrue([self.testRequest.HTTPMethod isEqualToString:@"PUT"]);
    XCTAssertTrue([[self.testRequest.URL path] isEqualToString:@"/profiles/2"]);
    XCTAssertTrue([requestBody isEqualToDictionary:updateData]);
}

- (void)test_increaseProperty {
    XCTestExpectation *expectation = [[XCTestExpectation alloc] initWithDescription:@"Update profile"];
    
    [self.network increasePropertyForProfile:@"2" propertyName:@"count" value:[NSNumber numberWithInt:1] completionHandler:^(NSDictionary *response, NSError *error) {
        [expectation fulfill];
    }];
    
    [self waitForExpectations:[NSArray arrayWithObject:expectation] timeout:10];
    NSDictionary* requestBody = [self parseHTTPBodyStream:self.testRequest.HTTPBodyStream];
    
    XCTAssertTrue([self.testRequest.HTTPMethod isEqualToString:@"PUT"]);
    XCTAssertTrue([[self.testRequest.URL path] isEqualToString:@"/profiles/2/count"]);
    NSDictionary *postData = @{
        @"operation": @"increase",
        @"value": [NSNumber numberWithInt:1]
    };
    XCTAssertTrue([requestBody isEqualToDictionary:postData]);
}

- (void)test_appendToProperty {
    XCTestExpectation *expectation = [[XCTestExpectation alloc] initWithDescription:@"Update profile"];
    NSArray *values = [NSArray arrayWithObjects:@"red", @"blue", nil];
    
    [self.network appendToPropertyForProfile:@"2" propertyName:@"tags" values:values completionHandler:^(NSDictionary *response, NSError *error) {
        [expectation fulfill];
    }];
    
    [self waitForExpectations:[NSArray arrayWithObject:expectation] timeout:10];
    NSDictionary* requestBody = [self parseHTTPBodyStream:self.testRequest.HTTPBodyStream];
    
    XCTAssertTrue([self.testRequest.HTTPMethod isEqualToString:@"PUT"]);
    XCTAssertTrue([[self.testRequest.URL path] isEqualToString:@"/profiles/2/tags"]);
    NSDictionary *postData = @{
        @"operation": @"append",
        @"value": values
    };
    XCTAssertTrue([requestBody isEqualToDictionary:postData]);
}

- (void)test_removeFromProperty{
    XCTestExpectation *expectation = [[XCTestExpectation alloc] initWithDescription:@"Update profile"];
    NSArray *values = [NSArray arrayWithObjects:@"red", @"blue", nil];
    
    [self.network removeFromPropertyForProfile:@"2" propertyName:@"tags" values:values completionHandler:^(NSDictionary *response, NSError *error) {
        [expectation fulfill];
    }];
    
    [self waitForExpectations:[NSArray arrayWithObject:expectation] timeout:10];
    NSDictionary* requestBody = [self parseHTTPBodyStream:self.testRequest.HTTPBodyStream];
    
    XCTAssertTrue([self.testRequest.HTTPMethod isEqualToString:@"PUT"]);
    XCTAssertTrue([[self.testRequest.URL path] isEqualToString:@"/profiles/2/tags"]);
    NSDictionary *postData = @{
        @"operation": @"remove",
        @"value": values
    };
    XCTAssertTrue([requestBody isEqualToDictionary:postData]);
}

- (void)test_createAlias {
    XCTestExpectation *expectation = [[XCTestExpectation alloc] initWithDescription:@"Send event"];
    
    [self.network createAliasForUserId:@"2" withDistinctId:@"abc" completionHandler:^(NSDictionary *response, NSError *error) {
        NSLog(@"%@", response);
        [expectation fulfill];
    }];
    
    [self waitForExpectations:[NSArray arrayWithObject:expectation] timeout:10];
    NSDictionary* requestBody = [self parseHTTPBodyStream:self.testRequest.HTTPBodyStream];
    
    NSDictionary *postData = @{
        @"distinct_id": @"abc",
        @"user_id": @"2"
    };
    
    XCTAssertTrue([self.testRequest.HTTPMethod isEqualToString:@"POST"]);
    XCTAssertTrue([[self.testRequest.URL path] isEqualToString:@"/alias"]);
    XCTAssertTrue([requestBody isEqualToDictionary:postData]);
}

- (void)test_identify {
    XCTestExpectation *expectation = [[XCTestExpectation alloc] initWithDescription:@"Send event"];
    
    [self.network identifyWithUserId:@"2" fromDistinctId:@"abc" completionHandler:^(NSDictionary *response, NSError *error) {
        NSLog(@"%@", response);
        [expectation fulfill];
    }];
    
    [self waitForExpectations:[NSArray arrayWithObject:expectation] timeout:10];
        
    XCTAssertTrue([self.testRequest.HTTPMethod isEqualToString:@"GET"]);
    XCTAssertTrue([[self.testRequest.URL path] isEqualToString:@"/alias/2"]);
    XCTAssertTrue([[self.testRequest.URL query] isEqualToString:@"current_distinct_id=abc"]);
}

-(NSDictionary *)parseHTTPBodyStream:(NSInputStream *)stream
{
    uint8_t byteBuffer[4096];
    [stream open];
    if (stream.hasBytesAvailable) {
        NSLog(@"bytes available");
        NSInteger bytesRead = [stream read:byteBuffer maxLength:sizeof(byteBuffer)]; //max len must match buffer size
        NSString *stringFromData = [[NSString alloc] initWithBytes:byteBuffer length:bytesRead encoding:NSUTF8StringEncoding];
        NSData *data = [stringFromData dataUsingEncoding:NSUTF8StringEncoding];
        
        return [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
    } else {
        return nil;
    }
}

@end
