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
#import "CCPDatabase.h"
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
@synthesize xmlPath;
@synthesize cachedUntil;
@synthesize delegate;

- (id)init
{
    if( self = [super init] )
    {
        messages = [[NSMutableArray alloc] init];
        messagesByID = [[NSMutableDictionary alloc] init];
        cachedUntil = [[NSDate distantPast] retain];
    }
    return self;
}

- (void)dealloc
{
    [messages release];
    [messagesByID release];
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
        [messages removeAllObjects];
        [self setCachedUntil:[NSDate distantPast]];
        [self loadMailingListNames];
    }
}

- (NSArray *)messages
{
    return [[messages copy] autorelease];
}

- (void)sortUsingDescriptors:(NSArray *)descriptors
{
    [messages sortUsingDescriptors:descriptors];
}

- (BOOL)startMailDownloadToPath:(NSString *)docPath args:(NSString *)args delegate:(id)del callback:(SEL)selector
{
    if( ![self character] )
        return NO;
    
    CharacterTemplate *template = [[self character] template];
    NSString *apiUrl = [Config getApiUrl:docPath
                                   keyID:[template accountId]
                        verificationCode:[template verificationCode]
                                  charId:[template characterId]];
    if( [args length] > 0 )
    {
        NSString *separator = ('&' == [args characterAtIndex:0])?@"":@"&"; // if the caller already included the ampersand, don't include it ourselves
        apiUrl = [apiUrl stringByAppendingFormat:@"%@%@", separator, args];
    }
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
            return NO;
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
    
    [opParse setDelegate:del];
    [opParse setCallback:selector];
    [opParse setObject:[[characterDir stringByAppendingPathComponent:[docPath lastPathComponent]] retain]];
    
    [opParse addDependency:op]; //THIS MUST BE THE FIRST DEPENDENCY.
    [opParse addCharacterDir:characterDir forSheet:docPath];
    
    [queue addOperation:op];
    [queue addOperation:opParse];
    
    [opParse release];
    [queue release];
    
    return YES;
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
    
    [self startMailDownloadToPath:@"/char/MailMessages.xml.aspx" args:nil delegate:self callback:@selector(parserOperationDone:errors:)];
}

- (void) parserOperationDone:(NSString *)path errors:(NSArray *)errors
{
    xmlDoc *doc = xmlReadFile( [path fileSystemRepresentation], NULL, 0 );
	if( doc == NULL )
    {
		NSLog(@"Failed to read %@",path);
        [path release];
		return;
	}
    [path release];
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

//    [messages removeAllObjects];
    
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
            [messagesByID setObject:message forKey:[NSNumber numberWithInteger:[message messageID]]];
        }
	}
    
    NSLog( @"Found %lu mail messages", (unsigned long)[messages count] );
    
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

    [self loadMessageBodies:[messagesByID allKeys]];
    
    return YES;
}

// https://neweden-dev.com/Char/MailBodies
- (void)loadMessageBodies:(NSArray *)messageIDs
{
    if( ![self character] )
        return;
    
    if( 0 == [messageIDs count] )
        return;

    // we should filter the array to remove any messages that have already had the body downloaded
    
    NSString *messageIDString = [NSString stringWithFormat:@"ids=%@", [messageIDs componentsJoinedByString:@","]];
    [self startMailDownloadToPath:@"/char/MailBodies.xml.aspx" args:messageIDString delegate:self callback:@selector(parseMailBodiesOperationDone:errors:)];
}

- (void) parseMailBodiesOperationDone:(NSString *)path errors:(NSArray *)errors
{
    xmlDoc *doc = xmlReadFile( [path fileSystemRepresentation], NULL, 0 );
    if( doc == NULL )
    {
        NSLog(@"Failed to read %@",path);
        [path release];
        return;
    }
    [path release];
    [self parseXmlMailBodies:doc];
    xmlFreeDoc(doc);
}

