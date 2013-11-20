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

@interface Cert()
@property (readwrite,nonatomic,retain) NSArray* basicSkills;
@property (readwrite,nonatomic,retain) NSArray* standardSkills;
@property (readwrite,nonatomic,retain) NSArray* improvedSkills;
@property (readwrite,nonatomic,retain) NSArray* advancedSkills;
@property (readwrite,nonatomic,retain) NSArray* eliteSkills;
@end

@implementation Cert

@synthesize certID;
@synthesize certGrade;
@synthesize groupID;
@synthesize name;
@synthesize certDescription;

@synthesize skillPrereqs;
@synthesize certPrereqs;
@synthesize basicSkills;
@synthesize standardSkills;
@synthesize improvedSkills;
@synthesize advancedSkills;
@synthesize eliteSkills;

@synthesize parent;

-(void) dealloc
{
    [name release];
	[certDescription release];
	[skillPrereqs release];
	[certPrereqs release];
	[super dealloc];
}

-(NSString*)certGradeText
{
	NSString *grade;
	switch (certGrade) {
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
	return [NSString stringWithFormat:@"%@ - %@",[parent certClassName],[self certGradeText]];
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
				 certPre:(NSArray*)cPre
			   certClass:(CertClass*)cC
{
	if((self = [super init])){
		certID = cID;
		certGrade = 0;
        groupID = gID;
        name = [cName retain];
		certDescription = [cDesc retain];
		skillPrereqs = nil; //[sPre retain];
		certPrereqs = [cPre retain];
		parent = cC; //NOT RETAINED
        [self parseDatabaseSkills:sPre];
	}
	return self;
}

+(Cert*) createCert:(NSInteger)cID 
			  group:(NSInteger)gID
               name:(NSString *)cName
			   text:(NSString*)cDesc
		   skillPre:(NSArray*)sPre
			certPre:(NSArray*)cPre
		  certClass:(CertClass*)cC
{
	Cert *c = [[Cert alloc]initWithDetails:cID 
									 group:gID
                                      name:cName
									  text:cDesc
								  skillPre:sPre
								   certPre:cPre
								 certClass:cC];
	return [c autorelease];
}

/*
 recursivley add all the prerequisites for this cert and all the subcerts.
 */
-(void) certSkillPrereqs:(NSMutableArray*)skillArray  forCert:(Cert*)c
{	
	//Do it in order of the most advanced cert first.
	[skillArray addObjectsFromArray:[c skillPrereqs]];
	
	for(CertPair *pair in [c certPrereqs]){
		Cert *preCert = [[[GlobalData sharedInstance]certTree]certForID:[pair certID]];
		[self certSkillPrereqs:skillArray forCert:preCert];
	}
}

-(NSArray*)certChainPrereqs
{
	NSMutableArray *ary = [[[NSMutableArray alloc]init]autorelease];
	
	[self certSkillPrereqs:ary forCert:self];
	
	return ary;
}

-(NSComparisonResult) gradeComparitor:(Cert*)rhs
{
	if(rhs->certGrade < self->certGrade){
		return NSOrderedAscending;
	}
	return NSOrderedDescending;
}


@end
