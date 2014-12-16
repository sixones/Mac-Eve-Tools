/*
 This file is part of Mac Eve Tools.
 
 Mac Eve Tools is free software: you can redistribute it and/or modify
 it under the terms of the GNU General Public License as published by
 the Free Software Foundation, either version 3 of the License, or
 (at your option) any later version.
 
 Mac Eve Tools is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 GNU General Public License for more details.
 
 You should have received a copy of the GNU General Public License
 along with Mac Eve Tools.  If not, see <http://www.gnu.org/licenses/>.
 
 Copyright Matt Tyson, 2009.
 Copyright Adam Livesley, 2013.
 */

#import <Cocoa/Cocoa.h>

#import "METPluggableView.h"
	//#import "PreferenceController.h"
#import "Character.h"
#import "DBManager.h"
#import "macros.h"
#import "METPluggableView.h"
#import "METInstance.h"

#import "StatusItemWindow.h"

@class ServerMonitor;
@class CharacterOverviewDatasource;
@class CharacterManager;

@interface MainController : NSWindowController 
	<DBManagerDelegate, NSWindowDelegate ,METInstance, NSApplicationDelegate>
{
	IBOutlet NSToolbar *toolbar;
	
	IBOutlet NSPanel *noCharsPanel;
	IBOutlet NSButton *noCharsButton;
	
		//PreferenceController *prefPanel;
	
	/*Character sheet on the toolbar*/
	IBOutlet NSPopUpButton *charButton;
	IBOutlet NSToolbarItem *charToolbarButton;
	IBOutlet NSToolbarItem *fetchCharButton;
	IBOutlet NSToolbarItem *charOverviewButton;
	IBOutlet NSToolbarItem *charSheetButton;
	IBOutlet NSToolbarItem *skillPlannerButton;
    IBOutlet NSToolbarItem *marketViewButton;
	IBOutlet NSProgressIndicator *loadingCycle;
	
	NSMutableArray *viewControllers; /*all the controllers we can display*/
	
	IBOutlet NSBox *viewBox;
	
	IBOutlet NSDrawer *overviewDrawer;
	IBOutlet NSTableView *overviewTableView;
	CharacterOverviewDatasource *overviewDatasource;
	
	IBOutlet NSToolbarItem *characterButton;
	IBOutlet NSToolbarItem *charPopupItem;
		
	/*Pointer to the view controller that is currently active*/
	id<METPluggableView> currentController;
	
	Character *currentCharacter;
		
	IBOutlet NSTextField *serverName;
	IBOutlet NSImageView *serverStatus;
	
	IBOutlet NSTextField *statusString;
	IBOutlet NSImageView *statusImage;
	NSTimer *statusMessageTimer;
	
	ServerMonitor *monitor;
	CharacterManager *characterManager;
    
    IBOutlet NSMenu *statusMenu;
    NSStatusItem *statusItem;
    
    StatusItemWindow *statusWindow;
    
    IBOutlet NSView *statusWindowView;
}

- (id) init;

- (IBAction) fetchCharButtonClick: (id) sender;
- (IBAction) charSelectorClick: (id) sender;
- (IBAction) showPrefPanel: (id) sender;
- (IBAction) viewSelectorClick: (id) sender;
- (IBAction) noCharsButtonClick: (id) sender;
- (IBAction) toolbarButtonClick: (id) sender;
- (IBAction) checkForUpdates: (id) sender;
- (IBAction) nextSkillPlan: (id) sender;
- (IBAction) prevSkillPlan: (id) sender;

- (void) openStatusWindowAt: (NSPoint) point;
- (void) closeStatusWindow;

- (void) enableStatusBar;
- (void) disableStatusBar;

@end
