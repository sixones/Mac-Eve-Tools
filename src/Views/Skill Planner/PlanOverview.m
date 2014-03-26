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

#import "PlanOverview.h"
#import "macros.h"

#import "GlobalData.h"
#import "SkillPlan.h"
#import "PlanView2Datasource.h"
#import "Character.h"

#import "SkillDetailsWindowController.h"
#import "MTSegmentedCell.h"
#import "MTSkillButtonCell.h"

#import "Helpers.h"
#import "Config.h"

#import "PlanIO.h"
#import "EvemonXmlPlanIO.h"

#import "ColumnConfigManager.h"

#import "AttributeModifierController.h"

@interface PlanOverview (SkillView2Private)

-(void) deleteSkillPlan:(NSIndexSet*)planIndexes;

-(void) cellPlusButtonClick:(id)sender;
-(void) cellMinusButtonClick:(id)sender;
-(void) cellNotesButtonClick:(id)sender;

@end

@implementation PlanOverview (SkillView2Private)

-(void) deleteSkillPlan:(NSIndexSet*)planIndexes
{
	NSMutableArray *indexArray = [NSMutableArray arrayWithCapacity:[planIndexes count]];
    [planIndexes enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
        [indexArray addObject:[NSNumber numberWithUnsignedLong:idx]];
    }];
    
    for( NSNumber *index in [indexArray reverseObjectEnumerator] )
    {
		SkillPlan *plan = [character skillPlanAtIndex:[index integerValue]];
		
		if(plan == nil){
			continue;
		}
		[character removeSkillPlan:plan];
    }

    [self refreshPlanView];
}

/*This is for the new plan sheet*/
- (void)sheetDidEnd:(NSWindow *)sheet 
		 returnCode:(NSInteger)returnCode 
		contextInfo:(void *)contextInfo
{	
	if(returnCode != 1){
		[newPlanName setObjectValue:nil];
		return;
	}
	
	NSString *str = [newPlanName stringValue];
	
	if([str length] == 0){
		return;
	}
	
	SkillPlan *plan = [delegate createNewPlan:str];
	
	if(plan != nil){
		[self refreshPlanView];
		[[self delegate] loadPlan:plan];
	}
	[newPlanName setObjectValue:nil];
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
	
	NSLog(@"Minus button click %ld",row);
}
-(void) cellNotesButtonClick:(id)sender
{
	NSInteger row = [sender clickedRow];
	NSLog(@"Notes button click row %ld",row);
}

@end


@implementation PlanOverview

@synthesize delegate;

-(SkillPlan *)currentPlan
{
    NSInteger selectedRow = [tableView selectedRow];
    
    if( !tableView || (selectedRow == -1) )
    {
        return nil;
    }
    
    return [character skillPlanAtIndex:selectedRow];
}

-(void) refreshPlanView
{
	[tableView reloadData];
}

-(void) selectRowIndexes:(NSIndexSet *)indexes byExtendingSelection:(BOOL)extend
{
    [tableView selectRowIndexes:indexes byExtendingSelection:extend];
}

-(void) buildSkillPlanColumnArray
{
	NSTableColumn *col;
	
	[skillPlanColumns removeAllObjects];
	
	NSData *data = [[NSUserDefaults standardUserDefaults] objectForKey:SKILL_PLAN_CONFIG];
	NSArray *ary;
	
	if(data == nil){
		//fall back to defaults
		ColumnConfigManager *ccm = [[ColumnConfigManager alloc]init];
		[ccm readConfig];
		ary = [ccm columns];
		[ccm release];		
	}else{
		ary = [NSKeyedUnarchiver unarchiveObjectWithData:data];
	}
	
	for(PlannerColumn *pcol in ary){
		if([pcol active]){
			col = [[NSTableColumn alloc]initWithIdentifier:[pcol identifier]];
			[col setWidth:[pcol columnWidth]];
			[[col headerCell]setStringValue:[pcol columnName]];
			[skillPlanColumns addObject:col];
			[col release];
			
			
			/*special case for the plan name column to add info and plus / minus buttons.*/
			
			if([[col identifier]isEqualToString:COL_PLAN_BUTTONS]){
				MTSkillButtonCell *cell = [[MTSkillButtonCell alloc]init];
				
				[cell setTarget:self];
				[cell setPlusButtonAction:@selector(cellPlusButtonClick:)];
				[cell setMinusButtonAction:@selector(cellMinusButtonClick:)];
				[cell setNotesButtonAction:@selector(cellNotesButtonClick:)];
				
				[col setDataCell:cell];
			}
		}
	}
}

