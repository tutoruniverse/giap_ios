//
//  GIAPDeviceTest.m
//  GIAP_Tests
//
//  Created by Tran Viet Thang on 2/25/20.
//  Copyright © 2020 uendno. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <CoreTelephony/CTTelephonyNetworkInfo.h>
#import <CoreTelephony/CTCarrier.h>
#import <SystemConfiguration/SystemConfiguration.h>
#import "GIAP/GIAPDevice.h"

@interface GIAPDeviceTest : XCTestCase

@property (atomic) GIAPDevice *device;

@end

@implementation GIAPDeviceTest

- (void)setUp {
    self.device = [GIAPDevice initWithToken:@"token"];
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
}

- (void)test_getConsistentProperties {
    NSDictionary *properties = [self.device getDeviceProperties];
    
    XCTAssertNotNil([properties valueForKey:@"$app_build_number"]);
    XCTAssertNotNil([properties valueForKey:@"$app_version_string"]);
    XCTAssertNotNil([properties valueForKey:@"$lib"]);
    XCTAssertNotNil([properties valueForKey:@"$lib_version"]);
    XCTAssertNotNil([properties valueForKey:@"$model"]);
    XCTAssertNotNil([properties valueForKey:@"$os"]);
    XCTAssertNotNil([properties valueForKey:@"$os_version"]);
    XCTAssertNotNil([properties valueForKey:@"$screen_height"]);
    XCTAssertNotNil([properties valueForKey:@"$screen_width"]);
    XCTAssertNotNil([properties valueForKey:@"$wifi"]);
}

@end
