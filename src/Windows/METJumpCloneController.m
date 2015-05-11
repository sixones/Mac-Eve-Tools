//
//  METJumpCloneController.m
//  Vitality
//
//  Created by Andrew Salamon on 5/6/15.
//  Copyright (c) 2015 Sebastian Kruemling. All rights reserved.
//

#import "METJumpCloneController.h"
#import "GlobalData.h"
#import "Character.h"
#import "METJumpClone.h"
#import "CCPImplant.h"
#import "Skill.h"
#import "SkillTree.h"
#import "Helpers.h"

@interface METJumpCloneController ()
@property (retain,readwrite) NSArray *jumpClones;
@property (retain,readwrite) NSTimer *jumpDateTimer;
@end

@implementation METJumpCloneController

@synthesize character = _character;
@synthesize jumpClones = _jumpClones;
@synthesize jumpDateTimer = _jumpDateTimer;

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
    [_jumpDateTimer invalidate];
    [_jumpDateTimer release];
    [super dealloc];
}

// Handle any initialization after window has been loaded from its nib file.
- (void)windowDidLoad
{
    [super windowDidLoad];
    
    [[self window] setTitle:[NSString stringWithFormat:@"%@: Jump Clones",[[self character] characterName]]];
    [portrait setImage:[[self character] portrait]];
    [self updateMaxJumpClonesField];
    [self updateJumpDelayField];
    [self updateNextJumpCloneDateField:nil];
}

- (void)windowWillClose:(NSNotification *)notification
{
    [self autorelease];
}

static const NSInteger infomorphPsychologyID = 24242;
static const NSInteger advancedInfomorphPsychologyID = 33407;
static const NSInteger infomorphSynchronizingID = 33399;

- (void)updateMaxJumpClonesField
{
    SkillTree *globalSkills = [[GlobalData sharedInstance] skillTree];
    SkillTree *skillTree = [[self character] skillTree];
    Skill *infomorphPsychology = [skillTree skillForIdInteger:infomorphPsychologyID];
    Skill *advanced = [skillTree skillForIdInteger:advancedInfomorphPsychologyID];
    [maxClones setObjectValue:[NSNumber numberWithInteger:([infomorphPsychology skillLevel] + [advanced skillLevel])]];
    
    NSString *name1 = infomorphPsychology?[infomorphPsychology skillName]:[[globalSkills skillForIdInteger:infomorphPsychologyID] skillName];
    NSString *name2 = advanced?[advanced skillName]:[[globalSkills skillForIdInteger:advancedInfomorphPsychologyID] skillName];
    NSString *desc = [NSString stringWithFormat:@"%@ %@\n%@ %@", name1, romanForInteger([infomorphPsychology skillLevel]),
                      name2, romanForInteger([advanced skillLevel])];
    [maxClones setToolTip:desc];
}

- (void)updateJumpDelayField
{
    SkillTree *globalSkills = [[GlobalData sharedInstance] skillTree];
    SkillTree *skillTree = [[self character] skillTree];
    Skill *infomorphSync = [skillTree skillForIdInteger:infomorphSynchronizingID];

    [jumpDelay setStringValue:[NSString stringWithFormat:@"%d %@", (24 - (int)[infomorphSync skillLevel]), NSLocalizedString( @"hours", @"Jump clone delay units" )]];
    
    NSString *name1 = infomorphSync?[infomorphSync skillName]:[[globalSkills skillForIdInteger:infomorphSynchronizingID] skillName];
    NSString *desc = [NSString stringWithFormat:@"%@ %@", name1, romanForInteger([infomorphSync skillLevel])];
    [jumpDelay setToolTip:desc];
}

- (void)updateNextJumpCloneDateField:(NSTimer *)timer
{
    NSDate *jumpDate = [[self character] jumpCloneDate]; // date-time of last clone jump
    SkillTree *skillTree = [[self character] skillTree];
    Skill *informorphSynchronizing = [skillTree skillForIdInteger:infomorphSynchronizingID]; // [skillTree skillForName:@"Infomorph Synchronizing"];
    
    // add 24 hours to last clone jump date, then subtract 1 hour per level of Infomorph Synchronizing
    jumpDate = [jumpDate dateByAddingTimeInterval:SEC_DAY-([informorphSynchronizing skillLevel]*SEC_HOUR)];
    
    [[self jumpDateTimer] invalidate];

    if( jumpDate == [jumpDate earlierDate:[NSDate date]] )
    {
        [nextJumpDate setStringValue:NSLocalizedString( @"Now", @"'Now' in reference to clone jump availability" )];
    }
    else
    {
        [nextJumpDate setObjectValue:jumpDate];
        [self setJumpDateTimer:[NSTimer scheduledTimerWithTimeInterval:[jumpDate timeIntervalSinceNow] target:self selector:@selector(updateNextJumpCloneDateField:) userInfo:nil repeats:NO]];
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
