//
//  METJumpCloneController.h
//  Vitality
//
//  Created by Andrew Salamon on 5/6/15.
//  Copyright (c) 2015 Sebastian Kruemling. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class Character;

@interface METJumpCloneController : NSWindowController
{
    Character *_character;
    NSArray *_jumpClones; //< We need this so we have a fixed order for the jump clones
    IBOutlet NSOutlineView *jumpCloneView;
    IBOutlet NSImageView *portrait;
    IBOutlet NSTextField *nextJumpDate;
    IBOutlet NSTextField *maxClones;
    IBOutlet NSTextField *jumpDelay;
    
    NSTimer *_jumpDateTimer;
}
@property (retain,readwrite) Character *character;
@property (retain,readonly) NSArray *jumpClones;

+(void) displayWindowForCharacter:(Character*)ch;

- (id) initWithCharacter:(Character *)_char;
@end
