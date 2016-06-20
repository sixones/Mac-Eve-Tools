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

#import "CharacterPrivate.h"

#import "Config.h"
#import "GlobalData.h"
#import "XmlHelpers.h"
#import "CharacterDatabase.h"
#import "SkillPlan.h"
#import "CCPType.h"
#import "CCPDatabase.h"
#import "CCPImplant.h"
#import "METJumpClone.h"

#import "XMLDownloadOperation.h"

#include <assert.h>

#include <libxml/tree.h>
#include <libxml/parser.h>


@implementation Character (CharacterPrivate) 


/*
	Wrapper function that parses all the XML sheets for this character.
 */
-(BOOL) parseCharacterXml:(NSString*)path
{
	NSString *xmlPath;
	xmlDoc *doc;
	BOOL rc = NO;
	
	xmlPath = [path stringByAppendingFormat:@"/%@",[XMLAPI_CHAR_SHEET lastPathComponent]];
	
	/*Parse CharacterSheet.xml.aspx*/
	doc = xmlReadFile([xmlPath fileSystemRepresentation],NULL,0);
	if(doc == NULL){
		NSLog(@"Failed to read %@",xmlPath);
		return NO;
	}
	rc = [self parseXmlSheet:doc];
	xmlFreeDoc(doc);
	
	if(!rc){
		NSLog(@"Failed to parse %@",xmlPath);
		return NO;
	}
	
	
	/*parse the skill in training.*/
	xmlPath = [path stringByAppendingFormat:@"/%@",[XMLAPI_CHAR_TRAINING lastPathComponent]];
	
	doc = xmlReadFile([xmlPath fileSystemRepresentation],NULL,0);
	if(doc == NULL){
		NSLog(@"Failed to read %@",xmlPath);
		return NO;
	}
	rc = [self parseXmlTraningSheet:doc];
	xmlFreeDoc(doc);

	if(!rc){
		NSLog(@"Failed to parse %@",xmlPath);
		return NO;
	}
	
	
	/*parse the training queue*/
	xmlPath = [path stringByAppendingFormat:@"/%@",[XMLAPI_CHAR_QUEUE lastPathComponent]];
	doc = xmlReadFile([xmlPath fileSystemRepresentation],NULL,0);
	if(doc == NULL){
		NSLog(@"Failed to read %@",xmlPath);
		return NO;
	}
	rc = [self parseXmlQueueSheet:doc];
	xmlFreeDoc(doc);
	
	if(!rc){
		NSLog(@"Failed to parse %@",xmlPath);
		return NO;
	}
	
	/*
	 All the required XML sheets have been parsed successfully
	 The Character Object is ready for usage.
	 */
	return YES;	
}



-(BOOL) xmlValidateData:(NSData*)xmlData xmlPath:(NSString*)path xmlDocName:(NSString*)docName
{
	BOOL rc = YES;
	
	/*Don't try and validate the character portrait*/
	if([docName isEqualToString:PORTRAIT]){
		return YES;
	}
	
	const char *bytes = [xmlData bytes];
	
	xmlDoc *doc = xmlReadMemory(bytes,(int)[xmlData length], NULL, NULL, 0);
	if(doc == NULL){
		return NO;
	}
	xmlNode *root_node = xmlDocGetRootElement(doc);
	if(root_node == NULL){
		xmlFreeDoc(doc);
		return NO;
	}
	xmlNode *result = findChildNode(root_node,(xmlChar*)"error");
	
	if(result != NULL){
		NSLog(@"%@",getNodeText(result));
		rc = NO;
	}
	
	xmlFreeDoc(doc);
	return rc;
}



/*
-(XMLDownloadOperation*) buildOperation:(NSString*)docPath
{

	NSString *apiUrl = [Config getApiUrl:docPath 
							   keyID:[account keyID] 
								  verificationCode:[account verificationCode]
								  charId:characterId];

	
	NSString *characterDir = [Config charDirectoryPath:[account keyID] 
											 character:[self characterId]];
	
	XMLDownloadOperation *op;
	
	op = [[XMLDownloadOperation alloc]init];
	[op setXmlDocUrl:apiUrl];
	[op setCharacterDirectory:characterDir];
	[op setXmlDoc:docPath];
	
	[op autorelease];
	
	return op;
}
*/

