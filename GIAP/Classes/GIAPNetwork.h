//
//  GIAPNetwork.h
//  GIAP
//
//  Created by Tran Viet Thang on 2/7/20.
//

#ifndef GIAPNetwork_h
#define GIAPNetwork_h


#endif /* GIAPNetwork_h */

@interface GIAPNetwork : NSObject

+ (instancetype)initWithToken:(NSString *) token serverUrl:(NSURL *)serverURL;
- (void) emitEvents:(NSArray *)events completionHandler:(void (^)(NSError*))completionHandler;
- (void) updateProfileWithId:(NSString *)profileId updateData:(NSDictionary *)updateData completionHandler:(void (^)(NSError*))completionHandler;
- (void) createAliasForUserId:(NSString *)userId withDistinctId:(NSString *)distinctId completionHandler:(void (^)(NSError*))completionHandler;
- (void) identifyWithUserId:(NSString *)userId fromDistinctId:(NSString *) distinctId completionHandler:(void (^)(NSString* , NSError*))completionHandler;

@end
