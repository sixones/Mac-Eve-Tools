//
//  MarketOrder.m
//  Mac Eve Tools
//
//  Created by Andrew Salamon on 5/29/13.
//  Copyright (c) 2013 Sebastian Kruemling. All rights reserved.
//

#import "MarketOrder.h"
#import "GlobalData.h"
#import "CCPType.h"
#import "CCPDatabase.h"

@interface MarketOrder()
@property (readwrite) NSString *stationName;
@end

@implementation MarketOrder

@synthesize orderID;
@synthesize charID;
@synthesize stationID;
@synthesize volEntered;
@synthesize volRemaining;
@synthesize minVolume;
@synthesize orderState;
@synthesize typeID;
@synthesize range;
@synthesize accountKey;
@synthesize price;
@synthesize escrow;
@synthesize buy;
@synthesize issued;
@synthesize stationName = _stationName;

- (NSString *)typeName
{
    CCPType *type = [[[GlobalData sharedInstance] database] type:self.typeID];
    if( !type || ![type typeName] )
        NSLog( @"Missing type name in a market order" );
    return [type typeName];
}

- (NSString *)state
{
    NSString *stateStr = nil;
    
    switch( self.orderState )
    {
        case OrderStateActive: stateStr = @"Open"; break;
        case OrderStateClosed: stateStr = @"Closed"; break;
        case OrderStateExpired: stateStr = @"Expired"; break;
        case OrderStateCancelled: stateStr = @"Cancelled"; break;
        case OrderStatePending: stateStr = @"Pending"; break;
        case OrderStateCharacterDeleted: stateStr = @"Char Deleted"; break;
        case OrderStateUnknown: stateStr = @"Unknown"; break;
    }
    return NSLocalizedString( stateStr, @"Order State String" );
}

- (void)setStationName:(NSString *)newStationName
{
    if( newStationName != _stationName )
    {
        [_stationName release];
        _stationName = [newStationName retain];
    }
}

- (NSString *)stationName
{
    if( nil == _stationName )
    {
        CCPDatabase *db = [[GlobalData sharedInstance] database];
        NSDictionary *station = [db stationForID:stationID];
        [self setStationName:[station objectForKey:@"name"]];
    }
    return _stationName;
}

@end