-(BOOL) parseCertList:(xmlNode*)rowset
{
	xmlNode *cur_node;
	for(cur_node = rowset->children;
		cur_node != NULL;
		cur_node = cur_node->next)
	{
		if(cur_node->type != XML_ELEMENT_NODE){
			continue;
		}
		
		NSString *certID = findAttribute(cur_node,(xmlChar*)"certificateID");
		
		[ownedCerts addObject:[NSNumber numberWithInteger:[certID integerValue]]];
	}
	
	return YES;
}


/*
 Build the SkillTree Object for the Character Skill Rowset.
 Requres the (hopefully) already constructed global skill tree
 so we can get the skill ID and determine what group it belongs to.
 
 for each skill
 find the group
 does the group exist in the tree?
 yes: add to that group
 no: create the group
 add the group to the tree
 add the skill to the group.
 
 this will give us a complete skill tree for this character
 */
-(BOOL) buildSkillTree:(xmlNode*)rowset;
{
	xmlNode *cur_node;
	SkillTree *master = [[GlobalData sharedInstance]skillTree];
	
	if(skillTree != nil){
		[skillTree release];
		skillTree = nil;
	}
	
	skillTree = [[SkillTree alloc]init];
	
	for(cur_node = rowset->children;
		cur_node != NULL;
		cur_node = cur_node->next)
	{
		NSString *typeID;
		NSString *skillPoints;
		NSString *level;
		
		if(cur_node->type != XML_ELEMENT_NODE){
			continue;
		}
		
		typeID = findAttribute(cur_node,(xmlChar*)"typeID");
		skillPoints = findAttribute(cur_node,(xmlChar*)"skillpoints");
		level = findAttribute(cur_node,(xmlChar*)"level");
		
		/*
		 Here we have all the details we can get from the character sheet for the skill.
		 Now we need to build up a skill tree using the details
		 */
		
		//NSLog(@"%@ %@ %@",typeID, skillPoints, level);
		Skill *temp = [master skillForIdInteger:[typeID integerValue]];
		if(temp == nil){
			NSLog(@"Error: cannot find skill %@ in skill tree! - skipping skill",typeID);
			continue;
		}
		Skill *s = [temp copy];
		[s setSkillPoints:[skillPoints integerValue]];
		[s setSkillLevel:[level integerValue]];
		
		SkillGroup *sg;
		if((sg = [skillTree groupForId:[s groupID]]) == nil){ /*If the skill group does not exist*/
			SkillGroup *masterGroup = [master groupForId:[s groupID]];
			assert(masterGroup != nil);
			sg = [[SkillGroup alloc]initWithDetails:[masterGroup groupName] group:[masterGroup groupID]];
			[skillTree addSkillGroup:sg]; /*add the skill group to the tree*/
			[sg autorelease];
		}
		[skillTree addSkill:s toGroup:[s groupID]];
		[s release];
	}
	
	/*once the skill tree has been parsed, we can read the training plans*/
	[self readSkillPlans];
	
	return YES;
}

-(BOOL) parseXmlQueueSheet:(xmlDoc*)document;
{
	xmlNode *root_node;
	xmlNode *result;
	
	root_node = xmlDocGetRootElement(document);
	
	result = findChildNode(root_node,(xmlChar*)"result");
	if(result == NULL){
		xmlNode *xmlErrorMessage = findChildNode(root_node,(xmlChar*)"error");
		if(xmlErrorMessage != NULL){
			errorMessage[CHAR_ERROR_TRAININGSHEET] = [[NSString stringWithString:getNodeText(xmlErrorMessage)]retain];
			error[CHAR_ERROR_TRAININGSHEET] = YES;
			NSLog(@"EVE error: %@",errorMessage[CHAR_ERROR_TRAININGSHEET]);
		}		
		return NO;
	}
	
	if(trainingQueue != nil){
		[trainingQueue release];
		trainingQueue = nil;
	}
	
	trainingQueue = [[SkillPlan alloc]initWithName:@"Training Queue" character:self];
	
	
	xmlNode *rowset = findChildNode(result,(xmlChar*)"rowset");
	
	for(xmlNode *cur_node = rowset->children;
		cur_node != NULL;
		cur_node = cur_node->next)
	{
		if(cur_node->type != XML_ELEMENT_NODE){
			continue;
		}
		NSString *type = findAttribute(cur_node,(xmlChar*)"typeID");
		NSString *level = findAttribute(cur_node,(xmlChar*)"level");
		
		if(type == nil){
			NSLog(@"Error parsing skill plan. typeID is nil");
			return NO;
		}
		if(type == nil){
			NSLog(@"Error parsing skill plan. typeID is nil");
			return NO;
		}
			
		[trainingQueue secretAddSkillToPlan:[NSNumber numberWithInteger:[type integerValue]]
							 level:[level integerValue]];
	}
	
	return YES;
}

