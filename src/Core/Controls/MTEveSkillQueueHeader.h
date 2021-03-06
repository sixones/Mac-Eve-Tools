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

@class SkillPlan;
@class Character;

@interface MTEveSkillQueueHeader : NSView <NSTableViewDelegate, NSTableViewDataSource> {
	SkillPlan *plan;
	Character *character;
	
	NSColor *progressColor1;
	NSColor *progressColor2;
    NSColor *warningColor1;
    NSColor *warningColor2;
    
	BOOL active;
    BOOL _warn;
    
	NSInteger planTrainingTime;
	
	NSDateFormatter *dFormat;
}

@property (assign) BOOL warn; ///< Visually warn the user if there's less than 24 hours in the queue.

-(BOOL) hidden;
-(void) setHidden:(BOOL)a;

-(SkillPlan*) skillPlan;
-(void) setSkillPlan:(SkillPlan*)skillPlan;

-(Character*) character;
-(void) setCharacter:(Character*)c;

-(void) tick;

-(NSInteger) timeRemaining;
-(void) setTimeRemaining:(NSInteger)timeRemaining;

@end
