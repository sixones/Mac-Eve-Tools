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
#import "MetTableHeaderMenuManager.h"

#import "Helpers.h"
#import "Config.h"

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
        // New plan is always added at the end, so select the last index
        [tableView selectRowIndexes:[NSIndexSet indexSetWithIndex:([character skillPlanCount]-1)] byExtendingSelection:NO];
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

- (id)init
{
    if( self = [super init] )
    {
		pvDatasource = [[PlanView2Datasource alloc]init];
		[pvDatasource setViewDelegate:self];
		        
		currentTag = -1;
	}
	return self;
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
	[pvDatasource setMode:SPMode_overview];
	[tableView setDataSource:self];
	
	[tableView registerForDraggedTypes:[NSArray arrayWithObjects:MTSkillArrayPBoardType,MTSkillIndexPBoardType,nil]];
	
	[tableView setDelegate:self];
	[tableView setTarget:self];
	[tableView setDoubleAction:@selector(rowDoubleClick:)];
    [tableView setColumnAutoresizingStyle: NSTableViewFirstColumnOnlyAutoresizingStyle];
    headerMenuManager = [[MetTableHeaderMenuManager alloc] initWithMenu:nil forTable:tableView];
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
        [self tableViewSelectionDidChange:nil];
	}
}

-(IBAction) planButtonClick:(id)sender
{
	[NSApp endSheet:newPlan returnCode:[sender tag]];
	[newPlan orderOut:sender];
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
		
		if( [rowset count] > 0 )
        {
            [self deleteSkillPlan:rowset];
            return YES;
		}
	}
    
    return NO;
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
    [delegate exportPlan:plan];

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
    [item setTarget:self];
    [menu addItem:item];
    [item release];
    
    [menu addItem:[NSMenuItem separatorItem]];
    
    item = [[NSMenuItem alloc]initWithTitle:NSLocalizedString(@"Delete",@"Delete a skill plan")
                                     action:@selector(removeSkillPlanFromOverview:)
                              keyEquivalent:@""];
    [item setRepresentedObject:planRow];
    [item setTarget:self];
    [menu addItem:item];
    [item release];
    
    item = [[NSMenuItem alloc]initWithTitle:NSLocalizedString(@"Rename",@"Rename a skill plan")
                                     action:@selector(renameSkillPlan:)
                              keyEquivalent:@""];
    [item setRepresentedObject:planRow];
    [item setTarget:self];
    [menu addItem:item];
    [item release];
	
    item = [[NSMenuItem alloc]initWithTitle:NSLocalizedString(@"Export",@"Export a skill plan")
                                     action:@selector(exportPlanAtRow:)
                              keyEquivalent:@""];
    [item setRepresentedObject:planRow];
    [item setTarget:self];
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
        if( row >= [character skillPlanCount] )
            return NSDragOperationNone;
        
        [aTableView setDropRow:row dropOperation:NSTableViewDropOn];
        return NSDragOperationCopy;
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

-(void)tableView:(NSTableView *)tableView sortDescriptorsDidChange: (NSArray *)oldDescriptors
{
//    NSArray *newDescriptors = [tableView sortDescriptors];
//    [orders sortUsingDescriptors:newDescriptors];
//    [tableView reloadData];
}

@end
