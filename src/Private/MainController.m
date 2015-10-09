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
 */

#import "MainController.h"
#import "CharacterSheetController.h"
#import "MTCharacterOverviewCell.h"
#import "Config.h"
#import "GlobalData.h"
#import "CCPDatabase.h"
#import "Character.h"
#import "Account.h"
#import "SkillTree.h"
#import "Helpers.h"
#import "SkillPlanController.h"
#import "ServerMonitor.h"
#import "EvemonXmlPlanIO.h"
#import "SkillPlan.h"
#import "METPluggableView.h"
#import "CharacterManager.h"
#import "MarketViewController.h"
#import "ContractsViewController.h"
#import "VitalityMail.h"
#import "MTNotifications.h"
#import "METPair.h"

#import "GeneralPrefViewController.h"
#import "AccountPrefViewController.h"
#import "DatabasePrefViewController.h"

#import "CCPType.h"
#import "CCPGroup.h"
#import "METDetailWindowController.h"
#import "METFittingController.h"
#import "METFitting.h"
#import "METOrganizationController.h"

#import "METConquerableStations.h"

#import "StatusItemViewController.h"

#import "DBManager.h"

#ifdef HAVE_SPARKLE
#import <Sparkle/Sparkle.h>
#endif

#import "StatusItemView.h"

#pragma mark MainController

#define WINDOW_SAVE_NAME @"MainWindowSave"

@interface MainController (MainControllerPrivate)

-(void)prefWindowWillClose:(NSNotification *)notification;
-(void)updatePopupButton;

-(void) setAsActiveView:(id<METPluggableView>)mvc;

-(void) serverStatus:(ServerStatus)status;
-(void) serverPlayerCount:(NSInteger)playerCount;

-(void) setStatusImage:(StatusImageState)state;
-(void) statusMessage:(NSString*)message;
@end


@implementation MainController (MainControllerPrivate)

-(void) setStatusImage:(enum StatusImageState)state
{
	if(state != StatusHidden){
		[statusImage setHidden:NO];
		[statusImage setEnabled:YES];
	}
	
	switch (state) {
		case StatusHidden:
			[statusImage setHidden:YES];
			[statusImage setEnabled:NO];
			break;
		case StatusGreen:
			[statusImage setImage:[NSImage imageNamed:@"green.tiff"]];
			break;
		case StatusYellow:
			[statusImage setImage:[NSImage imageNamed:@"yellow.tiff"]];
			break;
		case StatusRed:
			[statusImage setImage:[NSImage imageNamed:@"red.tiff"]];
			break;
		case StatusGray:
			[statusImage setImage:[NSImage imageNamed:@"gray.tiff"]];
			break;
		default:
			break;
	}
}


-(void) statusMessage:(NSString*)message
{
	if(message == nil){
		[statusString setHidden:YES];
		return;
	}
	[statusString setHidden:NO];
	[statusString setStringValue:message];
	[statusString sizeToFit];
}

-(void) clearTimer:(NSTimer*)theTimer
{
	@synchronized(self)
	{
		/*timer is now invalidated*/
		statusMessageTimer = nil;
		[self statusMessage:nil];
		[self setStatusImage:StatusHidden];
	}
}

-(void) setStatusMessage:(NSString*)message 
			  imageState:(enum StatusImageState)state
					time:(NSInteger)seconds
{
	@synchronized(self)
	{
		if(statusMessageTimer != nil){
			[statusMessageTimer invalidate];
			statusMessageTimer = nil;
		}
	
		//if zero, display forever.
		if(seconds == 0){
			[self statusMessage:message];
			return;
		}
		
		[self setStatusImage:state];
		
		[self statusMessage:message];
		statusMessageTimer = [NSTimer timerWithTimeInterval:(NSTimeInterval)seconds
													 target:self
												   selector:@selector(clearTimer:)
												   userInfo:nil
													repeats:NO];
		[[NSRunLoop currentRunLoop]addTimer:statusMessageTimer forMode:NSDefaultRunLoopMode];
	}
}


-(void) serverStatus:(ServerStatus)status
{
	switch(status)
	{
		case ServerUp:
			[serverStatus setImage:[NSImage imageNamed:@"green.tiff"]];
			break;
		case ServerDown:
			[serverStatus setImage:[NSImage imageNamed:@"red.tiff"]];
			break;
		case ServerUnknown:
			[serverStatus setImage:[NSImage imageNamed:@"lightgray.tiff"]];
			break;
		case ServerStarting:
			[serverStatus setImage:[NSImage imageNamed:@"yellow.tiff"]];
			break;
	}
}

