//
//  CertDetailsWindowController.h
//  Mac Eve Tools
//
//  Created by Matt Tyson on 27/01/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@class Cert;
@class Character;

@class CertPrerequisiteDatasource;

@interface CertDetailsWindowController : NSWindowController {

	IBOutlet NSTableView *certPrerequisites;
	IBOutlet NSTextField *certDescription;
	
	IBOutlet NSImageView *miniPortrait;
	IBOutlet NSTextField *trainingTime;
	
    
    IBOutlet NSButton *certLevel1;
    IBOutlet NSButton *certLevel2;
    IBOutlet NSButton *certLevel3;
    IBOutlet NSButton *certLevel4;
    IBOutlet NSButton *certLevel5;
    
	Cert *cert;
	Character *character;
	
	CertPrerequisiteDatasource *certDS;
}

+(void) displayWindowForCert:(Cert*)cer character:(Character*)ch;

- (IBAction)setCertLevel:(id)sender;

@end
