//
//  METJumpCloneController.m
//  Vitality
//
//  Created by Andrew Salamon on 5/6/15.
//  Copyright (c) 2015 Sebastian Kruemling. All rights reserved.
//

#import "METJumpCloneController.h"
#import "Character.h"
#import "METJumpClone.h"
#import "CCPImplant.h"

@interface METJumpCloneController ()
@property (retain,readwrite) NSArray *jumpClones;
@end

@implementation METJumpCloneController

@synthesize character = _character;
@synthesize jumpClones = _jumpClones;

+(void) displayWindowForCharacter:(Character*)ch
{
    // Suppress the clang analyzer warning. There's probably a better way to do this
#ifndef __clang_analyzer__
    METJumpCloneController *wc = [[METJumpCloneController alloc] initWithCharacter:ch];
    
    [[wc window] makeKeyAndOrderFront:nil];
#endif
}

- (id) initWithCharacter:(Character *)_char
{
    if( self = [super initWithWindowNibName:@"METJumpClone"] )
    {
        _character = [_char retain];
        _jumpClones = [[[_char jumpClones] allValues] retain];
    }
    return self;
}

- (void)dealloc
{
    [_character release];
    [_jumpClones release];
    [super dealloc];
}

- (void)windowDidLoad
{
    [super windowDidLoad];
    
    // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
    [[self window] setTitle:[NSString stringWithFormat:@"%@: Jump Clones",[[self character] characterName]]];
    [portrait setImage:[[self character] portrait]];
    [characterName setStringValue:[[self character] characterName]];
    
    NSDate *nextJump = [[self character] jumpCloneDate];
//    if( nextJump == [nextJump earlierDate:[NSDate date]] )
//    {
//        [nextJumpDate setStringValue:NSLocalizedString( @"Now", @"'Now' in reference to clone jump availability" )];
//    }
//    else
    {
        [nextJumpDate setObjectValue:nextJump];
    }
}

-(NSInteger)outlineView:(NSOutlineView *)outlineView numberOfChildrenOfItem:(id)item
{
    if( item == nil )
    {
        return [[self jumpClones] count];
    }
    
    return [[(METJumpClone *)item implants] count];
}

- (id)outlineView:(NSOutlineView *)outlineView
            child:(NSInteger)index
           ofItem:(id)item
{
    if( item == nil )
    {
        return [[self jumpClones] objectAtIndex:index];
    }
    
    NSArray *ary = [(METJumpClone *)item implants];
    return [ary objectAtIndex:index];
}

- (id)outlineView:(NSOutlineView *)outlineView
objectValueForTableColumn:(NSTableColumn *)tableColumn
           byItem:(id)item
{
    if( [item isKindOfClass:[METJumpClone class]] )
    {
        if( [[tableColumn identifier] isEqualToString:@"LOCATION_NAME"] )
        {
            return [(METJumpClone *)item locationName];
        }
        else if( [[tableColumn identifier] isEqualToString:@"CLONE_NAME"] )
        {
            return [(METJumpClone *)item cloneName];
        }
    }
    
    if( [item isKindOfClass:[CCPImplant class]] )
    {
        if( [[tableColumn identifier]isEqualToString:@"LOCATION_NAME"] )
        {
            return [(CCPImplant *)item typeName];
        }
    }
    return nil;
}

- (BOOL)outlineView:(NSOutlineView *)outlineView 
   isItemExpandable:(id)item
{
    if( [item isKindOfClass:[METJumpClone class]]
       && ([[(METJumpClone *)item implants] count] > 0) )
    {
        return YES;
    }
    return NO;
}

- (BOOL)outlineView:(NSOutlineView *)outlineView shouldEditTableColumn:(NSTableColumn *)tableColumn item:(id)item
{
    return NO;
}

@end
