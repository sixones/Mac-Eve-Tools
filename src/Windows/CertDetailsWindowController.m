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

#import "SkillDetailsWindowController.h"

#import "assert.h"

@interface CertDetailsWindowController()
- (NSImage *)generateButtonImage:(NSInteger)certLevel withState:(NSInteger)state;
@end

@implementation CertDetailsWindowController

-(void) awakeFromNib
{
    [self setCertLevel:certLevel1];
    [certPrerequisites setDoubleAction:@selector(rowDoubleClick:)];
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
    
    // trying to figure out how to change the look of the cert level buttons based on current skills
//    NSImage *image = [self generateButtonImage:1 withState:1];
//    [certLevel1 setImage:image];
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

-(IBAction) rowDoubleClick:(id)sender
{
    NSInteger selectedRow = [sender selectedRow];
	
	if( selectedRow == -1 )
    {
		return;
	}
	
    NSNumber *typeID = [[[certDS levelSkills] objectAtIndex:selectedRow] typeID];
    // It would be nice if we could display this stacked just below this certificate details window
    [SkillDetailsWindowController displayWindowForTypeID:typeID forCharacter:character];
}

- (NSImage *)generateButtonImage:(NSInteger)certLevel withState:(NSInteger)state
{
    NSRect rect = NSMakeRect(0.0,0.0,64.0,64.0);
    NSImage* anImage = [[NSImage alloc] initWithSize:rect.size];
    [anImage lockFocus];
    
    // state would be all skills, missing some skill levels or missing at least one skill.
    // Color should match what we show in the skill list
    NSColor *color = [NSColor colorWithDeviceRed:1.0 green:0.0 blue:0.0 alpha:0.5];
    color = [NSColor colorWithDeviceRed:1.0 green:0.5 blue:0.0 alpha:0.5];
    [color set];
    
    NSBezierPath *path = [NSBezierPath bezierPathWithRoundedRect:rect xRadius:5.0 yRadius:5.0];
    [path fill];
    
    [[NSColor blackColor] set];
    NSString *level = romanForInteger(certLevel);
    NSFont* font= [NSFont fontWithName:@"Lucida Grande" size:24.0];
    NSDictionary *attrs = [NSDictionary dictionaryWithObject:font forKey:NSFontAttributeName];
    NSSize size = [level sizeWithAttributes:attrs];
    rect.origin.x = (rect.size.width - size.width) / 2.0;
    rect.origin.y = -((rect.size.height - size.height) / 2.0);
    [level drawInRect:rect withAttributes:attrs];
    
    [anImage unlockFocus];
    return anImage;
}

@end
