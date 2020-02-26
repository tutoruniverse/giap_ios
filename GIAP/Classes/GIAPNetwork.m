//
//  GIAPNetwork.m
//  GIAP
//
//  Created by Tran Viet Thang on 2/7/20.
//

#import <Foundation/Foundation.h>
#import "GIAPNetwork.h"

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

- (void) emitEvents:(NSArray *)events completionHandler:(void (^)(NSDictionary*, NSError*))completionHandler
{
    NSURLRequest* request = [self buildRequestForEndpoint:@"/events" byHTTPMethod:@"POST" withQueryItems:nil andBody: @{
        @"events": events
    }];
    
    [[_urlSession dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        [self parseResponseData:data error:error completionHandler:completionHandler];
    }] resume];
}

- (void) updateProfileWithId:(NSString *)profileId updateData:(NSDictionary *)updateData completionHandler:(void (^)(NSDictionary*, NSError*))completionHandler
{
    NSURLRequest* request = [self buildRequestForEndpoint:[NSString stringWithFormat:@"/profiles/%@", profileId] byHTTPMethod:@"PUT" withQueryItems:nil andBody:updateData];
    
    [[_urlSession dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        [self parseResponseData:data error:error completionHandler:completionHandler];
    }] resume];
}

- (void) createAliasForUserId:(NSString *)userId withDistinctId:(NSString *)distinctId completionHandler:(void (^)(NSDictionary*, NSError*))completionHandler
{
    NSURLRequest* request = [self buildRequestForEndpoint:@"/alias" byHTTPMethod:@"POST" withQueryItems:nil andBody:@{
        @"user_id": userId,
        @"distinct_id": distinctId
    }];
    
    [[_urlSession dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        [self parseResponseData:data error:error completionHandler:completionHandler];
    }] resume];
}

- (void) identifyWithUserId:(NSString *)userId fromDistinctId:(NSString *) distinctId completionHandler:(void (^)(NSDictionary*, NSError*))completionHandler
{
    NSArray *queryItems = [NSArray arrayWithObject:[[NSURLQueryItem alloc] initWithName:@"current_distinct_id" value:distinctId]];
    NSURLRequest* request = [self buildRequestForEndpoint:[NSString stringWithFormat:@"/alias/%@", userId] byHTTPMethod:@"GET" withQueryItems:queryItems andBody:nil];
    
    [[self.urlSession dataTaskWithRequest:request completionHandler: ^(NSData *data, NSURLResponse *response, NSError *error) {
        [self parseResponseData:data error:error completionHandler:completionHandler];
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
    
    if (![method isEqualToString:@"GET"] && ![method isEqualToString:@"DELETE"]) {
        [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    }
    
    [request setValue:@"gzip" forHTTPHeaderField:@"Accept-Encoding"];
    [request setValue:[NSString stringWithFormat:@"Bearer %@", self.token] forHTTPHeaderField:@"Authorization"];
    [request setHTTPMethod:method];
    
    if (body) {
        NSError *error;
        NSData *bodyData = [NSJSONSerialization dataWithJSONObject:body options:0 error:&error];
        [request setHTTPBody:bodyData];
    }
    
    NSLog(@"%@ http request: %@?%@", self, request, body);
    
    return request;
}

- (void)parseResponseData:(NSData *)data error:(NSError *)error completionHandler:(void (^)(NSDictionary*, NSError*))completionHandler
{
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
    
    completionHandler(jsonResponse, nil);
}

@end
