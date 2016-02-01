//
//  MTNotificationCellView.m
//  Vitality
//
//  Created by Andrew Salamon on 1/21/16.
//  Copyright (c) 2016 Sebastian Kruemling. All rights reserved.
//

#import "MTNotificationCellView.h"
#import "MTNotification.h"

@implementation MTNotificationCellView

- (void)dealloc
{
    [view release];
    [super dealloc];
}

- (void)setNotification:(MTNotification *)notification
{
    if( _notification != notification )
    {
        _notification = [notification retain];
        [dateField setObjectValue:[notification sentDate]];
        [typeField setStringValue:[notification notificationTypeDescription]];
        [bodyView setAttributedStringValue:[notification attributedBody]];
    }
}

- (MTNotification *)notification
{
    return [[_notification retain] autorelease];
}

- (void)drawRect:(NSRect)dirtyRect {
    [super drawRect:dirtyRect];
    
    // Drawing code here.
}

@end
