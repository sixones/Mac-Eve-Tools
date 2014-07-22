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

#import "Character.h"

/*
 Do NOT call any of these methods yourself; this file should only be included
 by the Character class.
 */

@interface Character (CharacterPrivate)

/**
 Parse the XML returned by the Character Sheet EVE API call and update this
 character with the information.
 
 This function is the entry point to XML processing called by the
 `Character` constructor.
 
 @param path The directory on disk containing the returned XML document.

 @return `YES` if the character sheet was successfully processed; `NO`
 otherwise.
 */
-(BOOL) parseCharacterXml:(NSString*)path;

/**
 Parse the character's skills from the Character Sheet API call.

 @param rowset The character sheet's `skills` element as an `xmlNode`.

 @return `YES` if the skills were successfully processed; `NO` otherwise.
 */
-(BOOL) buildSkillTree:(xmlNode*)rowset;

/**
 Parse the XML returned from the Character Sheet API call.

 @param document The root of the character sheet.

 @return `YES` if the character sheet was successfully processed; `NO`
 otherwise.
 */
-(BOOL) parseXmlSheet:(xmlDoc*)document;

/**
 Parse the XML returned from the Skill in Training API call.

 @param document The root of the returned XML.

 @return `YES` if the skill in training was successfully processed; `NO`
 otherwise.
 */
-(BOOL) parseXmlTraningSheet:(xmlDoc*)document;

/**
 Parse the XML returned from the Training Queue API call.

 @param document The root of the returned XML.

 @return `YES` if the training queue was successfully processed; `NO`
 otherwise.
 */
-(BOOL) parseXmlQueueSheet:(xmlDoc*)document;

/**
 Parse the `attributes` node of the character sheet XML.

 @param attributes The `attributes` node.

 @return `YES` if the attributes were successfully processed; `NO`
 otherwise.
 */
-(BOOL) parseAttributes:(xmlNode*)attributes;

/**
 Parse the `attributeEnhancers` node of the character sheet XML.

 @param attrs The `attributeEnhancers` node.

 @return `YES` if the attributes were successfully processed; `NO`
 otherwise.
 */
-(BOOL) parseAttributeImplants:(xmlNode*)attrs;

/**
 Store data from the parsed XML in this object's dictionary.

 @param xmlKey The node's name.
 @param value  The node's value as text.
 */
-(void) addToDictionary:(const xmlChar*)xmlKey value:(NSString*)value;

/**
 Read this character's saved skill plans from local storage.
 If the skill plans already exist in memory, they are reloaded and the existing
 copy is released.

 @return The number of skill plans loaded.
 */
-(NSInteger) readSkillPlans;

/**
 Write this character's skill plans to local storage.

 @return `YES` if the write was successful; `NO` otherwise.
 */
-(BOOL) writeSkillPlan;

@end
