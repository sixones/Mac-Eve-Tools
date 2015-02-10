//
//  METMailHeaderCell.h
//  Vitality
//
//  Created by Andrew Salamon on 2/4/15.
//  Copyright (c) 2015 Sebastian Kruemling. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class METMailMessage;

@interface METMailHeaderCell : NSCell
{
    METMailMessage *message;
}

@property (readwrite,retain) METMailMessage *message;
@end
