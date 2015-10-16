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

@interface MTNotifications : NSViewController <METPluggableView,NSTableViewDataSource,METIDtoNameDelegate>
{
    Character *character;
    id<METInstance> app;
    METIDtoName *nameGetter;
    NSDate *cachedUntil;
    NSMutableData *xmlData;
    
    NSTimer *tickerTimer;
    NSUInteger nextNotification;
    
    NSMutableArray *notifications;
    
    IBOutlet NSTextField *tickerField;
}

@property (readonly,retain) NSDate *cachedUntil;
@property (readonly) NSArray *notifications;

+ (NSString *)newNotificationName; // name for the cocoa notification that we have new EVE notifications :)

- (IBAction)reload:(id)sender;
@end

