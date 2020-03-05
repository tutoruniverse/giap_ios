# GIAP iOS

## Description

GIAP for iOS is a SDK to help your app communicate with Got It Analytics Platform

## Installation

### Step 1: Add giap_ios as a submodule

Add giap_ios as a submodule to your local git repo like so:

```shell
git submodule add git@github.com:tutoruniverse/giap_ios.git
```

### Step 2: Instal via CocoaPods
Inside your Podfile:

```shell
pod 'GIAP', :path => './giap_ios'
```
`path` should point to the giap_ios submodule

Finally, run this command to make GIAP available inside your project:

```shell
pod install
```

## Usage

### Integrate

Import the header file

```objectivec
#import <GIAP/GIAP.h>
```

Initialize the library

```objectivec
[GIAP initWithToken:@"INSERT_YOUR_TOKEN_HERE" serverUrl:[NSURL URLWithString:@"INSERT_THE_GIAP_SERVER_URL_HERE"]];
```

### Create alias
Use this method right after user has just signed up

```objectivec
[[GIAP sharedInstance] alias:@"INSERT THE USER ID"];
```

### Identify
Use this method right after user has just logged in

```objectivec
[[GIAP sharedInstance] identify:@"INSERT THE USER ID"];
```

### Track

Use a string to represent the event name and a dictionary to represent the event properties. `properties` can be `nil`.

```objectivec
[[GIAP sharedInstance] track:@"Visit" properties:@{
    @"economy_group": economyGroup
}];
```

### Set properties for current profile
At any moment after initializing the lib, you can set custom properties for current tracking profile

```objectivec
[[GIAP sharedInstance] setProfileProperties:@{
    @"full_name": name
}];
```

### Update profile properties atomically
Increase/Decrease a numeric property

```objectivec
[[GIAP sharedInstance] increaseProfileProperty:@"count" value:[NSNumber numberWithInt:1]];
```
Append new elements to a list property

```objectivec
[[GIAP sharedInstance] appendToProfileProperty:@"tags" values:[tags componentsSeparatedByString:@","]];
```
Remove elements from a list property

```objectivec
[[GIAP sharedInstance] removeFromProfileProperty:@"tags" values:[tags componentsSeparatedByString:@","]];
```

### Reset
Use this method right after user has just logged out

```objectivec
[[GIAP sharedInstance] reset];
```

### Delegation
GIAP iOS SDK handles everything asynchronously. Your app can be notified about important tasks done by the SDK by using delegation.

Assign a delegate for the lib:

```objectivec
[GIAP sharedInstance].delegate = self;
```

Your class must conform the `GIAPDelegate` protocol:

```objectivec
@import GIAP;

@interface GIAPViewController: UIViewController <GIAPDelegate>
```

Implement the following methods for your class:

```objectivec
- (void)giap:(GIAP *)giap didResetWithDistinctId:(NSString *)distinctId
{
    NSLog(@"GIAP didResetWithDistinctId:%@", distinctId);
}

- (void)giap:(GIAP *)giap didEmitEvents:(NSArray *)events withResponse:(NSDictionary *)response andError:(NSError *)error
{
    NSLog(@"GIAP didEmitEvent:\n%@", events);
    if (error) {
        NSLog(@"%@", error);
    } else {
        NSLog(@"%@", response);
    }
}

- (void)giap:(GIAP *)giap didUpdateProfile:(NSString *)distinctId withProperties:(NSDictionary *)properties withResponse:(NSDictionary *)response andError:(NSError *)error
{
    NSLog(@"GIAP didUpdateProfile:\n%@ withProperties:%@", distinctId, properties);
    if (error) {
        NSLog(@"%@", error);
    } else {
        NSLog(@"%@", response);
    }
}

- (void)giap:(GIAP *)giap didCreateAliasForUserId:(NSString *)userId withDistinctId:(NSString *)distinctId withResponse:(NSDictionary *)response andError:(NSError *)error
{
    NSLog(@"GIAP didCreateAliasForUserId:\n%@ withDistinctId:%@", userId, distinctId);
    if (error) {
        NSLog(@"%@", error);
    } else {
        NSLog(@"%@", response);
    }
}

- (void)giap:(GIAP *)giap didIdentifyUserId:(NSString *)userId withCurrentDistinctId:(NSString *)distinctId withResponse:(NSDictionary *)response andError:(NSError *)error
{
    NSLog(@"GIAP didIdentifyUserId:\n%@ withCurrentDistinctId:%@", userId, distinctId);
    if (error) {
        NSLog(@"%@", error);
    } else {
        NSLog(@"%@", response);
    }
}
```