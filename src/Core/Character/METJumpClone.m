//
//  METJumpClone.m
//  Vitality
//
//  Created by Andrew Salamon on 5/5/15.
//  Copyright (c) 2015 Sebastian Kruemling. All rights reserved.
//

#import "METJumpClone.h"
#import "GlobalData.h"
#import "CCPDatabase.h"

@implementation METJumpClone
@synthesize jumpCloneID = _jumpCloneID;
@synthesize typeID = _typeID;
@synthesize locationID = _locationID;
@synthesize cloneName = _cloneName;

- (id)initWithID:(NSInteger)_id
{
    if( self = [super init] )
    {
        _jumpCloneID = _id;
        _implants = [[NSMutableArray alloc] init];
    }
    return self;
}

- (void)dealloc
{
    [_implants release];
    [_cloneName release];
    [_locationName release];
    [super dealloc];
}

- (void)addImplant:(CCPImplant *)implant
{
    [_implants addObject:implant];
}

- (NSArray *)implants
{
    return [[_implants retain] autorelease];
}

- (NSString *)locationName
{
    if( !_locationName )
    {
        CCPDatabase *db = [[GlobalData sharedInstance] database];
        NSDictionary *station = [db stationForID:[self locationID]];
        _locationName = [[station objectForKey:@"name"] retain];
    }
    return [[_locationName retain] autorelease];
}
@end
