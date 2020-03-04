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

@property (atomic, copy) NSString *token;
@property (atomic, copy) NSURL *serverUrl;
@property (atomic, retain) NSURLSession *urlSession;

+ (instancetype)initWithToken:(NSString *) token serverUrl:(NSURL *)serverURL;
- (void)emitEvents:(NSArray *)events completionHandler:(void (^)(NSDictionary*, NSError*))completionHandler;
- (void)updateProfileWithId:(NSString *)profileId updateData:(NSDictionary *)updateData completionHandler:(void (^)(NSDictionary*, NSError*))completionHandler;
- (void)createAliasForUserId:(NSString *)userId withDistinctId:(NSString *)distinctId completionHandler:(void (^)(NSDictionary*, NSError*))completionHandler;
- (void)identifyWithUserId:(NSString *)userId fromDistinctId:(NSString *) distinctId completionHandler:(void (^)(NSDictionary* , NSError*))completionHandler;
- (void)increasePropertyForProfile:(NSString *)profileId propertyName:(NSString *)propertyName value:(NSNumber *)value completionHandler:(void (^)(NSDictionary*, NSError*))completionHandler;
- (void)appendToPropertyForProfile:(NSString *)profileId propertyName:(NSString *)propertyName values:(NSArray *)values completionHandler:(void (^)(NSDictionary*, NSError*))completionHandler;
- (void)removeFromPropertyForProfile:(NSString *)profileId propertyName:(NSString *)propertyName values:(NSArray *)values completionHandler:(void (^)(NSDictionary*, NSError*))completionHandler;

@end
