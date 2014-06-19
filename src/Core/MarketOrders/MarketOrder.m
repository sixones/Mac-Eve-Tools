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
    CCPDatabase *db = [[GlobalData sharedInstance] database];
    CCPType *type = [db type:self.typeID];
    if( !type || ![type typeName] )
    {
        NSString *typeName = [db typeName:self.typeID];
        if( typeName )
            return typeName;
        NSLog( @"Missing type name in a market order" );
    }
    return [type typeName];
}

- (NSString *)state
{
    switch( self.orderState )
    {
        case OrderStateActive: return NSLocalizedString( @"Open", @"Order State Open String" ); break;
        case OrderStateClosed: return NSLocalizedString( @"Closed", @"Order State Closed String" ); break;
        case OrderStateExpired: return NSLocalizedString( @"Expired", @"Order State Expired String" ); break;
        case OrderStateCancelled: return NSLocalizedString( @"Cancelled", @"Order State Cancelled String" ); break;
        case OrderStatePending: return NSLocalizedString( @"Pending", @"Order State Pending String" ); break;
        case OrderStateCharacterDeleted: return NSLocalizedString( @"Char Deleted", @"Order State Char Deleted String" ); break;
        case OrderStateUnknown: return NSLocalizedString( @"Unknown", @"Order State Unknown String" ); break;
    }
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

- (double)totalValue
{
    return self.volEntered * self.price;
}

- (double)remainingValue
{
    return self.volRemaining * self.price;
}

@end
