//
//  CertGroup.m
//  Mac Eve Tools
//
//  Created by Matt Tyson on 25/01/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "CertGroup.h"
#import "Cert.h"

#import "GlobalData.h"
#import "CCPDatabase.h"
#import "CCPGroup.h"

@implementation CertGroup

@synthesize groupID;
@synthesize name;


-(void)dealloc
{
	[name release];
	[certificates release];
	[super dealloc];
}

-(id)initWithGroupID:(NSInteger)cID name:(NSString *)cName
{
	if( (self = [super init]) )
    {
		groupID = cID;
		certificates = [[NSMutableArray alloc] init];
        if( nil == cName )
        {
            CCPDatabase *db = [[GlobalData sharedInstance] database];
            CCPGroup *group = [db group:cID];
            name = [[group groupName] retain];
        }
        else
        {
            name = [cName retain];
        }
	}
	return self;
}

+(CertGroup*) createCertGroup:(NSInteger)cID name:(NSString*)cName
{
	CertGroup *cc = [[CertGroup alloc] initWithGroupID:cID
                                                  name:cName];
	return [cc autorelease];
}

-(NSInteger) count
{
	return [certificates count];
}

-(Cert *) certAtIndex:(NSInteger)index
{
	return [certificates objectAtIndex:index];
}

-(Cert *)certificateByID:(NSInteger)cID
{
    for( Cert *aCert in certificates )
        if( [aCert certID] == cID )
            return aCert;
    return nil;
}

-(void)addCertificate:(Cert *)aCert
{
    Cert *already = [self certificateByID:[aCert certID]];
    if( nil == already )
        [certificates addObject:aCert];
}
@end