-(void) serverPlayerCount:(NSInteger)playerCount
{
	NSMutableString *str = [NSMutableString stringWithString:@"Tranquility"];
    
	if(playerCount > 0){        
        NSNumberFormatter *countFormatter = [[NSNumberFormatter alloc] init];
        [countFormatter setNumberStyle: NSNumberFormatterDecimalStyle];
        [countFormatter setMaximumFractionDigits: 0];
                
        [str appendFormat: @" (%@)", [countFormatter stringFromNumber: @(playerCount)] ];
        
        [countFormatter release];
	}
    
	[serverName setStringValue: str];
}

/*NSApplication delegate*/

- (BOOL)applicationShouldHandleReopen:(NSApplication *)theApplication 
					hasVisibleWindows:(BOOL)flag
{
	if (!flag)
	{
		[[self window] makeKeyAndOrderFront:self];
		[[self window] makeMainWindow];
	}
	
	return YES;
}

/*NSWindow delegate*/
-(BOOL) windowShouldClose:(id)window
{
	[window orderOut:self]; //Don't close the window, just hide it.
	return NO;
}

-(void) appWillTerminate:(NSNotification*)notification
{
	[monitor stopMonitoring];
	[[self window] saveFrameUsingName:WINDOW_SAVE_NAME];
    [[[MBPreferencesController sharedController] moduleForIdentifier:@"AccountPrefView"] willBeClosed];
	[[[MBPreferencesController sharedController] moduleForIdentifier:@"DatabasePrefView"] willBeClosed];

	[[NSNotificationCenter defaultCenter]removeObserver:self];
	
	xmlCleanupParser();
}


-(void) updatePopupButton
{
	NSArray *charArray = [characterManager allCharacters];
	[charButton removeAllItems];
	
	if([charArray count] > 0){
		[charButton setEnabled:YES];
		
		NSMenu *menu;
		menu = [[NSMenu alloc] initWithTitle:@""];
		//NSMenuItem *defaultItem = nil;
		
		for(Character *c in charArray){
			
			NSMenuItem *item = [[NSMenuItem alloc] initWithTitle:[c characterName] action:nil keyEquivalent:@""];
			[item setRepresentedObject:c];
			[menu addItem:item];
						
			[item release];
		}
		
		[charButton setMenu:menu];
		[menu release];

//		Select the default item.
//		[charButton selectItem:defaultItem];
		
	}else{
		//No characters enabled. disable the control.
		[charButton setEnabled:NO];
	}
}

/*reload the datasource with new characters*/
-(void) reloadAllCharacters
{
	//returns YES if the delegate will be called
	BOOL rc = [characterManager setTemplateArray:[[Config sharedInstance] activeCharacters] delegate:self];
	
	//reload the drawer datasource.
	if(!rc){
		//Characters are all on disk. delegaete will not be called.
		[overviewTableView reloadData];
		//Redo the popup button.
		[self updatePopupButton];
	}//else - work done in delegate
}


-(void) databaseFinishedBuilding:(NSNotification *)notification
{
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:NOTE_DATABASE_BUILD_COMPLETE
                                                  object:nil];
    [self launchAppFinal:nil];
}

/*called once the program has finished loading, but before the window appears.*/
-(void) appIsActive:(NSNotification*)notification
{
    /*event will not happen again, no need to listen for it*/
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:NSApplicationDidBecomeActiveNotification
                                                  object:NSApp];
    
    xmlInitParser(); //Init libxml2
    
    /* check to see if the current database is the right version,
     Download a new version if required.
     */
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(databaseFinishedBuilding:)
                                                 name:NOTE_DATABASE_BUILD_COMPLETE
                                               object:nil];
    [dbManager databaseCheckAndUpdate:NO];
}

/*
 Launch the application proper, display the window to the user.
 */
