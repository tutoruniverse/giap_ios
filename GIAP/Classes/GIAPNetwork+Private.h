//
//  GIAPNetwork+Private.h
//  GIAP
//
//  Created by Tran Viet Thang on 2/10/20.
//

#ifndef GIAPNetwork_Private_h
#define GIAPNetwork_Private_h


#endif /* GIAPNetwork_Private_h */

#import "GIAPNetwork.h"

@interface GIAPNetwork()

#pragma mark Properties
@property (atomic, copy) NSString *token;
@property (atomic, copy) NSURL *serverUrl;
@property (atomic, retain) NSURLSession *urlSession;

@end
