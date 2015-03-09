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

#import "SkillPlanController.h"
#import "GlobalData.h"
#import "SkillSearchView.h"
#import "Helpers.h"
#import "PlanView2Datasource.h"
#import "PlanOverview.h"

/*datasources*/
#import "SkillSearchCharacterDatasource.h"
#import "SkillSearchShipDatasource.h"
#import "SkillSearchCertDatasource.h"

#import "METInstance.h"

#import "PlanIO.h"
#import "EvemonXmlPlanIO.h"
#import "Skill.h"
#import "SkillPair.h"
#import "SkillPlan.h"

@interface SkillPlanController (SkillPlanControllerPrivate)

/*delegate methods for the splitting panel*/
- (CGFloat)splitView:(NSSplitView *)sender constrainMinCoordinate:(CGFloat)proposedMin ofSubviewAt:(NSInteger)offset;
//- (CGFloat)splitView:(NSSplitView *)sender constrainMaxCoordinate:(CGFloat)proposedMax ofSubviewAt:(NSInteger)offset;
- (void)splitView:(NSSplitView *)sender resizeSubviewsWithOldSize:(NSSize)oldSize;

/*private methods for managing the panels*/

@end


@implementation SkillPlanController (SkillPlanControllerPrivate) 

- (CGFloat)splitView:(NSSplitView *)sender constrainMinCoordinate:(CGFloat)proposedMin ofSubviewAt:(NSInteger)offset
{
	if(offset == 0){
		return [[[sender subviews] objectAtIndex:offset]bounds].size.width;
	}
	return proposedMin;
}

/*
- (CGFloat)splitView:(NSSplitView *)sender constrainMaxCoordinate:(CGFloat)proposedMax ofSubviewAt:(NSInteger)offset
{
	return proposedMax;
}
*/

/*
	FFS. you think they could make the splitview come with code like this built in. it must
	be a fairly common way to want the view to resize.
 */
- (void)splitView:(NSSplitView *)sender resizeSubviewsWithOldSize:(NSSize)oldSize
{	
	// http://www.wodeveloper.com/omniLists/macosx-dev/2003/May/msg00261.html
	// http://snipplr.com/view/2452/resize-nssplitview-nicely/
	// grab the splitviews
    NSView *left = [[sender subviews] objectAtIndex:0];
    NSView *right = [[sender subviews] objectAtIndex:1];
	
	CGFloat minLeftWidth = [skillSearchView bounds].size.width;
    CGFloat dividerThickness = [sender dividerThickness];
	
	// get the different frames
    NSRect newFrame = [sender frame];
    NSRect leftFrame = [left frame];
    NSRect rightFrame = [right frame];
	
	// change in width for this redraw
	CGFloat	dWidth  = newFrame.size.width - oldSize.width;
	
	// ratio of the left frame width to the right used for resize speed when both panes are being resized
	CGFloat rLeftRight = (leftFrame.size.width - minLeftWidth) / rightFrame.size.width;
	
	// resize the height of the left
    leftFrame.size.height = newFrame.size.height;
    leftFrame.origin = NSMakePoint(0,0);
	
	// resize the left & right pane equally if we are shrinking the frame
	// resize the right pane only if we are increasing the frame
	// when resizing lock at minimum width for the left panel
	if(leftFrame.size.width <= minLeftWidth && dWidth < 0) {
		rightFrame.size.width += dWidth;
	} else if(dWidth > 0) {
		rightFrame.size.width += dWidth;
	} else {
		leftFrame.size.width += dWidth * rLeftRight;
		rightFrame.size.width += dWidth * (1 - rLeftRight);
	}
	
	rightFrame.size.width = newFrame.size.width - leftFrame.size.width - dividerThickness;
	rightFrame.size.height = newFrame.size.height;
	rightFrame.origin.x = leftFrame.size.width + dividerThickness;
	
	[left setFrame:leftFrame];
	[right setFrame:rightFrame];
}

#pragma mark characterDidUpdate
-(void) characterDidUpdate:(Character*)c didSucceed:(BOOL)success docPath:(NSString*)docPath
{
	if(success && [docPath isEqualToString:XMLAPI_CHAR_SHEET]){
		[skillCharDatasource setCharacter:c];
		[skillSearchView reloadDatasource:skillCharDatasource]; /*datasouce has changed.*/
	}
}