-(void) launchAppFinal:(id)obj
{	
	
	Config *cfg = [Config sharedInstance];
    
	////////////// ---- THIS BLOCK MUST EXECUTE BEFORE ANY OTHER CODE ---- \\\\\\\\\\\\\\\\
	[[GlobalData sharedInstance]skillTree];
	[[GlobalData sharedInstance]certTree];
	////////////// ---- BLOCK END ---- \\\\\\\\\\\\\\\\

	
	/*init the views that will be used by this window*/
	
	[[self window] makeKeyAndOrderFront:self];
	
	id<METPluggableView> mvc;
	mvc = [[CharacterSheetController alloc]init];
	[mvc view];//trigger the awakeFromNib
	[mvc setInstance:self];
	[viewControllers addObject:mvc];
	[(NSObject*)mvc release];
	
	/*
	 
	Menu Item for importing evemon plans.  This doesn't work properly yet and shouldn't be included.
	 
	id<METPluggableView> view = [viewControllers objectAtIndex:1];
	NSMenuItem *menuItem = [view menuItems];
	if(menuItem != nil){
		[[NSApp mainMenu]insertItem:menuItem atIndex:1];
	}
	*/
	
	/*because of the threading and preloading the skill planner will awake early*/

	
	mvc = [[SkillPlanController alloc]init];
	[mvc view];//trigger the awakeFromNib
	[mvc setInstance:self];
	[viewControllers addObject:mvc];
	[(NSObject*)mvc release];
	
    mvc = [[MarketViewController alloc] init];
    [mvc view];//trigger the awakeFromNib
    [mvc setInstance:self];
    [viewControllers addObject:mvc];
    [(NSObject*)mvc release];
    
    mvc = [[ContractsViewController alloc] init];
    [mvc view];//trigger the awakeFromNib
    [mvc setInstance:self];
    [viewControllers addObject:mvc];
    [(NSObject*)mvc release];

    mvc = [[VitalityMail alloc] init];
    [mvc view];//trigger the awakeFromNib
    [mvc setInstance:self];
    [viewControllers addObject:mvc];
    [mvc release];

	[[self window] makeMainWindow];
	[[self window] setDelegate:self];
	[(NSApplication *)NSApp setDelegate:self];
		
#ifdef HAVE_SPARKLE
	SUUpdater *updater = [SUUpdater sharedUpdater];
	[updater setAutomaticallyChecksForUpdates:NO];
	[updater setFeedURL:[NSURL URLWithString:[[NSUserDefaults standardUserDefaults] stringForKey:UD_UPDATE_FEED_URL]]];
	[updater setSendsSystemProfile:[[NSUserDefaults standardUserDefaults] boolForKey:UD_SUBMIT_STATS]];
    
    NSLog(@"Sparkle configured for %@", [[NSUserDefaults standardUserDefaults] stringForKey:UD_UPDATE_FEED_URL]);
#endif
	
	if([[cfg accounts] count] == 0){
		[NSApp beginSheet:noCharsPanel
		   modalForWindow:[self window]
			modalDelegate:nil
		   didEndSelector:NULL
			  contextInfo:NULL];
	}
#ifdef HAVE_SPARKLE
	else{
		if([[NSUserDefaults standardUserDefaults] boolForKey:UD_CHECK_FOR_UPDATES]){
			[[SUUpdater sharedUpdater]checkForUpdatesInBackground];
		}
	}
#endif
	
	//Set the character sheet as the active view.
	mvc = [viewControllers objectAtIndex:VIEW_CHARSHEET];
	[self setAsActiveView:mvc];
	[toolbar setSelectedItemIdentifier:[charSheetButton itemIdentifier]];
	
	// init the character manager object.
	characterManager = [[CharacterManager alloc]init];
	[characterManager setTemplateArray:[cfg activeCharacters] delegate:self];
	
	[overviewTableView setDataSource:characterManager];
	[overviewTableView setDelegate:characterManager];
	[overviewTableView reloadData];
	
	[self performSelector:@selector(setCurrentCharacter:) 
			   withObject:[characterManager defaultCharacter]];
	
	[self updatePopupButton];
		
	/*check to see if the server is up*/
	[self serverStatus:ServerUnknown];
	[monitor startMonitoring];
		//[self fetchCharButtonClick:nil];
	
	if ([characterManager defaultCharacter] != NULL) {
		[self fetchCharButtonClick:nil];
	}
    
    METConquerableStations *stat = [[METConquerableStations alloc] init];
    [stat reload:self];
    [stat release];
}

