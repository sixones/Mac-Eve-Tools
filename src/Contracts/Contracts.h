//
//  Contracts.h
//  Mac Eve Tools
//
//  Created by Andrew Salamon on 5/17/13.
//  Copyright (c) 2013 Sebastian Kruemling. All rights reserved.
//

#import <Foundation/Foundation.h>

@class Character;

@interface Contracts : NSObject
{
    Character *_character;
    NSMutableArray *_contracts;
    NSString *_xmlPath;
    NSDate *_cachedUntil;
    id _delegate;
}

@property (retain) Character *character;
@property (retain) NSMutableArray *contracts;
@property (readonly,retain) NSString *xmlPath;
@property (readonly,retain) NSDate *cachedUntil;
@property (readwrite,assign) id delegate;

- (IBAction)reload:(id)sender;
- (void)sortUsingDescriptors:(NSArray *)descriptors;
- (void)requestContract:(NSNumber *)contractID;
@end
