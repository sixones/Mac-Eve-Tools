//
//  MTNotificationCellView.h
//  Vitality
//
//  Created by Andrew Salamon on 1/21/16.
//  Copyright (c) 2016 Sebastian Kruemling. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class MTNotification;

@interface MTNotificationCellView : NSTableCellView
{
    MTNotification *_notification;
    
    IBOutlet NSView *view;
    IBOutlet NSTextField *dateField;
    IBOutlet NSTextField *typeField;
    IBOutlet NSTextField *bodyView;
}
@property (readwrite,retain) MTNotification *notification;

@end
