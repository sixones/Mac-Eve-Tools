//
//  METURLRequest.m
//  Vitality
//
//  Created by Andrew Salamon on 11/25/14.
//  Copyright (c) 2014 Sebastian Kruemling. All rights reserved.
//

#import "METURLRequest.h"
#import "GlobalData.h"

@implementation METURLRequest

@synthesize delegate = _delegate;
@synthesize data = _data;

- (instancetype)initWithURL:(NSURL *)URL
{
    if( self = [super initWithURL:URL] )
    {
        [super setValue:[GlobalData userAgent] forHTTPHeaderField:@"User-Agent"];
        _data = [[NSMutableData alloc] init];
    }
    return self;
}

- (instancetype)initWithURL:(NSURL *)URL cachePolicy:(NSURLRequestCachePolicy)cachePolicy timeoutInterval:(NSTimeInterval)timeoutInterval
{
    if( self = [super initWithURL:URL cachePolicy:cachePolicy timeoutInterval:timeoutInterval] )
    {
        [super setValue:[GlobalData userAgent] forHTTPHeaderField:@"User-Agent"];
        _data = [[NSMutableData alloc] init];
    }
    return self;
}

- (void)dealloc
{
    [_data release];
    [super dealloc];
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
    [[self data] setLength:0];
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
    [[self data] appendData:data];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    if( [[self delegate] respondsToSelector:@selector(connectionDidFinishLoading:withError:)] )
    {
        [[self delegate] performSelector:@selector(connectionDidFinishLoading:withError:) withObject:connection withObject:nil];
    }
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
    if( [[self delegate] respondsToSelector:@selector(connectionDidFinishLoading:withError:)] )
    {
        [[self delegate] performSelector:@selector(connectionDidFinishLoading:withError:) withObject:connection withObject:error];
    }
}

@end
