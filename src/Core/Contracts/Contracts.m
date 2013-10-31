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
    
    [self setXmlPath:[characterDir stringByAppendingPathComponent:[XMLAPI_CHAR_CONTRACTS lastPathComponent]]];
    
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
	[opParse addCharacterDir:characterDir forSheet:XMLAPI_CHAR_CONTRACTS];
    
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
 
 <row contractID="72716865" issuerID="91794908" issuerCorpID="1406664155" assigneeID="98159347" acceptorID="0" startStationID="60004588" endStationID="61000617" type="Courier" status="Outstanding" title="" forCorp="0" availability="Private" dateIssued="2013-09-15 14:59:52" dateExpired="2013-09-29 14:59:52" dateAccepted="" numDays="7" dateCompleted="" price="0.00" reward="14905500.00" collateral="0.00" buyout="0.00" volume="59622.4475" />

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
            [contract setCharacter:[self character]];
             
            for( xmlAttr *attr = cur_node->properties; attr; attr = attr->next )
            {
                NSString *value = [NSString stringWithUTF8String:(const char*) attr->children->content];
                if( xmlStrcmp(attr->name, (xmlChar *)"type") == 0 )
                {
                    [contract setType:value];
                }
                else if( xmlStrcmp(attr->name, (xmlChar *)"status") == 0 )
                {
                    [contract setStatus:value];
                }
                else if( xmlStrcmp(attr->name, (xmlChar *)"contractID") == 0 )
                {
                    [contract setContractID:[value integerValue]];
                }
                else if( xmlStrcmp(attr->name, (xmlChar *)"startStationID") == 0 )
                {
                    [contract setStartStationID:[value integerValue]];
                }
                else if( xmlStrcmp(attr->name, (xmlChar *)"endStationID") == 0 )
                {
                    [contract setEndStationID:[value integerValue]];
                }
                else if( xmlStrcmp(attr->name, (xmlChar *)"volume") == 0 )
                {
                    [contract setVolume:[value doubleValue]];
                }
                else if( xmlStrcmp(attr->name, (xmlChar *)"price") == 0 )
                {
                    [contract setPrice:[value doubleValue]];
                }
                else if( xmlStrcmp(attr->name, (xmlChar *)"reward") == 0 )
                {
                    [contract setReward:[value doubleValue]];
                }
                else if( xmlStrcmp(attr->name, (xmlChar *)"collateral") == 0 )
                {
                    [contract setCollateral:[value doubleValue]];
                }
                else if( xmlStrcmp(attr->name, (xmlChar *)"buyout") == 0 )
                {
                    [contract setBuyout:[value doubleValue]];
                }
                else if( xmlStrcmp(attr->name, (xmlChar *)"dateIssued") == 0 )
                {
                    NSDate *date = [NSDate dateWithNaturalLanguageString:value];
                    [contract setIssued:date];
                }
                else if( xmlStrcmp(attr->name, (xmlChar *)"dateExpired") == 0 )
                {
                    NSDate *date = [NSDate dateWithNaturalLanguageString:value];
                    [contract setExpired:date];
                }
                else if( xmlStrcmp(attr->name, (xmlChar *)"dateAccepted") == 0 )
                {
                    NSDate *date = [NSDate dateWithNaturalLanguageString:value];
                    [contract setAccepted:date];
                }
                else if( xmlStrcmp(attr->name, (xmlChar *)"dateCompleted") == 0 )
                {
                    NSDate *date = [NSDate dateWithNaturalLanguageString:value];
                    [contract setCompleted:date];
                }
                else if( xmlStrcmp(attr->name, (xmlChar *)"availability") == 0 )
                {
                    [contract setAvailability:value];
                }
                else if( xmlStrcmp(attr->name, (xmlChar *)"title") == 0 )
                {
                    [contract setTitle:value];
                }
                else if( xmlStrcmp(attr->name, (xmlChar *)"numDays") == 0 )
                {
                    [contract setDays:[value integerValue]];
                }
                else if( xmlStrcmp(attr->name, (xmlChar *)"forCorp") == 0 )
                {
                    //NSLog( @"Contract forCorp: %@", value );
                }
                else if( xmlStrcmp(attr->name, (xmlChar *)"issuerID") == 0 )
                {
                    //[contract setDays:[value integerValue]];
                }
                else if( xmlStrcmp(attr->name, (xmlChar *)"issuerCorpID") == 0 )
                {
                    //[contract setDays:[value integerValue]];
                }
                else if( xmlStrcmp(attr->name, (xmlChar *)"assigneeID") == 0 )
                {
                    //[contract setDays:[value integerValue]];
                }
                else if( xmlStrcmp(attr->name, (xmlChar *)"acceptorID") == 0 )
                {
                    //[contract setDays:[value integerValue]];
                }
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
    
    if( [delegate respondsToSelector:@selector(contractsFinishedUpdating)] )
    {
        [delegate performSelector:@selector(contractsFinishedUpdating)];
    }
	return YES;
}

@end
