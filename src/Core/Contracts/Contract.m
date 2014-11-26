//
//  MarketOrder.m
//  Mac Eve Tools
//
//  Created by Andrew Salamon on 5/29/13.
//  Copyright (c) 2013 Sebastian Kruemling. All rights reserved.
//

#import "Contract.h"
#import "ContractItem.h"

#import "GlobalData.h"
#import "CCPType.h"
#import "CCPDatabase.h"
#import "Config.h"
#import "METIDtoName.h"
#import "MTISKFormatter.h"

#import "Character.h"
#import "CharacterTemplate.h"
#import "XMLDownloadOperation.h"
#import "XMLParseOperation.h"
#import "XmlHelpers.h"
#include <libxml/tree.h>
#include <libxml/parser.h>

/* Sample xml of a contract
 <rowset name="contractList" key="contractID"
 columns="contractID
 issuerID
 issuerCorpID
 assigneeID
 acceptorID
 startStationID
 endStationID
 type
 status
 title
 forCorp
 availability
 dateIssued
 dateExpired
 dateAccepted
 numDays
 dateCompleted
 price
 reward
 collateral
 buyout
 volume">
 <row contractID="72716865" issuerID="91794908" issuerCorpID="1406664155" assigneeID="98159347" acceptorID="0" startStationID="60004588" endStationID="61000617" type="Courier" status="Outstanding" title="" forCorp="0" availability="Private" dateIssued="2013-09-15 14:59:52" dateExpired="2013-09-29 14:59:52" dateAccepted="" numDays="7" dateCompleted="" price="0.00" reward="14905500.00" collateral="0.00" buyout="0.00" volume="59622.4475" />
 */

@interface Contract()
@property (readwrite,retain) NSDate *cachedUntil; // For contained items, not the contract itself
@property (readwrite,retain) NSString *xmlPath;
@property (readwrite,assign) BOOL loading;
@property (readwrite,retain) NSString *issuerName;
@property (readwrite,retain) NSString *issuerCorpName;
@property (readwrite,retain) NSString *assigneeName;
@property (readwrite,retain) NSString *acceptorName;
@property (readwrite,retain) NSString *startStationName;
@property (readwrite,retain) NSString *endStationName;
@end

@implementation Contract

@synthesize character = _character;
@synthesize xmlPath = _xmlPath;
@synthesize delegate = _delegate;

@synthesize type = _type;
@synthesize status = _status;
@synthesize contractID = _contractID;
@synthesize startStationID = _startStationID;
@synthesize endStationID = _endStationID;

@synthesize issuerID = _issuerID;
@synthesize issuerCorpID = _issuerCorpID;
@synthesize acceptorID = _acceptorID;
@synthesize assigneeID = _assigneeID;
@synthesize issuerName = _issuerName;
@synthesize issuerCorpName = _issuerCorpName;
@synthesize assigneeName = _assigneeName;
@synthesize acceptorName = _acceptorName;

@synthesize startStationName = _startStationName;
@synthesize endStationName = _endStationName;

@synthesize volume = _volume;
@synthesize price = _price;
@synthesize reward = _reward;
@synthesize collateral = _collateral;
@synthesize buyout = _buyout;
@synthesize issued = _issued;
@synthesize expired = _expired;
@synthesize accepted = _accepted;
@synthesize completed = _completed;
@synthesize availability = _availability;
@synthesize title = _title;
@synthesize days = _days;
@synthesize forCorp = _forCorp;
@synthesize cachedUntil = _cachedUntil;
@synthesize items = _items;
@synthesize loading = _loading;

- (id)init
{
    if( self = [super init] )
    {
        _items = [[NSMutableArray alloc] init];
        nameFetcher = [[METIDtoName alloc] init];
        [nameFetcher setDelegate:self];
        [self setLoading:NO];
    }
    return self;
}

- (void)dealloc
{
    [super dealloc];
    [_character release];
    [_xmlPath release];
    [_type release];
    [_status release];
    [_items release];
    [_issued release];
    [_expired release];
    [_accepted release];
    [_completed release];
    [_availability release];
    [_title release];
    [_cachedUntil release];
    [_startStationName release];
    [_endStationName release];
    [nameFetcher release];
}

- (void)setStartStationName:(NSString *)newStationName
{
    if( newStationName != _startStationName )
    {
        [_startStationName release];
        _startStationName = [newStationName retain];
    }
}

- (NSString *)startStationName
{
    if( nil == _startStationName )
    {
        CCPDatabase *db = [[GlobalData sharedInstance] database];
        NSDictionary *station = [db stationForID:[self startStationID]];
        [self setStartStationName:[station objectForKey:@"name"]];
    }
    return _startStationName;
}