-(void) setAsActiveView:(id<METPluggableView>)mvc
{
	if(mvc == currentController){
		return;
	}
	
	id<METPluggableView> old = currentController;
	currentController = mvc;
	[old viewWillBeDeactivated];
	[mvc viewWillBeActivated];

	[viewBox setContentView:[mvc view]];
	[old viewIsInactive];
	if(currentCharacter != nil){
		[mvc setCharacter:currentCharacter];
	}
	[mvc viewIsActive];
}

-(void) prefWindowWillClose:(NSNotification *)notification
{
    [[[MBPreferencesController sharedController] window] orderOut:self];
    
	[[[MBPreferencesController sharedController] moduleForIdentifier:@"AccountPrefView"] willBeClosed];
	[[[MBPreferencesController sharedController] moduleForIdentifier:@"DatabasePrefView"] willBeClosed];

	//[[Config sharedInstance] clearAccounts];
	[self reloadAllCharacters];
	[overviewTableView reloadData];
	
	[self performSelector:@selector(setCurrentCharacter:) 
			   withObject:[characterManager defaultCharacter]];
	
	//[self fetchCharButtonClick:nil];
	[self updatePopupButton];
}

@end

@implementation MainController

-(void) dealloc
{
    [[NSStatusBar systemStatusBar] removeStatusItem: statusItem];
    
	[viewControllers release];
    [dbManager release];
    [undoManager release];
    
	[super dealloc];
}

-(id)init
{
	if((self = [super initWithWindowNibName:@"MainMenu"])){
		viewControllers = [[NSMutableArray alloc]init];
        dbManager = [[DBManager alloc] init];
        undoManager = [[NSUndoManager alloc] init];
        
		/*Some notifications that we want to listen to*/
		[[NSNotificationCenter defaultCenter]
		 addObserver:self 
		 selector:@selector(appIsActive:) 
		 name:NSApplicationDidBecomeActiveNotification 
		 object:NSApp];	
		
		[[NSNotificationCenter defaultCenter]
		 addObserver:self 
		 selector:@selector(appWillTerminate:) 
		 name:NSApplicationWillTerminateNotification 
		 object:NSApp];
		
		monitor = [[ServerMonitor alloc]init];
		[[NSNotificationCenter defaultCenter]
		 addObserver:self 
		 selector:@selector(serverStatusUpdate:) 
		 name:SERVER_STATUS_NOTIFICATION 
		 object:monitor];
        
        [[NSAppleEventManager sharedAppleEventManager] setEventHandler:self andSelector:@selector(getUrl:withReplyEvent:) forEventClass:kInternetEventClass andEventID:kAEGetURL];
	}
	
	return self;
}


