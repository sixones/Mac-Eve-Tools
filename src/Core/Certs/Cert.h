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

/*
	This is a level of a particular cert.  
 EG Core Fitting - Basic.
 Core Fitting - Standard.
 
 Contains a link back to the parent class, as info about a cert is
 incomplete without knowint its parent class.
 */

@interface Cert : NSObject {
	NSInteger certID;	
	NSInteger certGrade;
	NSInteger groupID;
    
    NSString *name;
	NSString *certDescription;
	
	NSArray *certPrereqs; //Certs requried as prereqs. (NSInteger certID)
	NSArray *skillPrereqs; //Skills required for this cert. (SkillPair)
	
    // Skill pairs required for each level of this certificate
    NSArray *basicSkills;
    NSArray *standardSkills;
    NSArray *improvedSkills;
    NSArray *advancedSkills;
    NSArray *eliteSkills;
    
    CertClass *parent; // NOT RETAINED.
}

@property (readonly,nonatomic) NSInteger certID;
@property (readonly,nonatomic) NSInteger certGrade;
@property (readonly,nonatomic) NSInteger groupID;
@property (readonly,nonatomic,retain) NSString *name;
@property (readonly,nonatomic,retain) NSString* certDescription;

@property (readonly,nonatomic) NSArray* certPrereqs;
@property (readonly,nonatomic,retain) NSArray* skillPrereqs;
@property (readonly,nonatomic,retain) NSArray* basicSkills;
@property (readonly,nonatomic,retain) NSArray* standardSkills;
@property (readonly,nonatomic,retain) NSArray* improvedSkills;
@property (readonly,nonatomic,retain) NSArray* advancedSkills;
@property (readonly,nonatomic,retain) NSArray* eliteSkills;

@property (readonly,nonatomic) CertClass* parent;

+(Cert*) createCert:(NSInteger)cID 
			  group:(NSInteger)gID
               name:(NSString *)cName
			   text:(NSString*)cDesc
		   skillPre:(NSArray*)sPre
			certPre:(NSArray*)cPre
		  certClass:(CertClass*)cC;

-(NSString*) certGradeText;
-(NSString*) fullCertName;

/*return the prerequsites of this cert, and all the prerequisite certs*/
-(NSArray*) certChainPrereqs;

@end
