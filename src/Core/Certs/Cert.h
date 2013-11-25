//
//  Cert.h
//  Mac Eve Tools
//
//  Created by Matt Tyson on 25/01/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class SkillPair;
@class CertClass;
@class Character;

/*
 This is a Certificate, specifically Rubicon or later type certificates.
 */

@interface Cert : NSObject {
	NSInteger certID;	
	NSInteger groupID;
    
    NSString *name;
	NSString *certDescription;
		
    // Skill pairs required for each level of this certificate
    NSArray *basicSkills;
    NSArray *standardSkills;
    NSArray *improvedSkills;
    NSArray *advancedSkills;
    NSArray *eliteSkills;
}

@property (readonly,nonatomic) NSInteger certID;
@property (readonly,nonatomic) NSInteger groupID;
@property (readonly,nonatomic,retain) NSString *name;
@property (readonly,nonatomic,retain) NSString* certDescription;

@property (readonly,nonatomic,retain) NSArray* basicSkills;
@property (readonly,nonatomic,retain) NSArray* standardSkills;
@property (readonly,nonatomic,retain) NSArray* improvedSkills;
@property (readonly,nonatomic,retain) NSArray* advancedSkills;
@property (readonly,nonatomic,retain) NSArray* eliteSkills;

+(Cert*) createCert:(NSInteger)cID 
			  group:(NSInteger)gID
               name:(NSString *)cName
			   text:(NSString*)cDesc
		   skillPre:(NSArray*)sPre;

-(NSString*) nameForCertLevel:(NSInteger)level;
-(NSString*) fullCertName;

/* Skills required for the given certificate level */
-(NSArray *) skillsForLevel:(NSInteger)level;

-(BOOL) character:(Character *)_character hasLevel:(NSInteger)level;
@end
