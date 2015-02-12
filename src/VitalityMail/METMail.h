//
//  METMail.h
//  Vitality
//
//  Created by Andrew Salamon on Dec 8, 2014.
//  Copyright (c) 2014 Vitality Project. All rights reserved.
//

#import <Foundation/Foundation.h>

@class Character;

@interface METMail : NSObject
{
    Character *_character;
    NSMutableArray *messages;
    NSMutableDictionary *messagesByID;
    NSString *xmlPath;
    NSDate *cachedUntil;
    id delegate;
}

@property (retain) Character *character;
@property (readonly,retain) NSString *xmlPath;
@property (readonly,retain) NSDate *cachedUntil;
@property (readwrite,assign) id delegate;

- (NSArray *)messages;

- (IBAction)reload:(id)sender;
- (void)sortUsingDescriptors:(NSArray *)descriptors;

- (void)loadMailingListNames;
@end
