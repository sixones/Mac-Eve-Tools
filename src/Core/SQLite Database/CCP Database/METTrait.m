//
//  METTrait.m
//  Vitality
//
//  Created by Andrew Salamon on 7/21/14.
//  Copyright (c) 2014 Sebastian Kruemling. All rights reserved.
//

#import "METTrait.h"

@implementation METTrait
@synthesize skillName;
@synthesize bonus;
@synthesize bonusString;
@synthesize unitString;

- (NSComparisonResult)compare:(id)other
{
    return [[self skillName] compare:[other skillName]];
}

@end
