//
//  IndustryJob.h
//  Vitality
//
//  Created by Andrew Salamon on 5/16/2016.
//  Copyright (c) 2016 Vitality Project. All rights reserved.
//

#import <Foundation/Foundation.h>

/*
 <row jobID="242407819"
 installerID="91794908"
 installerName="Bleyddyn apRhys"
 facilityID="60014927"
 solarSystemID="30004852"
 solarSystemName="DZ6-I5"
 stationID="60014927"
 activityID="1"
 blueprintID="1015050047654"
 blueprintTypeID="23528"
 blueprintTypeName="Drone Link Augmentor I Blueprint"
 blueprintLocationID="60014927"
 outputLocationID="60014927"
 runs="10"
 cost="7050.00"
 teamID="0"
 licensedRuns="60"
 probability="1"
 productTypeID="0"
 productTypeName=""
 status="1"
 timeInSeconds="19009"
 startDate="2014-10-11 21:14:40"
 endDate="2014-10-12 02:31:29"
 pauseDate="0001-01-01 00:00:00"
 completedDate="0001-01-01 00:00:00"
 completedCharacterID="0"
 />
 */

typedef enum {
    JobStatusActive = 1,
    JobStatusPaused = 2, // Facility Offline
    JobStatusReady = 3,
    JobStatusDelivered = 101,
    JobStatusCancelled = 102,
    JobStatusReverted = 103,
    JobStatusUnknown = -1
} JobStatusType;

@interface IndustryJob : NSObject
{
    NSInteger _jobID;
    NSInteger _installerID;
    NSString * _installerName;
    NSInteger _facilityID;
    NSInteger _solarSystemID;
    NSString * _solarSystemName;
    NSInteger _stationID;
    NSInteger _activityID;
    NSInteger _blueprintID;
    NSInteger _blueprintTypeID;
    NSString * _blueprintTypeName;
    NSInteger _blueprintLocationID;
    NSInteger _outputLocationID;
    NSInteger _runs;
    double _cost;
    NSInteger _teamID;
    NSInteger _licensedRuns;
    NSInteger _probability;
    NSInteger _productTypeID;
    NSString * _productTypeName;
    JobStatusType _status;
    NSInteger _timeInSeconds;
    NSDate * _startDate;
    NSDate * _endDate;
    NSDate * _pauseDate;
    NSDate * _completedDate;
    NSInteger _completedCharacterID;
    
    NSString *_stationName;
}
@property (assign) NSInteger jobID;
@property (assign) NSInteger installerID;
@property (retain) NSString * installerName;
@property (assign) NSInteger facilityID;
@property (assign) NSInteger solarSystemID;
@property (retain) NSString * solarSystemName;
@property (assign) NSInteger stationID;
@property (assign) NSInteger activityID;
@property (assign) NSInteger blueprintID;
@property (assign) NSInteger blueprintTypeID;
@property (retain) NSString * blueprintTypeName;
@property (assign) NSInteger blueprintLocationID;
@property (assign) NSInteger outputLocationID;
@property (assign) NSInteger runs;
@property (assign) double cost;
@property (assign) NSInteger teamID;
@property (assign) NSInteger licensedRuns;
@property (assign) NSInteger probability;
@property (assign) NSInteger productTypeID;
@property (retain) NSString * productTypeName;
@property (assign) JobStatusType status;
@property (assign) NSInteger timeInSeconds;
@property (retain) NSDate * startDate;
@property (retain) NSDate * endDate;
@property (retain) NSDate * pauseDate;
@property (retain) NSDate * completedDate;
@property (assign) NSInteger completedCharacterID;

@property (retain,readonly) NSString *stationName;

+ (JobStatusType)jobStatusFromInteger:(NSInteger)raw;

- (NSString *)typeName;
- (NSString *)jobStatus;


@end