@end


@implementation SkillPlanController

-(SkillPlanController*) init
{
	if((self = [super initWithNibName:@"SkillPlan" bundle:nil])){
		
	}
	return self;
}


-(void) awakeFromNib
{
	st = [[[GlobalData sharedInstance]skillTree] retain];
	    
	/*Add the subviews. skillSearchView on the left, and the plan view on the right*/
	[splitView addSubview:skillSearchView];
	//[splitView addSubview:planTabView];
	[splitView addSubview:skillView2];
	[splitView setPosition:([skillSearchView bounds].size.width) ofDividerAtIndex:0];
	
	[splitView setDelegate:self]; /*to control the resizing*/
	[skillSearchView setDelegate:self]; /*this class will receive notifications about skills that have been selected*/
	
	skillCharDatasource = [[SkillSearchCharacterDatasource alloc]init];
	[skillCharDatasource setSkillTree:st];
	if(activeCharacter != nil){
		[skillCharDatasource setCharacter: activeCharacter];
	}
	[skillSearchView addDatasource: skillCharDatasource];
	
	skillCertDatasource = [[SkillSearchCertDatasource alloc]init];
	if(skillSearchView != nil){
		[skillSearchView addDatasource: skillCertDatasource];
	}	
	
	skillShipDatasource = [[SkillSearchShipDatasource alloc]initWithCategory: DB_CATEGORY_SHIP];
	if(skillShipDatasource != nil){
		[skillSearchView addDatasource: skillShipDatasource];
	}
    
	skillItemDatasource = [[SkillSearchModuleDatasource alloc]initWithCategory: DB_CATEGORY_MODULE];
	if (skillItemDatasource != nil){
		[skillSearchView addDatasource: skillItemDatasource];
	}
    
    [skillSearchView selectDefaultGroup];
    
	[skillView2 setDelegate:self];
    [planOverview setDelegate:self];
    
    [self buildAdvancedMenu];
}

-(void) dealloc
{
	[super dealloc];
}

#pragma mark METPluggableView stuff

-(void) setCharacter:(Character*)c
{
	if(c == nil){
		return;
	}
	if(c == activeCharacter){
		return;
	}
	if(activeCharacter != nil){
		[activeCharacter release];
	}

	[skillView2 setCharacter:c];
	[planOverview setCharacter:c];
    
	activeCharacter = [c retain];
	
	[skillCharDatasource setCharacter:c];
	[skillSearchView reloadDatasource:skillCharDatasource]; /*datasouce has changed.*/
    
    [skillCertDatasource setCharacter:c];
    [planOverview tableViewSelectionDidChange:nil];
}

-(Character*) character;
{
	return activeCharacter;
}

-(void) viewIsInactive
{	
	if(activeCharacter != nil){
		[activeCharacter release];
		activeCharacter = nil;
	}
}

-(void) viewIsActive
{
	[skillCharDatasource setSkillTree:st];
	[skillCharDatasource setCharacter:activeCharacter];
	
	[skillSearchView reloadDatasource:skillCharDatasource];
//	[skillSearchView selectDefaultGroup];
	
	[skillView2 refreshPlanView];
    [planOverview refreshPlanView];
    //[[[self view] window] makeFirstResponder:[skillSearchView searchField]];
}

-(void) viewWillBeDeactivated
{
}
-(void) viewWillBeActivated
{
}

/*construct the toolbar menu*/
-(NSMenuItem*) menuItems
{
	NSMenuItem *topLevel = [[NSMenuItem allocWithZone:[NSMenu menuZone]]initWithTitle:@"Planner"
																   action:NULL
															keyEquivalent:@""];

	return [topLevel autorelease];
}

-(NSView*) view
{
	return [super view];
}

- (void)performFindPanelAction:(id)sender
{
    [[[self view] window] makeFirstResponder:[skillSearchView searchField]];
}

/*Skill search delegate controls.  called when the SkillSearchView wants to add a skill to a plan*/
#pragma mark SkillSearchViewDelegate

-(void) planAddSkillArray:(NSArray*)skills
{
	[skillView2 addSkillArrayToActivePlan:skills];
}

#pragma mark SkillView2Delegate

