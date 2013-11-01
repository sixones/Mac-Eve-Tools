//
//  MetLabelValueTableCellView.h
//  Vitality
//
//  Created by Andrew Salamon on 11/1/13.
//  Copyright (c) 2013 Sebastian Kruemling. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface MetLabelValueTableCellView : NSTableCellView
{
@private
    IBOutlet NSTextField *labelTextField;
    IBOutlet NSTextField *valueTextField;
}

@property(assign) NSTextField *labelTextField;
@property(assign) NSTextField *valueTextField;

@end