-(void) awakeFromNib
{
	[NSDateFormatter setDefaultFormatterBehavior:NSDateFormatterBehavior10_4];
	
	/* setting default preferences values */
		
	NSMutableDictionary *prefDefaults = [[NSMutableDictionary alloc] init];
	
	[prefDefaults setObject:[NSNumber numberWithBool:YES] forKey:UD_SUBMIT_STATS];
	[prefDefaults setObject:[NSNumber numberWithBool:YES] forKey:UD_CHECK_FOR_UPDATES];
    [prefDefaults setObject:[NSNumber numberWithBool:NO] forKey:UD_ENABLE_MENUBAR];
	[prefDefaults setObject:[NSNumber numberWithInt:l_EN] forKey:UD_DATABASE_LANG];
	
    // FIXME: should all be moved to compile definitions
	[prefDefaults setObject:[@"~/Library/Application Support/Vitality" stringByExpandingTildeInPath] forKey:UD_ROOT_PATH];
	[prefDefaults setObject:[[@"~/Library/Application Support/Vitality" stringByExpandingTildeInPath] stringByAppendingFormat:@"/database.sqlite"] forKey:UD_ITEM_DB_PATH];
	[prefDefaults setObject:@"https://api.eveonline.com" forKey:UD_API_URL];
	[prefDefaults setObject:@"https://imageserver.eveonline.com/Character/" forKey:UD_PICTURE_URL];
    [prefDefaults setObject:@"https://imageserver.eveonline.com/" forKey:UD_IMAGE_URL];
	
	[prefDefaults setObject:@"https://sixones.github.io/vitality/appcast3.xml" forKey:UD_UPDATE_FEED_URL];
	[prefDefaults setObject:@"https://sixones.github.io/vitality/database.xml" forKey:UD_DB_UPDATE_URL];
	[prefDefaults setObject:@"https://sixones.github.io/vitality/database.sql.bz2" forKey:UD_DB_SQL_URL];
	
	[prefDefaults setObject:[NSNumber numberWithInt:20] forKey:UD_DATABASE_MIN_VERSION];
	 	
	[[NSUserDefaults standardUserDefaults] registerDefaults:prefDefaults];
	[prefDefaults release];
	

	/* Init window */
	
	NSWindow *window = [self window];
	//[window setRepresentedFilename:WINDOW_SAVE_NAME];
	[window setFrameAutosaveName:WINDOW_SAVE_NAME];
    [window setReleasedWhenClosed: true];
		
	[noCharsPanel setDefaultButtonCell:[noCharsButton cell]]; //alert if you don't have an account set up
	
	[window setContentBorderThickness:30.0 forEdge:NSMinYEdge];
	[[serverName cell] setBackgroundStyle:NSBackgroundStyleRaised];
	[[statusString cell] setBackgroundStyle:NSBackgroundStyleRaised];
	
	/*add the menu item*/
	/*
	for(id<METPluggableView> v in viewControllers){
		NSMenuItem *menuItem = [v menuItems];
		if(menuItem != nil){
			[[NSApp mainMenu]insertItem:menuItem atIndex:1];
			//[[NSApp mainMenu]addItem:menuItem];
		}
	}*/
    
	/* initialization of the new preferences window */
	
	AccountPrefViewController *accounts = [[AccountPrefViewController alloc] initWithNibName:@"AccountPrefView" bundle:nil];
	GeneralPrefViewController *general = [[GeneralPrefViewController alloc] initWithNibNameAndController:@"GeneralPrefView" bundle:nil controller: self];
	DatabasePrefViewController *database = [[DatabasePrefViewController alloc] initWithNibName:@"DatabasePrefView" bundle:nil];
	
	[[MBPreferencesController sharedController] setWindowModules:[NSArray arrayWithObjects:general, accounts, database, nil]];
	[accounts release];
	[general release];
	[database release];
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(prefWindowWillClose:) name:NSWindowWillCloseNotification object:[[MBPreferencesController sharedController] window]];

	/*
		notify when the selection of the overview tableview has changed.
	 */
	[[NSNotificationCenter defaultCenter]
	 addObserver:self
	 selector:@selector(charOverviewSelection:)
	 name:NSTableViewSelectionDidChangeNotification
	 object:overviewTableView];
	
	statusMessageTimer = nil;
    [self stopLoadingAnimation];
    
    if ([[NSUserDefaults standardUserDefaults] boolForKey: UD_ENABLE_MENUBAR] == YES) {
        [self enableStatusBar];
    }

}

- (void) enableStatusBar {
    // status bar item
    statusItem = [[[NSStatusBar systemStatusBar] statusItemWithLength: NSVariableStatusItemLength] retain];
    StatusItemView *statusView = [[[StatusItemView alloc] initWithFrame: NSMakeRect(0, 0, 30, [[NSStatusBar systemStatusBar] thickness]) controller: self] autorelease];
    
    [statusItem setView: statusView];
}


- (void) disableStatusBar {
    [self closeStatusWindow];
    
    [[NSStatusBar systemStatusBar] removeStatusItem: statusItem];
    
    statusItem = nil;
}


- (void) openStatusWindowAt: (NSPoint) point {
    if (statusWindow == nil) {
        StatusItemViewController *statusController = [[[StatusItemViewController alloc] initWithNibName: @"StatusItemView" bundle: nil] autorelease];
        [statusController attachMainController: self];
        [statusController setCharacter: currentCharacter];
                
        statusWindow = [[StatusItemWindow alloc] initWithController: statusController attachedToPoint: point andMainController: self];
    }
        
    [statusWindow makeKeyAndOrderFront: self];
    [statusWindow makeMainWindow];
    [(StatusItemView*) [statusItem view] open];
}

- (void) closeStatusWindow {
    [(StatusItemView*) [statusItem view] close];
    
    if (statusWindow != nil) {
        [statusWindow close];
    
        statusWindow = nil;
    }
}