- (void)setEndStationName:(NSString *)newStationName
{
    if( newStationName != _endStationName )
    {
        [_endStationName release];
        _endStationName = [newStationName retain];
    }
}

- (NSString *)endStationName
{
    if( nil == _endStationName )
    {
        CCPDatabase *db = [[GlobalData sharedInstance] database];
        NSDictionary *station = [db stationForID:[self endStationID]];
        [self setEndStationName:[station objectForKey:@"name"]];
    }
    return _endStationName;
}

- (NSArray *)items
{
    if( (nil == _items) && ![self loading] )
    {
        [self preloadItems];
    }
    return _items;
}

- (void)preloadItems
{
    if( [self loading] )
        return;
    if( ![self character] )
        return;
    if( ![self contractID] )
        return;
    if( [[self type] isEqualToString:@"Courier"] )
        return; // Courier contracts never include items
    
    if( [[self cachedUntil] isGreaterThan:[NSDate date]] )
    {
        NSLog( @"Skipping download of Contract items because of Cached Until date" );
        [self setLoading:NO];
        return;
    }
    
    [self setLoading:YES];
    
    CharacterTemplate *template = [[self character] template];
    
    NSString *docPath = XMLAPI_CHAR_CONTRACT_ITEMS;
    NSString *apiUrl = [Config getApiUrl:docPath
                                   keyID:[template accountId]
                        verificationCode:[template verificationCode]
                                  charId:[template characterId]];
    apiUrl = [apiUrl stringByAppendingFormat:@"&contractID=%ld",(unsigned long)[self contractID]];

	NSString *characterDir = [Config charDirectoryPath:[template accountId]
											 character:[template characterId]];
    NSString *pendingDir = [characterDir stringByAppendingString:@"/pending"];
    
    NSString *docPathID = [[[docPath stringByDeletingPathExtension] stringByAppendingFormat:@"_%ld", (unsigned long)[self contractID]] stringByAppendingPathExtension:[docPath pathExtension]];
    [self setXmlPath:[characterDir stringByAppendingPathComponent:[docPathID lastPathComponent]]]; // this won't work. need at least the contract ID.
    
	//create the output directory, the XMLParseOperation will clean it up
    // TODO move this to an operations sub-class and have all of the download operations depend on it
	NSFileManager *fm = [NSFileManager defaultManager];
	if( ![fm fileExistsAtPath:pendingDir isDirectory:nil] )
    {
		if( ![fm createDirectoryAtPath: pendingDir withIntermediateDirectories:YES attributes:nil error:nil] )
        {
			//NSLog(@"Could not create directory %@",pendingDir);
            [self setLoading:NO];
			return;
		}
	}
    
	XMLDownloadOperation *op = [[[XMLDownloadOperation alloc] init] autorelease];
	[op setXmlDocUrl:apiUrl];
	[op setCharacterDirectory:characterDir];
	[op setXmlDoc:docPathID];
    
    NSOperationQueue *queue = [[NSOperationQueue alloc] init];
	[queue setMaxConcurrentOperationCount:3];
    
	//This object will call the delegate function.
    
	XMLParseOperation *opParse = [[XMLParseOperation alloc] init];
    
	[opParse setDelegate:self];
	[opParse setCallback:@selector(parserOperationDone:errors:)];
	[opParse setObject:nil];
    
	[opParse addDependency:op]; //THIS MUST BE THE FIRST DEPENDENCY.
	[opParse addCharacterDir:characterDir forSheet:docPathID];
    
	[queue addOperation:op];
	[queue addOperation:opParse];
    
	[opParse release];
	[queue release];
    
}

- (void) parserOperationDone:(id)ignore errors:(NSArray *)errors
{
    // read data from marketFile and create an xmlDoc
    // parse it
    xmlDoc *doc = xmlReadFile( [[self xmlPath] fileSystemRepresentation], NULL, 0 );
	if( doc == NULL )
    {
		NSLog(@"Failed to read %@",[self xmlPath]);
        [self setLoading:NO];
		return;
	}
	[self parseXmlContractItems:doc];
	xmlFreeDoc(doc);
}

/* Sample xml for contract items:
 <?xml version='1.0' encoding='UTF-8'?>
 <eveapi version="2">
 <currentTime>2013-10-31 17:29:23</currentTime>
 <result>
 <rowset name="itemList" key="recordID" columns="recordID,typeID,quantity,rawQuantity,singleton,included">
 <row recordID="1119936136" typeID="2913" quantity="1" singleton="0" included="1" />
 <row recordID="1119936137" typeID="21896" quantity="113" singleton="0" included="1" />
 <row recordID="1119936138" typeID="21896" quantity="113" singleton="0" included="1" />
 </rowset>
 </result>
 <cachedUntil>2023-10-29 17:29:23</cachedUntil>
 </eveapi>
 */
