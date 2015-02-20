//
//  MarketOrder.m
//  Mac Eve Tools
//
//  Created by Andrew Salamon on 5/29/13.
//  Copyright (c) 2013 Sebastian Kruemling. All rights reserved.
//

#import "METMailMessage.h"

#import "GlobalData.h"
#import "CCPType.h"
#import "CCPDatabase.h"
#import "Config.h"
#import "METIDtoName.h"

#import "Character.h"
#import "CharacterTemplate.h"
#import "XMLDownloadOperation.h"
#import "XMLParseOperation.h"
#import "XmlHelpers.h"
#include <libxml/tree.h>
#include <libxml/parser.h>


@implementation METMailMessage

@synthesize character;
@synthesize delegate;
@synthesize messageID;
@synthesize senderID;
@synthesize senderName;
@synthesize subject;
@synthesize body;
@synthesize sentDate;
@synthesize toCorpOrAllianceID;
@synthesize senderTypeID;
@synthesize toCharacterIDs;
@synthesize toListID;
@synthesize read;

- (id)init
{
    if( self = [super init] )
    {
    }
    return self;
}

- (void)dealloc
{
    [super dealloc];
    [character release];
}

- (NSSet *)allIDs
{
    NSMutableSet *ids = [NSMutableSet set];
    [ids addObject:[NSNumber numberWithInteger:[self toCorpOrAllianceID]]];
    [ids addObject:[NSNumber numberWithInteger:[self toListID]]];
    [ids addObject:[NSNumber numberWithInteger:[self senderID]]];
    
    for( NSString *anID in [self toCharacterIDs] )
    {
        [ids addObject:[NSNumber numberWithInteger:[anID integerValue]]];
    }
    return ids;
}

- (NSString *)toDisplayName
{
    NSMutableArray *ids = [NSMutableArray arrayWithArray:[self toCharacterIDs]];
    if( 0 != [self toCorpOrAllianceID] )
        [ids addObject:[[NSNumber numberWithInteger:[self toCorpOrAllianceID]] stringValue]];
    if( 0 != [self toListID] )
        [ids addObject:[[NSNumber numberWithInteger:[self toListID]] stringValue]];
    
    CCPDatabase *db = [[GlobalData sharedInstance] database];
    NSMutableArray *names = [NSMutableArray array];
    
    for( NSString *anID in ids )
    {
        NSString *aName = [db characterNameForID:[anID integerValue]];
        if( aName )
        {
            [names addObject:aName];
        }
        else
        {
            [names addObject:anID];
        }
    }
    
    return [names componentsJoinedByString:@", "];
}

-(NSComparisonResult) compareByDate:(METMailMessage *)rhs
{
    return [[self sentDate] compare:[rhs sentDate]];
}

@end
