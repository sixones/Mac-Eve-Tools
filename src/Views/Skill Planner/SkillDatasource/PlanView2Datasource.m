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

#import "PlanView2Datasource.h"

#import "SkillPlan.h"
#import "Character.h"
#import "Helpers.h"
#import "GlobalData.h"
#import "Config.h"

#import <assert.h>

@implementation PlanView2Datasource

@synthesize planId;

-(id) init
{
	if(self = [super init]){
		masterSkillSet = [[[[GlobalData sharedInstance]skillTree] skillSet]retain];
	}
	return self;
}

-(void) dealloc
{
	[masterSkillSet release];
	[super dealloc];
}

-(void) setViewDelegate:(id<PlanView2Delegate>)delegate
{
	viewDelegate = delegate;
}

-(Character*) character
{
	return character;
}
-(void) setCharacter:(Character*)c
{
    if( character != c )
    {
        [character release];
        character = [c retain];
        planId = 0;
    }
}

-(SkillPlan*) currentPlan
{
	return [character skillPlanById:planId];
}

-(void) removeSkillsFromPlan:(NSArray*)skillIndexes
{
	SkillPlan *plan = [self currentPlan];
	[plan removeSkillArrayFromPlan:skillIndexes];
	[plan savePlan];
}

- (NSInteger)numberOfRowsInTableView:(NSTableView *)aTableView
{
	return [[self currentPlan] skillCount];
}