-(BOOL) parseXmlContractItems:(xmlDoc*)document
{
	xmlNode *root_node;
	xmlNode *result;
    xmlNode *rowset;
    
	root_node = xmlDocGetRootElement(document);
    
	result = findChildNode(root_node,(xmlChar*)"result");
	if( NULL == result )
    {
		NSLog(@"Could not get result tag in parseXmlContracts");
		
		xmlNode *xmlErrorMessage = findChildNode(root_node,(xmlChar*)"error");
		if( NULL != xmlErrorMessage )
        {
			NSLog( @"%@", [NSString stringWithString:getNodeText(xmlErrorMessage)] );
		}
        [self setLoading:NO];
		return NO;
	}
    
    rowset = findChildNode(result,(xmlChar*)"rowset");
	if( NULL == result )
    {
		NSLog(@"Could not get rowset tag in parseXmlContracts");
		
		xmlNode *xmlErrorMessage = findChildNode(root_node,(xmlChar*)"error");
		if( NULL != xmlErrorMessage )
        {
			NSLog( @"%@", [NSString stringWithString:getNodeText(xmlErrorMessage)] );
		}
        [self setLoading:NO];
		return NO;
	}
    
    [_items removeAllObjects];
    
	for( xmlNode *cur_node = rowset->children;
        NULL != cur_node;
        cur_node = cur_node->next)
	{
		if( XML_ELEMENT_NODE != cur_node->type )
        {
			continue;
		}
        
		if( xmlStrcmp(cur_node->name,(xmlChar*)"row") == 0 )
        {
//            <row recordID="1119936138" typeID="21896" quantity="113" singleton="0" included="1" />
            ContractItem *item = [[[ContractItem alloc] init] autorelease];

            for( xmlAttr *attr = cur_node->properties; attr; attr = attr->next )
            {
                NSString *value = [NSString stringWithUTF8String:(const char*) attr->children->content];
                if( xmlStrcmp(attr->name, (xmlChar *)"typeID") == 0 )
                {
                    [item setTypeID:[value integerValue]];
                }
                else if( xmlStrcmp(attr->name, (xmlChar *)"quantity") == 0 )
                {
                    [item setQuantity:[value integerValue]];
                }
                else if( xmlStrcmp(attr->name, (xmlChar *)"rawQuantity") == 0 )
                {
                    [item setRawQuantity:[value integerValue]];
                }
                else if( xmlStrcmp(attr->name, (xmlChar *)"singleton") == 0 )
                {
                    [item setSingleton:[value integerValue]];
                }
                else if( xmlStrcmp(attr->name, (xmlChar *)"included") == 0 )
                {
                    [item setIncluded:[value integerValue]];
                }
            }
            [_items addObject:item];
        }
	}
        
    // Grab the "cachedUntil" node so we don't re-request data until after that time.
    // format: 2013-05-22 22:32:5
    xmlNode *cached = findChildNode( root_node, (xmlChar *)"cachedUntil" );
    if( NULL != cached )
    {
        NSString *dtString = getNodeText( cached );
        NSDate *cacheDate = [NSDate dateWithNaturalLanguageString:dtString];
        [self setCachedUntil:cacheDate];
        
    }
    
    if( [[self delegate] conformsToProtocol:@protocol(ContractDelegate)] )
    {
        [[self delegate] contractItemsFinishedUpdating];
    }
    
    [self setLoading:NO];
	return YES;
}

- (void)preloadNames
{
    NSMutableSet *ids = [NSMutableSet set];
    
    if( nil == [self issuerName] )
        [ids addObject:[NSNumber numberWithInteger:[self issuerID]]];
    if( nil == [self issuerCorpName] )
        [ids addObject:[NSNumber numberWithInteger:[self issuerCorpID]]];
    if( nil == [self assigneeName] && (0 != [self assigneeID]) )
        [ids addObject:[NSNumber numberWithInteger:[self assigneeID]]];
    if( nil == [self acceptorName] && (0 != [self acceptorID]) )
        [ids addObject:[NSNumber numberWithInteger:[self acceptorID]]];
    
    if( [ids count] )
    {
        [nameFetcher namesForIDs:ids];
    }
}

