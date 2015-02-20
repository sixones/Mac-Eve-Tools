//
//  METMailHeaderCell.m
//  Vitality
//
//  Created by Andrew Salamon on 2/4/15.
//  Copyright (c) 2015 Vitality Project. All rights reserved.
//

#import "METMailHeaderCell.h"
#import "METMailMessage.h"

@implementation METMailHeaderCell

@synthesize message;

-(NSRect) drawStringEndingAtPoint:(const NSPoint*)endPoint text:(NSAttributedString*)text
{
    NSSize textSize = [text size];
    //NSPoint startPoint = NSMakePoint(endPoint->x - textSize.width, endPoint->y);
    NSRect area = NSMakeRect(endPoint->x - textSize.width, endPoint->y, textSize.width, textSize.height);
    
    [text drawInRect:area];
    return area;
}

- (void)makeBold:(NSMutableAttributedString *)str
{
    [str beginEditing];
    [str applyFontTraits:NSBoldFontMask
                   range:NSMakeRange(0, [str length])];
    [str endEditing];
}

- (void)drawWithFrame:(NSRect)cellFrame inView:(NSView *)controlView
{
    NSString *from = [[self message] senderName];
    NSMutableAttributedString *astr = [[[NSMutableAttributedString alloc] initWithString:from] autorelease];
    if( ![[self message] read] )
        [self makeBold:astr];
    [astr drawInRect:cellFrame];
    
    NSPoint right = NSMakePoint(NSMaxX(cellFrame),NSMinY(cellFrame));
    NSString *date = [NSDateFormatter localizedStringFromDate:[[self message] sentDate] dateStyle:NSDateFormatterShortStyle timeStyle:NSDateFormatterShortStyle];
    astr = [[[NSMutableAttributedString alloc] initWithString:date] autorelease];
    [self drawStringEndingAtPoint:&right text:astr];

    astr = [[[NSMutableAttributedString alloc] initWithString:[[self message] subject]] autorelease];
    if( ![[self message] read] )
        [self makeBold:astr];
    cellFrame.origin.x += 32;
    cellFrame.origin.y += [astr size].height;
    cellFrame.size.width -= 32;
    cellFrame.size.height -= [astr size].height;
    NSStringDrawingOptions opts = NSStringDrawingTruncatesLastVisibleLine | NSStringDrawingUsesLineFragmentOrigin;
    [astr drawWithRect:cellFrame options:opts];
}
@end