-(void) buildSkillOverviewColumnArray
{
	NSTableColumn *col;
	
	[overviewColumns removeAllObjects];
	
	col = [[NSTableColumn alloc]initWithIdentifier:COL_POV_NAME];
	[col setWidth:270.0];
	[[col headerCell]setStringValue:NSLocalizedString(@"Plan Name",@"Column header for skill plan overview")];
	[overviewColumns addObject:col];
	[col release];
	
	col = [[NSTableColumn alloc]initWithIdentifier:COL_POV_SKILLCOUNT];
	[col setWidth:90.0];
	[[col headerCell]setStringValue:NSLocalizedString(@"Skill Count",@"Column header for skill plan overview")];
	[overviewColumns addObject:col];
	[col release];

	col = [[NSTableColumn alloc]initWithIdentifier:COL_POV_TIMELEFT];
	[col setWidth:160.0];
	[[col headerCell]setStringValue:NSLocalizedString(@"Training Time",@"Column header for skill plan overview")];
	[overviewColumns addObject:col];
	[col release];
}

-(void) buildTableviewColumns
{
	[self buildSkillOverviewColumnArray];
	[self buildSkillPlanColumnArray];
}

- (id)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code here.
		overviewColumns = [[NSMutableArray alloc]init];
		skillPlanColumns = [[NSMutableArray alloc]init];
		
		pvDatasource = [[PlanView2Datasource alloc]init];
		[pvDatasource setViewDelegate:self];
		
		[self buildTableviewColumns];
        [self buildAdvancedMenuForPlansOverview];
        
		currentTag = -1;
	}
	return self;
}

-(void) buildAdvancedMenuForPlansOverview {
    while ([advancedButton.itemArray count] > 1) {
        [advancedButton removeItemAtIndex: 1];
    }
    
    NSMenuItem *item = [[NSMenuItem alloc]initWithTitle:@"Import from EVEMon XML" action:@selector(importEvemonPlan:) keyEquivalent:@""];
    [item setTarget:self];
    [[advancedButton menu] addItem:item];
}

-(void) buildAdvancedMenuForPlan {
    while ([advancedButton.itemArray count] > 1) {
        [advancedButton removeItemAtIndex: 1];
    }
    
    
    NSMenuItem *item = [[NSMenuItem alloc]initWithTitle:@"Setup Attributes" action:@selector(attributeModifierButtonClick:) keyEquivalent:@""];
    [item setTarget:self];
    [[advancedButton menu] addItem:item];
    
    [[advancedButton menu] addItem: [NSMenuItem separatorItem]];
    
    item = [[NSMenuItem alloc]initWithTitle:@"Copy as EVE Text" action:@selector(exportPlanToEVEText:) keyEquivalent:@""];
    [item setTarget:self];
    [[advancedButton menu] addItem:item];
    
    item = [[NSMenuItem alloc]initWithTitle:@"Copy as Plain Text" action:@selector(exportPlanToText:) keyEquivalent:@""];
    [item setTarget:self];
    [[advancedButton menu] addItem:item];
    
    [[advancedButton menu] addItem: [NSMenuItem separatorItem]];
    
    item = [[NSMenuItem alloc]initWithTitle:@"Export to EVEMon XML" action:@selector(exportEvemonPlan:) keyEquivalent:@""];
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
	[self performPlanExport:[self currentPlan]];
}

