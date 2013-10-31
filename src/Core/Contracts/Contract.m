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

#import "Character.h"
#import "CharacterTemplate.h"
#import "XMLDownloadOperation.h"
#import "XMLParseOperation.h"
#import "XmlHelpers.h"
#include <libxml/tree.h>
#include <libxml/parser.h>

@interface Contract()
@property (readwrite) NSString *stationName;
@property (readwrite,retain) NSDate *cachedUntil; // For contained items, not the contract itself
@property (readwrite,retain) NSString *xmlPath;
@property (readwrite,assign) BOOL loading;
@end

@implementation Contract

@synthesize character;
@synthesize xmlPath;
@synthesize delegate;

@synthesize type;
@synthesize status;
@synthesize contractID;
@synthesize startStationID;
@synthesize endStationID;

@synthesize startStationName = _startStationName;
@synthesize endStationName = _endStationName;

@synthesize volume;
@synthesize price;
@synthesize reward;
@synthesize collateral;
@synthesize issued;
@synthesize expired;
@synthesize accepted;
@synthesize completed;
@synthesize availability;
@synthesize title;
@synthesize days;
@synthesize cachedUntil;
@synthesize items = _items;
@synthesize loading;

- (id)init
{
    if( self = [super init] )
    {
        _items = [[NSMutableArray alloc] init];
        [self setLoading:NO];
    }
    return self;
}

- (void)dealloc
{
    [super dealloc];
    [character release];
    [xmlPath release];
    [type release];
    [status release];
    [_items release];
    [issued release];
    [expired release];
    [accepted release];
    [completed release];
    [availability release];
    [title release];
    [cachedUntil release];
    [_startStationName release];
    [_endStationName release];
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
        NSDictionary *station = [db stationForID:startStationID];
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
        NSDictionary *station = [db stationForID:endStationID];
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
    
    if( [cachedUntil isGreaterThan:[NSDate date]] )
    {
        NSLog( @"Skipping download of Contract items because of Cached Until date" );
        [self setLoading:NO];
        return;
    }
    
    CharacterTemplate *template = [[self character] template];
    
    NSString *docPath = XMLAPI_CHAR_CONTRACT_ITEMS;
    NSString *apiUrl = [Config getApiUrl:docPath
                                   keyID:[template accountId]
                        verificationCode:[template verificationCode]
                                  charId:[template characterId]];
    apiUrl = [apiUrl stringByAppendingFormat:@"&contractID=%ld",[self contractID]];

	NSString *characterDir = [Config charDirectoryPath:[template accountId]
											 character:[template characterId]];
    NSString *pendingDir = [characterDir stringByAppendingString:@"/pending"];
    
    NSString *docPathID = [[[docPath stringByDeletingPathExtension] stringByAppendingFormat:@"_%ld", [self contractID]] stringByAppendingPathExtension:[docPath pathExtension]];
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
        else
        {
			//NSLog(@"Created directory %@",pendingDir);
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
    xmlDoc *doc = xmlReadFile( [xmlPath fileSystemRepresentation], NULL, 0 );
	if( doc == NULL )
    {
		NSLog(@"Failed to read %@",xmlPath);
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
            ContractItem *item = [[ContractItem alloc] init];

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
    
    if( [delegate respondsToSelector:@selector(contractItemsFinishedUpdating)] )
    {
        [delegate performSelector:@selector(contractItemsFinishedUpdating)];
    }
    
    [self setLoading:NO];
	return YES;
}

@end
