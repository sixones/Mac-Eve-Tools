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

#import "PlanView2.h"
#import "macros.h"

#import "GlobalData.h"
#import "SkillPlan.h"
#import "PlanView2Datasource.h"
#import "Character.h"

#import "SkillDetailsWindowController.h"
#import "MTSkillButtonCell.h"
#import "MetTableHeaderMenuManager.h"

#import "Helpers.h"
#import "Config.h"

#import "PlanIO.h"
#import "EvemonXmlPlanIO.h"

@interface PlanView2 (SkillView2Private)

-(void) removeSkillsFromPlan:(NSIndexSet*)skillIndexes;
-(void) removeSkillsPopupConfirmation:(NSArray*)antiPlan;
-(void) removeSkillSheetDidEnd:(NSWindow *)sheet returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo;

-(void) cellPlusButtonClick:(id)sender;
-(void) cellMinusButtonClick:(id)sender;
-(void) cellNotesButtonClick:(id)sender;

@end

@implementation PlanView2 (SkillView2Private)

-(void) removeSkillSheetDidEnd:(NSWindow *)sheet 
					returnCode:(NSInteger)returnCode 
				   contextInfo:(void *)contextInfo
{
	NSArray *antiPlan = contextInfo;
	if(returnCode == 1){
		[pvDatasource removeSkillsFromPlan:antiPlan];
		[self refreshPlanView];
	}
	[antiPlan release];
}

-(void) removeSkillsPopupConfirmation:(NSArray*)antiPlan
{
	if([antiPlan count] == 1){
		[pvDatasource removeSkillsFromPlan:antiPlan];
		[self refreshPlanView];
		return;
	}
	
	SkillTree *st = [[GlobalData sharedInstance]skillTree];
	
	NSRect panelRect = basePanelSize;
	
	NSMutableString *str = [[NSMutableString alloc]init];
	
	for(SkillPair *sp in antiPlan){
		Skill *s = [st skillForId:[sp typeID]];
		[str appendFormat:@"%@ %@\n",[s skillName],romanForInteger([sp skillLevel])];	
	}
	[planSkillList setStringValue:str];
	[str release];
	
	/*magic number. I can't seem to work out how to get the size of a text field, but this seems to work. fix later.*/
	//Note to self: attributed strings
	panelRect.size.height = basePanelSize.size.height + [antiPlan count] * 17; 
	
	[skillRemovePanel setFrame:panelRect display:YES];
	
	//[planSkillToRemove sizeToFit];
	[planSkillList sizeToFit];
	
	[NSApp beginSheet:skillRemovePanel
	   modalForWindow:[self window]
		modalDelegate:self
	   didEndSelector:@selector(removeSkillSheetDidEnd:returnCode:contextInfo:)
		  contextInfo:[antiPlan retain]];
}

-(void) removeSkillsFromPlan:(NSIndexSet*)rowset
{
	NSUInteger rowsetCount = [rowset count];
	NSUInteger *ary = malloc(sizeof(NSUInteger) * rowsetCount);
	NSUInteger actual = [rowset getIndexes:ary maxCount:(sizeof(NSUInteger) * rowsetCount) inIndexRange:nil];
	
	assert(actual == rowsetCount);
	
	NSArray *antiPlan = [[pvDatasource currentPlan] constructAntiPlan:ary arrayLength:rowsetCount];
	free(ary);
	
	[self removeSkillsPopupConfirmation:antiPlan];
}

-(void)toobarMessageForPlan:(SkillPlan*)plan
{
	NSString *trainingTime = stringTrainingTime([plan trainingTime]);
	NSString *message = [NSString stringWithFormat:
						 NSLocalizedString(@"%ld skills planned. Total training time: %@",
										   @"Bottom toolbar text. Shows plan training time"),
						 [plan skillCount],trainingTime];
	[delegate setToolbarMessage:message];
}

