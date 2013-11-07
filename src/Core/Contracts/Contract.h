//
//  Contract.h
//  Mac Eve Tools
//
//  Created by Andrew Salamon on 8/21/13.
//  Copyright (c) 2013 Andrew Salamon. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "METIDtoName.h"

@protocol ContractDelegate<NSObject>
- (void)contractItemsFinishedUpdating;
- (void)contractNamesFinishedUpdating;
@end

@class Character;
@class METIDtoName;

@interface Contract : NSObject<METIDtoNameDelegate>
{
@private
    METIDtoName *nameFetcher;
}

@property (retain) Character *character;
@property (readonly,retain) NSString *xmlPath;
@property (readwrite,assign) id<ContractDelegate> delegate;

@property (retain) NSString *type;
@property (retain) NSString *status;
@property (assign) NSUInteger contractID;
@property (assign) NSUInteger startStationID;
@property (assign) NSUInteger endStationID;
@property (assign) double volume;
@property (assign) double price; // I will pay...
@property (assign) double reward; // I will receive...
@property (assign) double collateral;
@property (assign) double buyout;

@property (assign) NSUInteger issuerID;
@property (assign) NSUInteger issuerCorpID;
@property (assign) NSUInteger assigneeID;
@property (assign) NSUInteger acceptorID;
@property (readonly,retain) NSString *issuerName;
@property (readonly,retain) NSString *issuerCorpName;
@property (readonly,retain) NSString *assigneeName;
@property (readonly,retain) NSString *acceptorName;

@property (retain) NSDate *issued;
@property (retain) NSDate *expired;
@property (retain) NSDate *accepted;
@property (retain) NSDate *completed;
@property (retain) NSString *availability;
@property (retain) NSString *title;
@property (assign) NSUInteger days;
@property (assign) BOOL forCorp;

@property (readonly,retain) NSString *startStationName;
@property (readonly,retain) NSString *endStationName;

@property (readonly,retain) NSDate *cachedUntil; // For contained items, not the contract itself
@property (readonly,retain) NSMutableArray *items;

// If we haven't downloaded any items, or the cachedUntil time has passed, then download and store contract items
- (void)preloadItems;

// Get names associated with IDs in this contract
- (void)preloadNames;
@end
