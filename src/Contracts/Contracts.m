//
//  Contracts.m
//  Mac Eve Tools
//
//  Created by Andrew Salamon on 5/17/13.
//  Copyright (c) 2013 Sebastian Kruemling. All rights reserved.
//

#import "Contracts.h"

#import "Character.h"
#import "macros.h"
#import "Contract.h"

#import "METRowsetEnumerator.h"
#import "METXmlNode.h"

@implementation Contracts

@synthesize contracts = _contracts;
@synthesize delegate = _delegate;

- (id)init
{
    if( self = [super init] )
    {
        _contracts = [[NSMutableArray alloc] init];
        contractsAPI = [[METRowsetEnumerator alloc] initWithCharacter:nil API:XMLAPI_CHAR_CONTRACTS forDelegate:self];
        singleContractAPI = [[METRowsetEnumerator alloc] initWithCharacter:nil API:XMLAPI_CHAR_CONTRACTS forDelegate:self];
    }
    return self;
}

- (void)dealloc
{
    [_contracts release];
    [contractsAPI release];
    [singleContractAPI release];
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
        [[self contracts] removeAllObjects];
        [contractsAPI setCharacter:character];
        [singleContractAPI setCharacter:character];
    }
}

- (void)sortUsingDescriptors:(NSArray *)descriptors
{
    [[self contracts] sortUsingDescriptors:descriptors];
}

- (IBAction)reload:(id)sender
{
    [contractsAPI run];
}

- (void)requestContract:(NSNumber *)contractID
{
    NSAssert( nil != contractID, @"Missing contract ID in [Contracts requestContract]" );
    [singleContractAPI runWithURLExtras:[NSString stringWithFormat:@"&contractID=%ld", (unsigned long)[contractID unsignedIntegerValue]]];
}

- (void)apiDidFinishLoading:(METRowsetEnumerator *)rowset withError:(NSError *)error
{
    if( error )
    {
        if( [error code] == METRowsetCached )
            NSLog( @"Skipping download of Contracts because of Cached Until date." ); // handle cachedUntil errors differently
        else if( [error code] == METRowsetMissingCharacter )
            ; // don't bother logging an error
        else
            NSLog( @"Error requesting Contracts: %@", [error localizedDescription] );
        // Turn off the spinning download indicator
        if( [[self delegate] respondsToSelector:@selector(contractsSkippedUpdating)] )
        {
            [[self delegate] performSelector:@selector(contractsSkippedUpdating)];
        }
        return;
    }
    
    NSArray *newContracts = [self contractsFromRowset:rowset];
    
    if( rowset == contractsAPI )
    {
        [[self contracts] removeAllObjects];
        [[self contracts] addObjectsFromArray:newContracts];
        
        if( [[self delegate] respondsToSelector:@selector(contractsFinishedUpdating:)] )
        {
            [[self delegate] performSelector:@selector(contractsFinishedUpdating:) withObject:[self contracts]];
        }
    }
    else if( rowset == singleContractAPI )
    {
        if( [[self delegate] respondsToSelector:@selector(contractFinishedUpdating:)] )
        {
            [[self delegate] performSelector:@selector(contractFinishedUpdating:) withObject:newContracts];
        }
    }
    else
    {
        NSLog( @"Invalid rowset in Contracts." );
    }
}


/* Sample xml for contracts:
 <?xml version='1.0' encoding='UTF-8'?>
 <eveapi version="2">
 <currentTime>2011-07-30 04:47:30</currentTime>
 <result>
 <rowset name="contractList" key="contractID" columns="contractID,issuerID,issuerCorpID,assigneeID,acceptorID,startStationID,endStationID,
 type,status,title,forCorp,dateIssued,dateExpired,dateAccepted,numDays,dateCompleted,price,reward,collateral,volume" />
 
 <row contractID="72716865" issuerID="91794908" issuerCorpID="1406664155" assigneeID="98159347" acceptorID="0" startStationID="60004588" endStationID="61000617" type="Courier" status="Outstanding" title="" forCorp="0" availability="Private" dateIssued="2013-09-15 14:59:52" dateExpired="2013-09-29 14:59:52" dateAccepted="" numDays="7" dateCompleted="" price="0.00" reward="14905500.00" collateral="0.00" buyout="0.00" volume="59622.4475" />

 </result>
 <cachedUntil>2011-07-30 05:44:30</cachedUntil>
 </eveapi>
 */
-(NSArray *) contractsFromRowset:(METRowsetEnumerator *)rowset
{
    NSMutableArray *localContracts = [NSMutableArray array];
    
    for( METXmlNode *row in rowset )
    {
        //  <row notificationID="304084087" typeID="16" senderID="797400947" sentDate="2010-04-12 12:32:00" read="0"/>
        NSDictionary *properties = [row properties];
        NSUInteger contractID = [[properties objectForKey:@"contractID"] integerValue];
        if( 0 != contractID )
        {
            Contract *contract = [[Contract alloc] init];
            [contract setCharacter:[self character]];
            [contract setContractID:contractID];
            [contract setIssued:[NSDate dateWithNaturalLanguageString:[properties objectForKey:@"dateIssued"]]];
            [contract setExpired:[NSDate dateWithNaturalLanguageString:[properties objectForKey:@"dateExpired"]]];
            [contract setAccepted:[NSDate dateWithNaturalLanguageString:[properties objectForKey:@"dateAccepted"]]];
            [contract setCompleted:[NSDate dateWithNaturalLanguageString:[properties objectForKey:@"dateCompleted"]]];
            [contract setType:[properties objectForKey:@"type"]];
            [contract setStatus:[properties objectForKey:@"status"]];
            [contract setStartStationID:[[properties objectForKey:@"startStationID"] integerValue]];
            [contract setEndStationID:[[properties objectForKey:@"endStationID"] integerValue]];
            [contract setVolume:[[properties objectForKey:@"volume"] doubleValue]];
            [contract setPrice:[[properties objectForKey:@"price"] doubleValue]];
            [contract setReward:[[properties objectForKey:@"reward"] doubleValue]];
            [contract setCollateral:[[properties objectForKey:@"collateral"] doubleValue]];
            [contract setBuyout:[[properties objectForKey:@"buyout"] doubleValue]];
            [contract setAvailability:[properties objectForKey:@"availability"]];
            [contract setTitle:[properties objectForKey:@"title"]];
            [contract setDays:[[properties objectForKey:@"numDays"] integerValue]];
            [contract setDays:[[properties objectForKey:@"forCorp"] integerValue]];
            [contract setIssuerID:[[properties objectForKey:@"issuerID"] integerValue]];
            [contract setIssuerCorpID:[[properties objectForKey:@"issuerCorpID"] integerValue]];
            [contract setAssigneeID:[[properties objectForKey:@"assigneeID"] integerValue]];
            [contract setAcceptorID:[[properties objectForKey:@"acceptorID"] integerValue]];
            [localContracts addObject:contract];
            [contract release];
        }
    }
    
    return localContracts;
}

@end