-(BOOL) parseXmlTraningSheet:(xmlDoc*)document
{
	xmlNode *root_node;
	xmlNode *result;
	
	root_node = xmlDocGetRootElement(document);
	
	result = findChildNode(root_node,(xmlChar*)"result");
	if(result == NULL){
		NSLog(@"Failed to find result tag");
		xmlNode *xmlErrorMessage = findChildNode(root_node,(xmlChar*)"error");
		if(xmlErrorMessage != NULL){
			errorMessage[CHAR_ERROR_TRAININGSHEET] = [[NSString stringWithString:getNodeText(xmlErrorMessage)]retain];
			error[CHAR_ERROR_TRAININGSHEET] = YES;
			NSLog(@"EVE error: %@",errorMessage[CHAR_ERROR_TRAININGSHEET]);
		}		
		return NO;
	}
	
	for(xmlNode *cur_node = result->children;
		cur_node != NULL;
		cur_node = cur_node->next)
	{
		if(cur_node->type != XML_ELEMENT_NODE){
			continue;
		}
		
		/*
		 since we are essentially grabbing everything we could probably do away with the 
		 xmlStrcmp() functions and stuff everything into the dictionary.
		 */
		
		if(xmlStrcmp(cur_node->name,(xmlChar*)"trainingEndTime") == 0){
			[self addToDictionary:cur_node->name value:getNodeText(cur_node)];
		}else if(xmlStrcmp(cur_node->name,(xmlChar*)"trainingStartTime") == 0){
			[self addToDictionary:cur_node->name value:getNodeText(cur_node)];
		}else if(xmlStrcmp(cur_node->name,(xmlChar*)"trainingTypeID") == 0){
			[self addToDictionary:cur_node->name value:getNodeText(cur_node)];
		}else if(xmlStrcmp(cur_node->name,(xmlChar*)"trainingStartSP") == 0){
			[self addToDictionary:cur_node->name value:getNodeText(cur_node)];
		}else if(xmlStrcmp(cur_node->name,(xmlChar*)"trainingDestinationSP") == 0){
			[self addToDictionary:cur_node->name value:getNodeText(cur_node)];
		}else if(xmlStrcmp(cur_node->name,(xmlChar*)"trainingToLevel") == 0){
			[self addToDictionary:cur_node->name value:getNodeText(cur_node)];
		}else if(xmlStrcmp(cur_node->name,(xmlChar*)"skillInTraining") == 0){
			/*
			 if this is equal to zero, there is no skill in training 
			 the existing skill training data will need to be removed from the dictionary.
			 or the skillInTraining flag set, and the skill panel set or ignored based on that
			 */
			[self addToDictionary:cur_node->name value:getNodeText(cur_node)];
		}
	}
	
	/*clear out error information*/
	error[CHAR_ERROR_TRAININGSHEET] = NO;
	if(errorMessage[CHAR_ERROR_TRAININGSHEET] != nil){
		[errorMessage[CHAR_ERROR_TRAININGSHEET] release];
		errorMessage[CHAR_ERROR_TRAININGSHEET] = nil;
	}	
	
	return YES;
}

