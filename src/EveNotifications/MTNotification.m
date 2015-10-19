//
//  MTNotification.m
//  Vitality
//
//  Created by Andrew Salamon on 10/8/15.
//  Copyright (c) 2015 Sebastian Kruemling. All rights reserved.
//

#import "MTNotification.h"

@implementation MTNotification

@synthesize notificationID;
@synthesize typeID;
@synthesize senderID;
@synthesize sentDate;
@synthesize read;

static NSDictionary *idNames = nil;

+ (void)initialize
{
    if( (nil == idNames) && (self == [MTNotification self]) )
    {
        idNames = [[NSDictionary dictionaryWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"NotificationTypeIDs" ofType:@"plist" inDirectory:nil]] retain];
    }
}

+ (MTNotification *)notificationWithID:(NSInteger)notID typeID:(NSInteger)tID sender:(NSInteger)senderID sentDate:(NSDate *)sentDate read:(BOOL)read
{
    MTNotification *note = [[MTNotification alloc] init];
    [note setNotificationID:notID];
    [note setTypeID:tID];
    [note setSenderID:senderID];
    [note setSentDate:sentDate];
    [note setRead:read];
    
    return [note autorelease];
}

- (NSString *)notificationTypeDescription
{
    NSString *desc = [idNames objectForKey:[[NSNumber numberWithInteger:[self typeID]] stringValue]];
    if( !desc )
        NSLog( @"Unknown EVE Notification typeID: %ld", (long)[self typeID] );
    return desc;
}

- (NSString *)tickerDescription
{
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDoesRelativeDateFormatting:YES];
    [formatter setDateStyle:NSDateFormatterShortStyle];
    return [NSString stringWithFormat:@"%@: %@", [formatter stringFromDate:[self sentDate]], [self notificationTypeDescription]];
}
@end
