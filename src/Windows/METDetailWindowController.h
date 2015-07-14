//
//  METDetailWindowController.h
//  Vitality
//
//  Created by Andrew Salamon on 6/22/15.
//  Copyright (c) 2015 Sebastian Kruemling. All rights reserved.
//

#import <Foundation/Foundation.h>

@class CCPType;
@class Character;

@interface METDetailWindowController : NSObject
+ (id)displayDetailsOfType:(CCPType*)type forCharacter:(Character*)ch;
@end
