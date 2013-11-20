//
//  CertTree.h
//  Mac Eve Tools
//
//  Created by Matt Tyson on 25/01/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class CertCategory;
@class Cert;

@interface CertTree : NSObject {
	NSMutableArray *certGroups;
	
	NSMutableDictionary *allCerts;
    NSMutableDictionary *certsByGroupID;
    NSArray *certificates;
}

@property (readonly,retain) NSArray *certificates;

-(NSInteger) catCount;
-(CertCategory*) catAtIndex:(NSInteger)index;

-(Cert*) certForID:(NSInteger)certID;

+(CertTree *) createCertTree:(NSArray *)certs; // rubicon version
@end
