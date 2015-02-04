//
//  VitalityMail.h
//  VitalityMail
//
//  Created by Andrew Salamon on 10/8/14.
//  Copyright (c) 2014 Sebastian Kruemling. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "METPluggableView.h"
#import "METIDtoName.h"

@class Character;
@class METInstance;
@class METMail;

@interface VitalityMail : NSViewController <METPluggableView,NSTableViewDataSource,NSOutlineViewDataSource,METIDtoNameDelegate>
{
    Character *character;
    id<METInstance> app;
    METIDtoName *nameGetter;
    
    METMail *mail;
    
    NSMutableDictionary *namesByID;
    NSMutableArray *mailboxPairs;
    
    IBOutlet NSOutlineView *mailboxView;
}

- (BOOL)saveMailMessages:(NSArray *)messages; // Insert each message into the database
- (BOOL)saveMailBodies:(NSArray *)messages; // This will update each row in the database with the message body

@end
