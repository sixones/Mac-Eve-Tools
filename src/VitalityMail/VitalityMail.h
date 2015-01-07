//
//  VitalityMail.h
//  VitalityMail
//
//  Created by Andrew Salamon on 10/8/14.
//  Copyright (c) 2014 Sebastian Kruemling. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "METPluggableView.h"

@class Character;
@class METInstance;
@class METMail;

@interface VitalityMail : NSViewController <METPluggableView,NSTableViewDataSource>
{
    Character *character;
    id<METInstance> app;
    
    METMail *mail;
}

- (BOOL)saveMailMessages:(NSArray *)messages;

@end
