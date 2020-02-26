#ifdef __OBJC__
#import <UIKit/UIKit.h>
#else
#ifndef FOUNDATION_EXPORT
#if defined(__cplusplus)
#define FOUNDATION_EXPORT extern "C"
#else
#define FOUNDATION_EXPORT extern
#endif
#endif
#endif

#import "Constants.h"
#import "GIAP+Private.h"
#import "GIAP.h"
#import "GIAPDevice.h"
#import "GIAPNetwork.h"
#import "GIAPStorage+Private.h"
#import "GIAPStorage.h"

FOUNDATION_EXPORT double GIAPVersionNumber;
FOUNDATION_EXPORT const unsigned char GIAPVersionString[];

