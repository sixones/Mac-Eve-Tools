//
//  VitalityMail.m
//  VitalityMail
//
//  Created by Andrew Salamon on 10/8/14.
//  Copyright (c) 2014 Sebastian Kruemling. All rights reserved.
//

#import "VitalityMail.h"

#import "METMail.h"

@implementation VitalityMail

-(id) init
{
    if( (self = [super initWithNibName:@"MailView" bundle:nil]) )
    {
        mail = [[METMail alloc] init];
        [mail setDelegate:self];
    }
    
    return self;
}

- (void)dealloc
{
    [character release];
    [mail release];
    [super dealloc];
}

- (void)setCharacter:(Character *)_character
{
    if( _character != character )
    {
        [character release];
        character = [_character retain];
        [mail setCharacter:character];
        [mail reload:self];
        [app setToolbarMessage:NSLocalizedString(@"Getting Mail…",@"Getting Mail status line")];
        [app startLoadingAnimation];
    }
}


//called after the window has become active
-(void) viewIsActive
{
    
}

-(void) viewIsInactive
{
    
}

-(void) viewWillBeDeactivated
{
    
}

-(void) viewWillBeActivated
{
    [app setToolbarMessage:NSLocalizedString(@"Getting Mail…",@"Getting Mail status line")];
    [app startLoadingAnimation];
    [mail reload:self];
}

-(void) setInstance:(id<METInstance>)instance
{
    if( instance != app )
    {
        [app release];
        app = [instance retain];
    }
}

-(NSMenuItem*) menuItems
{
    return nil;
}

- (void)mailFinishedUpdating
{
//    NSArray *newDescriptors = [contractsTable sortDescriptors];
//    [contracts sortUsingDescriptors:newDescriptors];
//    [contractsTable reloadData];
    [app setToolbarMessage:NSLocalizedString(@"Finished Updating Mail…",@"Finished Updating Mail status line") time:5];
    [app stopLoadingAnimation];
}

- (void)mailSkippedUpdating
{
    [app setToolbarMessage:NSLocalizedString(@"Using Cached Mail…",@"Using Cached Mail status line") time:5];
    [app stopLoadingAnimation];
}


@end
