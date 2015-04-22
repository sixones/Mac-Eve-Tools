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
@end