-(void) setCurrentCharacter:(Character*)character
{
	if(character == nil){
		return;
	}
	if(currentCharacter != nil){
		[currentCharacter release];
	}
	
	currentCharacter = [character retain];
	
	[charButton selectItemWithTitle:[character characterName]];
	
	[characterButton setImage:[character portrait]];
	[characterButton setLabel:[character characterName]];
	
	if(currentController != nil){
		[currentController setCharacter:currentCharacter];
	}
	
	NSLog(@"Current character is %@",[currentCharacter characterName]);
	
	[[self window]setTitle: [currentCharacter characterName]];
    
    if (statusWindow) {
        [statusWindow setCharacter: currentCharacter];
    }
}

-(IBAction)charSelectorClick:(id)sender
{
	NSMenuItem *item = [(NSPopUpButton*)sender selectedItem];
	
	[self setCurrentCharacter:[item representedObject]];
}

-(void) updateActiveCharacter
{
	//Get the id for the current character, find the new object in the character manager.
	Character *character = [characterManager characterById:[currentCharacter characterId]];
	if(character == nil){
        // This can happen when Vitality is first used, so just grab the first character
        character = [characterManager defaultCharacter];
        if( nil == character )
        {
            NSLog(@"ERROR: Couldn't find character %lu.  Can't update.", (unsigned long)[currentCharacter characterId]);
            return;
        }
	}
	[self setCurrentCharacter:character];
}

- (NSUndoManager *) undoManager
{
    return undoManager;
}
- (NSUndoManager *)windowWillReturnUndoManager:(id)window
{
    return undoManager;
}

#pragma mark Character update delegate
//Called from the character manager class.

-(void) batchUpdateOperationDone:(NSArray*)errors
{
	// All characters have been updated.
	NSLog(@"Finished batch update operation");
	
	
	[statusString setHidden:YES];
	[fetchCharButton setEnabled:YES];
	[charButton setEnabled:YES];
    [self stopLoadingAnimation];
	
	/*
	 replace this with a new message that says update completed
	 and then have a timer that will clear the message after X seconds.
	 Need to be careful with race conditions, however.
	 
	 Ideally we want to be able to provide a simple error message here,
	 however this may not be possible because we are updating a bunch of
	 characters, each with possibly a different error message.
	*/
	[self statusMessage:nil];
	
	if(errors != nil){
		[self setStatusMessage:NSLocalizedString(@"Error updating characters", nil) imageState:StatusRed time:5];
	}else{
		[self setStatusMessage:NSLocalizedString(@"Update Completed", nil) imageState:StatusGreen time:5];
	}
	
	//reload the datasource for the character overview.
	[overviewTableView reloadData];
	
	//now we need to present the new character object to the active view.
	
	[self updateActiveCharacter];
}

-(void) updateAllCharacters
{
	[self statusMessage:NSLocalizedString(@"Updating Characters ...", nil)];
	[characterManager updateAllCharacters:self];
	[fetchCharButton setEnabled:NO];
	[charButton setEnabled:NO];
    [self startLoadingAnimation];
}

-(IBAction) fetchCharButtonClick:(id)sender
{
//	if([[Config sharedInstance]batchUpdateCharacters]){
		[self updateAllCharacters];
//	}else{
//		[self updateActiveCharacter];
//	}
}

-(IBAction) showPrefPanel:(id)sender;
{
    [[MBPreferencesController sharedController] showWindow:sender];
}

-(IBAction) toolbarButtonClick:(id)sender
{
	if([sender tag] == -1){
		[overviewDrawer toggle:self];
		return;
	}
	
	id<METPluggableView> mvc = [viewControllers objectAtIndex:[sender tag]];
	
	NSMenuItem *item;
	
	//Check to see if the current controller has a menu item.
	item = [currentController menuItems];
	if(item != nil){
		[[NSApp mainMenu]removeItemAtIndex:1];
	}
	
	[self setStatusMessage:nil imageState:StatusHidden time:0];//clear any toolbar message.
	[self setAsActiveView:mvc];
	
	//	remove the old one(if it exists) add the new one.
	item = [mvc menuItems];
	if(item != nil){
		[[NSApp mainMenu]insertItem:item atIndex:1];
	}
}

-(IBAction) viewSelectorClick:(id)sender
{
	NSMenuItem *item = [sender selectedItem];
	
	id<METPluggableView> mvc = [item representedObject];
	 
	[self setAsActiveView:mvc];
}

