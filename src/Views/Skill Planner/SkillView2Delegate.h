//
//  SkillView2Delegate.h
//  Vitality
//
//  Created by Andrew Salamon on 3/26/14.
//  Copyright (c) 2014 Andrew Salamon. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol SkillView2Delegate <METInstance>

/*
 the plan summary wants to create a new plan
 returns YES on success. NO if a plan was not created
 */
-(SkillPlan*) createNewPlan:(NSString*)name;

/*
 Remove a plan from the queue
 YES on success NO on failure
 */
-(BOOL) removePlan:(NSInteger)planId;

/*
 the user wants to move the plan in the plan list
 return YES if allowed, NO if not
 */
-(BOOL) planMovedFromIndex:(NSInteger)from toIndex:(NSInteger)to;

-(void) loadPlan:(SkillPlan *)skillPlan;

-(void) exportPlan:(SkillPlan *)skillPlan;
@end