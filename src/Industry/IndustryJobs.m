//
//  IndustryJobs.m
//  Vitality
//
//  Created by Andrew Salamon on 5/16/2016.
//  Copyright (c) 2016 The Vitality Project. All rights reserved.
//

#import "IndustryJobs.h"

#import "Config.h"
#import "GlobalData.h"
#import "XmlHelpers.h"
#import "Character.h"
#import "CharacterTemplate.h"
#import "IndustryJob.h"

#import "METRowsetEnumerator.h"
#import "METXmlNode.h"

#include <assert.h>

static NSString *XMLAPI_CHAR_INDUSTRYJOBS = @"/char/IndustryJobs.xml.aspx";
static NSString *XMLAPI_CHAR_INDUSTRYHISTORY = @"/char/IndustryJobsHistory.xml.aspx";

@interface IndustryJobs()
@end

@implementation IndustryJobs

@synthesize character = _character;
@synthesize jobs = _jobs;
@synthesize delegate = _delegate;

- (id)init
{
    if( self = [super init] )
    {
        _jobs = [[NSMutableArray alloc] init];
        industryJobsAPI = [[METRowsetEnumerator alloc] initWithCharacter:nil API:XMLAPI_CHAR_INDUSTRYJOBS forDelegate:self];
        industryHistoryAPI = [[METRowsetEnumerator alloc] initWithCharacter:nil API:XMLAPI_CHAR_INDUSTRYHISTORY forDelegate:self];
    }
    return self;
}

- (void)dealloc
{
    [_jobs release];
    [industryJobsAPI release];
    [industryHistoryAPI release];
    [super dealloc];
}

- (Character *)character
{
    return [[_character retain] autorelease];
}

- (void)setCharacter:(Character *)character
{
    if( _character != character )
    {
        [_character release];
        _character = [character retain];
        [[self jobs] removeAllObjects];
        [industryJobsAPI cancel];
        [industryJobsAPI setCharacter:character];
        [industryHistoryAPI cancel];
        [industryHistoryAPI setCharacter:character];
    }
}

- (void)sortUsingDescriptors:(NSArray *)descriptors
{
    [[self jobs] sortUsingDescriptors:descriptors];
}

- (IBAction)reload:(id)sender
{
    [industryJobsAPI run];
}

- (void)apiDidFinishLoading:(METRowsetEnumerator *)rowset withError:(NSError *)error
{
    if( error )
    {
        if( [error code] == METRowsetCached )
        {
            if( rowset == industryJobsAPI )
                NSLog( @"Skipping Industry Jobs because of Cached Until date." ); // handle cachedUntil errors differently
            else if( rowset == industryHistoryAPI )
                NSLog( @"Skipping Industry History because of Cached Until date." ); // handle cachedUntil errors differently
        }
        else if( [error code] == METRowsetMissingCharacter )
            ; // don't bother logging an error but maybe add an assert?
        else
            NSLog( @"Error requesting Industry Jobs: %@", [error localizedDescription] );
        
        if( [[self delegate] respondsToSelector:@selector(jobsSkippedUpdating)] )
        {
            [[self delegate] performSelector:@selector(jobsSkippedUpdating)];
        }
        
        if( (rowset != industryJobsAPI) && (rowset != industryHistoryAPI) )
            [rowset release];
        return;
    }
    
    //[[rowset xmlData] writeToFile:@"/tmp/jobs.xml" atomically:YES]; // for debugging only
    
    NSArray *newOrders = [self industryJobsFromRowset:rowset];
    
    if( (rowset == industryJobsAPI) || (rowset == industryHistoryAPI) )
    {
        [[self jobs] removeAllObjects];
        [[self jobs] addObjectsFromArray:newOrders];
        
        if( [[self delegate] respondsToSelector:@selector(jobsFinishedUpdating:)] )
        {
            [[self delegate] performSelector:@selector(jobsFinishedUpdating:) withObject:[self jobs]];
        }
        if( rowset == industryJobsAPI )
            [industryHistoryAPI run];
    }
    else
    {
        NSAssert(YES, @"Invalid industry job enumerator" );
    }
}


-(NSArray *) industryJobsFromRowset:(METRowsetEnumerator *)rowset
{
    NSMutableArray *localJobs = [NSMutableArray array];
    
    for( METXmlNode *row in rowset )
    {
        NSDictionary *properties = [row properties];
        NSUInteger jobID = [[properties objectForKey:@"jobID"] integerValue];
        if( 0 != jobID )
        {
            IndustryJob *job = [[[IndustryJob alloc] init] autorelease];
            [job setJobID:jobID];
            
            [job setInstallerID:[[properties objectForKey:@"installerID"] integerValue]];
            [job setInstallerName:[properties objectForKey:@"installerName"]];
            [job setFacilityID:[[properties objectForKey:@"facilityID"] integerValue]];
            [job setSolarSystemID:[[properties objectForKey:@"solarSystemID"] integerValue]];
            [job setSolarSystemName:[properties objectForKey:@"solarSystemName"]];
            [job setStationID:[[properties objectForKey:@"stationID"] integerValue]];
            [job setActivityID:[[properties objectForKey:@"activityID"] integerValue]];
            [job setBlueprintID:[[properties objectForKey:@"blueprintID"] integerValue]];
            [job setBlueprintTypeID:[[properties objectForKey:@"blueprintTypeID"] integerValue]];
            [job setBlueprintTypeName:[properties objectForKey:@"blueprintTypeName"]];
            [job setBlueprintLocationID:[[properties objectForKey:@"blueprintLocationID"] integerValue]];
            [job setOutputLocationID:[[properties objectForKey:@"outputLocationID"] integerValue]];
            [job setRuns:[[properties objectForKey:@"runs"] integerValue]];
            [job setCost:[[properties objectForKey:@"cost"] doubleValue]];
            [job setTeamID:[[properties objectForKey:@"teamID"] integerValue]];
            [job setLicensedRuns:[[properties objectForKey:@"licensedRuns"] integerValue]];
            [job setProbability:[[properties objectForKey:@"probability"] integerValue]];
            [job setProductTypeID:[[properties objectForKey:@"productTypeID"] integerValue]];
            [job setProductTypeName:[properties objectForKey:@"productTypeName"]];
            [job setStatus:[IndustryJob jobStatusFromInteger:[[properties objectForKey:@"status"] integerValue]]];
            [job setTimeInSeconds:[[properties objectForKey:@"timeInSeconds"] integerValue]];
            [job setStartDate:[NSDate dateWithNaturalLanguageString:[properties objectForKey:@"startDate"]]];
            [job setEndDate:[NSDate dateWithNaturalLanguageString:[properties objectForKey:@"endDate"]]];
            [job setPauseDate:[NSDate dateWithNaturalLanguageString:[properties objectForKey:@"pauseDate"]]];
            [job setCompletedCharacterID:[[properties objectForKey:@"completedCharacterID"] integerValue]];
            NSString *compDate = [properties objectForKey:@"completedDate"];
            if( [@"0001-01-01 00:00:00" isEqualToString:compDate] )
                [job setCompletedDate:nil];
            else
                [job setCompletedDate:[NSDate dateWithNaturalLanguageString:compDate]];

            [localJobs addObject:job];
        }
    }
    
    return localJobs;
}

@end
