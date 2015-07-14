//
//  METFitting.m
//  Vitality
//
//  Created by Andrew Salamon on 6/22/15.
//  Copyright (c) 2015 Sebastian Kruemling. All rights reserved.
//

#import "METFitting.h"
#import "GlobalData.h"
#import "CCPDatabase.h"
#import "CCPType.h"

@implementation METFitting

@synthesize ship = _ship;
@synthesize name = _name;

+ (METFitting *)fittingFromDNA:(NSString *)dna
{
    CCPDatabase *ccpdb = [[GlobalData sharedInstance] database];
    METFitting *fit = nil;
    
    // See also: https://wiki.eveonline.com/en/wiki/Ship_DNA
    NSArray *items = [dna componentsSeparatedByString:@":"];
    for( NSString *item in items )
    {
        // This skips the double colon at the end, along with any other empty sections
        if( [item length] == 0 )
            continue;
        
        NSArray *itemAndCount = [item componentsSeparatedByString:@";"];
        NSInteger typeID = -1;
        NSInteger count = 0;
        if( [itemAndCount count] == 1 )
        {
            typeID = [[itemAndCount objectAtIndex:0] integerValue];
            count = 1;
        }
        else if( [itemAndCount count] == 2 )
        {
            typeID = [[itemAndCount objectAtIndex:0] integerValue];
            count = [[itemAndCount objectAtIndex:1] integerValue];
        }
        else
        {
            NSLog( @"Error parsing fitting DNA: %@", dna );
        }
        
        if( typeID > -1 )
        {
            CCPType *type = [ccpdb type:typeID];
            if( type )
            {
                if( !fit )
                {
                    fit = [[METFitting alloc] init];
                    [fit setShip:type];
                    [fit setName:[type typeName]];
                }
                [fit addCount:count ofType:type];
            }
        }
    }
    return [fit autorelease];
}

- (id)init
{
    if( self = [super init] )
    {
        items = [[NSMutableArray alloc] init];
        itemCounts = [[NSCountedSet alloc] init];
    }
    return self;
}

- (void)dealloc
{
    [_ship release];
    [_name release];
    [items release];
    [itemCounts release];
    [super dealloc];
}

- (void)addCount:(NSInteger)count ofType:(CCPType *)type
{
    [items addObject:type];
    for( NSInteger i = 0; i < count; ++i )
        [itemCounts addObject:type];
}

- (NSArray *)items
{
    return [[items retain] autorelease];
}

- (NSInteger)countOfItem:(CCPType *)item
{
    return [itemCounts countForObject:item];
}

@end
