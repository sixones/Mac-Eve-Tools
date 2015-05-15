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

#import <Cocoa/Cocoa.h>

#import "METInstance.h"
#import "PlanView2Datasource.h"
#import "AttributeModifierController.h"

@class SkillPlan;
@class SkillPlanNote;
@class PlanView2Datasource;
@class Character;
@class MetTableHeaderMenuManager;

@interface PlanView2 : NSView <NSTableViewDelegate,PlanView2Delegate> {
	IBOutlet NSTableView *tableView;
    IBOutlet NSScrollView *scrollView;
		
	IBOutlet NSPanel *skillRemovePanel;
	IBOutlet NSTextField *planSkillList;
	
	NSRect basePanelSize;
		
	PlanView2Datasource *pvDatasource;
	
	Character *character;
	
	NSInteger currentTag;
    SkillPlan *_currentPlan;
    
	id delegate;
    MetTableHeaderMenuManager *headerMenuManager;
}

@property (readwrite,nonatomic,assign) id delegate;

-(IBAction) antiPlanButtonClick:(id)sender;
-(IBAction) displayPlanByPlanId:(NSInteger)tag;

-(void) addSkillArrayToActivePlan:(NSArray*)skillArray;

-(void) setCharacter:(Character*)c;
-(Character*) character;

-(void)loadPlan:(SkillPlan *)plan;

-(void) refreshPlanView;

- (void)addNoteToSkillPlan:(SkillPlanNote *)skillNote; ///< Open a modal alert with a text field. Update skillNote or create a new one if argument is nil

@end
