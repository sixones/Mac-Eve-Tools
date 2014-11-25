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

- (instancetype)initWithURL:(NSURL *)URL
{
    if( self = [super initWithURL:URL] )
    {
        [super setValue:[[GlobalData sharedInstance] userAgent] forHTTPHeaderField:@"User-Agent"];
    }
    return self;
}

- (instancetype)initWithURL:(NSURL *)URL cachePolicy:(NSURLRequestCachePolicy)cachePolicy timeoutInterval:(NSTimeInterval)timeoutInterval
{
    if( self = [super initWithURL:URL cachePolicy:cachePolicy timeoutInterval:timeoutInterval] )
    {
        [super setValue:[[GlobalData sharedInstance] userAgent] forHTTPHeaderField:@"User-Agent"];
    }
    return self;
}

@end
