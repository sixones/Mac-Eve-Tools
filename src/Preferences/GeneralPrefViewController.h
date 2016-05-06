//
//  GeneralViewController.h
//  Mac Eve Tools
//
//  Created by Sebastian Kruemling on 17.06.10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "MBPreferencesController.h"
#import "MainController.h"

@interface GeneralPrefViewController : NSViewController <MBPreferencesModule> {
    MainController* _mainController;
}

- (NSString *)title;
- (NSString *)identifier;
- (NSImage *)image;

- (GeneralPrefViewController *) initWithNibNameAndController: (NSString*) nibName bundle: (NSBundle*) bundle controller: (MainController *) mainController;

- (IBAction) sendStatisticsChanged: (NSButton*) sender;
- (IBAction) sendMenuBarChanged: (NSButton*) sender;


@end