/*called to dismiss the panel that appears if you have no characaters*/
-(IBAction) noCharsButtonClick:(id)sender
{
	[NSApp endSheet:noCharsPanel];
	[noCharsPanel orderOut:sender];
	[self showPrefPanel:nil];
}

-(IBAction) checkForUpdates:(id)sender
{
#ifdef HAVE_SPARKLE
    SUUpdater *updater = [SUUpdater sharedUpdater];
    [updater checkForUpdates:[self window]];
#endif
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(databaseFinishedBuilding2:)
                                                 name:NOTE_DATABASE_BUILD_COMPLETE
                                               object:nil];
    [dbManager databaseCheckAndUpdate:YES];
}

-(void) databaseFinishedBuilding2:(NSNotification *)notification
{
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:NOTE_DATABASE_BUILD_COMPLETE
                                                  object:nil];
}


-(void) newDatabaseAvailable:(DBManager*)manager status:(BOOL)status
{
	if(!status){
		NSRunAlertPanel(@"Database is up to date",
						@"You have the lastest database version", 
						@"Close",nil,nil);
		return;
	}
	NSInteger result = NSRunAlertPanel(@"New database available",
								 @"Do you wish to download the new item database?", 
								 @"Download",
								 @"Ignore", 
								 nil);
	
	switch (result) {
		case NSAlertDefaultReturn:
		//	[dbManager downloadDatabase:[self window]];
			break;
		default:
			break;
	}
}

-(void) serverStatusUpdate:(NSNotification*)notification
{
	[self serverStatus:[monitor status]];
	[self serverPlayerCount:[monitor numPlayers]];
}

-(void) charOverviewClick:(NSTableView*)sender
{
	NSInteger row = [sender selectedRow];
	if(row == -1){
		return;
	}
	
	[self setCurrentCharacter:[(CharacterManager*)[sender dataSource]characterAtIndex:row]];
}

-(void) charOverviewSelection:(NSNotification*)notification
{
	[self charOverviewClick:[notification object]];
}

-(void) setToolbarMessage:(NSString *)message
{
	//Set a permanat message
	[self setStatusMessage:message
				imageState:StatusHidden
					  time:0];
}

-(void) setToolbarMessage:(NSString*)message time:(NSInteger)seconds
{
	[self setStatusMessage:message imageState:StatusHidden time:seconds];
}

-(void) startLoadingAnimation
{
	[loadingCycle setHidden:NO];
	[loadingCycle startAnimation:nil];
}

-(void) stopLoadingAnimation
{
    [loadingCycle setHidden:YES];
	[loadingCycle stopAnimation:nil];
}

- (BOOL)validateUserInterfaceItem:(id <NSValidatedUserInterfaceItem>)anItem
{
    SEL theAction = [anItem action];
    
    if( theAction == @selector(nextSkillPlan:) )
    {
        if( [currentController respondsToSelector:@selector(nextSkillPlan:)] )
        {
            return YES;
        }
        return NO;
    }
    else if( theAction == @selector(prevSkillPlan:) )
    {
        if( [currentController respondsToSelector:@selector(prevSkillPlan:)] )
        {
            return YES;
        }
        return NO;
    }

    return YES;
}

- (IBAction) nextSkillPlan: (id) sender
{
    if( [currentController respondsToSelector:@selector(nextSkillPlan:)] )
    {
        [currentController performSelector:@selector(nextSkillPlan:) withObject:sender];
    }
}
- (IBAction) prevSkillPlan: (id) sender
{
    if( [currentController respondsToSelector:@selector(prevSkillPlan:)] )
    {
        [currentController performSelector:@selector(prevSkillPlan:) withObject:sender];
    }
}

- (void)performFindPanelAction:(id)sender
{
    if( [currentController respondsToSelector:@selector(performFindPanelAction:)] )
    {
        [currentController performSelector:@selector(performFindPanelAction:) withObject:sender];
    }
}

/**
 URL schemes not yet handled:
 warreport:430633
 fitting:29337:2048;1:31011;1:11269;2:31055;2:3025;3:5011;1:6005;1:1978;1:2364;3:11325;1:2488;3:250;3:12822;3:23089;3:32006;35::
 joinchannel:-58925251//None//None
 contract:30003048//86415664
 */
