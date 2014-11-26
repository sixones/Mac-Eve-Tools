//
//  CCPImplant.m
//  Vitality
//
//  Created by Andrew Salamon on 11/24/14.
//  Copyright (c) 2014 Sebastian Kruemling. All rights reserved.
//

#import "CCPImplant.h"
#import "CCPType.h"

@implementation CCPImplant

@synthesize type = _type;
@synthesize charisma;
@synthesize intelligence;
@synthesize memory;
@synthesize perception;
@synthesize willpower;

- (id)initWithType:(CCPType *)baseType
{
    if( self = [super init] )
    {
        _type = [baseType retain];
    }
    
    return self;
}

- (void)dealloc
{
    [_type release];
    [super dealloc];
}

- (NSInteger)typeID
{
    return [[self type] typeID];
}

- (NSString *)typeName
{
    return [[self type] typeName];
}

- (NSString *)typeDescription
{
    return [[self type] typeDescription];
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"%@\n    char:%ld  int:%ld  mem:%ld  per:%ld  wil:%ld", [[self type] description], (long)[self charisma], (long)[self intelligence], (long)[self memory], (long)[self perception], (long)[self willpower]];
}
@end
