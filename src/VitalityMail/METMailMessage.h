//
//  Contract.h
//  Mac Eve Tools
//
//  Created by Andrew Salamon on 8/21/13.
//  Copyright (c) 2013 Andrew Salamon. All rights reserved.
//

#import <Foundation/Foundation.h>

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

@interface METMailMessage : NSObject
{
@private
    Character *character;
    id<MailMessageDelegate> delegate;

    NSUInteger messageID;
    NSUInteger senderID;
    NSString *senderName;
    NSDate *sentDate;
    NSString *subject;
    NSString *body;
    NSUInteger toCorpOrAllianceID;
    NSUInteger senderTypeID;
    NSArray *toCharacterIDs;
    NSUInteger toListID;
    BOOL read;
}

@property (retain) Character *character;
@property (readwrite,assign) id<MailMessageDelegate> delegate;

@property (assign) NSUInteger messageID;
@property (assign) NSUInteger senderID;
@property (readwrite,retain) NSString *senderName;
@property (retain) NSDate *sentDate;
@property (readwrite,retain) NSString *subject;
@property (assign) NSUInteger toCorpOrAllianceID;
@property (assign) NSUInteger senderTypeID;
@property (readwrite,retain) NSArray *toCharacterIDs;
@property (assign) NSUInteger toListID;
@property (readwrite,retain) NSString *body;
@property (assign) BOOL read;

- (NSString *)toDisplayName; ///< A string version of the 'To' field, suitable for display

- (NSSet *)allIDs; ///< NSNumbers for all ID's in the message: from, toCharacterIDs, etc

-(NSComparisonResult) compareByDate:(METMailMessage *)rhs;
@end