-(BOOL) parseXmlMailBodies:(xmlDoc*)document
{
    xmlNode *root_node;
    xmlNode *result;
    xmlNode *rowset;
    
    root_node = xmlDocGetRootElement(document);
    
    result = findChildNode(root_node,(xmlChar*)"result");
    if( NULL == result )
    {
        NSLog(@"Could not get result tag in parseXmlMailBodies");
        
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
        NSLog(@"Could not get rowset tag in parseXmlMailBodies");
        
        xmlNode *xmlErrorMessage = findChildNode(root_node,(xmlChar*)"error");
        if( NULL != xmlErrorMessage )
        {
            NSLog( @"%@", [NSString stringWithString:getNodeText(xmlErrorMessage)] );
        }
        return NO;
    }
    
    for( xmlNode *cur_node = rowset->children;
        NULL != cur_node;
        cur_node = cur_node->next)
    {
        if( XML_ELEMENT_NODE != cur_node->type )
        {
            continue;
        }
        
        /*
         <rowset name="messages" key="messageID" columns="messageID">
         <row messageID="343465359"><![CDATA[<font size="12" color="#bfffffff">Hi all!<br><br>Time for the sexy cats :-)<br><br>Read this: </font><font size="12" color="#ffffa600"><loc><a href="http://www.kadeshi.com/forum/index.php?topic=6834.0">http://www.kadeshi.com/forum/index.php?topic=6834.0</a></loc><br><br></font><font size="12" color="#bfffffff">Hope to see you there!<br><br>Best Regards<br><br>Ltd SpacePig</font>]]></row>
         */
        if( xmlStrcmp(cur_node->name,(xmlChar*)"row") == 0 )
        {
            METMailMessage *message = nil;
            
            for( xmlAttr *attr = cur_node->properties; attr; attr = attr->next )
            {
                NSString *messageID = [NSString stringWithUTF8String:(const char*) attr->children->content];
                if( xmlStrcmp(attr->name, (xmlChar *)"messageID") == 0 )
                {
                    message = [messagesByID objectForKey:[NSNumber numberWithInteger:[messageID integerValue]]]; // Find the message with this messageID
                }
            }
            // now get the content of this row (a CDATA node) and set it as the body of the message
            NSString *body = [NSString stringWithUTF8String:(const char*) cur_node->children->content];
            if( body )
                [message setBody:body];
        }
    }
    
    // change this to a different callback so we know to update mail bodies in the database
    if( [delegate respondsToSelector:@selector(mailBodiesFinishedUpdating)] )
    {
        [delegate performSelector:@selector(mailBodiesFinishedUpdating)];
    }
    return YES;
}


// https://neweden-dev.com/Char/MailingLists
- (void)loadMailingListNames
{
    if( ![self character] )
        return;
    
    // we should filter the array to remove any messages that have already had the body downloaded
    
    [self startMailDownloadToPath:XMLAPI_CHAR_MAILLISTS args:nil delegate:self callback:@selector(parseMailingListOperationDone:errors:)];
}

- (void) parseMailingListOperationDone:(NSString *)path errors:(NSArray *)errors
{
    xmlDoc *doc = xmlReadFile( [path fileSystemRepresentation], NULL, 0 );
    if( doc == NULL )
    {
        NSLog(@"Failed to read %@",path);
        [path release];
        return;
    }
    [path release];
    [self parseXmlMailingLists:doc];
    xmlFreeDoc(doc);
}

/*
 <?xml version='1.0' encoding='UTF-8'?>
 <eveapi version="2">
 <currentTime>2009-12-02 06:29:32</currentTime>
 <result>
 <rowset name="mailingLists" key="listID" columns="listID,displayName">
 <row listID="128250439" displayName="EVETycoonMail" />
 <row listID="128783669" displayName="EveMarketScanner" />
 <row listID="141157801" displayName="Exploration Wormholes" />
 </rowset>
 </result>
 <cachedUntil>2009-12-02 12:29:32</cachedUntil>
 </eveapi>
*/
-(BOOL) parseXmlMailingLists:(xmlDoc*)document
{
    xmlNode *root_node;
    xmlNode *result;
    xmlNode *rowset;
    
    root_node = xmlDocGetRootElement(document);
    
    result = findChildNode(root_node,(xmlChar*)"result");
    if( NULL == result )
    {
        NSLog(@"Could not get result tag in parseXmlMailBodies");
        
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
        NSLog(@"Could not get rowset tag in parseXmlMailBodies");
        
        xmlNode *xmlErrorMessage = findChildNode(root_node,(xmlChar*)"error");
        if( NULL != xmlErrorMessage )
        {
            NSLog( @"%@", [NSString stringWithString:getNodeText(xmlErrorMessage)] );
        }
        return NO;
    }
    
    CCPDatabase *db = [[GlobalData sharedInstance] database];

    for( xmlNode *cur_node = rowset->children;
        NULL != cur_node;
        cur_node = cur_node->next)
    {
        if( XML_ELEMENT_NODE != cur_node->type )
        {
            continue;
        }
        
        /*
         <row listID="141157801" displayName="Exploration Wormholes" />
         */
        if( xmlStrcmp(cur_node->name,(xmlChar*)"row") == 0 )
        {
            NSInteger listID = -1;
            NSString *listName = nil;
            
            for( xmlAttr *attr = cur_node->properties; attr; attr = attr->next )
            {
                NSString *value = [NSString stringWithUTF8String:(const char*) attr->children->content];
                if( xmlStrcmp(attr->name, (xmlChar *)"listID") == 0 )
                {
                    listID = [value integerValue];
                }
                else if( xmlStrcmp(attr->name, (xmlChar *)"displayName") == 0 )
                {
                    listName = value;
                }
            }
            
            if( (-1 != listID) && ([listName length] > 0) )
                [db insertCharacterID:listID name:listName];
        }
    }
    
//    if( [delegate respondsToSelector:@selector(mailBodiesFinishedUpdating)] )
//    {
//        [delegate performSelector:@selector(mailBodiesFinishedUpdating)];
//    }
    return YES;
}
@end