/* TODO: Add support for Jump Fatigue:
 <jumpActivation>2014-12-14 04:48:27</jumpActivation>
 <jumpFatigue>2014-12-14 05:41:06</jumpFatigue>
 <jumpLastUpdate>2014-12-14 04:42:37</jumpLastUpdate>
 
 Both jumpFatigue and jumpActivation are time stamps for when those counters expire. So in the above example the character will be able to jump again at 17:33:41 on 2014-10-28 and their fatigue will expire at the same time. jumpLastUpdate is when the last jump occurred by that character. This was included for those who wish to show something like what the EVE client does with timers (such as these). To If you wanted to show something like that you need a start time, and thats what jumpLastUpdate is.
 
http://community.eveonline.com/news/dev-blogs/long-distance-travel-changes-inbound/
 
 TODO: Convert from using a dictionary to properties on the Character class
 
 And next available clone jump using this plus skills:
 <cloneJumpDate>2014-10-08 20:54:50</cloneJumpDate>
 
 And this would be useful when looking at skill plans:
 <rowset name="multiCharacterTraining" key="trainingEnd" columns="trainingEnd">
 <row trainingEnd="2014-12-11 14:15:16" />
 <row trainingEnd="2014-12-11 20:20:20" />
 </rowset>
 
 More info we should grab and display:
 <corporationName>Ravens of Morrighan</corporationName>
 <corporationID>98464925</corporationID>
 <allianceName />
 <allianceID>0</allianceID>
 <factionName />
 <factionID>0</factionID>
 <freeSkillPoints>310000</freeSkillPoints>
 <freeRespecs>2</freeRespecs>
*/
-(BOOL) parseXmlSheet:(xmlDoc*)document
{
    NSMutableDictionary *clones = [NSMutableDictionary dictionary];
	xmlNode *root_node;
	xmlNode *result;
	
	root_node = xmlDocGetRootElement(document);
	
	result = findChildNode(root_node,(xmlChar*)"result");
	if(result == NULL){
		NSLog(@"Could not get result tag");
		
		xmlNode *xmlErrorMessage = findChildNode(root_node,(xmlChar*)"error");
		if(xmlErrorMessage != NULL){
			errorMessage[CHAR_ERROR_CHARSHEET] = [[NSString stringWithString:getNodeText(xmlErrorMessage)]retain];
			error[CHAR_ERROR_CHARSHEET] = YES;
			NSLog(@"EVE error: %@",errorMessage[CHAR_ERROR_CHARSHEET]);
		}
		return NO;
	}
	
	for(xmlNode *cur_node = result->children; 
		cur_node != NULL;
		cur_node = cur_node->next)
	{
		if(cur_node->type != XML_ELEMENT_NODE){
			continue;
		}
		
		if(xmlStrcmp(cur_node->name,(xmlChar*)"characterID") == 0){
			
			NSString *charIdString = getNodeText(cur_node);
			
			characterId = (NSUInteger) [charIdString integerValue];
			[self addToDictionary:cur_node->name value:charIdString];
			
		}else if(xmlStrcmp(cur_node->name,(xmlChar*)"name") == 0){
			
			characterName = getNodeText(cur_node);
			[characterName retain];
			[self addToDictionary:cur_node->name value:characterName];
			
		}else if(xmlStrcmp(cur_node->name,(xmlChar*)"race") == 0){
			[self addToDictionary:cur_node->name value:getNodeText(cur_node)];
		}else if(xmlStrcmp(cur_node->name,(xmlChar*)"bloodLine") == 0){
			[self addToDictionary:cur_node->name value:getNodeText(cur_node)];
		}else if(xmlStrcmp(cur_node->name,(xmlChar*)"gender") == 0){
			[self addToDictionary:cur_node->name value:getNodeText(cur_node)];
		}else if(xmlStrcmp(cur_node->name,(xmlChar*)"corporationName") == 0){
			[self addToDictionary:cur_node->name value:getNodeText(cur_node)];
		}else if(xmlStrcmp(cur_node->name,(xmlChar*)"corporationID") == 0){
			[self addToDictionary:cur_node->name value:getNodeText(cur_node)];
		}else if(xmlStrcmp(cur_node->name,(xmlChar*)"balance") == 0){
			[self addToDictionary:cur_node->name value:getNodeText(cur_node)];
		}else if(xmlStrcmp(cur_node->name,(xmlChar*)"attributes") == 0){
			/*process attributes here*/
			[self parseAttributes:cur_node];
		}
        else if( xmlStrcmp(cur_node->name,(xmlChar*)"cloneJumpDate") == 0 )
        {
            /*  <cloneJumpDate>2014-10-08 20:54:50</cloneJumpDate> */
            NSString *cloneJumpString = getNodeText(cur_node);
            if( cloneJumpString )
            {
                NSDate *cloneJumpDate = [NSDate dateWithNaturalLanguageString:cloneJumpString];
                [self setJumpCloneDate:cloneJumpDate];
            }
		}
        else if(xmlStrcmp(cur_node->name,(xmlChar*)"rowset") == 0)
        {
			
			xmlChar* rowset_name = xmlGetProp(cur_node,(xmlChar*)"name");
			
			if(xmlStrcmp(rowset_name,(xmlChar*)"skills") == 0)
            {
				/*process the skills for the character here.*/
				[self buildSkillTree:cur_node];
			}
            else if(xmlStrcmp(rowset_name,(xmlChar*)"certificates") == 0)
            {
				[self parseCertList:cur_node];
			}
            else if(xmlStrcmp(rowset_name,(xmlChar*)"implants") == 0)
            {
                [self parseImplants:cur_node];
            }
            else if(xmlStrcmp(rowset_name,(xmlChar*)"jumpClones") == 0)
            {
                [self parseJumpClones:cur_node into:clones];
            }
            else if(xmlStrcmp(rowset_name,(xmlChar*)"jumpCloneImplants") == 0)
            {
                [self parseJumpCloneImplants:cur_node into:clones];
            }
			xmlFree(rowset_name);
		}
	}
	
	/*sum all the values*/
	[self processAttributeSkills];
    [self setJumpClones:clones];
    
	/*
		The Characater must have been completly built up and is ready for use
	 */
	
	error[CHAR_ERROR_CHARSHEET] = NO;
	if(errorMessage[CHAR_ERROR_CHARSHEET] != nil){
		[errorMessage[CHAR_ERROR_CHARSHEET] release];
	}
	
	return YES;
}