- (void)getUrl:(NSAppleEventDescriptor *)event withReplyEvent:(NSAppleEventDescriptor *)replyEvent
{
    CCPDatabase *ccpdb = [[GlobalData sharedInstance] database];
    // Get the URL
    NSString *urlStr = [[event paramDescriptorForKeyword:keyDirectObject] stringValue];
    NSURL *url = [NSURL URLWithString:urlStr];
    NSString *scheme = [url scheme];
    NSString *path = [url resourceSpecifier];

    if( [@"showinfo" isEqualToString:scheme] )
    {
        /*
         Characters:
         1377/91671093
         1375/93347663
         1385/94798453
         1378/91794908
         1386/94916626
         
         16159/99005559 (Alliance)
         2/98160107 (Corp)
         
         5/30004815  (system)
         4/20000207 (Constellation)
         3/10000016 (Region)
         
         2454/1017452634108 (Drone)
         
         From: https://wiki.eveonline.com/en/wiki/IGB_Javascript_Methods
         Some Helpful Type ID Numbers
         
         Alliance 16159
         Character 1377 (see note 1)
         Corporation 2
         Constellation 4
         Region 3
         Solar System 5
         Station 3867 (see note 2)
         */
        NSScanner *scanner = [NSScanner scannerWithString:path];
        NSInteger infoType = -1;
        NSInteger typeID = -1;
        if( [scanner scanInteger:&infoType]
           && [scanner scanString:@"//" intoString:nil]
           && [scanner scanInteger:&typeID] )
        {
            // handle it
            NSLog( @"Showinfo URL kind/typeID: %ld/%ld", (long)infoType, (long)typeID );
            
//            CCPType *type = [ccpdb type:infoType];
            if( ((infoType >= 1373) && (infoType <= 1386))
               || infoType == 2
               || infoType == 16159 )
            {
                [METOrganizationController displayOrganizationWithType:infoType andID:typeID];
            }
            else if( (3 == infoType)
                    || (4 == infoType)
                    || (5 == infoType) )
            {
                // System form: http://evemaps.dotlan.net/system/C3-0YD
                // NSURL *newURL = [NSURL URLWithString:[NSString stringWithFormat:@"http://evemaps.dotlan.net/system/%@", name]];
                // Region (map) URL form to use: http://evemaps.dotlan.net/map/Tenerifis/C3-0YD
                // Similar if you want to show a constellation: http://evemaps.dotlan.net/map/Tenerifis/E-IFSA
                // And this for a region: http://evemaps.dotlan.net/map/Tenerifis
                NSString *urlString = nil;
                switch( infoType )
                {
                    case 5: // A system
                    {
                        // get system/region names and build a Dotlan URL
                        METPair *names = [ccpdb namesForSystemID:typeID];
                        if( names )
                        {
                            urlString = [NSString stringWithFormat:@"http://evemaps.dotlan.net/map/%@/%@",
                                                                  [[names second] stringByReplacingOccurrencesOfString:@" " withString:@"_"],
                                                                  [[names first] stringByReplacingOccurrencesOfString:@" " withString:@"_"]];
                            
                        }
                        break;
                    }
                    case 4: // A constellation
                    {
                        // get system/region names and build a Dotlan URL
                        METPair *names = [ccpdb namesForConstellationID:typeID];
                        if( names )
                        {
                            urlString = [NSString stringWithFormat:@"http://evemaps.dotlan.net/map/%@/%@",
                                         [[names second] stringByReplacingOccurrencesOfString:@" " withString:@"_"],
                                         [[names first] stringByReplacingOccurrencesOfString:@" " withString:@"_"]];
                            
                        }
                        break;
                    }
                    case 3: // A region
                    {
                        NSString *regionName = [ccpdb nameForRegionID:typeID];
                        if( regionName )
                        {
                            urlString = [NSString stringWithFormat:@"http://evemaps.dotlan.net/map/%@", regionName];
                        }
                        break;
                    }
                }
                if( urlString )
                    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:urlString]];
            }
        }
        else
        {
            NSInteger typeID = [path integerValue];
            CCPType *type = [ccpdb type:typeID];
            [METDetailWindowController displayDetailsOfType:type forCharacter:currentCharacter];

        }
    }
    else if( [@"fitting" isEqualToString:scheme] )
    {
        METFitting *fit = [METFitting fittingFromDNA:path];
        if( fit )
            [METFittingController displayFitting:fit forCharacter:currentCharacter];
    }
    else
    {
        NSLog( @"Unhandled URL scheme: %@", urlStr );
    }
}

@end
