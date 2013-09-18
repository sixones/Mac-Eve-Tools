//
//  MarketOrder.m
//  Mac Eve Tools
//
//  Created by Andrew Salamon on 5/29/13.
//  Copyright (c) 2013 Sebastian Kruemling. All rights reserved.
//

#import "Contract.h"
#import "GlobalData.h"
#import "CCPType.h"
#import "CCPDatabase.h"

@interface Contract()
@property (readwrite) NSString *stationName;
@end

@implementation Contract

@synthesize type;
@synthesize status;
@synthesize contractID;
@synthesize startStationID;
@synthesize endStationID;

@synthesize startStationName = _startStationName;
@synthesize endStationName = _endStationName;

@synthesize orderID;
@synthesize charID;
@synthesize volEntered;
@synthesize volRemaining;
@synthesize minVolume;
@synthesize typeID;
@synthesize range;
@synthesize accountKey;
@synthesize price;
@synthesize escrow;
@synthesize buy;
@synthesize issued;

- (void)setStartStationName:(NSString *)newStationName
{
    if( newStationName != _startStationName )
    {
        [_startStationName release];
        _startStationName = [newStationName retain];
    }
}

- (NSString *)startStationName
{
    if( nil == _startStationName )
    {
        CCPDatabase *db = [[GlobalData sharedInstance] database];
        NSDictionary *station = [db stationForID:startStationID];
        [self setStartStationName:[station objectForKey:@"name"]];
    }
    return _startStationName;
}

- (void)setEndStationName:(NSString *)newStationName
{
    if( newStationName != _endStationName )
    {
        [_endStationName release];
        _endStationName = [newStationName retain];
    }
}

- (NSString *)endStationName
{
    if( nil == _endStationName )
    {
        CCPDatabase *db = [[GlobalData sharedInstance] database];
        NSDictionary *station = [db stationForID:endStationID];
        [self setEndStationName:[station objectForKey:@"name"]];
    }
    return _endStationName;
}

@end
