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

#import "CCPGroup.h"
#import "CCPType.h"
#import "CCPDatabase.h"

#import "METSubGroup.h"

#import "macros.h"

@implementation CCPGroup

@synthesize groupID;
@synthesize categoryID;
@synthesize groupName;

-(CCPGroup*) init
{
	if(self = [super init]){

	}
	return self;
}

-(void) appendTypesToSubgroup:(NSMutableArray*)sub subGroup:(METSubGroup*)group
{
	
}

-(void) buildSubGroups:(NSArray*)typeArray
{
    NSMutableDictionary *subGroupsTemp = [NSMutableDictionary dictionary];
    
	for(CCPType *type in types)
    {
        NSString *raceName = [database nameForRace:[type raceID]];
        if( raceName )
        {
            METSubGroup *subgroup = [subGroupsTemp objectForKey:raceName];
            if( !subgroup )
            {
                subgroup = [[METSubGroup alloc]
                            initWithName:raceName
                            andTypes:nil
                            forMetaGroup:NullType
                            withRace:[type raceID]];
                [subGroupsTemp setObject:subgroup forKey:raceName];
                [subgroup release];
            }
            [subgroup addType:type];
        }
        else
        {
            NSLog( @"Unknown race ID: %ld", (long)[type raceID] );
        }
	}
	
	[subGroups release];
	subGroups = [[NSMutableArray alloc] initWithArray:[subGroupsTemp allValues]];
}

-(CCPGroup*) initWithGroup:(NSInteger)gID
				  category:(NSInteger)cID
				 groupName:(NSString*)gName
				  database:(CCPDatabase*)db
{
	if(self = [self init]){
		groupID = gID;
		categoryID = cID;
		groupName = [gName retain];
		database = [db retain];
		types = [[database typesInGroup:gID]retain];
		count = [types count];
	}
	return self;
}

-(void)dealloc
{
	[types release];
	[groupName release];
	[database release];
	[subGroups release];
	[super dealloc];
}

-(NSInteger) typeCount
{
	return count;
}
-(CCPType*) typeAtIndex:(NSInteger)index
{
	return [types objectAtIndex:index];
}
-(CCPType*) typeByID:(NSInteger)tID
{
	for(CCPType *t in types){
		if([t typeID] == tID){
			return t;
		}
	}
	return nil;
}

-(NSInteger) subGroupCount
{
	if([subGroups count] == 0){
		[self buildSubGroups:types];
	}
	return [subGroups count];
}

-(METSubGroup*) subGroupAtIndex:(NSInteger)index
{
	return [subGroups objectAtIndex:index];
}


@end