/*base attributes before any modifiers are applied*/
-(BOOL) parseAttributes:(xmlNode*)attributes
{
	for(xmlNode *cur_node = attributes->children;
		cur_node != NULL;
		cur_node = cur_node->next)
	{
		if(cur_node->type != XML_ELEMENT_NODE){
			continue;
		}
		
		NSInteger value = [getNodeText(cur_node) integerValue];
		
		if(xmlStrcmp(cur_node->name,(xmlChar*)"intelligence") == 0){
			baseAttributes[ATTR_INTELLIGENCE] = value;
		}else if(xmlStrcmp(cur_node->name,(xmlChar*)"memory") == 0){
			baseAttributes[ATTR_MEMORY] = value;
		}else if(xmlStrcmp(cur_node->name,(xmlChar*)"charisma") == 0){
			baseAttributes[ATTR_CHARISMA] = value;
		}else if(xmlStrcmp(cur_node->name,(xmlChar*)"perception") == 0){
			baseAttributes[ATTR_PERCEPTION] = value;
		}else if(xmlStrcmp(cur_node->name,(xmlChar*)"willpower") == 0){
			baseAttributes[ATTR_WILLPOWER] = value;
		}
	}
	return YES;
}

/*
<rowset name="implants" key="typeID" columns="typeID,typeName">
<row typeID="13283" typeName="Limited Ocular Filter" />
<row typeID="9956" typeName="Social Adaptation Chip - Basic" />
<row typeID="9941" typeName="Memory Augmentation - Basic" />
<row typeID="9943" typeName="Cybernetic Subprocessor - Basic" />
</rowset>
*/
-(BOOL) parseImplants:(xmlNode*)attrs
{
    CCPDatabase *ccpdb = [[GlobalData sharedInstance] database];

    for(xmlNode *attr_node = attrs->children;
        attr_node != NULL;
        attr_node = attr_node->next)
    {
        if(attr_node->type != XML_ELEMENT_NODE){
            continue;
        }
        
        xmlChar* typeID = xmlGetProp(attr_node,(xmlChar*)"typeID");
//        xmlChar* typeName = xmlGetProp(attr_node,(xmlChar*)"typeName");
        
        NSString *typeIDString = [NSString stringWithUTF8String:(const char *)typeID];
        CCPImplant *implant = [ccpdb implantWithID:[typeIDString integerValue]]; // TODO: save these if/when we have some other use for them. E.g. showing the user what implants they have injected
        implantAttributes[ATTR_PERCEPTION] += [implant perception];
        implantAttributes[ATTR_MEMORY] += [implant memory];
        implantAttributes[ATTR_WILLPOWER] += [implant willpower];
        implantAttributes[ATTR_INTELLIGENCE] += [implant intelligence];
        implantAttributes[ATTR_CHARISMA] += [implant charisma];

    }
    return YES;
}

