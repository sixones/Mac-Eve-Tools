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


@interface METMailMessage()
@property (readwrite,retain) NSDate *cachedUntil;
@property (readwrite,retain) NSString *xmlPath;
@property (readwrite,assign) BOOL loading;
@end

@implementation METMailMessage

@synthesize character;
@synthesize xmlPath;
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
@synthesize cachedUntil;
@synthesize loading;

- (id)init
{
    if( self = [super init] )
    {
        nameFetcher = [[METIDtoName alloc] init];
        [nameFetcher setDelegate:self];
        [self setLoading:NO];
    }
    return self;
}

- (void)dealloc
{
    [super dealloc];
    [character release];
    [xmlPath release];
    [nameFetcher release];
}

- (void)preloadNames
{
    NSMutableSet *ids = [NSMutableSet set];
    
//    if( nil == [self issuerName] )
//        [ids addObject:[NSNumber numberWithInteger:[self issuerID]]];
//    if( nil == [self issuerCorpName] )
//        [ids addObject:[NSNumber numberWithInteger:[self issuerCorpID]]];
//    if( nil == [self assigneeName] && (0 != [self assigneeID]) )
//        [ids addObject:[NSNumber numberWithInteger:[self assigneeID]]];
//    if( nil == [self acceptorName] && (0 != [self acceptorID]) )
//        [ids addObject:[NSNumber numberWithInteger:[self acceptorID]]];
    
    if( [ids count] )
    {
        [nameFetcher namesForIDs:ids];
    }
}

- (void)namesFromIDs:(NSDictionary *)names
{
//    NSString *name = nil;
//    BOOL changed = NO;
    
//    name = [names objectForKey:[NSNumber numberWithInteger:[self issuerID]]];
//    if( name )
//    {
//        [self setIssuerName:name];
//        changed = YES;
//    }
    
//    if( changed && [delegate conformsToProtocol:@protocol(ContractDelegate)] )
//    {
//        [delegate contractNamesFinishedUpdating];
//    }
}

@end