-(SkillPlan*) createNewPlan:(NSString*)planName;
{
	SkillPlan *plan = [activeCharacter createSkillPlan:planName];
	
	return plan;
}


/*planid is the index in the array of skill plans*/
-(BOOL) removePlan:(NSInteger)planId
{
	SkillPlan *sp = [activeCharacter skillPlanAtIndex:planId];
	if(sp == nil){
		NSLog(@"SkillPlan %ld not found in character %@", (long)planId, [activeCharacter characterName]);
		return NO;
	}
	
	[activeCharacter removeSkillPlanAtIndex:planId];
	return YES;
}

-(BOOL) planMovedFromIndex:(NSInteger)from toIndex:(NSInteger)to
{
	return NO;
}

-(void) setInstance:(id<METInstance>)instance
{
	//Don't retain.
	mainApp = instance;
}

-(void) setToolbarMessage:(NSString *)message
{
	//Set a permanat message
	[mainApp setToolbarMessage:message];
}

-(void) setToolbarMessage:(NSString*)message time:(NSInteger)seconds
{
	[mainApp setToolbarMessage:message time:seconds];
}

-(void) startLoadingAnimation
{
    [mainApp startLoadingAnimation];
}

-(void) stopLoadingAnimation
{
    [mainApp stopLoadingAnimation];
}

- (IBAction) nextSkillPlan: (id) sender
{
    [planOverview nextSkillPlan:sender];
}

- (IBAction) prevSkillPlan: (id) sender
{
    [planOverview prevSkillPlan:sender];
}

-(void) loadPlan:(SkillPlan*)plan
{
    [skillView2 loadPlan:plan];
}

#pragma mark Advanced menu methods
-(void) buildAdvancedMenu
{
    while ([advancedButton.itemArray count] > 1) {
        [advancedButton removeItemAtIndex: 1];
    }
    
    NSMenuItem *item = [[NSMenuItem alloc]initWithTitle:@"Setup Attributes" action:@selector(attributeModifierButtonClick:) keyEquivalent:@""];
    [item setTarget:self];
    [[advancedButton menu] addItem:item];
    
    [[advancedButton menu] addItem: [NSMenuItem separatorItem]];
    
    item = [[NSMenuItem alloc]initWithTitle:@"Import Plan from EVEMon XML" action:@selector(importEvemonPlan:) keyEquivalent:@""];
    [item setTarget:self];
    [[advancedButton menu] addItem:item];

    item = [[NSMenuItem alloc]initWithTitle:@"Export Plan to EVEMon XML" action:@selector(exportEvemonPlan:) keyEquivalent:@""];
    [item setTarget:self];
    [[advancedButton menu] addItem:item];

    [[advancedButton menu] addItem: [NSMenuItem separatorItem]];

    item = [[NSMenuItem alloc]initWithTitle:@"Copy Plan as EVE Text" action:@selector(exportPlanToEVEText:) keyEquivalent:@""];
    [item setTarget:self];
    [[advancedButton menu] addItem:item];
    
    item = [[NSMenuItem alloc]initWithTitle:@"Copy Plan as Plain Text" action:@selector(exportPlanToText:) keyEquivalent:@""];
    [item setTarget:self];
    [[advancedButton menu] addItem:item];
}

-(void) importEvemonPlan:(id)sender
{
	NSOpenPanel *op = [NSOpenPanel openPanel];
	[op setCanChooseDirectories:NO];
	[op setCanChooseFiles:YES];
	[op setAllowsMultipleSelection:NO];
	[op setAllowedFileTypes:[NSArray arrayWithObjects:@"emp",@"xml",nil]];
	
	if([op runModal] == NSFileHandlingPanelCancelButton){
		return;
	}
	
	if([[op URLs]count] == 0){
		return;
	}
	
	NSURL *url = [[op URLs]objectAtIndex:0];
	if(url == nil){
		return;
	}
	
	/*
	 now we import the plan.
	 the evemon format doesn't have the plan name encoded
	 in the xml (and there could be a clash anyway) so prompt
	 the user for the plan name.
	 */
	[self performPlanImport:[url path]];
}

-(void) exportEvemonPlan:(id)sender
{
	[self performPlanExport:@""];
}

