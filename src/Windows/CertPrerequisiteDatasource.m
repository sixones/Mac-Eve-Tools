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
@synthesize levelSkills = _levelSkills;

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
    [_levelSkills release];
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

- (BOOL)tableView:(NSTableView *)tableView writeRowsWithIndexes:(NSIndexSet *)rowIndexes toPasteboard:(NSPasteboard *)pboard
{
	NSArray *prereqs = [[self levelSkills] objectsAtIndexes:rowIndexes];
	
	[pboard declareTypes:[NSArray arrayWithObject:MTSkillArrayPBoardType] owner:self];
	
	NSMutableData *data = [[NSMutableData alloc]init];
	
	NSKeyedArchiver *archiver = [[NSKeyedArchiver alloc]initForWritingWithMutableData:data];
	[archiver setOutputFormat:NSPropertyListBinaryFormat_v1_0];
	[archiver encodeObject:prereqs];
	[archiver finishEncoding];
	
	[pboard setData:data forType:MTSkillArrayPBoardType];
	
	[archiver release];
	[data release];
	
	return YES;
}

@end
