//
//  Contract.h
//  Mac Eve Tools
//
//  Created by Andrew Salamon on 8/21/13.
//  Copyright (c) 2013 Andrew Salamon. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "METIDtoName.h"

/*
 <row
 messageID="343465359"
 senderID="1597400586"
 senderName="Ltd SpacePig"
 sentDate="2014-10-06 09:43:00"
 title="Important!  Read this"
 toCorpOrAllianceID="1147488332"
 toCharacterIDs=""
 toListID=""
 senderTypeID="1373"
 />
 */

@protocol MailMessageDelegate<NSObject>
- (void)mailMessageFinishedUpdating;
- (void)mailMessageNamesFinishedUpdating;
@end

@class Character;
@class METIDtoName;

@interface METMailMessage : NSObject<METIDtoNameDelegate>
{
@private
    METIDtoName *nameFetcher;
}

@property (retain) Character *character;
@property (readonly,retain) NSString *xmlPath;
@property (readwrite,assign) id<MailMessageDelegate> delegate;

@property (assign) NSUInteger messageID;
@property (assign) NSUInteger senderID;
@property (readwrite,retain) NSString *senderName;
@property (retain) NSDate *sentDate;
@property (readwrite,retain) NSString *subject;
@property (assign) NSUInteger toCropOrAllianceID;
@property (assign) NSUInteger senderTypeID;
@property (readonly,retain) NSArray *toCharacterIDs;
@property (assign) NSUInteger toListID;

@property (readonly,retain) NSDate *cachedUntil; // For contained items, not the contract itself

// If we haven't downloaded any items, or the cachedUntil time has passed, then download and store contract items
- (void)preloadItems;

// Get names associated with IDs in this contract
- (void)preloadNames;
@end
