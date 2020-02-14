//
//  GIAPNetwork.m
//  GIAP
//
//  Created by Tran Viet Thang on 2/7/20.
//

#import <Foundation/Foundation.h>
#import "GIAPNetwork.h"
#import "GIAPNetwork+Private.h"

@implementation GIAPNetwork: NSObject

+ (instancetype)initWithToken:(NSString *) token serverUrl:(NSURL *)serverURL
{
    GIAPNetwork* instance = [GIAPNetwork alloc];
    instance.serverUrl = serverURL;
    instance.token = token;
    
    NSURLSessionConfiguration *sessionConfig = [NSURLSessionConfiguration defaultSessionConfiguration];
    sessionConfig.timeoutIntervalForRequest = 30.0;
    instance.urlSession = [NSURLSession sessionWithConfiguration:sessionConfig];
    
    return instance;
}

- (void) emitEvents:(NSArray *)events completionHandler:(void (^)(NSError*))completionHandler
{
    NSURLRequest* request = [self buildRequestForEndpoint:@"/events" byHTTPMethod:@"POST" withQueryItems:nil andBody: @{
        @"events": events
    }];
    
    [[_urlSession dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        completionHandler(error);
    }] resume];
}

- (void) updateProfileWithId:(NSString *)profileId updateData:(NSDictionary *)updateData completionHandler:(void (^)(NSError*))completionHandler
{
    NSURLRequest* request = [self buildRequestForEndpoint:[NSString stringWithFormat:@"/profiles/%@", profileId] byHTTPMethod:@"PUT" withQueryItems:nil andBody:updateData];
    
    [[_urlSession dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        completionHandler(error);
    }] resume];
}

- (void) createAliasForUserId:(NSString *)userId withDistinctId:(NSString *)distinctId completionHandler:(void (^)(NSError*))completionHandler
{
    NSURLRequest* request = [self buildRequestForEndpoint:@"/alias" byHTTPMethod:@"PUT" withQueryItems:nil andBody:@{
        @"user_id": userId,
        @"distinct_id": distinctId
    }];
    
    [[_urlSession dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        completionHandler(error);
    }] resume];
}

- (void) identifyWithUserId:(NSString *)userId fromDistinctId:(NSString *) distinctId completionHandler:(void (^)(NSString*, NSError*))completionHandler
{
    NSArray *queryItems = [NSArray arrayWithObject:[[NSURLQueryItem alloc] initWithName:@"current_distinct_id" value:distinctId]];
    NSURLRequest* request = [self buildRequestForEndpoint:@"/alias" byHTTPMethod:@"GET" withQueryItems:queryItems andBody:nil];
    
    [[self.urlSession dataTaskWithRequest:request completionHandler: ^(NSData *data, NSURLResponse *response, NSError *error) {
        if (error) {
            completionHandler(nil, error);
            return;
        }
        
        NSError *jsonError;
        NSDictionary *jsonResponse = [NSJSONSerialization JSONObjectWithData:data options:0 error:&jsonError];
        
        if (jsonError) {
            completionHandler(nil, jsonError);
            return;
        }
        
        completionHandler([jsonResponse valueForKey:@"distinct_id"], nil);
    }] resume];
}

- (NSURLRequest *)buildRequestForEndpoint:(NSString *)endpoint
                             byHTTPMethod:(NSString *)method
                           withQueryItems:(NSArray <NSURLQueryItem *> *)queryItems
                                  andBody:(NSDictionary *)body
{
    // Build URL from path and query items
    NSURL *urlWithEndpoint = [self.serverUrl URLByAppendingPathComponent:endpoint];
    NSURLComponents *components = [NSURLComponents componentsWithURL:urlWithEndpoint
                                             resolvingAgainstBaseURL:YES];
    if (queryItems) {
        components.queryItems = queryItems;
    }
    
    // NSURLComponents/NSURLQueryItem doesn't encode + as %2B, and then the + is interpreted as a space on servers
    components.percentEncodedQuery = [components.percentEncodedQuery stringByReplacingOccurrencesOfString:@"+" withString:@"%2B"];
    
    // Build request from URL
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:components.URL];
    [request setValue:@"gzip" forHTTPHeaderField:@"Accept-Encoding"];
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    [request setValue:@"Authorization" forHTTPHeaderField:[NSString stringWithFormat:@"Bearer%@", self.token]];
    [request setHTTPMethod:method];
    
    if (body) {
        NSError *error;
        NSData *bodyData = [NSJSONSerialization dataWithJSONObject:body options:0 error:&error];
        [request setHTTPBody:bodyData];
    }
    
    NSLog(@"%@ http request: %@?%@", self, request, body);
    
    return request;
}

@end