- (void)namesFromIDs:(NSDictionary *)names
{
    NSString *name = nil;
    BOOL changed = NO;
    
    name = [names objectForKey:[NSNumber numberWithInteger:[self issuerID]]];
    if( name )
    {
        [self setIssuerName:name];
        changed = YES;
    }
    name = [names objectForKey:[NSNumber numberWithInteger:[self issuerCorpID]]];
    if( name )
    {
        [self setIssuerCorpName:name];
        changed = YES;
    }
    name = [names objectForKey:[NSNumber numberWithInteger:[self assigneeID]]];
    if( name )
    {
        [self setAssigneeName:name];
        changed = YES;
    }
    name = [names objectForKey:[NSNumber numberWithInteger:[self acceptorID]]];
    if( name )
    {
        [self setAcceptorName:name];
        changed = YES;
    }
    
    if( changed && [[self delegate] conformsToProtocol:@protocol(ContractDelegate)] )
    {
        [[self delegate] contractNamesFinishedUpdating];
    }
}

// A lot of this is somewhat duplicated from ContractDetailsController and should combined, somehow.
- (NSString *)description
{
    NSMutableString *desc = [NSMutableString string];

    BOOL isCourier = [[self type] isEqualToString:@"Courier"];
    
    [desc appendFormat:@"%@: %@\n", @"Type", [self type]];
    [desc appendFormat:@"%@: %@\n", @"Status", [self status]];
    [desc appendFormat:@"%@: %@\n", @"Contract ID", [NSString stringWithFormat:@"%ld",[self contractID]]];
    [desc appendFormat:@"%@: %@\n", @"Start", [self startStationName]];
    
    if( isCourier )
    {
        [desc appendFormat:@"%@: %@\n", @"End", [self endStationName]];
    }
    
    
    id value = nil;
    
    value = [self issuerName];
    [desc appendFormat:@"%@: %@\n", @"Issuer", (value?value:[NSNumber numberWithInteger:[self issuerID]])];
    
    value = [self issuerCorpName];
    [desc appendFormat:@"%@: %@\n", @"Corporation", (value?value:[NSNumber numberWithInteger:[self issuerCorpID]])];
    
    // skip this for non-courier contracts?
    if( [self assigneeID] != 0 )
    {
        value = [self assigneeName];
        [desc appendFormat:@"%@: %@\n", @"Assignee", (value?value:[NSNumber numberWithInteger:[self assigneeID]])];
    }
    
    if( [self acceptorID] != 0 )
    {
        value = [self acceptorName];
        [desc appendFormat:@"%@: %@\n", @"Acceptor", (value?value:[NSNumber numberWithInteger:[self acceptorID]])];
    }
    
    NSString *withSeparators = [NSNumberFormatter localizedStringFromNumber:[NSNumber numberWithDouble:[self volume]] numberStyle:NSNumberFormatterDecimalStyle];
    [desc appendFormat:@"%@: %@\n", @"Volume", [NSString stringWithFormat:@"%@ m\u00B3",withSeparators]];
    
    MTISKFormatter *iskFormatter = [[[MTISKFormatter alloc] init] autorelease];

    NSString *priceStr = [iskFormatter stringFromNumber:[NSNumber numberWithDouble:[self price]]];
    if( priceStr )
    {
        [desc appendFormat:@"%@: %@\n", @"Price", priceStr];
    }
    
    if( isCourier )
    {
        [desc appendFormat:@"%@: %@\n", @"Reward", [iskFormatter stringFromNumber:[NSNumber numberWithDouble:[self reward]]]];
        
        [desc appendFormat:@"%@: %@\n", @"Collateral", [iskFormatter stringFromNumber:[NSNumber numberWithDouble:[self collateral]]]];
    }
    
    if( [[self type] isEqualToString:@"Auction"] )
    {
        [desc appendFormat:@"%@: %@\n", @"Buyout", [iskFormatter stringFromNumber:[NSNumber numberWithDouble:[self buyout]]]];
    }
    
    [desc appendFormat:@"%@: %@\n", @"Issued", [self issued]];
    
    if( (![self completed] && [self expired]) || ([self completed] && ([[self expired] compare:[self completed]] == NSOrderedAscending)) )
    {
        BOOL future = [[self expired] compare:[NSDate date]] == NSOrderedDescending;
        if( future )
            [desc appendFormat:@"%@: %@\n", @"Expires", [self expired]];
        else
            [desc appendFormat:@"%@: %@\n", @"Expired", [self expired]];
    }
    
    if( isCourier && [self accepted] )
    {
        [desc appendFormat:@"%@: %@\n", @"Accepted", [self accepted]];
    }
    
    if( [self completed] )
    {
        [desc appendFormat:@"%@: %@\n", @"Completed", [self completed]];
    }

    [desc appendString:@"\n"];
    
    for( ContractItem *item in [self items] )
    {
        [desc appendFormat:@"%@ x%ld\n", [item name], [item quantity]];
    }
    return desc;
}
@end