/*
<rowset name="jumpClones" key="jumpCloneID" columns="jumpCloneID,typeID,locationID,cloneName">
<row jumpCloneID="19933997" typeID="164" locationID="60010825" cloneName="" />
<row jumpCloneID="20412514" typeID="164" locationID="60010861" cloneName="" />
<row jumpCloneID="20842890" typeID="164" locationID="61000260" cloneName="" />
</rowset>
*/
-(BOOL) parseJumpClones:(xmlNode*)attrs into:(NSMutableDictionary *)clones
{
    for(xmlNode *attr_node = attrs->children;
        attr_node != NULL;
        attr_node = attr_node->next)
    {
        if( attr_node->type != XML_ELEMENT_NODE )
        {
            continue;
        }
        if( xmlStrcmp(attr_node->name,(xmlChar*)"row") != 0 )
        {
            continue;
        }

        xmlChar* cloneIDString = xmlGetProp(attr_node,(xmlChar*)"jumpCloneID");
        xmlChar* typeIDString = xmlGetProp(attr_node,(xmlChar*)"typeID");
        xmlChar* locationIDString = xmlGetProp(attr_node,(xmlChar*)"locationID");
        xmlChar* cloneName = xmlGetProp(attr_node,(xmlChar*)"cloneName");
        
        NSInteger cloneID = (NSInteger) [[NSString stringWithUTF8String:(char *)cloneIDString] integerValue];
        NSInteger typeID = (NSInteger) [[NSString stringWithUTF8String:(char *)typeIDString] integerValue];
        NSInteger locationID = (NSInteger) [[NSString stringWithUTF8String:(char *)locationIDString] integerValue];
        NSString *name = [NSString stringWithUTF8String:(char *)cloneName];
        
        METJumpClone *clone = [clones objectForKey:[NSNumber numberWithInteger:cloneID]];
        if( !clone )
        {
            clone = [[[METJumpClone alloc] initWithID:cloneID] autorelease];
            [clones setObject:clone forKey:[NSNumber numberWithInteger:cloneID]];
        }
        [clone setTypeID:typeID];
        [clone setLocationID:locationID];
        [clone setCloneName:name];
    }
    return YES;
}

/*
<rowset name="jumpCloneImplants" key="jumpCloneID" columns="jumpCloneID,typeID,typeName">
<row jumpCloneID="19933997" typeID="9899" typeName="Ocular Filter - Basic" />
<row jumpCloneID="19933997" typeID="9941" typeName="Memory Augmentation - Basic" />
<row jumpCloneID="19933997" typeID="9942" typeName="Neural Boost - Basic" />
<row jumpCloneID="19933997" typeID="9943" typeName="Cybernetic Subprocessor - Basic" />
</rowset>
*/
-(BOOL) parseJumpCloneImplants:(xmlNode*)attrs into:(NSMutableDictionary *)clones
{
    CCPDatabase *ccpdb = [[GlobalData sharedInstance] database];

    for(xmlNode *attr_node = attrs->children;
        attr_node != NULL;
        attr_node = attr_node->next)
    {
        if( attr_node->type != XML_ELEMENT_NODE )
        {
            continue;
        }
        if( xmlStrcmp(attr_node->name,(xmlChar*)"row") != 0 )
        {
            continue;
        }
        
        xmlChar* cloneIDString = xmlGetProp(attr_node,(xmlChar*)"jumpCloneID");
        xmlChar* typeIDString = xmlGetProp(attr_node,(xmlChar*)"typeID");
        xmlChar* typeName = xmlGetProp(attr_node,(xmlChar*)"typeName");
        
        NSInteger cloneID = (NSInteger) [[NSString stringWithUTF8String:(char *)cloneIDString] integerValue];
        NSInteger typeID = (NSInteger) [[NSString stringWithUTF8String:(char *)typeIDString] integerValue];
        
        METJumpClone *clone = [clones objectForKey:[NSNumber numberWithInteger:cloneID]];
        if( !clone )
        {
            clone = [[[METJumpClone alloc] initWithID:cloneID] autorelease];
            [clones setObject:clone forKey:[NSNumber numberWithInteger:cloneID]];
        }
        
        CCPImplant *implant = [ccpdb implantWithID:typeID];

        [clone addImplant:implant];
        
        NSString *implantName = [NSString stringWithUTF8String:(char *)typeName];
        if( ![implantName isEqualToString:[implant typeName]] )
            NSLog( @"Implant names differ: %@   vs   %@", implantName, [implant typeName] );
    }
    return YES;
}

