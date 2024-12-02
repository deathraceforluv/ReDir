#import <Foundation/Foundation.h>
#import <objc/runtime.h>

#define API_URL @"http://localhost:3000"  // Change to your local HTTP server URL
#define EPIC_GAMES_URL @"ol.epicgames.com"

// Custom URL Protocol
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
    [NSURLProtocol setProperty:@YES forKey:@"Handled" inRequest:modifiedRequest];

    // Bypass SSL by allowing the modified request to be sent using a custom NSURLSession
    [self sendRequest:modifiedRequest];
}

- (void)stopLoading {
    // Implement stop loading logic if necessary
}

- (void)sendRequest:(NSURLRequest *)request {
    // Create a custom NSURLSession that ignores SSL certificate errors
    NSURLSessionConfiguration *sessionConfig = [NSURLSessionConfiguration defaultSessionConfiguration];
    
    // Create a custom delegate to handle SSL bypass
    NSURLSession *session = [NSURLSession sessionWithConfiguration:sessionConfig delegate:self delegateQueue:nil];
    
    NSURLSessionDataTask *task = [session dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        if (error) {
            NSLog(@"Request failed: %@", error);
        } else {
            // Handle response data
            NSLog(@"Request succeeded: %@", response);
        }
    }];
    [task resume];
}

// SSL bypass handler for the NSURLSession delegate
- (void)URLSession:(NSURLSession *)session
       didReceiveChallenge:(NSURLAuthenticationChallenge *)challenge
       completionHandler:(void (^)(NSURLSessionAuthChallengeDisposition disposition, NSURLCredential *credential))completionHandler {
    // Always trust the certificate and ignore SSL errors
    if ([challenge.protectionSpace.authenticationMethod isEqualToString:NSURLAuthenticationMethodServerTrust]) {
        NSURLCredential *credential = [NSURLCredential credentialForTrust:challenge.protectionSpace.serverTrust];
        completionHandler(NSURLSessionAuthChallengeUseCredential, credential);
    } else {
        completionHandler(NSURLSessionAuthChallengePerformDefaultHandling, nil);
    }
}

@end

__attribute__((constructor)) void entry() {
    [NSURLProtocol registerClass:[CustomURLProtocol class]];
}
