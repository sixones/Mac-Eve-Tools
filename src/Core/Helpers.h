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

#include "macros.h"

/**
 @name Roman Numerals
 */

/**
 Return the Roman numerals corresponding to Arabic numbers.
 
 Example:
 
    romanForString(@"3")
 
 returns `@"III"`.
 
 @param value A number expressed as an NSString of Arabic numerals.
 
 @return The same number expressed with Roman numerals.
 */
NSString* romanForString(NSString *value);

/**
 Converts an integer to Roman numerals.
 
 Example:
 
 romanForInteger(3)
 
 returns `@"III"`.
 
 @param value An `NSInteger` to be converted.
 
 @return The same number expressed with Roman numerals.
 */
NSString* romanForInteger(NSInteger value);

/*
 @name Attribute Codes
 */

/**
 Returns the database code for a given attribute.
 
 @param str An attribute string constant from `macros.h`.
 
 @return The attribute's integer code.
 */
NSInteger attrCodeForString(NSString *str);

/**
 Returns the attribute name for a given attribute code.
 
 @param code An attribute code as returned by `attrCodeForString`.
 
 @return The attribute's string constant from `macros.h`.
 */
NSString* strForAttrCode(NSInteger code);

/**
 Returns the internal attribute code for an attribute code from the EVE Online database dump.
 
 @param dbcode An attribute code from the database dump.
 
 @return The matching internal attribute code from `macros.h`, or 0 if the provided code is invalid.
 */
NSInteger attrCodeForDBInt(NSInteger dbcode);

/**
 @name Directory Creation
 */

/**
 Creates a directory at the given path, and intermediate directories if required.
 
 @param path The full pathname of the directory to be created.
 
 @return `YES` if successful, or `NO` otherwise.
 */
BOOL createDirectory(NSString *path);

/**
 @name Skill Points
 */

/**
 Return the number of skill points required to advance a skill one level.
 
 @param skillLevel The level to be trained to, from 1 to 5.
 @param skillRank  The skill's training-time multiplier, from 1 to 16.
 
 @return The number of skill points required to advance from `skillLevel - 1` to `skillLevel`.
 */
NSInteger skillPointsForLevel(NSInteger skillLevel, NSInteger skillRank);

/**
 Return the number of skill points required to advance a skill to the specified level from level 0.
 
 @param skillLevel The level to be trained to, from 1 to 5.
 @param skillRank  The skill's training-time multiplier, from 1 to 16.
 
 @return The number of skill points required to advance from 0 to `skillLevel`.
 */
NSInteger totalSkillPointsForLevel(NSInteger skillLevel, NSInteger skillRank);

/**
 @name Training Time
 */

/**
 Constants with which to construct a bitmask for `stringTrainingTime2`.
 */
enum TrainingTimeFields
{
	TTF_Days = (1 << 1),
	TTF_Hours = (1 << 2),
	TTF_Minutes = (1 << 3),
	TTF_Seconds = (1 << 4),
	TTF_All = 0xFFFFFFFF
};

/**
 Convert a time in seconds to a string representation.
 
 @param trainingTime The time to be displayed, in seconds.
 @param ttf          A bitmask identifying the `TrainingTimeFields` to be included.
 
 @return A string representation of `trainingTime`.
 */
NSString* stringTrainingTime2(NSInteger trainingTime, enum TrainingTimeFields ttf);

/**
 Convert a time in seconds to a string representation.
 
 @param trainingTime The time to be displayed, in seconds.
 
 @return A string representation of `trainingTime` in the form "0d 0h 0m 0s".
 */
NSString* stringTrainingTime(NSInteger trainingTime);

/**
 Return the progress of a skill level's training.
 
 @param startingPoints  The number of skill points at which training commenced.
 @param finishingPoints The number of skill points at which training will be completed.
 @param currentPoints   The current number of skill points.
 
 @return The current level's progress, from 0.0 to 1.0.
 */
CGFloat skillPercentCompleted(NSInteger startingPoints, NSInteger finishingPoints, NSInteger currentPoints);

/**
 Wrapper for `sqlite3_column_text` that returns an `NSString`.
 
 @param stmt The SQLite prepared statement being evaluated.
 @param col  The index of the text column to return.
 
 @return The contents of the specified column.
 */
NSString* sqlite3_column_nsstr(void *stmt, int col);

/**
 Returns the language corresponding to a `DatabaseLanguage` member.
 
 @param lang A `DatabaseLanguage` member.
 
 @return The human-readable name of the language corresponding to `lang`.
 */
NSString* languageForId(enum DatabaseLanguage lang);

/**
 Returns the ISO-639-2 language code corresponding to a database
 language.
 
 @param lang A `DatabaseLanguage` member.
 
 @return The corresponding ISO-639-2 code, in upper-case, or `NULL` if English.
 */
const char* langCodeForId(enum DatabaseLanguage lang);
