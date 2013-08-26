//
//  Contracts.m
//  Mac Eve Tools
//
//  Created by Andrew Salamon on 5/17/13.
//  Copyright (c) 2013 Sebastian Kruemling. All rights reserved.
//

#import "Contracts.h"

#import "Config.h"
#import "GlobalData.h"
#import "XmlHelpers.h"
#import "Character.h"
#import "CharacterTemplate.h"
#import "Contract.h"

#import "XMLDownloadOperation.h"
#import "XMLParseOperation.h"

#include <assert.h>

#include <libxml/tree.h>
#include <libxml/parser.h>

@interface Contracts()
@property (readwrite,retain) NSString *xmlPath;
@property (readwrite,retain) NSDate *cachedUntil;
@end

@implementation Contracts

@synthesize character = _character;
@synthesize contracts;
@synthesize xmlPath;
@synthesize cachedUntil;
@synthesize delegate;

- (id)init
{
    if( self = [super init] )
    {
        contracts = [[NSMutableArray alloc] init];
        cachedUntil = [[NSDate distantPast] retain];
    }
    return self;
}

- (void)dealloc
{
    [contracts release];
    [cachedUntil release];
    [super dealloc];
}

- (Character *)character
{
    return [[_character retain] autorelease];
}

- (void)setCharacter:(Character *)character
{
    if( _character != character )
    {
        [_character release];
        _character = [character retain];
        [[self contracts] removeAllObjects];
        [self setCachedUntil:[NSDate distantPast]];
    }
}

- (void)sortUsingDescriptors:(NSArray *)descriptors
{
    [contracts sortUsingDescriptors:descriptors];
}

- (IBAction)reload:(id)sender
{
    if( ![self character] )
        return;
    
    if( [cachedUntil isGreaterThan:[NSDate date]] )
    {
        NSLog( @"Skipping download of Contracts because of Cached Until date" );
        return;
    }
    
    CharacterTemplate *template = nil;
    NSUInteger chID = [[self character] characterId];
    
    for( CharacterTemplate *charTemplate in [[Config sharedInstance] activeCharacters] )
    {
        NSUInteger tempID = [[charTemplate characterId] integerValue];
        if( tempID == chID )
        {
            template = charTemplate;
            break;
        }
    }
    
    
    NSString *docPath = XMLAPI_CHAR_CONTRACTS;
    NSString *apiUrl = [Config getApiUrl:docPath
                                   keyID:[template accountId]
                        verificationCode:[template verificationCode]
                                  charId:[template characterId]];
    
	NSString *characterDir = [Config charDirectoryPath:[template accountId]
											 character:[template characterId]];
    NSString *pendingDir = [characterDir stringByAppendingString:@"/pending"];
    
    [self setXmlPath:[characterDir stringByAppendingPathComponent:[XMLAPI_CHAR_ORDERS lastPathComponent]]];
    
	//create the output directory, the XMLParseOperation will clean it up
    // TODO move this to an operations sub-class and have all of the download operations depend on it
	NSFileManager *fm = [NSFileManager defaultManager];
	if( ![fm fileExistsAtPath:pendingDir isDirectory:nil] )
    {
		if( ![fm createDirectoryAtPath: pendingDir withIntermediateDirectories:YES attributes:nil error:nil] )
        {
			//NSLog(@"Could not create directory %@",pendingDir);
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
	[op setXmlDoc:docPath];
    
    NSOperationQueue *queue = [[NSOperationQueue alloc] init];
	[queue setMaxConcurrentOperationCount:3];
    
	//This object will call the delegate function.
    
	XMLParseOperation *opParse = [[XMLParseOperation alloc] init];
    
	[opParse setDelegate:self];
	[opParse setCallback:@selector(parserOperationDone:errors:)];
	[opParse setObject:nil];
    
	[opParse addDependency:op]; //THIS MUST BE THE FIRST DEPENDENCY.
	[opParse addCharacterDir:characterDir forSheet:XMLAPI_CHAR_ORDERS];
    
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
		return;
	}
	[self parseXmlContracts:doc];
	xmlFreeDoc(doc);
}

/* Sample xml for contracts:
 <?xml version='1.0' encoding='UTF-8'?>
 <eveapi version="2">
 <currentTime>2011-07-30 04:47:30</currentTime>
 <result>
 <rowset name="contractList" key="contractID" columns="contractID,issuerID,issuerCorpID,assigneeID,acceptorID,startStationID,endStationID,
 type,status,title,forCorp,dateIssued,dateExpired,dateAccepted,numDays,dateCompleted,price,reward,collateral,volume" />
 </result>
 <cachedUntil>2011-07-30 05:44:30</cachedUntil>
 </eveapi>
 */
-(BOOL) parseXmlContracts:(xmlDoc*)document
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
		return NO;
	}

    [contracts removeAllObjects];
    
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
            Contract *contract = [[Contract alloc] init];
            
            for( xmlAttr *attr = cur_node->properties; attr; attr = attr->next )
            {
                NSString *value = [NSString stringWithUTF8String:(const char*) attr->children->content];
//                if( xmlStrcmp(attr->name, (xmlChar *)"orderID") == 0 )
//                {
//                    [order setOrderID:[value integerValue]];
//                }
//                else if( xmlStrcmp(attr->name, (xmlChar *)"orderState") == 0 )
//                {
//                    NSInteger intValue = [value integerValue];
//                    OrderStateType stType = OrderStateUnknown;
//                    switch( intValue )
//                    {
//                        case 0: stType = OrderStateActive; break;
//                        case 1: stType = OrderStateClosed; break;
//                        case 2: stType = OrderStateExpired; break;
//                        case 3: stType = OrderStateCancelled; break;
//                        case 4: stType = OrderStatePending; break;
//                        case 5: stType = OrderStateCharacterDeleted; break;
//                        default: stType = OrderStateUnknown; break;
//
//                    }
//                    [order setOrderState:stType];
//                }
//                else if( xmlStrcmp(attr->name, (xmlChar *)"price") == 0 )
//                {
//                    [order setPrice:[value doubleValue]];
//                }
//                else if( xmlStrcmp(attr->name, (xmlChar *)"bid") == 0 )
//                {
//                    if( [value isEqualToString:@"0"] )
//                        [order setBuy:NO];
//                    else
//                        [order setBuy:YES];
//                }
//                else if( xmlStrcmp(attr->name, (xmlChar *)"issued") == 0 )
//                {
//                    NSDate *issuedDate = [NSDate dateWithNaturalLanguageString:value];
//                    [order setIssued:issuedDate];
//                }
            }
            [contracts addObject:contract];
        }
	}
    
    // Should also grab the "cachedUntil" node so we don't re-request data until after that time.
    // 2013-05-22 22:32:5
    xmlNode *cached = findChildNode( root_node, (xmlChar *)"cachedUntil" );
    if( NULL != cached )
    {
        NSString *dtString = getNodeText( cached );
        NSDate *cacheDate = [NSDate dateWithNaturalLanguageString:dtString];
        [self setCachedUntil:cacheDate];

    }
    
    if( [delegate respondsToSelector:@selector(ordersFinishedUpdating)] )
    {
        [delegate performSelector:@selector(ordersFinishedUpdating)];
    }
	return YES;
}

@end
