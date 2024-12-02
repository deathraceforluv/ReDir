// Copyright (c) 2024 Project Nova LLC

#import <Foundation/Foundation.h>
#import <objc/runtime.h>

#define API_URL @"https://api.novafn.dev"
#define EPIC_GAMES_URL @"ol.epicgames.com"

@interface CustomURLProtocol : NSURLProtocol
@end

@implementation CustomURLProtocol

+ (BOOL)canInitWithRequest:(NSURLRequest *)request {
    NSString *absoluteURLString = [[request URL] absoluteString];
    if ([absoluteURLString containsString:EPIC_GAMES_URL] && ![absoluteURLString containsString:@"/CloudDir/"]) {
        if ([NSURLProtocol propertyForKey:@"Handled" inRequest:request]) {
            return NO;
        }
        return YES;
    }
    return NO;
}

+ (NSURLRequest*)canonicalRequestForRequest:(NSURLRequest*)request {
    return request;
}

- (void)startLoading {
    NSMutableURLRequest *modifiedRequest = [[self request] mutableCopy];
    
    NSString *originalPath = [modifiedRequest.URL path];
    NSString *originalQuery = [modifiedRequest.URL query];
    
    NSString *newBaseURLString = API_URL;
    NSURLComponents *components = [NSURLComponents componentsWithString:newBaseURLString];
    
    components.path = originalPath;
    if (originalQuery) {
        components.query = originalQuery;
    }
    
    [modifiedRequest setURL:components.URL];
    
    // Mark the request as handled
    [NSURLProtocol setProperty:@YES forKey:@"Handled" inRequest:modifiedRequest];
    
    // Ensure that this request forwarding is done safely on the correct thread (main thread)
    dispatch_async(dispatch_get_main_queue(), ^{
        [[self client] URLProtocol:self
          wasRedirectedToRequest:modifiedRequest
                redirectResponse:nil];
    });
}

- (void)stopLoading {
    // Cleanup code (if needed)
}

@end

// Register CustomURLProtocol in a proper place, such as in AppDelegate or somewhere appropriate
- (void)applicationDidFinishLaunching:(UIApplication *)application {
    [NSURLProtocol registerClass:[CustomURLProtocol class]];
}
