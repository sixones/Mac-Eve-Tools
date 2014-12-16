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

@property (retain) Character *character;
@property (retain) NSMutableArray *messages;
@property (readonly,retain) NSString *xmlPath;
@property (readonly,retain) NSDate *cachedUntil;
@property (readwrite,assign) id delegate;

- (IBAction)reload:(id)sender;
- (void)sortUsingDescriptors:(NSArray *)descriptors;
@end
