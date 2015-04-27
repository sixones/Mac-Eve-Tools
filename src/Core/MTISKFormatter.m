//
//  MTISKFormatter.m
//  Vitality
//
//  Created by Andrew Salamon on 10/28/13.
//  Copyright (c) 2013 Sebastian Kruemling. All rights reserved.
//

#import "MTISKFormatter.h"

@implementation MTISKFormatter

-(id)init
{
    if( self = [super init] )
    {
        [self setFormatterBehavior:NSNumberFormatterBehavior10_4];
        [self setNumberStyle:NSNumberFormatterCurrencyStyle];
        [self setPositiveSuffix:@" ISK"];
        [self setNegativeSuffix:@" ISK"];
        [self setPositivePrefix:@""];
        [self setNegativePrefix:@"-"];
    }
    
    return self;
}
@end
