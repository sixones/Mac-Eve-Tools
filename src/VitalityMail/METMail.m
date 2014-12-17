//
//  METMail.m
//  Vitality
//
//  Created by Andrew Salamon on Dec 8, 2014.
//  Copyright (c) 2014 Vitality Project. All rights reserved.
//

#import "METMail.h"

#import "Config.h"
#import "GlobalData.h"
#import "XmlHelpers.h"
#import "Character.h"
#import "CharacterTemplate.h"
#import "Contract.h"
#import "METMailMessage.h"

#import "XMLDownloadOperation.h"
#import "XMLParseOperation.h"

#include <assert.h>

#include <libxml/tree.h>
#include <libxml/parser.h>

@interface METMail()
@property (readwrite,retain) NSString *xmlPath;
@property (readwrite,retain) NSDate *cachedUntil;
@end

@implementation METMail

@synthesize character = _character;
@synthesize messages;
@synthesize xmlPath;
@synthesize cachedUntil;
@synthesize delegate;

- (id)init
{
    if( self = [super init] )
    {
        messages = [[NSMutableArray alloc] init];
        cachedUntil = [[NSDate distantPast] retain];
    }
    return self;
}

- (void)dealloc
{
    [messages release];
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
        [[self messages] removeAllObjects];
        [self setCachedUntil:[NSDate distantPast]];
    }
}

- (void)sortUsingDescriptors:(NSArray *)descriptors
{
    [messages sortUsingDescriptors:descriptors];
}

- (IBAction)reload:(id)sender
{
    if( ![self character] )
        return;
    
    if( [cachedUntil isGreaterThan:[NSDate date]] )
    {
        NSLog( @"Skipping download of Mail because of Cached Until date: %@", cachedUntil );
        // Turn off the spinning download indicator
        if( [delegate respondsToSelector:@selector(mailSkippedUpdating)] )
        {
            [delegate performSelector:@selector(mailSkippedUpdating)];
        }
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
    
    
    NSString *docPath = @"/char/MailMessages.xml.aspx";
    NSString *apiUrl = [Config getApiUrl:docPath
                                   keyID:[template accountId]
                        verificationCode:[template verificationCode]
                                  charId:[template characterId]];
    
	NSString *characterDir = [Config charDirectoryPath:[template accountId]
											 character:[template characterId]];
    NSString *pendingDir = [characterDir stringByAppendingString:@"/pending"];
    
    [self setXmlPath:[characterDir stringByAppendingPathComponent:[docPath lastPathComponent]]];
    
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
	[opParse addCharacterDir:characterDir forSheet:docPath];
    
	[queue addOperation:op];
	[queue addOperation:opParse];
    
	[opParse release];
	[queue release];

}

- (void) parserOperationDone:(id)ignore errors:(NSArray *)errors
{
    xmlDoc *doc = xmlReadFile( [xmlPath fileSystemRepresentation], NULL, 0 );
	if( doc == NULL )
    {
		NSLog(@"Failed to read %@",xmlPath);
		return;
	}
	[self parseXmlMailMessages:doc];
	xmlFreeDoc(doc);
}

/* Sample xml for mail:
 <?xml version='1.0' encoding='UTF-8'?>
 <eveapi version="2">
 <currentTime>2014-10-16 22:51:11</currentTime>
 <result>
 <rowset name="messages" key="messageID" columns="messageID,senderID,senderName,sentDate,title,toCorpOrAllianceID,toCharacterIDs,toListID">
 
 <row messageID="343473429" senderID="1038223958" senderName="Agamemnnonn" sentDate="2014-10-06 17:55:00" title="Goodbye My Friends" toCorpOrAllianceID="1147488332" toCharacterIDs="" toListID="" senderTypeID="1376" />
 <row messageID="343464728" senderID="1625677343" senderName="Speedtouch" sentDate="2014-10-06 08:46:00" title="FA leaving CFC" toCorpOrAllianceID="1147488332" toCharacterIDs="" toListID="" senderTypeID="1378" />

 </result>
 <cachedUntil>2011-07-30 05:44:30</cachedUntil>
 </eveapi>
 */
-(BOOL) parseXmlMailMessages:(xmlDoc*)document
{
	xmlNode *root_node;
	xmlNode *result;
    xmlNode *rowset;
    
	root_node = xmlDocGetRootElement(document);
    
	result = findChildNode(root_node,(xmlChar*)"result");
	if( NULL == result )
    {
		NSLog(@"Could not get result tag in parseXmlMailMessages");
		
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
		NSLog(@"Could not get rowset tag in parseXmlMailMessages");
		
		xmlNode *xmlErrorMessage = findChildNode(root_node,(xmlChar*)"error");
		if( NULL != xmlErrorMessage )
        {
			NSLog( @"%@", [NSString stringWithString:getNodeText(xmlErrorMessage)] );
		}
		return NO;
	}

    [messages removeAllObjects];
    
	for( xmlNode *cur_node = rowset->children;
		 NULL != cur_node;
		 cur_node = cur_node->next)
	{
		if( XML_ELEMENT_NODE != cur_node->type )
        {
			continue;
		}
        
        /*
         <row
         messageID="343465359"
         senderID="1597400586"
         senderName="Ltd SpacePig"
         sentDate="2014-10-06 09:43:00"
         title="Important!  Read this"
         toCorpOrAllianceID="1147488332"
         toCharacterIDs=""
         toListID=""
         senderTypeID="1373"
         />
*/
		if( xmlStrcmp(cur_node->name,(xmlChar*)"row") == 0 )
        {
            METMailMessage *message = [[METMailMessage alloc] init];
            [message setCharacter:[self character]];
             
            for( xmlAttr *attr = cur_node->properties; attr; attr = attr->next )
            {
                NSString *value = [NSString stringWithUTF8String:(const char*) attr->children->content];
                if( xmlStrcmp(attr->name, (xmlChar *)"messageID") == 0 )
                {
                    [message setMessageID:[value integerValue]];
                }
                else if( xmlStrcmp(attr->name, (xmlChar *)"senderID") == 0 )
                {
                    [message setSenderID:[value integerValue]];
                }
                else if( xmlStrcmp(attr->name, (xmlChar *)"senderName") == 0 )
                {
                    [message setSenderName:value];
                }
                else if( xmlStrcmp(attr->name, (xmlChar *)"sentDate") == 0 )
                {
                    NSDate *date = [NSDate dateWithNaturalLanguageString:value];
                    [message setSentDate:date];
                }
                else if( xmlStrcmp(attr->name, (xmlChar *)"title") == 0 )
                {
                    [message setSubject:value];
                }
                else if( xmlStrcmp(attr->name, (xmlChar *)"toCorpOrAllianceID") == 0 )
                {
                    [message setToCorpOrAllianceID:[value integerValue]];
                }
                else if( xmlStrcmp(attr->name, (xmlChar *)"toCharacterIDs") == 0 )
                {
                    [message setToCharacterIDs:[value componentsSeparatedByString:@","]];
                }
                else if( xmlStrcmp(attr->name, (xmlChar *)"toListID") == 0 )
                {
                    [message setToListID:[value integerValue]];
                }
            }
            [messages addObject:message];
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
    
    if( [delegate respondsToSelector:@selector(mailFinishedUpdating)] )
    {
        [delegate performSelector:@selector(mailFinishedUpdating)];
    }
	return YES;
}

@end
