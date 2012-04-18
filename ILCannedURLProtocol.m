//
//  ILCannedURLProtocol.m
//
//  Created by Claus Broch on 10/09/11.
//  Copyright 2011 Infinite Loop. All rights reserved.
//
//  Redistribution and use in source and binary forms, with or without modification, are permitted
//  provided that the following conditions are met:
//
//  - Redistributions of source code must retain the above copyright notice, this list of conditions 
//    and the following disclaimer.
//  - Redistributions in binary form must reproduce the above copyright notice, this list of 
//    conditions and the following disclaimer in the documentation and/or other materials provided 
//    with the distribution.
//  - Neither the name of Infinite Loop nor the names of its contributors may be used to endorse or 
//    promote products derived from this software without specific prior written permission.
//
//  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR 
//  IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND 
//  FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR 
//  CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL 
//  DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, 
//  DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, 
//  WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY 
//  WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
//

#import "ILCannedURLProtocol.h"

// Undocumented initializer obtained by class-dump - don't use this in production code destined for the App Store
@interface NSHTTPURLResponse(UndocumentedInitializer)
- (id)initWithURL:(NSURL*)URL statusCode:(NSInteger)statusCode headerFields:(NSDictionary*)headerFields requestTime:(double)requestTime;
@end

@interface ILCannedURLProtocol()
+ (NSMutableDictionary*)responses;
@end

static NSMutableDictionary *gILCannedResponses;

@implementation ILCannedURLProtocol

+ (NSMutableDictionary*)responses {
    if (gILCannedResponses == nil) {
        gILCannedResponses = [NSMutableDictionary dictionary];
    }
    return gILCannedResponses;
}

+ (BOOL)canInitWithRequest:(NSURLRequest *)request {
	// For now only supporting http GET and POST
//	return [[[request URL] scheme] isEqualToString:@"http"] && ([[request HTTPMethod] isEqualToString:@"GET"] || [[request HTTPMethod] isEqualToString:@"POST"]);
    return YES;
}

+ (NSURLRequest *)canonicalRequestForRequest:(NSURLRequest *)request {
	return request;
}

+ (void)setCannedResponseData:(NSData*)data {
    [self setCannedResponseData:data forPath:@""];
}

+ (void)setCannedResponseData:(NSData *)data forPath:(NSString *)path {
    NSMutableDictionary *responsesForPaths = [self responses];
    NSMutableDictionary *response = [responsesForPaths objectForKey:path];
    if (response == nil) {
        response = [NSMutableDictionary dictionary];
        [responsesForPaths setValue:response forKey:path];
    }
    [response setValue:data forKey:@"data"];
}

+ (void)setCannedHeaders:(NSDictionary*)headers {
    [self setCannedHeaders:headers forPath:@""];
}

+ (void)setCannedHeaders:(NSDictionary *)headers forPath:(NSString *)path {
    NSMutableDictionary *responsesForPaths = [self responses];
    NSMutableDictionary *response = [responsesForPaths objectForKey:path];
    if (response == nil) {
        response = [NSMutableDictionary dictionary];
        [responsesForPaths setValue:response forKey:path];
    }
    [response setValue:headers forKey:@"headers"];
}

+ (void)setCannedStatusCode:(NSInteger)statusCode {
    [self setCannedStatusCode:statusCode forPath:@""];
}

+ (void)setCannedStatusCode:(NSInteger)statusCode forPath:(NSString *)path {
    NSMutableDictionary *responsesForPaths = [self responses];
    NSMutableDictionary *response = [responsesForPaths objectForKey:path];
    if (response == nil) {
        response = [NSMutableDictionary dictionary];
        [responsesForPaths setValue:response forKey:path];
    }
    [response setValue:[NSNumber numberWithInt:statusCode] forKey:@"statusCode"];
}

+ (void)setCannedError:(NSError*)error {
    [self setCannedError:error forPath:@""];
}

+ (void)setCannedError:(NSError *)error forPath:(NSString *)path {
    NSMutableDictionary *responsesForPaths = [self responses];
    NSMutableDictionary *response = [responsesForPaths objectForKey:path];
    if (response == nil) {
        response = [NSMutableDictionary dictionary];
        [responsesForPaths setValue:response forKey:path];
    }
    [response setValue:error forKey:@"error"];
}

+ (void)reset {
    [[self responses] removeAllObjects];
}

- (NSCachedURLResponse *)cachedResponse {
	return nil;
}

- (void)startLoading {
    NSURLRequest *request = [self request];
	id<NSURLProtocolClient> client = [self client];
	
    NSString *path = [[request URL] path];
    NSDictionary *dictionary = [[ILCannedURLProtocol responses] objectForKey:path];
    // If there aren't entries for this path, see if there are default entries
    if (dictionary == nil) {
        dictionary = [[ILCannedURLProtocol responses] objectForKey:@""];
    }
    NSData *data = [dictionary objectForKey:@"data"];
    NSError *error = [dictionary objectForKey:@"error"];
	if (data) {
		// Send the canned data
        NSInteger statusCode = [[dictionary objectForKey:@"statusCode"] intValue];
        NSDictionary *headers = [dictionary objectForKey:@"headers"];
		NSHTTPURLResponse *response = [[NSHTTPURLResponse alloc] initWithURL:[request URL]
																  statusCode:statusCode
																headerFields:headers 
																 requestTime:0.0];
		
		[client URLProtocol:self didReceiveResponse:response cacheStoragePolicy:NSURLCacheStorageNotAllowed];
		[client URLProtocol:self didLoadData:data];
		[client URLProtocolDidFinishLoading:self];
	} else if (error) {
		// Send the canned error
		[client URLProtocol:self didFailWithError:error];
	} else {
        // TODO: What if we don't have data or an error?  Should we handle in a default way?
        NSAssert1(false, @"ILCannedURLProtocol called with unhandled path: %@", path);
    }
}

- (void)stopLoading {
}

@end