-(void) exportPlanToText:(id)sender {
    [self performTextPlanExportToClipboard: false];
}

-(void) exportPlanToEVEText:(id)sender {
    [self performTextPlanExportToClipboard: true];
}

-(IBAction) attributeModifierButtonClick:(id)sender
{
	
    SkillPlan *plan = [planOverview currentPlan];
    
    [attributeModifier setCharacter:activeCharacter andPlan:plan];
    
    [NSApp beginSheet:attributeModifierPanel
       modalForWindow:[NSApp mainWindow]
        modalDelegate:attributeModifier
       didEndSelector:@selector(sheetDidEnd:returnCode:contextInfo:)
          contextInfo:attributeModifierPanel];
}

/*
 this is for importing a plan
 It only seems to work if the plan view is active.
 */
-(void) importSheetDidEnd:(NSWindow *)sheet
			   returnCode:(NSInteger)returnCode
			  contextInfo:(NSString *)filePath
{
	[filePath autorelease];
	
	NSString *planName = [newPlanName stringValue];
	
	SkillPlan *plan = [self createNewPlan:planName];
	if(plan == nil){
		NSLog(@"Failed to create plan %@",planName);
		return;
	}
	
	/*import the evemon plan*/
	EvemonXmlPlanIO *pio = [[EvemonXmlPlanIO alloc]init];
	
	BOOL rc = [pio read:filePath intoPlan:plan];
	
	[pio release];
	
	if(!rc){
		NSLog(@"Failed to read plan!");
		[activeCharacter removeSkillPlan:plan];
        
		NSAlert *alert = [[NSAlert alloc]init];
		[alert addButtonWithTitle:@"Ok"];
		[alert setMessageText:
		 NSLocalizedString(@"Error importing the plan",
						   @"error message generated when the program can't parse a skill plan import")];
		[alert setInformativeText:
		 NSLocalizedString(@"The plan file couldn't be understood\r\nOr there were no skills to import",
						   @"error message generated when the program can't parse a skill plan import")];
		[alert runModal];
		[alert release];
		
	}
	
    // should select it
    [planOverview refreshPlanView];
}

-(void) performPlanImport:(NSString*)filePath
{
	[NSApp beginSheet:newPlan
	   modalForWindow:[NSApp mainWindow]
		modalDelegate:self
	   didEndSelector:@selector(importSheetDidEnd:returnCode:contextInfo:)
		  contextInfo:[filePath retain]];
}

-(void) performPlanExport:(NSString*)filePath
{
	SkillPlan *plan = [planOverview currentPlan];
	[self exportPlan:plan];
}

-(void) performTextPlanExportToClipboard:(BOOL) eveStyle {
	SkillPlan *plan = [planOverview currentPlan];
        
    NSMutableString *planString = [NSMutableString string];
	NSInteger counter = [plan skillCount];
    
	for(NSInteger i = 0; i < counter; i++)
    {
        SkillPair *sp = [plan skillAtIndex:i];
		Skill *s = [st skillForId:[sp typeID]];
        
        if (eveStyle) {
            [planString appendFormat:@"<a href='showinfo:%d'>%@</a>\t L%d\n", (int) [sp typeID], [s skillName], (int) [sp skillLevel]];
        } else {
            [planString appendFormat:@"%@\t L%d\n", [s skillName], (int) [sp skillLevel]];
        }
	}
    
    [[NSPasteboard generalPasteboard] clearContents];
    [[NSPasteboard generalPasteboard] setString:planString forType:NSStringPboardType];
}

-(void) exportPlan:(SkillPlan *)plan
{
	NSString *proposedFileName = [NSString stringWithFormat:@"%@ - %@.emp",
								  [activeCharacter characterName],
								  [plan planName]];
	
	NSSavePanel *sp = [NSSavePanel savePanel];
	
	[sp setAllowedFileTypes:[NSArray arrayWithObjects:@"emp",@"xml",nil]];
	[sp setNameFieldStringValue:proposedFileName];
	[sp setCanSelectHiddenExtension:YES];
	
	if([sp runModal] == NSFileHandlingPanelOKButton){
		EvemonXmlPlanIO *pio = [[EvemonXmlPlanIO alloc]init];
		[pio write:plan toFile:[[sp URL]path]];
		[pio release];
	}
}

@end
