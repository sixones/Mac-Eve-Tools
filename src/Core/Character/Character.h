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

	//#import "Account.h"
#import "Character.h"
#import "SkillTree.h"
#import "SkillPair.h"
#import "macros.h"


/*prevent circular includes*/
@class SkillPlan;

@class Character;
@class CharacterTemplate;
@class CharacterDatabase;

/**
 The `Character` class represents all the information found in the EVE
 Online API's Character Sheet call.
 */

@interface Character : NSObject <NSOutlineViewDataSource> {
	/**
	 The character's database ID, as provided in the characterID API parameter.
	 */
	NSUInteger characterId;

	/**
	 The character's name.
	 */
	NSString *characterName;

	/**
	 The location of the character's data directory on disk.
	 */
	NSString *characterFilePath;

	/**
	 Generic key-value data storage used internally by `Character`.
	 */
	NSMutableDictionary *data;

	/**
	 This character's current skills.
	 */
	SkillTree *skillTree;

	/**
	 This character's training queue.
	 */
	SkillPlan *trainingQueue;

	/**
	 This character's saved training plans.
	 */
	NSMutableArray *skillPlans;

	/**
	 This character's record in the local SQLite database.
	 */
	CharacterDatabase *database;

	/**
	 The ID of this character's currently-training skill, which is the corresponding
     /row[@typeID] attribute from the Skill Tree API call.
	 */
	NSNumber *trainingSkill;

	/**
	 This character's portrait.
	 */
	NSImage *portrait;

	/**
	 Current error messages, if any, for this character.
	 */
	NSString *errorMessage[CHAR_ERROR_TOTAL];

	/**
	 The expiration date of this character's locally-cached information.
	 */
	NSDate *cacheExpiry;

	/**
	 This character's current certificates, as `NSNumber`s corresponding to their
     certID values.
	 */
	NSMutableSet *ownedCerts;

	/**
	 Unused value.
	 */
	NSInteger updateProgress;

	/**
	 This character's base (pre-implant) attribute levels.

     The array's indices are `ATTR_INTELLIGENCE`, `ATTR_MEMORY`, `ATTR_CHARISMA`,
     `ATTR_PERCEPTION`, and `ATTR_WILLPOWER`.
	 */
	NSInteger baseAttributes[ATTR_TOTAL];

	/**
	 This character's implant-provided attribute modifiers.

     The array's indices are `ATTR_INTELLIGENCE`, `ATTR_MEMORY`, `ATTR_CHARISMA`,
     `ATTR_PERCEPTION`, and `ATTR_WILLPOWER`.
	 */
	NSInteger implantAttributes[ATTR_TOTAL];

	/**
	 Temporary values used when calculating an optimized training queue.

     The array's indices are `ATTR_INTELLIGENCE`, `ATTR_MEMORY`, `ATTR_CHARISMA`,
     `ATTR_PERCEPTION`, and `ATTR_WILLPOWER`.
	 */
	NSInteger tempBonuses[ATTR_TOTAL];

	/**
	 This character's total attribute levels, with all bonuses applied.

     The array's indices are `ATTR_INTELLIGENCE`, `ATTR_MEMORY`, `ATTR_CHARISMA`,
     `ATTR_PERCEPTION`, and `ATTR_WILLPOWER`.
	 */
	CGFloat attributeTotals[ATTR_TOTAL];

	/**
	 `YES` if there was an error while updating this character; no otherwise.

     The array's indices are `CHAR_ERROR_CHARSHEET`, `CHAR_ERROR_TRAININGSHEET`,
     and `CHAR_ERROR_QUEUE`.
	 */
	BOOL error[CHAR_ERROR_TOTAL];

	/**
	 `YES` if this character is currently training a skill; `NO` otherwise.
	 */
	BOOL isTraining;
}

/**
 @name Properties
 */

/**
 This character's portrait.
 */
@property (readonly,nonatomic) NSImage* portrait;

/**
 This character's character ID, as provided by the Eve API.
 */
@property (readonly,nonatomic) NSUInteger characterId;

/**
 This character's name.
 */
@property (readonly,nonatomic) NSString* characterName;

/**
 This character's skill tree.
 */
@property (readonly,nonatomic) SkillTree* skillTree;

/**
 This character's current training queue.
 */
@property (readonly,nonatomic) SkillPlan* trainingQueue;

@property (readonly,nonatomic) CharacterDatabase *database;

/**
 @name Initialization
 */

/**
 Initialize this character object using the data in `path`.

 @param path The path to a folder on disk containing character data as
 populated by the `updateTemplateArray:delegate:` method of `CharacterManager`.

 @return Self.
 */
-(Character*) initWithPath:(NSString*)path;

/**
 @name Dictionary Access
 */

/**
 Return a string value stored in this character's associated `NSDictionary`.
 
 Valid keys are defined in `macros.h`.

 @param key The value's key.

 @return The requested value as an NSString.
 */
-(NSString*) stringForKey:(NSString*)key;