-(void) exportPlanToText:(id)sender {
    [self performTextPlanExportToClipboard: false];
}

-(void) exportPlanToEVEText:(id)sender {
    [self performTextPlanExportToClipboard: true];
}

-(void) dealloc
{
	[overviewColumns release];
	[skillPlanColumns release];
	[character release];
	[pvDatasource release];
	[super dealloc];
}

-(void) awakeFromNib
{
	//[self switchColumns:overviewColumns];
    
	[pvDatasource setMode:SPMode_overview];
	[tableView setDataSource:self];
	
	[tableView registerForDraggedTypes:[NSArray arrayWithObjects:MTSkillArrayPBoardType,MTSkillIndexPBoardType,nil]];
	
	[tableView setDelegate:self];
	[tableView setTarget:self];
	[tableView setDoubleAction:@selector(rowDoubleClick:)];
    [tableView setColumnAutoresizingStyle: NSTableViewFirstColumnOnlyAutoresizingStyle];
		
	basePanelSize = [skillRemovePanel frame];
    
    [self buildAdvancedMenuForPlansOverview];
}

- (void)drawRect:(NSRect)rect {
    // Drawing code here.
}

-(IBAction) plusMinusButtonClick:(id)sender
{
	NSInteger tag = [sender tag];
	
	if(tag == TAG_PLUS_BUTTON)
    {
		[NSApp beginSheet:newPlan
		   modalForWindow:[tableView window]
			modalDelegate:self
		   didEndSelector:@selector(sheetDidEnd:returnCode:contextInfo:)
			  contextInfo:NULL];
		
	}
    else if(tag == TAG_MINUS_BUTTON)
    {
		if([tableView selectedRow] == -1)
        {
			return;
		}
		
        [self deleteSkillPlan:[tableView selectedRowIndexes]];
	}
}

-(IBAction) attributeModifierButtonClick:(id)sender
{
	
	if([pvDatasource mode] == SPMode_plan){
		SkillPlan *plan = [character skillPlanById:[pvDatasource planId]];
		
		[attributeModifier setCharacter:character andPlan:plan];
	
		[NSApp beginSheet:attributeModifierPanel
		   modalForWindow:[NSApp mainWindow]
			modalDelegate:attributeModifier
		   didEndSelector:@selector(sheetDidEnd:returnCode:contextInfo:)
			  contextInfo:attributeModifierPanel];
	}
}

-(IBAction) planButtonClick:(id)sender
{
	[NSApp endSheet:newPlan returnCode:[sender tag]];
	[newPlan orderOut:sender];
}
-(IBAction) antiPlanButtonClick:(id)sender
{
	[NSApp endSheet:skillRemovePanel returnCode:[sender tag]];
	[skillRemovePanel orderOut:sender];
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
	
	SkillPlan *plan = [delegate createNewPlan:planName];
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
		[character removeSkillPlan:plan];

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
	
    [self refreshPlanView];
}

-(void) performPlanImport:(NSString*)filePath
{
	[NSApp beginSheet:newPlan
	   modalForWindow:[NSApp mainWindow]
		modalDelegate:self
	   didEndSelector:@selector(importSheetDidEnd:returnCode:contextInfo:)
		  contextInfo:[filePath retain]];
}

