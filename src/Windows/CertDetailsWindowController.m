//
//  CertDetailsWindowController.m
//  Mac Eve Tools
//
//  Created by Matt Tyson on 27/01/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "CertDetailsWindowController.h"

#import "CertPrerequisiteDatasource.h"

#import "Character.h"
#import "Cert.h"
#import "CertClass.h"
#import "CertPair.h"
#import "CertTree.h"
#import "SkillPair.h"
#import "GlobalData.h"
#import "SkillPlan.h"
#import "Helpers.h"

#import "assert.h"


@implementation CertDetailsWindowController

-(void) awakeFromNib
{
    [self setCertLevel:certLevel1];
}

-(id) initWithCert:(Cert*)cer forCharacter:(Character*)ch
{
	if((self = [super initWithWindowNibName:@"CertDetails"])){
		cert = [cer retain];
		character = [ch retain];
		certDS = [[CertPrerequisiteDatasource alloc]initWithCert:cert forCharacter:character];
	}
	
	return self;
}

-(void)dealloc
{
	[cert release];
	[character release];
	[certPrerequisites setDataSource:nil];
	[certDS release];
	[super dealloc];
}

-(void) setLabels
{
	[certDescription setStringValue:[cert certDescription]];
}

-(void) setDatasource
{
	[certPrerequisites setDataSource:certDS];
}

+(void) displayWindowForCert:(Cert*)cer character:(Character*)ch
{
	CertDetailsWindowController *wc = [(CertDetailsWindowController*)
									   [CertDetailsWindowController alloc]initWithCert:cer
																		  forCharacter:ch];
    [[wc window]makeKeyAndOrderFront:nil];
}

// TODO Change the background colors of the buttons to show how far the character is toward achieving that level in this certificate
// Green means all skills/levels attained
// Yellow means all skills trained, but some not high enough level
// Red means one or more skills are not trained at all
- (IBAction)setCertLevel:(id)sender
{
    NSInteger level = [sender tag];
    [certDS setCertLevel:level];
    [certLevel1 setState:(1 == level)];
    [certLevel2 setState:(2 == level)];
    [certLevel3 setState:(3 == level)];
    [certLevel4 setState:(4 == level)];
    [certLevel5 setState:(5 == level)];
    [certPrerequisites reloadData];
    [self calculateTimeToTrain];
    [[certLevel5 cell] setBackgroundColor:[NSColor redColor]];
}

-(void) windowWillClose:(NSNotification*)note
{
	[[NSNotificationCenter defaultCenter]removeObserver:self];
	[self autorelease];
}

-(void) calculateTimeToTrain
{
	//Normally skill plans should be created using the character object, but we don't want to save this plan
	
	NSString *text = @"";
	
	[miniPortrait setImage:[character portrait]];
	
    SkillPlan *plan = [[SkillPlan alloc]initWithName:@"--TEST--" character:character];
    [plan addSkillArrayToPlan:[certDS levelSkills]];
    [plan purgeCompletedSkills];
    
    NSInteger timeToTrain = [plan trainingTime];
    
    [plan release];
    
    if(timeToTrain > 0)
    {
        NSString *timeToTrainString = stringTrainingTime(timeToTrain);
        
        text = [NSString stringWithFormat:
                NSLocalizedString(@"%@ could have this certificate level in %@",@"<@CharacterName> could have this cert"),
                [character characterName], timeToTrainString];
    }
	
	[trainingTime setStringValue:text];
}

-(void) windowDidLoad
{
	[[NSNotificationCenter defaultCenter] 
	 addObserver:self
	 selector:@selector(windowWillClose:)
	 name:NSWindowWillCloseNotification
	 object:[self window]];
	
	[self calculateTimeToTrain];
	[self setLabels];
	[self setDatasource];
	[[self window]setTitle:[cert fullCertName]];
}

@end