-(void) cellPlusButtonClick:(id)sender
{	
	/*
	 Find out what skill this is.
	 If level 5, do nothing.
	 Else, add it to the next level in the next row.
	 */
	NSInteger row = [sender clickedRow];
	NSInteger insertRow = -1;
	
	SkillPlan *plan = [pvDatasource currentPlan];
	
	SkillPair *pair = [plan skillAtIndex:row];
	
	NSInteger maxQueuedLevel = [plan maxLevelForSkill:[pair typeID] atIndex:&insertRow];
	
	if((maxQueuedLevel == 5) || (maxQueuedLevel == 0)){
		return;
	}
	
	SkillPair *newPair = [[SkillPair alloc]initWithSkill:[pair typeID] level:maxQueuedLevel+1];
	[plan addSkill:newPair atIndex:insertRow+1];
	[newPair release];
	
	[[pvDatasource currentPlan]savePlan];
	[self refreshPlanView];
}
-(void) cellMinusButtonClick:(id)sender
{
	/*
	 Find this skill and remove it from the plan
	 */
	NSInteger row = [sender clickedRow];
	SkillPlan *plan = [pvDatasource currentPlan];
	
	/*this does not display the warning dialog.*/
	[plan removeSkillAtIndex:row];
	[[pvDatasource currentPlan]savePlan];
	[self refreshPlanView];
	
	NSLog(@"Minus button click %ld", (long)row);
}
-(void) cellNotesButtonClick:(id)sender
{
	NSInteger row = [sender clickedRow];
	NSLog(@"Notes button click row %ld", (long)row);
}

@end


@implementation PlanView2

@synthesize delegate;

-(IBAction) displayPlanByPlanId:(NSInteger)tag
{
    if(tag == currentTag){
        return;
    }
    
    [pvDatasource setPlanId:tag];
    
    currentTag = tag;
    
    // TODO: it would be better if each plan remembered the last selected skill and we re-selected it
    [tableView deselectAll: self];
    [self tableView:tableView sortDescriptorsDidChange:nil];
    
    //	[self refreshPlanView];
}

-(void) loadPlan:(SkillPlan*)plan;
{
	[self displayPlanByPlanId:[plan planId]];
}

-(void) refreshPlanView
{
    [tableView selectRowIndexes:[NSIndexSet indexSetWithIndex:0] byExtendingSelection:NO];
	[tableView reloadData];
    [self toobarMessageForPlan:[pvDatasource currentPlan]];
}

-(void) selectRowIndexes:(NSIndexSet *)indexes byExtendingSelection:(BOOL)extend
{
    [tableView selectRowIndexes:indexes byExtendingSelection:extend];
}


- (id)initWithFrame:(NSRect)frame
{
    if( self = [super initWithFrame:frame] )
    {
		pvDatasource = [[PlanView2Datasource alloc] init];
		[pvDatasource setViewDelegate:self];
		        
		currentTag = -1;
	}
	return self;
}

-(IBAction) antiPlanButtonClick:(id)sender
{
    [NSApp endSheet:skillRemovePanel returnCode:[sender tag]];
    [skillRemovePanel orderOut:sender];
}

-(void) dealloc
{
	[character release];
	[pvDatasource release];
    [headerMenuManager release];
	[super dealloc];
}

-(void) awakeFromNib
{
	[tableView setDataSource:pvDatasource];
	
	[tableView registerForDraggedTypes:[NSArray arrayWithObjects:MTSkillArrayPBoardType,MTSkillIndexPBoardType,nil]];
	
	[tableView setDelegate:self];
	[tableView setTarget:self];
	[tableView setDoubleAction:@selector(rowDoubleClick:)];
    
    NSMenu * menu = [[[NSMenu alloc] init] autorelease];
    
    NSMenuItem *reset = [[NSMenuItem alloc] initWithTitle:@"Manual Sorting" action:@selector(resetSorting:) keyEquivalent:@""];
    [reset setTarget:self];
    [menu addItem:reset];
    
    NSMenuItem *prereq = [[NSMenuItem alloc] initWithTitle:@"Fix Prerequisites" action:@selector(fixPrerequisites:) keyEquivalent:@""];
    [prereq setTarget:self];
    [menu addItem:prereq];
    
    [menu addItem:[NSMenuItem separatorItem]];
    
    headerMenuManager = [[MetTableHeaderMenuManager alloc] initWithMenu:menu forTable:tableView];

	basePanelSize = [skillRemovePanel frame];
}

