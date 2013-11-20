//
//  CertTree.m
//  Mac Eve Tools
//
//  Created by Matt Tyson on 25/01/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "CertTree.h"

#import "Cert.h"
#import "CertClass.h"
#import "CertCategory.h"
#import "CertGroup.h"

#import "SkillPair.h"
#import "CertPair.h"

@interface CertTree()
@property (readwrite,retain) NSArray *certificates;
@end

@implementation CertTree
@synthesize certificates;

-(void)dealloc
{
	[allCerts release];
	[certGroups release];
	[super dealloc];
}

-(NSInteger) catCount
{
	return [certGroups count];
}
-(CertGroup *) catAtIndex:(NSInteger)index
{
	return [certGroups objectAtIndex:index];
}
-(CertGroup *) groupForID:(NSInteger)gID
{
    for( CertGroup *aGroup in certGroups )
        if( gID == [aGroup groupID] )
            return aGroup;
    return nil;
}

-(Cert*) certForID:(NSInteger)certID
{
	return [allCerts objectForKey:[NSNumber numberWithInteger:certID]];
}

-(CertTree *) initWithCertificates:(NSArray *)_certificates
{
    if( self = [super init] )
    {
        certificates = [_certificates retain];
        allCerts = [[NSMutableDictionary alloc] init];
        certGroups = [[NSMutableArray alloc] init];

        for( Cert *aCert in _certificates )
        {
            [allCerts setObject:aCert forKey:[NSNumber numberWithInteger:[aCert certID]]];
            
            CertGroup *group = [self groupForID:[aCert groupID]];
            if( nil == group )
            {
                group = [CertGroup createCertGroup:[aCert groupID] name:nil];
                [certGroups addObject:group];
            }
            [group addCertificate:aCert];
        }
    }
    return self;
}

+(CertTree *) createCertTree:(NSArray *)certificates
{
    CertTree *tree = [[CertTree alloc] initWithCertificates:certificates];
    return [tree autorelease];
}

@end
