//
//  GeneralViewController.m
//  Mac Eve Tools
//
//  Created by Sebastian Kruemling on 17.06.10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "GeneralPrefViewController.h"

#ifdef HAVE_SPARKLE
#import <Sparkle/Sparkle.h>
#endif

#import "MainController.h"


@implementation GeneralPrefViewController

- (GeneralPrefViewController *) initWithNibNameAndController: (NSString*) nibName bundle: (NSBundle*) bundle controller: (MainController *) mainController {
    if( self = [self initWithNibName: nibName bundle: bundle] )
    {
        _mainController = mainController;
    }
    
    return self;
}

- (NSString *)title
{
	return NSLocalizedString(@"General", @"General settings");
}

- (NSString *)identifier
{
	return @"GeneralPrefView";
}

- (NSImage *)image
{
	return [NSImage imageNamed:@"NSPreferencesGeneral"];
}

- (IBAction) sendStatisticsChanged:(NSButton *)sender {
#ifdef HAVE_SPARKLE
	[[SUUpdater sharedUpdater]setSendsSystemProfile:[sender state] == NSOnState];
#endif
}

- (IBAction) sendMenuBarChanged:(NSButton *)sender {
    if ([sender state] == NSOnState) {
        [_mainController enableStatusBar];
    } else {
        [_mainController disableStatusBar];
    }
}

@end