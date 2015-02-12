//
//  METMessageViewController.h
//  Vitality
//
//  Created by Andrew Salamon on 2/12/15.
//  Copyright (c) 2015 Sebastian Kruemling. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class METMailMessage;

@interface METMessageViewController : NSViewController
{
    METMailMessage *message;
    
    IBOutlet NSTextField *from;
    IBOutlet NSTextField *to;
    IBOutlet NSTextField *sentDate;
    IBOutlet NSTextField *subject;
    IBOutlet NSTextView *body;
}

@property (retain,readwrite) METMailMessage *message;
@end