-(void) performPlanExport:(SkillPlan *)plan
{
	NSString *proposedFileName = [NSString stringWithFormat:@"%@ - %@.emp",
								  [character characterName],
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

-(void) performTextPlanExportToClipboard:(BOOL) eveStyle {
	SkillPlan *plan = [self currentPlan];
    SkillTree *st = [[GlobalData sharedInstance]skillTree];
    
    NSMutableString *planString = [NSMutableString string];
	NSInteger counter = [plan skillCount];
    
	for(NSInteger i = 0; i < counter; i++) {
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

- (IBAction) nextSkillPlan: (id) sender
{
    NSInteger row = [tableView selectedRow];
    NSInteger count = [tableView numberOfRows];
    row++;
    if( row >= count )
        row = 0;
    [tableView selectRowIndexes:[NSIndexSet indexSetWithIndex:row] byExtendingSelection:NO];
}

- (IBAction) prevSkillPlan: (id) sender
{
    NSInteger row = [tableView selectedRow];
    NSInteger count = [tableView numberOfRows];
    row--;
    if( row < 0 )
        row = count - 1;
    [tableView selectRowIndexes:[NSIndexSet indexSetWithIndex:row] byExtendingSelection:NO];
}

#pragma mark TableView Delegate methods

-(void) tableView:(NSTableView*)aTableView keyDownEvent:(NSEvent*)theEvent
{
	NSString *chars = [theEvent characters];
	if([chars length] == 0){
		return;
	}
	unichar ch = [chars characterAtIndex:0];
	/*if the user pressed a delete key, delete all the selected skills or plans*/
	if((ch == NSDeleteCharacter) || (ch == NSBackspaceCharacter) || (ch == NSDeleteFunctionKey))
	{	
		NSIndexSet *rowset = [tableView selectedRowIndexes];
		
		if( [rowset count] > 0 )
        {
            [self deleteSkillPlan:rowset];
		}
	}
}

- (void)tableViewSelectionDidChange:(NSNotification *)notification
{
	NSInteger selectedRow = [tableView selectedRow];
	
	if(selectedRow == -1){
		return;
	}
	
    SkillPlan *plan = [character skillPlanAtIndex:selectedRow];
    [[self delegate] loadPlan:plan];
}

/* Start in-place editing of the plan name */
-(void) rowDoubleClick:(id)sender
{
	NSInteger selectedRow = [sender selectedRow];
	    
    NSInteger column = [tableView columnWithIdentifier:COL_POV_NAME];
	
	[tableView editColumn:column row:selectedRow withEvent:nil select:YES];
}


#pragma mark Table row menu delegates
-(void) removeSkillPlanFromOverview:(id)sender
{
	NSNumber *planId = [sender representedObject];
	[self deleteSkillPlan:[NSIndexSet indexSetWithIndex:[planId unsignedIntegerValue]]];
}

-(void) renameSkillPlan:(id)sender
{
	NSNumber *planRow = [sender representedObject];
	
	NSInteger column = [tableView columnWithIdentifier:COL_POV_NAME];
	
	[tableView editColumn:column row:[planRow integerValue] withEvent:nil select:YES];
}

-(void) activatePlanAtRow:(id)sender
{
	NSNumber *planRow = [sender representedObject];
	
	SkillPlan *plan = [character skillPlanAtIndex:[planRow integerValue]];
	[[self delegate] loadPlan:plan];
}

-(void) exportPlanAtRow:(id)sender
{
	NSNumber *planRow = [sender representedObject];
	
	SkillPlan *plan = [character skillPlanAtIndex:[planRow integerValue]];
    [self performPlanExport:plan];

}

#pragma mark

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

- (void)tableViewColumnDidResize:(NSNotification *)aNotification
{
    // let the framework handle resizing
    /*
	NSTableColumn *col = [[aNotification userInfo]objectForKey:@"NSTableColumn"];
	NSLog(@"resized %@ to %.2f",[col identifier],(double)[col width]);
	
	//write out the new column width
	ColumnConfigManager *ccm = [[ColumnConfigManager alloc]init];	
	
	[ccm setWidth:[col width] forColumn:[col identifier]];
	
	[ccm release];
    */
}

- (void)tableViewColumnDidMove:(NSNotification *)aNotification
{
	//NSNumber *oldIndex = [[aNotification userInfo]objectForKey:@"NSOldColumn"];
	//NSNumber *newIndex = [[aNotification userInfo]objectForKey:@"NSNewColumn"];	
	
	//The column at oldIndex got moved to newIndex.
}

- (NSInteger)numberOfRowsInTableView:(NSTableView *)aTableView
{
    return [character skillPlanCount];
}

-(id) tableView:(NSTableView *)aTableView
objectValueForTableColumn:(NSTableColumn *)aTableColumn
			row:(NSInteger)rowIndex
{
	SkillPlan *skillPlan = [character skillPlanAtIndex:rowIndex];
	
	if([[aTableColumn identifier]isEqualToString:COL_POV_NAME])
    {
		return [skillPlan planName];
	}
    else if([[aTableColumn identifier]isEqualToString:COL_POV_SKILLCOUNT])
    {
		return [NSNumber numberWithInteger:[skillPlan skillCount]];
	}
    else if([[aTableColumn identifier]isEqualToString:COL_POV_TIMELEFT])
    {
		return stringTrainingTime([skillPlan trainingTime]);
	}
	    
	return nil;
}

- (void)tableView:(NSTableView *)aTableView
   setObjectValue:(id)anObject
   forTableColumn:(NSTableColumn *)aTableColumn
			  row:(NSInteger)rowIndex
{
	SkillPlan *plan = [character skillPlanAtIndex:rowIndex];
	NSString *oldName = [[plan planName]retain];
	[plan setPlanName:anObject];
	if(![character renameSkillPlan:plan]){ //verify that the name change succeded
		[plan setPlanName:oldName];//rename failed. restore old name.
	}
	[oldName release];
}

-(NSMenu*) tableView:(NSTableView*)table
  menuForTableColumn:(NSTableColumn*)column
				 row:(NSInteger)row
{
	if(row == -1)
    {
		return nil;
	}
	
	NSMenu *menu = nil;
	SkillPlan *skillPlan = nil;
	NSMenuItem *item = nil;
	NSNumber *planRow = [NSNumber numberWithInteger:row];
	
	menu = [[[NSMenu alloc]initWithTitle:@""]autorelease];
    
    skillPlan = [character skillPlanAtIndex:row];
    
    if(skillPlan == nil){
        return nil;
    }
    
    item = [[NSMenuItem alloc]initWithTitle:[skillPlan planName]
                                     action:@selector(activatePlanAtRow:)
                              keyEquivalent:@""];
    [item setRepresentedObject:planRow];
    [menu addItem:item];
    [item release];
    
    [menu addItem:[NSMenuItem separatorItem]];
    
    item = [[NSMenuItem alloc]initWithTitle:NSLocalizedString(@"Delete",@"Delete a skill plan")
                                     action:@selector(removeSkillPlanFromOverview:)
                              keyEquivalent:@""];
    [item setRepresentedObject:planRow];
    [menu addItem:item];
    [item release];
    
    item = [[NSMenuItem alloc]initWithTitle:NSLocalizedString(@"Rename",@"Rename a skill plan")
                                     action:@selector(renameSkillPlan:)
                              keyEquivalent:@""];
    [item setRepresentedObject:planRow];
    [menu addItem:item];
    [item release];
	
    item = [[NSMenuItem alloc]initWithTitle:NSLocalizedString(@"Export",@"Export a skill plan")
                                     action:@selector(exportPlanAtRow:)
                              keyEquivalent:@""];
    [item setRepresentedObject:planRow];
    [menu addItem:item];
    [item release];

	return menu;
}

-(BOOL) shouldHighlightCell:(NSInteger)rowIndex
{
	return NO;
}

#pragma mark Drag and drop methods
- (BOOL)tableView:(NSTableView *)tv
writeRowsWithIndexes:(NSIndexSet *)rowIndexes
	 toPasteboard:(NSPasteboard*)pboard
{
	[pboard declareTypes:[NSArray arrayWithObject:MTSkillIndexPBoardType] owner:self];
	
	id array;
	NSMutableData *data = [[NSMutableData alloc]initWithCapacity:0];
	NSKeyedArchiver *archiver = [[NSKeyedArchiver alloc]initForWritingWithMutableData:data];
	
	[archiver setOutputFormat:NSPropertyListBinaryFormat_v1_0];
	
	NSUInteger count = [rowIndexes count];
	
	if(count == 1){
		array = [NSArray arrayWithObject:[NSNumber numberWithInteger:[rowIndexes firstIndex]]];
	}else{
		array = [[[NSMutableArray alloc]initWithCapacity:count]autorelease];
		
		NSUInteger *indexBuffer = malloc(sizeof(NSUInteger) * count);
		
		[rowIndexes getIndexes:indexBuffer maxCount:count inIndexRange:nil];
		
		for(NSUInteger i=0; i < count; i++){
			[array addObject:[NSNumber numberWithInteger:(NSInteger)indexBuffer[i]]];
		}
		
		free(indexBuffer);
	}
	
	[archiver encodeObject:array forKey:DRAG_SKILLINDEX];
	
	[archiver finishEncoding];
	
	[pboard setData:data forType:MTSkillIndexPBoardType];
	
	[archiver release];
	[data release];
	
	return YES;
}


- (NSDragOperation)tableView:(NSTableView *)aTableView
				validateDrop:(id < NSDraggingInfo >)info
				 proposedRow:(NSInteger)row
	   proposedDropOperation:(NSTableViewDropOperation)operation
{
    if( [info draggingSource] == aTableView )
    {
        [aTableView setDropRow:row dropOperation:NSTableViewDropAbove];
        return NSDragOperationMove;
    }
    else
    {
        [aTableView setDropRow:row dropOperation:NSTableViewDropOn];
        return NSDragOperationCopy;
    }
    
	if([info draggingSource] == aTableView){
		[aTableView setDropRow:row dropOperation:NSTableViewDropAbove];
		return NSDragOperationMove;
	}
	
	return NSDragOperationCopy;
}

- (BOOL)tableView:(NSTableView *)aTableView
	   acceptDrop:(id < NSDraggingInfo >)info
			  row:(NSInteger)row
	dropOperation:(NSTableViewDropOperation)operation
{	
	if([info draggingSource] == aTableView)
    {
		/*We are reording skills within a plan*/
		NSData *data = [[info draggingPasteboard]dataForType:MTSkillIndexPBoardType];
		NSKeyedUnarchiver *unarchiver = [[NSKeyedUnarchiver alloc]initForReadingWithData:data];
		NSArray *indexArray = [unarchiver decodeObjectForKey:DRAG_SKILLINDEX];
		
		[unarchiver finishDecoding];
		[unarchiver release];
		

        // What to do if we drop one skill plan on another? Copy all skills from the source plan to the destination?
        NSIndexSet *indexes = [character moveSkillPlan:indexArray to:row];
        [self selectRowIndexes:indexes byExtendingSelection:NO];
        [self refreshPlanView];
        return [indexes count] > 0;

	}else{
		/*
		 this is a copy array type.  If we are in overview mode, append skills to the existing plan,
		 or create a new plan, if is not dropped on an existing plan.
		 
		 if it is not overview mode, append to the current planId
		 */
		NSData *data = [[info draggingPasteboard]dataForType:MTSkillArrayPBoardType];
		NSKeyedUnarchiver *unarchiver = [[NSKeyedUnarchiver alloc]initForReadingWithData:data];
		
		NSArray *array = [unarchiver decodeObject];
		
		[unarchiver finishDecoding];
		[unarchiver release];
		
        if(operation == NSTableViewDropOn)
        {
            SkillPlan *plan = [character skillPlanAtIndex:row];

            /*find the plan we are dropping on, append skills to this plan*/
            //SkillPlan *dropPlan = [character skillPlanAtIndex:row];
            [plan addSkillArrayToPlan:array];
            [plan savePlan];
            [aTableView setNeedsDisplayInRect:[aTableView frameOfCellAtColumn:1 row:row]];
            [aTableView setNeedsDisplayInRect:[aTableView frameOfCellAtColumn:2 row:row]];
            return YES;
        }else if(operation == NSTableViewDropAbove){
            return NO;
        }
	}
	return NO;
}


@end
