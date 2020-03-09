//
//  GIAP+Private.h
//  GIAP
//
//  Created by Tran Viet Thang on 2/7/20.
//

#ifndef GIAP_Private_h
#define GIAP_Private_h


#endif /* GIAP_Private_h */

#import "GIAP.h"
#import "GIAPNetwork.h"
#import "GIAPDevice.h"
#import "GIAPStorage.h"

@interface GIAP()

#pragma mark Properties

@property (atomic, copy) NSString *token;
@property (atomic, copy) NSString *distinctId;
@property (atomic, copy) NSString *deviceId;
@property (atomic, retain) GIAPNetwork *network;
@property (atomic, retain) GIAPDevice *device;
@property (atomic, retain) GIAPStorage *storage;
@property (atomic, strong) NSMutableArray *taskQueue;
@property (atomic, retain) NSTimer *timer;
@property (nonatomic) dispatch_queue_t serialQueue;
@property (atomic) BOOL flushing;
@property (atomic) BOOL disabled;

@end
