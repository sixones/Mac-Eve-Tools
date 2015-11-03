//
//  Contracts.h
//  Mac Eve Tools
//
//  Created by Andrew Salamon on 5/17/13.
//  Copyright (c) 2013 Sebastian Kruemling. All rights reserved.
//

#import <Foundation/Foundation.h>

@class Character;
@class METRowsetEnumerator;

@interface Contracts : NSObject
{
    Character *_character;
    NSMutableArray *_contracts;
    METRowsetEnumerator *contractsAPI;
    id _delegate;
}

@property (retain) Character *character;
@property (retain) NSMutableArray *contracts;
@property (readwrite,assign) id delegate;

- (IBAction)reload:(id)sender;
- (void)sortUsingDescriptors:(NSArray *)descriptors;
- (void)requestContract:(NSNumber *)contractID;
@end
