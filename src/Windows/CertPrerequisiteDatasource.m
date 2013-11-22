//
//  CertPrerequisiteDatasource.m
//  Mac Eve Tools
//
//  Created by Matt Tyson on 3/03/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "CertPrerequisiteDatasource.h"


#import "Cert.h"
#import "CertPair.h"
#import "CertTree.h"
#import "Skill.h"
#import "Character.h"
#import "GlobalData.h"
#import "SkillPair.h"
#import "Helpers.h"

@interface CertPrerequisiteDatasource()
@property (readwrite,retain,nonatomic) NSArray *levelSkills; // skills required for this level

@end

@implementation CertPrerequisiteDatasource

@synthesize certLevel;
@synthesize levelSkills;

-(CertPrerequisiteDatasource*) initWithCert:(Cert*)c
							   forCharacter:(Character*)ch;
{
	if((self = [super init])){
		character = [ch retain];
		cert = [c retain];
	}
	
	return self;
}

-(void)dealloc
{
	[character release];
	[cert release];
	[super dealloc];
}

- (void)setCertLevel:(NSInteger)_certLevel
{
    if( certLevel != _certLevel )
    {
        certLevel = _certLevel;
        
        switch(certLevel)
        {
            case 1: [self setLevelSkills:[cert basicSkills]]; break;
            case 2: [self setLevelSkills:[cert standardSkills]]; break;
            case 3: [self setLevelSkills:[cert improvedSkills]]; break;
            case 4: [self setLevelSkills:[cert advancedSkills]]; break;
            case 5: [self setLevelSkills:[cert eliteSkills]]; break;
            default:
                NSAssert(YES,@"Invalid cert level in [CertPrerequisiteDatasource setCertLevel" );
        }
    }
}

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView
{
    return [[self levelSkills] count];
}

- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
    NSString *baseString = nil;
    SkillPair *sp = [[self levelSkills] objectAtIndex:row];
    NSInteger requiredLevel = [sp skillLevel];
    
    if( [[tableColumn identifier] isEqualToString:@"skill"] )
    {
        baseString = [sp name];
    }
    else if( [[tableColumn identifier] isEqualToString:@"level"] )
    {
        baseString = romanForInteger(requiredLevel);
    }
    
    Skill *s = [[character skillTree] skillForId:[sp typeID]];
    
    NSColor *colour;
    if( s == nil )
    {
        colour = [NSColor redColor];
    }
    else if( [s skillLevel] < requiredLevel )
    {
        colour = [NSColor orangeColor];
    }
    else
    {
        colour = [NSColor blueColor];
    }
    
    return [self colouredString:baseString colour:colour];
}

/*
 The cert prerequisite datasource is a special case, as it does cert 
 prerequisites as well as skill prerequisites.
 
 This could maybe be folded in to the SkillPrerequisiteDatasource, by
 ignoring the cert prereqs if none are given.
 */

-(NSInteger)outlineView:(NSOutlineView *)outlineView 
 numberOfChildrenOfItem:(id)item
{
	if(item == nil){
		return [[cert certPrereqs]count] + [[cert skillPrereqs]count];
	}
	
	if([item isKindOfClass:[CertPair class]]){
		Cert *c = [[[GlobalData sharedInstance]certTree]certForID:[item certID]];
		return [[c certPrereqs]count] + [[c skillPrereqs]count];
	}
	
	if([item isKindOfClass:[SkillPair class]]){
		Skill *s = [[[GlobalData sharedInstance]skillTree]skillForId:[item typeID]];;
		return [[s prerequisites]count];
	}
	
	return 0;
}


-(id) certPairAtIndex:(Cert*)c index:(NSInteger)index
{
	NSInteger certCount = [[c certPrereqs] count];
	if(index < certCount){
		return [[c certPrereqs]objectAtIndex:index];
	}else{
		return [[c skillPrereqs]objectAtIndex:index - certCount];
	}
	return nil;
}

- (id)outlineView:(NSOutlineView *)outlineView 
			child:(NSInteger)index 
		   ofItem:(id)item
{
	/*
	 this is a bit messy, as we need to first count of the cert prerequs, 
	 then move onto skill prereqs if that is greater than than the cert count.
	 */
	if(item == nil){
		return [self certPairAtIndex:cert index:index];
	}
	
	if([item isKindOfClass:[CertPair class]]){
		Cert *c = [[[GlobalData sharedInstance]certTree]certForID:[item certID]];
		return [self certPairAtIndex:c index:index];
	}
	
	if([item isKindOfClass:[SkillPair class]]){
		Skill *s = [[[GlobalData sharedInstance]skillTree]skillForId:[item typeID]];
		return [[s prerequisites]objectAtIndex:index];
	}
	
	NSLog(@"%@",[item className]);
	
	return nil;
}

-(NSAttributedString*) colouredString:(NSString*)str colour:(NSColor*)colour
{
    NSAssert(str, @"Null string in colouredString:colour:");
	NSDictionary *dict = [NSDictionary dictionaryWithObject:colour
													 forKey:NSForegroundColorAttributeName];
	NSAttributedString *astr = [[NSAttributedString alloc]initWithString:str
															  attributes:dict];
	[astr autorelease];
	
	return astr;
}

- (id)outlineView:(NSOutlineView *)outlineView 
objectValueForTableColumn:(NSTableColumn *)tableColumn 
		   byItem:(id)item
{
	if(item == nil){
		return @"nil";
	}
	
	if([item isKindOfClass:[SkillPair class]]){
		
		Skill *s = [[character skillTree]skillForId:[(SkillPair*)item typeID]];
		
		NSColor *colour;
		if(s == nil){
			colour = [NSColor redColor];
		}else if([s skillLevel] < [item skillLevel]){
			colour = [NSColor orangeColor];
		}else{
			colour = [NSColor blueColor];
		}
		
		return [self colouredString:[item roman] colour:colour];
	}
	
	if([item isKindOfClass:[CertPair class]]){
		Cert *c = [[[GlobalData sharedInstance]certTree]certForID:[item certID]];
		
		if([character hasCert:[item certID]]){
			return [self colouredString:[c fullCertName] colour:[NSColor blueColor]];
		}
		
		return [c fullCertName];
	}
	
	return [item className];
}

- (BOOL)outlineView:(NSOutlineView *)outlineView 
   isItemExpandable:(id)item
{
	if([item isKindOfClass:[SkillPair class]]){
		Skill *s = [[[GlobalData sharedInstance]skillTree]skillForId:[item typeID]];
		if([[s prerequisites]count] > 0){
			return YES;
		}
	}
	
	if([item isKindOfClass:[CertPair class]]){
		Cert *c = [[[GlobalData sharedInstance]certTree]certForID:[item certID]];
		if([[c certPrereqs]count] > 0){
			return YES;
		}
		if([[c skillPrereqs]count] > 0){
			return YES;
		}
	}
	
	return NO;
}


@end
