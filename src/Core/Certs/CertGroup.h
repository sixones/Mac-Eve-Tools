//
//  CertGroup.h
//  Mac Eve Tools
//
//  Created by Matt Tyson on 25/01/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class Cert;

@interface CertGroup : NSObject {
	NSInteger groupID;
	NSString *name;
	
	NSMutableArray *certificates;
}

@property (readonly,nonatomic) NSInteger groupID;
@property (readonly,nonatomic) NSString* name;

-(NSInteger) count;
-(Cert *) certAtIndex:(NSInteger)index;
-(void) addCertificate:(Cert *)aCert;

+(CertGroup*) createCertGroup:(NSInteger)cID name:(NSString*)cName;

@end
