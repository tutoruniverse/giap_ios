//
//  GIAPStorage.h
//  GIAP
//
//  Created by Tran Viet Thang on 2/12/20.
//

#ifndef GIAPStorage_h
#define GIAPStorage_h


#endif /* GIAPStorage_h */

@interface GIAPStorage : NSObject

@property (atomic, copy) NSString *token;

+ (instancetype)initWithToken:(NSString *)token;
- (NSString *)getDistinctId;
- (void)setDistinctId:(NSString *)distinctId;
- (NSString *)resetDistinctId;
- (NSString *)getUUIDDeviceId;
- (NSString *)resetUUIDDeviceId;
- (void)saveTaskQueue:(NSArray *)taskQueue;
- (NSArray *)getTaskQueue;
@end
