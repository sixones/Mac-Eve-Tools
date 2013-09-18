//
//  Contract.h
//  Mac Eve Tools
//
//  Created by Andrew Salamon on 8/21/13.
//  Copyright (c) 2013 Andrew Salamon. All rights reserved.
//

#import <Foundation/Foundation.h>


/*
 <rowset name="contractList" key="contractID" 
columns="contractID
issuerID
issuerCorpID
assigneeID
acceptorID
startStationID
endStationID
type
status
title
forCorp
availability
dateIssued
dateExpired
dateAccepted
numDays
dateCompleted
price
reward
collateral
buyout
volume">
 <row contractID="72716865" issuerID="91794908" issuerCorpID="1406664155" assigneeID="98159347" acceptorID="0" startStationID="60004588" endStationID="61000617" type="Courier" status="Outstanding" title="" forCorp="0" availability="Private" dateIssued="2013-09-15 14:59:52" dateExpired="2013-09-29 14:59:52" dateAccepted="" numDays="7" dateCompleted="" price="0.00" reward="14905500.00" collateral="0.00" buyout="0.00" volume="59622.4475" />
*/

@interface Contract : NSObject

@property (retain) NSString *type;
@property (retain) NSString *status;
@property (assign) NSUInteger contractID;
@property (assign) NSUInteger startStationID;
@property (assign) NSUInteger endStationID;

@property (assign) NSUInteger orderID;
@property (assign) NSUInteger charID;
@property (assign) NSUInteger volEntered;
@property (assign) NSUInteger volRemaining;
@property (assign) NSUInteger minVolume;
@property (assign) NSUInteger typeID;
@property (retain) NSString *range;
@property (assign) NSUInteger accountKey;
@property (assign) double price;
@property (assign) double escrow;
@property (assign) BOOL buy; // if false = sell order
@property (retain) NSDate *issued;

@property (readonly,retain) NSString *startStationName;
@property (readonly,retain) NSString *endStationName;
@end