- (void)drawRect:(NSRect)rect {
    // Drawing code here.
}


-(void) rowDoubleClick:(id)sender
{
	NSInteger selectedRow = [sender selectedRow];
	
	if( selectedRow == -1 )
    {
		return;
	}
	
    /* Display a popup window for the clicked skill */
    NSNumber *typeID = [[[character skillPlanById:[pvDatasource planId]] skillAtIndex:selectedRow] typeID];
    [SkillDetailsWindowController displayWindowForTypeID:typeID forCharacter:character];
}

-(void) displaySkillWindow:(id)sender
{
	Skill *s = [sender representedObject];
	
	if(s == nil){
		NSLog(@"Error: Skill is nil!");
		return;
	}
	
	[SkillDetailsWindowController displayWindowForTypeID:[s typeID] forCharacter:character];
}

-(void) setCharacter:(Character*)c
{
	if(c == character){
		return;
	}
	
	[character release];
	character = [c retain];
	[pvDatasource setCharacter:c];
	[self refreshPlanView];
}

-(Character*) character
{
	return character;
}

#pragma mark TableView Delegate methods

-(BOOL) tableView:(NSTableView*)aTableView keyDownEvent:(NSEvent*)theEvent
{
	NSString *chars = [theEvent characters];
	if([chars length] == 0){
		return NO;
	}
	unichar ch = [chars characterAtIndex:0];
	/*if the user pressed a delete key, delete all the selected skills or plans*/
	if((ch == NSDeleteCharacter) || (ch == NSBackspaceCharacter) || (ch == NSDeleteFunctionKey))
	{	
		NSIndexSet *rowset = [tableView selectedRowIndexes];
		
		if([rowset count] > 0)
        {
            [self removeSkillsFromPlan:rowset];
            return YES;
		}
	}
    return NO;
}

 /*menu delegates*/
-(void) removeSkillFromPlan:(id)sender
{
	NSNumber *planId = [sender representedObject];
	[self removeSkillsFromPlan:[NSIndexSet indexSetWithIndex:[planId unsignedIntegerValue]]];
}

-(void) trainSkillToLevel:(id)sender
{
	SkillPair *pair = [sender representedObject];
	if([[pvDatasource currentPlan]increaseSkillToLevel:pair]){
		[self refreshPlanView];
	}
}

-(void) addSkillArrayToActivePlan:(NSArray*)skillArray
{
	[pvDatasource addSkillArrayToActivePlan:skillArray];
	[[pvDatasource currentPlan]savePlan];
	[self refreshPlanView];
}

- (BOOL)tableView:(NSTableView *)aTableView 
shouldEditTableColumn:(NSTableColumn *)aTableColumn 
			  row:(NSInteger)rowIndex
{
	return NO;
}

- (void)tableView:(NSTableView *)_tableView willDisplayCell:(id)cell1 forTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)rowIndex
{
    [pvDatasource tableView:_tableView willDisplayCell:cell1 forTableColumn:tableColumn row:rowIndex];
}

-(void)tableView:(NSTableView *)_tableView sortDescriptorsDidChange: (NSArray *)oldDescriptors
{
    // remember the currently selected plan, then re-select it after sorting
//    NSIndexSet *current = [tableView selectedRowIndexes];
    [pvDatasource sortSkillsUsingDescriptors:[_tableView sortDescriptors]];
    [_tableView reloadData];
//    if( current )
//    {
//        NSInteger index = [character indexOfPlan:current];
//        [tableView selectRowIndexes:[NSIndexSet indexSetWithIndex:index] byExtendingSelection:NO];
//    }
}

-(void)resetSorting:(id)sender
{
//    NSSortDescriptor *manual = [[[NSSortDescriptor alloc] initWithKey:@"manual" ascending:YES] autorelease];
//    [tableView setSortDescriptors:[NSArray arrayWithObject:manual]];
    [tableView setSortDescriptors:nil];
    //[self tableView:tableView sortDescriptorsDidChange:nil];
    [tableView reloadData];
}

-(void) fixPrerequisites:(id)sender
{
    [pvDatasource sortPlanByPrerequisites];
    [tableView setSortDescriptors:nil];
    [tableView reloadData];
}
@end