/**
 Return an integer value stored in this character's associated `NSDictionary`.

 Valid keys are defined in `macros.h`.

 @param key The value's key.

 @return The requested value as an NSInteger. If the requested value is not
 numeric, returns 0.
 */
-(NSInteger) integerForKey:(NSString*)key;

/**
 Formats an NSInteger as a string with the specifier `%2.2f`.
 
 This function is used when displaying a character's attribute values.

 @param attr The integer to be formatted.

 @return The formated integer as an NSString.
 */
-(NSString*) getAttributeString:(NSInteger)attr;

/**
 @name Character Attributes
 */

/**
 Returns an attribute's value without the learning bonus applied.
 
 Valid attributes are:
 
 - `ATTR_INTELLIGENCE`
 - `ATTR_MEMORY`
 - `ATTR_CHARISMA`
 - `ATTR_PERCEPTION`
 - `ATTR_WILLPOWER`.

 @param attr The attribute's enum value.

 @return The value of the attribute `attr`.
 */
-(NSInteger) attributeValue:(NSInteger)attr;

/**
 @name Character Skills
 */

/**
 This character's total skill points.

 @return The number of skill points.
 */
-(NSInteger) skillPointTotal;

/**
 This character's count of skills that have been trained to level V.

 @return The number of skills at level V.
 */
-(NSInteger) skillsAtV;

/**
 This character's count of skills known (injected).

 @return The number of skills injected.
 */
-(NSInteger) skillsKnown;

/**
 @name Character Portrait
 */

/**
 Delete this character's portrait on disk.
 */
-(void) deletePortrait;

/**
 @name Skill Training
 */

/**
 Calculate the training time for a skill given the number of points required.

 Skill types are defined in `macros.h`.

 @param primary   The skill's primary attribute.
 @param secondary The skill's secondary attribute.
 @param sp        The number of skill points to be trained.

 @return The training time in seconds.
 */
-(NSInteger) trainingTimeInSeconds:(NSInteger)primary 
						 secondary:(NSInteger)secondary 
					   skillPoints:(NSInteger)sp;

/**
 Calculate the training time to train a skill to a given level. This method
 considers partially-trained skills.

 Skill types are defined in `macros.h`.

 @param typeID    The skill's typeID value.
 @param fromLevel The starting level.
 @param toLevel   The desired ending level.

 @return The training time in seconds.
 */
-(NSInteger) trainingTimeInSeconds:(NSNumber*)typeID
						 fromLevel:(NSInteger)fromLevel 
						   toLevel:(NSInteger)toLevel;

/**
 Calculate the training time to train a skill to a given level. This method
 considers partially-trained skills.

 Skill types are defined in `macros.h`.

 @param typeID    The skill's typeID value.
 @param fromLevel The starting level.
 @param toLevel   The desired ending level.
 @param train     `YES` if the skill currently in training should be included.

 @return The training time in seconds.
 */
-(NSInteger) trainingTimeInSeconds:(NSNumber*)typeID 
						 fromLevel:(NSInteger)fromLevel 
						   toLevel:(NSInteger)toLevel 
		   accountForTrainingSkill:(BOOL)train;

/**
 Calculate the portion of a skill that has been trained to the specified level.

 @param typeID    The skill's type ID.
 @param fromLevel The starting level.
 @param toLevel   The ending level.

 @return The skill's progress, from 0.0 (no training) to 1.0 (fully trained).
 */
-(CGFloat) percentCompleted:(NSNumber*)typeID
				  fromLevel:(NSInteger)fromLevel 
					toLevel:(NSInteger)toLevel;

/**
 Calculate the number of skill-points trained per hour.

 @param primary   The skill's primary attribute.
 @param secondary The skill's secondary attribute.

 @return The number of skill-points trained per hour.
 */
-(NSInteger) spPerHour:(NSInteger)primary
			 secondary:(NSInteger)secondary;

/**
 Calculate the number of skill-points trained per hour for the skill currently
 in training.

 @return The number of skill-points trained per hour.
 */
-(NSInteger) spPerHour;

/**
 Check if this character is currently training a skill.

 @return `YES` if the character is training; `NO` otherwise.
 */
-(BOOL) isTraining;

/**
 Get the skill this character is currently training.

 @bug The return value is undefined if no skill is being trained.

 @return The typeID of the skill in training.
 */
-(NSNumber*)trainingSkill;

/*
 returns autoreleased objects
 DO NOT call these methods if isTraining returns NO
 */

/**
 Get the time until the skill currently training advances to the next level.

 @warning Do not call this method if isTraining returns `NO`.

 @return The number of seconds until the next level is attained in the
 currently-training skill.
 */
-(NSInteger) skillTrainingFinishSeconds;

/**
 Get the number of skill points trained to date in the currently-training skill.

 @warning Do not call this method if isTraining returns `NO`.

 @return The number of skill points in the currently-training skill, rounded
 to the nearest integer.
 */
-(NSInteger) currentSPForTrainingSkill;