-(id) tableView:(NSTableView *)aTableView 
objectValueForTableColumn:(NSTableColumn *)aTableColumn 
			row:(NSInteger)rowIndex
{
	SkillPlan *skillPlan = [self currentPlan];
    SkillPair *sp = [skillPlan skillAtIndex:rowIndex];
    
    if( [sp isKindOfClass:[SkillPlanNote class]] )
    {
        if( [[aTableColumn identifier] isEqualToString:COL_PLAN_SKILLNAME] )
        {
            return [(SkillPlanNote *)sp note];
        }

        return nil;
    }
    
	Skill *s = [masterSkillSet objectForKey:[sp typeID]];
	
	if([[aTableColumn identifier] isEqualToString:COL_PLAN_SKILLNAME])
    {
		return [sp roman];
	}
    else if([[aTableColumn identifier] isEqualToString:COL_PLAN_SPHR])
    {
		return [NSNumber numberWithInteger:[sp skillPointsPerHourFor:character]];
	}
    else if([[aTableColumn identifier] isEqualToString:COL_PLAN_TRAINING_TIME])
    {
		NSInteger trainingTime = (NSInteger)[[skillPlan skillTrainingFinish:rowIndex]
											 timeIntervalSinceDate:[skillPlan skillTrainingStart:rowIndex]];
		if(trainingTime == 0){
			return NSLocalizedString(@"Complete",@"Skill planner. Training Time column.  Skill has finished training.");
		}else{
			return stringTrainingTime(trainingTime);
		}
	}
    else if([[aTableColumn identifier] isEqualToString:COL_PLAN_TRAINING_TTD])
    {
		NSInteger trainingTime = (NSInteger)[[skillPlan skillTrainingFinish:rowIndex]
											 timeIntervalSinceDate:[skillPlan skillTrainingStart:0]];
		return stringTrainingTime(trainingTime);
	}
    else if([[aTableColumn identifier] isEqualToString:COL_PLAN_CALSTART])
    {
		/*the date and time that this skill will start training*/
		return [[GlobalData sharedInstance]formatDate:[skillPlan skillTrainingStart:rowIndex]];
	}
    else if([[aTableColumn identifier] isEqualToString:COL_PLAN_CALFINISH])
    {
		return [[GlobalData sharedInstance]formatDate:[skillPlan skillTrainingFinish:rowIndex]];
	}
    else if([[aTableColumn identifier] isEqualToString:COL_PLAN_PERCENT])
    {
		CGFloat percentCompleted = [character percentCompleted:[sp typeID]
													 fromLevel:[sp skillLevel]-1 
													   toLevel:[sp skillLevel]];
		long int intPercent = xlround(percentCompleted * 100.0);
		
		return [NSString stringWithFormat:@"%ld%%",MIN(intPercent,100l)];
	}
    else if( [[aTableColumn identifier] isEqualToString:COL_PLAN_PRIMARY_ATTR] )
    {
        NSString *prim = strForAttrCode([s primaryAttr]);
        return prim;
    }
    else if( [[aTableColumn identifier] isEqualToString:COL_PLAN_SECONDARY_ATTR] )
    {
        NSString *second = strForAttrCode([s secondaryAttr]);
        return second;
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
	/*
	 this right click is to remove skills from the skill plan.  we have to figure out if removing the skill being removed
	 from the plan has prerequisites, and remove them as well.
	 */
	
	if(row == -1){
		return nil;
	}
	
    SkillPlan *skillPlan = [self currentPlan];
    
    if(skillPlan == nil){
        return nil;
    }
    
	NSNumber *planRow = [NSNumber numberWithInteger:row];
	NSMenu *menu = [[[NSMenu alloc]initWithTitle:@""]autorelease];
    SkillPair *sp = [skillPlan skillAtIndex:row];
    
    if( [sp isKindOfClass:[SkillPlanNote class]] )
    {
        NSMenuItem *item = [[NSMenuItem alloc]initWithTitle:NSLocalizedString( @"Edit Note", @"Edit Note contextual menu item title" )
                                                     action:@selector(editSkillPlanNote:)
                                              keyEquivalent:@""];
        [item setRepresentedObject:sp];
        [menu addItem:item];
        [item release];
        return menu;
    }
    
    Skill *s = [masterSkillSet objectForKey:[sp typeID]];
    
    
    NSMenuItem *item = [[NSMenuItem alloc]initWithTitle:[s skillName]
                                     action:@selector(displaySkillWindow:)
                              keyEquivalent:@""];
    [item setRepresentedObject:s];
    [menu addItem:item];
    [item release];
    
    [menu addItem:[NSMenuItem separatorItem]];
    
    item = [[NSMenuItem alloc]initWithTitle:[NSString stringWithFormat:
                                             NSLocalizedString(@"Remove %@ %@",@"Remove <SkillName> <SkillLevel>"),[s skillName],
                                             romanForInteger([sp skillLevel])]
                                     action:@selector(removeSkillFromPlan:)
                              keyEquivalent:@""];
    [item setRepresentedObject:planRow];
    [menu addItem:item];
    [item release];
    
    /*
     If the skill is not planned to a level higher than the current level
     then add the option to right-click and train to a particular level.
     */
    
    NSInteger queuedIndex;
    NSInteger queuedMax = [[self currentPlan]maxLevelForSkill:[sp typeID] atIndex:&queuedIndex];
    
    if(queuedMax < 5){
        for(NSInteger i = queuedMax + 1; i <= 5; i++){
            item = [[NSMenuItem alloc]initWithTitle:
                    [NSString stringWithFormat:
                     NSLocalizedString(@"Train to level %@",@"Train skill to level"),romanForInteger(i) ]
                                             action:@selector(trainSkillToLevel:)
                                      keyEquivalent:@""];
            
            SkillPair *newPair = [[SkillPair alloc]initWithSkill:[sp typeID] level:i];
            
            [item setRepresentedObject:newPair];
            [menu addItem:item];
            [item release];
            [newPair release];
        }
    }
	
	return menu;
}

- (void)tableView:(NSTableView *)tableView willDisplayCell:(id)cell1 forTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)rowIndex
{
	if( [[tableColumn identifier] isEqualToString:COL_PLAN_SKILLNAME] )
    {
        SkillPlan *skillPlan = [self currentPlan];

        // If this skill is missing pre-requisites before it in the skill plan or already trained, then color the text red
        if( ![skillPlan validateSkillAtIndex:rowIndex] )
        {
            [cell1 setTextColor:[NSColor redColor]];
        }
        else
        {
            [cell1 setTextColor:[NSColor blackColor]];
        }
    }
}

-(BOOL) shouldHighlightCell:(NSInteger)rowIndex
{
	if([character isTraining]){
		SkillPlan *plan = [self currentPlan];
		SkillPair *sp = [plan skillAtIndex:rowIndex];
		if([[sp typeID]integerValue] == [character integerForKey:CHAR_TRAINING_TYPEID]){
			if([sp skillLevel] == [character integerForKey:CHAR_TRAINING_LEVEL]){
				return YES;
			}
		}
	}
	return NO;
}

