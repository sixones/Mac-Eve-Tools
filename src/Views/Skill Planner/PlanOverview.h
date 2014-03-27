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
#import "SkillView2Delegate.h"

@class SkillPlan;
@class PlanView2Datasource;
@class Character;
@class MetTableHeaderMenuManager;

@interface PlanOverview : NSObject <NSTableViewDelegate,NSTableViewDataSource,PlanView2Delegate> {
	IBOutlet NSButton *plusButton;
	IBOutlet NSButton *minusButton;
	
	IBOutlet NSTableView *tableView;
    IBOutlet NSScrollView *scrollView;
	
	IBOutlet NSPanel *newPlan;
	IBOutlet NSTextField *newPlanName;
    
	PlanView2Datasource *pvDatasource;
	
	Character *character;
	
	NSInteger currentTag;
	
	id<SkillView2Delegate> delegate;
    MetTableHeaderMenuManager *headerMenuManager;
}

@property (readwrite,nonatomic,assign) id<SkillView2Delegate> delegate;

-(IBAction) plusMinusButtonClick:(id)sender;
-(IBAction) planButtonClick:(id)sender;
-(IBAction) nextSkillPlan:(id)sender;
-(IBAction) prevSkillPlan:(id)sender;

-(void) addSkillArrayToActivePlan:(NSArray*)skillArray;

-(void) setCharacter:(Character*)c;
-(Character*) character;

-(void) refreshPlanView;

-(SkillPlan *)currentPlan;
@end
