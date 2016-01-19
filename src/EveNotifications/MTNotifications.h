//
//  MTNotifications.h
//  Vitality
//
//  Created by Andrew Salamon on 10/8/15.
//  Copyright (c) 2015 Sebastian Kruemling. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "METPluggableView.h"
#import "METIDtoName.h"

@class Character;
@class METRowsetEnumerator;

/**
 TODO: Add an Info button (next to the reload button) that will open up a detail window with a table view of all notifications.
 */
@interface MTNotifications : NSViewController <METPluggableView,NSTableViewDataSource,METIDtoNameDelegate>
{
    Character *character;
    id<METInstance> app;
    METIDtoName *nameGetter;
    METRowsetEnumerator *apiGetter;
    METRowsetEnumerator *bodyGetter;
    
    NSTimer *tickerTimer;
    NSUInteger nextNotification;
    
    NSMutableArray *notifications;
    
    IBOutlet NSTextField *tickerField;
}

@property (readonly) NSArray *notifications;

+ (NSString *)newNotificationName; // name for the cocoa notification that we have new EVE notifications :)

- (IBAction)reload:(id)sender;
@end

