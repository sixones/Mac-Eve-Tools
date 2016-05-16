//
//  IndustryJob.m
//  Vitality
//
//  Created by Andrew Salamon on 5/16/2016.
//  Copyright (c) 2016 The Vitality Project. All rights reserved.
//

#import "IndustryJob.h"
#import "GlobalData.h"
#import "CCPType.h"
#import "CCPDatabase.h"

@interface IndustryJob()
@property (readwrite) NSString *stationName;
@end

@implementation IndustryJob

@synthesize jobID = _jobID;
@synthesize installerID = _installerID;
@synthesize installerName = _installerName;
@synthesize facilityID = _facilityID;
@synthesize solarSystemID = _solarSystemID;
@synthesize solarSystemName = _solarSystemName;
@synthesize stationID = _stationID;
@synthesize activityID = _activityID;
@synthesize blueprintID = _blueprintID;
@synthesize blueprintTypeID = _blueprintTypeID;
@synthesize blueprintTypeName = _blueprintTypeName;
@synthesize blueprintLocationID = _blueprintLocationID;
@synthesize outputLocationID = _outputLocationID;
@synthesize runs = _runs;
@synthesize cost = _cost;
@synthesize teamID = _teamID;
@synthesize licensedRuns = _licensedRuns;
@synthesize probability = _probability;
@synthesize productTypeID = _productTypeID;
@synthesize productTypeName = _productTypeName;
@synthesize status = _status;
@synthesize timeInSeconds = _timeInSeconds;
@synthesize startDate = _startDate;
@synthesize endDate = _endDate;
@synthesize pauseDate = _pauseDate;
@synthesize completedDate = _completedDate;
@synthesize completedCharacterID = _completedCharacterID;

- (NSString *)typeName
{
    CCPDatabase *db = [[GlobalData sharedInstance] database];
    CCPType *type = [db type:self.blueprintTypeID];
    if( !type || ![type typeName] )
    {
        NSString *typeName = [db typeName:self.blueprintTypeID];
        if( typeName )
            return typeName;
        NSLog( @"Missing type name in an industry job for type: %ld", (unsigned long)self.blueprintTypeID );
    }
    return [type typeName];
}

+ (JobStatusType)jobStatusFromInteger:(NSInteger)raw
{
    switch( raw )
    {
        case 1: return JobStatusActive; break;
        case 2: return JobStatusPaused; break;
        case 3: return JobStatusReady; break;
        case 101: return JobStatusDelivered; break;
        case 102: return JobStatusCancelled; break;
        case 103: return JobStatusReverted; break;
        default: return JobStatusUnknown; break;
    }
    return JobStatusUnknown;
}

- (NSString *)jobStatus
{
    switch( self.status )
    {
        case JobStatusActive: return NSLocalizedString( @"Active", @"Industry Job Active String" ); break;
        case JobStatusPaused: return NSLocalizedString( @"Paused", @"Industry Job Paused String" ); break;
        case JobStatusReady: return NSLocalizedString( @"Ready", @"Industry Job Ready String" ); break;
        case JobStatusDelivered: return NSLocalizedString( @"Delivered", @"Industry Job Delivered String" ); break;
        case JobStatusCancelled: return NSLocalizedString( @"Cancelled", @"Industry Job Cancelled String" ); break;
        case JobStatusReverted: return NSLocalizedString( @"Reverted", @"Industry Job Reverted String" ); break;
        case JobStatusUnknown: return NSLocalizedString( @"Unknown", @"Industry Job Unknown String" ); break;
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
        NSDictionary *station = [db stationForID:[self stationID]];
        [self setStationName:[station objectForKey:@"name"]];
    }
    return _stationName;
}


@end