/**
 Get the currently-training skill.

 @warning Do not call this method if isTraining returns `NO`.

 @return The currently-training skill as a `SkillPair`.
 */
-(SkillPair*) currentlyTrainingSkill;

/**
 Get the end time for this character's queued training.

 @warning Do not call this method if isTraining returns `NO`.

 @return The time at which thhis character's currently-queued training ends.
 */
-(NSDate*) skillTrainingFinishDate;

/**
 @name Skill Plans
 */

/**
 Get this character's skill set.

 TODO: What does this function do? What is it used for? I haven't the slightest
 clue.

 @return The skill set dictionary.
 */
-(NSDictionary*) skillSet;

/**
 Get the number of skill plans created for this user.

 @return The number of skill plans.
 */
-(NSInteger) skillPlanCount;

/**
 Create a new skill plan for this user.

 @param planName The new skill plan's name.

 @return A SkillPlan object for the new skill plan.
 */
-(SkillPlan*) createSkillPlan:(NSString*)planName;

// TODO: This is messy; remove the redundant ones and have a single method
/**
 Remove a skill plan.

 @param plan The SkillPlan object to be removed.
 */
-(void) removeSkillPlan:(SkillPlan*)plan;

/**
 Remove a skill plan by its local database ID.

 @param planId The plan's database ID (primary key).
 */
-(void) removeSkillPlanById:(NSInteger)planId;

/**
 Remove a skill plan by its array index.

 @param index The plan's index.
 */
-(void) removeSkillPlanAtIndex:(NSInteger)index;

/**
 Find a skill plan by its array index.

 @param index The index into this character's plan arry.

 @return The SkillPlan at that index. If the index is invalid, throws
 `NSRangeException`.
 */
-(SkillPlan*) skillPlanAtIndex:(NSInteger)index;

/**
 Find a skill plan by its local database ID.

 @param planId The plan's database ID (primary key).

 @return The SkillPlan with that ID, or `nil` if no such plan exists.
 */
-(SkillPlan*) skillPlanById:(NSInteger)planId;
-(NSInteger) indexOfPlan:(SkillPlan *)plan;

/**
 Save a skill plan's name change to local storage; its `planName`
 property should have already been changed to the new name.

 @param plan The SkillPlan to save.

 @return `YES` if the save was successful, or `NO` otherwise.
 */
-(BOOL) renameSkillPlan:(SkillPlan*)plan;

/**
 Change one or more skill plans' positions in the character's list of plans.

 @param fromIndexArray The SkillPlans' current array indices.
 @param toIndex        The position at which to insert the SkillPlans.

 @return An NSIndexSet containing the SkillPlans' new indices.
 */
-(NSIndexSet *) moveSkillPlan:(NSArray*)fromIndexArray to:(NSInteger)toIndex;

/* Sort the skill plan overview. Sort based on planOrder to return to manual sort */
- (void)sortSkillPlansUsingDescriptors:(NSArray *)descriptors;

/* TODO: The skill functions below will be (possibly) be ripped out later. */

/**
 Write a skill plan's changes, if any, to local storage.

 @param plan The SkillPlan to commit.
 */
-(void) updateSkillPlan:(SkillPlan*)plan;

/**
 @name Error Messages
 */

/* TODO: These error functions might also get ripped out. */

/**
 Check for a character sheet error.

 @return `YES` if there is a character sheet error to display; `NO` otherwise.
 */
-(BOOL) charSheetError;

/**
 Get the current character sheet error message.

 @return The current character sheet error message, or `nil` if none.
 */
-(NSString*) charSheetErrorMessage;

/**
 Check for a training sheet error.

 @return `YES` if there is a training sheet error to display; `NO` otherwise.
 */
-(BOOL) trainingSheetError;

/**
 Get the current training sheet error message.

 @return The current training sheet error message, or `nil` if none.
 */
-(NSString*) trainingSheetErrorMessage;

/**
 @name Character Attributes
 */

// Used for optimising a skill plan.

/**
 Modify a character attribute.

 @param attribute The attribute to modify, as defined in `macros.h`.
 @param level     The number of levels to add (or subtract if negative).
 */
-(void) modifyAttribute:(NSInteger)attribute  byLevel:(NSInteger)level;

/**
 Set a character attribute.

 @param attribute The attribute to modify, as defined in `macros.h`.
 @param level     The new level for the attribute.
 */
-(void) setAttribute:(NSInteger)attribute toLevel:(NSInteger)level;

/**
 Reset all temporary attribute bonuses.
 */
-(void) resetTempAttrBonus;

/**
 Calculate the effective attributes based on implants and other bonuses.
 */
-(void) processAttributeSkills;

/**
 Check if this character has been awarded a certificate.

 @param certID The certificate to check, expressed as the `certificateID`
 attribute from the Certificate Tree API call.

 @return `YES` if this character has the specified certificate; `NO` otherwise.
 */
-(BOOL) hasCert:(NSInteger)certID;

/**
 Get this character's template object.

 @return The `CharacterTemplate` corresponding to this character.
 */
-(CharacterTemplate *)template;

@end
