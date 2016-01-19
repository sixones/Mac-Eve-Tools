//
//  MTNotification.h
//  Vitality
//
//  Created by Andrew Salamon on 10/8/15.
//  Copyright (c) 2015 Sebastian Kruemling. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface MTNotification : NSObject
{
    NSInteger notificationID;
    NSInteger typeID;
    NSInteger senderID;
    NSDate *sentDate;
    BOOL read;
    NSString *body;
}

@property (readwrite,assign) NSInteger notificationID;
@property (readwrite,assign) NSInteger typeID;
@property (readwrite,assign) NSInteger senderID;
@property (readwrite,retain) NSDate *sentDate;
@property (readwrite,assign) BOOL read;
@property (readwrite,retain) NSString *body;

+ (MTNotification *)notificationWithID:(NSInteger)notID typeID:(NSInteger)tID sender:(NSInteger)senderID sentDate:(NSDate *)sentDate read:(BOOL)read;

- (NSString *)notificationTypeDescription;
- (NSString *)tickerDescription; ///< Type Description and date
@end
