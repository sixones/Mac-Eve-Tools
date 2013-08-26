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

@property (retain) Character *character;
@property (retain) NSMutableArray *contracts;
@property (readonly,retain) NSString *xmlPath;
@property (readonly,retain) NSDate *cachedUntil;
@property (readwrite,assign) id delegate;

- (IBAction)reload:(id)sender;
- (void)sortUsingDescriptors:(NSArray *)descriptors;
@end
