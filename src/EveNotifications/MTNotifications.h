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
    
    NSMutableArray *notifications;
}

@property (readonly,retain) NSDate *cachedUntil;

@end

