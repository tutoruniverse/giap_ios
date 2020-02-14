//
//  GIAPDevice.h
//  GIAP
//
//  Created by Tran Viet Thang on 2/11/20.
//

#ifndef GIAPDevice_h
#define GIAPDevice_h


#endif /* GIAPDevice_h */

@interface GIAPDevice : NSObject

+ (instancetype)initWithToken:(NSString *)token;
- (NSDictionary *) getDeviceProperties;
- (NSString *)getIDFA;
- (NSString *)getIdentifierForVendor;

@end
