//
//  CertPrerequisiteDatasource.h
//  Mac Eve Tools
//
//  Created by Matt Tyson on 3/03/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class Cert;
@class Character;


@interface CertPrerequisiteDatasource : NSObject <NSTableViewDataSource> {
	Cert *cert;
	Character *character;
    NSInteger certLevel; // what level to use for displaying skills
}

@property (readwrite,nonatomic,assign) NSInteger certLevel;
@property (readonly,retain,nonatomic) NSArray *levelSkills; // skills required for the currently selected cert level, objects are SkillPair's

-(CertPrerequisiteDatasource*) initWithCert:(Cert*)c
							   forCharacter:(Character*)ch;

@end