-(void) addSkillArrayToActivePlan:(NSArray*)skillArray
{
    SkillPlan *plan = [self currentPlan];
    [plan addSkillArrayToPlan:skillArray];
}

#pragma mark Drag and drop methods
/** Write skill pairs (not just indexes) to the paste board.
 This is needed if we are dragging from one table (e.g. skill plan detail table)
 to another table (e.g. skill plan overview table)
 */
- (void)writeSkillArray:(NSIndexSet *)rowIndexes toPasteboard:(NSPasteboard *)pboard
{
    SkillPlan *skillPlan = [self currentPlan];
    
    if( skillPlan == nil )
    {
        return;
    }

	NSMutableArray *skillArray = [NSMutableArray array];

    [rowIndexes enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
        [skillArray addObject:[skillPlan skillAtIndex:idx]];
    }];
    
    NSMutableData *data = [NSMutableData data];
	NSKeyedArchiver *archiver = [[[NSKeyedArchiver alloc] initForWritingWithMutableData:data] autorelease];
    
	[archiver setOutputFormat:NSPropertyListBinaryFormat_v1_0];
	[archiver encodeObject:skillArray];
	[archiver finishEncoding];
	
    [pboard addTypes:[NSArray arrayWithObject:MTSkillArrayPBoardType] owner:self];	
	[pboard setData:data forType:MTSkillArrayPBoardType];
}

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
	
    // This is for dragging skills from one skill plan into another
    [self writeSkillArray:rowIndexes toPasteboard:pboard];
    
	return YES;
}


- (NSDragOperation)tableView:(NSTableView *)aTableView
				validateDrop:(id < NSDraggingInfo >)info
				 proposedRow:(NSInteger)row 
	   proposedDropOperation:(NSTableViewDropOperation)operation
{	
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
	SkillPlan *plan = [self currentPlan];
	
	if( [info draggingSource] == aTableView )
    {
		/* We are reordering skills within a plan */
		NSData *data = [[info draggingPasteboard]dataForType:MTSkillIndexPBoardType];
		NSKeyedUnarchiver *unarchiver = [[NSKeyedUnarchiver alloc]initForReadingWithData:data];
		NSArray *indexArray = [unarchiver decodeObjectForKey:DRAG_SKILLINDEX];
		
		[unarchiver finishDecoding];
		[unarchiver release];
		
        BOOL rc = [plan moveSkill:indexArray to:row];
        
        if(rc){
            [plan savePlan];
            [viewDelegate refreshPlanView];
            [aTableView deselectAll:self];
        }
        
        return rc;
	}
    else
    {
		/*
		 this is a copy array type.
		 
		 append to the current planId
		 */
		NSData *data = [[info draggingPasteboard]dataForType:MTSkillArrayPBoardType];
		NSKeyedUnarchiver *unarchiver = [[NSKeyedUnarchiver alloc]initForReadingWithData:data];
		
		NSArray *array = [unarchiver decodeObject];
		
		[unarchiver finishDecoding];
		[unarchiver release];
		
        [plan addSkillArrayToPlan:array];
        [plan savePlan];
        [viewDelegate refreshPlanView];
        return YES;
	}
	return NO;
}

-(void)tableView:(NSTableView *)_tableView sortDescriptorsDidChange: (NSArray *)oldDescriptors
{
    // remember the currently selected plan, then re-select it after sorting
    //    NSIndexSet *current = [tableView selectedRowIndexes];
    [self sortSkillsUsingDescriptors:[_tableView sortDescriptors]];
    [_tableView reloadData];
    //    if( current )
    //    {
    //        NSInteger index = [character indexOfPlan:current];
    //        [tableView selectRowIndexes:[NSIndexSet indexSetWithIndex:index] byExtendingSelection:NO];
    //    }
}

- (void)sortSkillsUsingDescriptors:(NSArray *)descriptors
{
	SkillPlan *plan = [self currentPlan];
    [plan sortUsingDescriptors:descriptors];
}

-(void) sortPlanByPrerequisites
{
	SkillPlan *plan = [self currentPlan];
    [plan sortPlanByPrerequisites];
}

@end