-(void) addToDictionary:(const xmlChar*)xmlKey value:(NSString*)value
{
	[data setValue:value forKey:[NSString stringWithUTF8String:(const char*)xmlKey]];
}

/*
 read the character skill plans from the sqlite database. delete the internal list if it exists
*/

-(NSInteger) readSkillPlans
{
	if(skillPlans != nil){
		[skillPlans release];
	}
	
	skillPlans = [[database readSkillPlans:self]retain];
	
	return [skillPlans count];
}

-(BOOL) writeSkillPlan
{
	return [database writeSkillPlans:skillPlans];
}



/*
 This is some of the old updating code that existed before the CharacterManager class.
 It shouldn't be used anymore.
 */
-(void) xmlDidFailWithError:(NSError*)xmlErrorMessage xmlPath:(NSString*)path xmlDocName:(NSString*)docName
{
	assert(0);
	NSLog(@"Connection failed! (%@)",[xmlErrorMessage localizedDescription]);
}

-(void) xmlDocumentFinished:(BOOL)status xmlPath:(NSString*)path xmlDocName:(NSString*)docName;
{
	assert(0);
	if(status == NO){
		NSLog(@"Failed to download XML %@",docName);
		return;
	}
	
	BOOL rc = NO;
	
	if([docName isEqualToString:XMLAPI_CHAR_TRAINING]){
		xmlDoc *doc = xmlReadFile([path fileSystemRepresentation],NULL,0);
		
		if(doc == NULL){
			NSLog(@"Error reading %@",path);
		}else{
			rc = [self parseXmlTraningSheet:doc];
			xmlFreeDoc(doc);
		}
	}else if([docName isEqualToString:XMLAPI_CHAR_SHEET]){
		xmlDoc *doc = xmlReadFile([path fileSystemRepresentation],NULL,0);
		
		if(doc == NULL){
			NSLog(@"Error reading %@",path);
		}else{
			rc = [self parseXmlSheet:doc];
			xmlFreeDoc(doc);
			
			NSLog(@"%@ finished update procedure",characterName);		
			for(SkillPlan *plan in skillPlans){
				if([plan purgeCompletedSkills] > 0){
					NSLog(@"Purging plan %@",[plan planName]);
					/*we prob don't need to post this notification anymore*/
					[[NSNotificationCenter defaultCenter]
					 postNotificationName:CHARACTER_SKILL_PLAN_PURGED
					 object:plan];	
				}
			}
			
			[[NSNotificationCenter defaultCenter]
			 postNotificationName:CHARACTER_SHEET_UPDATE_NOTIFICATION 
			 object:self];
		}
	}else if([docName isEqualToString:PORTRAIT]){
		rc = status;
	}else if([docName isEqualToString:XMLAPI_CHAR_QUEUE]){
		xmlDoc *doc = xmlReadFile([path fileSystemRepresentation],NULL,0);
		
		if(doc == NULL){
			NSLog(@"Error reading %@",path);
		}else{
			rc = [self parseXmlQueueSheet:doc];
			xmlFreeDoc(doc);
		}
		
	}else{
		NSLog(@"Unknown callback %@",docName);
		assert(0);
	}
}

@end
