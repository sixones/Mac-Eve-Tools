//
//  Cert.m
//  Mac Eve Tools
//
//  Created by Matt Tyson on 25/01/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "Cert.h"
#import "GlobalData.h"
#import "CertPair.h"
#import "CertTree.h"
#import "CertClass.h"
#import "SkillPair.h"
#import "Character.h"

@interface Cert()
@property (readwrite,nonatomic,retain) NSArray* basicSkills;
@property (readwrite,nonatomic,retain) NSArray* standardSkills;
@property (readwrite,nonatomic,retain) NSArray* improvedSkills;
@property (readwrite,nonatomic,retain) NSArray* advancedSkills;
@property (readwrite,nonatomic,retain) NSArray* eliteSkills;
@end

@implementation Cert

@synthesize certID;
@synthesize groupID;
@synthesize name;
@synthesize certDescription;

@synthesize basicSkills;
@synthesize standardSkills;
@synthesize improvedSkills;
@synthesize advancedSkills;
@synthesize eliteSkills;

-(void) dealloc
{
    [name release];
	[certDescription release];
	[super dealloc];
}

-(NSString*) nameForCertLevel:(NSInteger)level
{
	NSString *grade;
	switch (level) {
		case 1:
			grade = @"Basic";
			break;
		case 2:
			grade = @"Standard";
			break;
		case 3:
			grade = @"Improved";
			break;
		case 4:
			grade = @"Advanced";
			break;
		case 5:
			grade = @"Elite";
			break;
			
		default:
			grade = @"???";
	}
	
	return grade;
}

-(NSString*) fullCertName
{
	return [self name];
}

-(void)addOneSkill:(int)index fromArray:(NSArray *)aSkill toArray:(NSMutableArray *)array
{
    NSInteger level = [[aSkill objectAtIndex:index] integerValue];
    if( level > 0 )
    {
        [array addObject:[SkillPair withSkill:[aSkill objectAtIndex:0] level:level]];
    }
}

-(void)parseDatabaseSkills:(NSArray *)skills
{
    NSMutableArray *basic = [NSMutableArray array];
    NSMutableArray *standard = [NSMutableArray array];
    NSMutableArray *improved = [NSMutableArray array];
    NSMutableArray *advanced = [NSMutableArray array];
    NSMutableArray *elite = [NSMutableArray array];
    
    for( NSArray *aSkill in skills )
    {
        [self addOneSkill:1 fromArray:aSkill toArray:basic];
        [self addOneSkill:2 fromArray:aSkill toArray:standard];
        [self addOneSkill:3 fromArray:aSkill toArray:improved];
        [self addOneSkill:4 fromArray:aSkill toArray:advanced];
        [self addOneSkill:5 fromArray:aSkill toArray:elite];
    }
    
    [self setBasicSkills:basic];
    [self setStandardSkills:standard];
    [self setImprovedSkills:improved];
    [self setAdvancedSkills:advanced];
    [self setEliteSkills:elite];
}

-(Cert*) initWithDetails:(NSInteger)cID 
				   group:(NSInteger)gID
                    name:(NSString *)cName
					text:(NSString*)cDesc
				skillPre:(NSArray*)sPre
{
	if((self = [super init])){
		certID = cID;
        groupID = gID;
        name = [cName retain];
		certDescription = [cDesc retain];
        [self parseDatabaseSkills:sPre];
	}
	return self;
}

+(Cert*) createCert:(NSInteger)cID 
			  group:(NSInteger)gID
               name:(NSString *)cName
			   text:(NSString*)cDesc
		   skillPre:(NSArray*)sPre
{
	Cert *c = [[Cert alloc]initWithDetails:cID 
									 group:gID
                                      name:cName
									  text:cDesc
								  skillPre:sPre];
	return [c autorelease];
}

-(NSArray *) skillsForLevel:(NSInteger)level
{
    NSArray *skills = nil;
	switch (level) {
		case 1:
			skills = [self basicSkills];
			break;
		case 2:
			skills = [self standardSkills];
			break;
		case 3:
			skills = [self improvedSkills];
			break;
		case 4:
			skills = [self advancedSkills];
			break;
		case 5:
			skills = [self eliteSkills];
			break;
	}
    return [[skills retain] autorelease];
}

-(BOOL) character:(Character *)_character hasLevel:(NSInteger)level
{
    NSArray *skillPairs = [self skillsForLevel:level];
    SkillTree *charSkills = [_character skillTree];
    
    for( SkillPair *skillPair in skillPairs )
    {
        // if the character doesn't have this skill to this level, return NO
        Skill *sk = [charSkills skillForId:[skillPair typeID]];
        if( [sk skillLevel] < [skillPair skillLevel] )
            return NO;
    }
    
    return YES;
}

@end
