//
//  METIDtoName.m
//  Vitality
//
//  Created by Andrew Salamon on 5/17/13.
//  Copyright (c) 2013 Sebastian Kruemling. All rights reserved.
//

#import "METIDtoName.h"

#import "Config.h"
#import "GlobalData.h"
#import "XmlHelpers.h"
#import "CCPDatabase.h"
#include <assert.h>

#include <libxml/tree.h>
#include <libxml/parser.h>
#import <sqlite3.h>

@interface METIDtoName()
@property (readwrite,retain) NSDate *cachedUntil;
-(BOOL) parseXmlIDsToNames:(xmlDoc *)data;
@end

@implementation METIDtoName

@synthesize cachedUntil;

+ (NSString *)reloadNotificationName
{
    return @"ConquerableStationsUpdated";
}

- (id)init
{
    if( self = [super init] )
    {
        xmlData = [[NSMutableData alloc] init];
        cachedUntil = [[NSDate distantPast] retain];
        cachedNames = [[NSMutableDictionary alloc] init];
    }
    return self;
}

- (void)dealloc
{
    [xmlData release];
    [cachedUntil release];
    [cachedNames release];
    [super dealloc];
}

- (NSSet *)validateIDs:(NSSet *)IDs
{
    NSMutableSet *validated = [NSMutableSet set];
    CCPDatabase *db = [[GlobalData sharedInstance] database];

    [cachedNames removeAllObjects];
    
    for( NSNumber *anID in IDs )
    {
        NSString *name = [db characterNameForID:[anID integerValue]];
        if( name )
        {
            [cachedNames setObject:name forKey:anID];
        }
        else
        {
            [validated addObject:anID];
        }
    }
    
    if( [validated count] > 250 )
    {
        NSLog( @"Too many character ID's. Skipping some" );
        return [NSSet setWithArray:[[validated allObjects] subarrayWithRange:NSMakeRange(0,250)]];
    }
    
    return validated;
}

- (void)namesForIDs:(NSSet *)IDs
{
    if( [cachedUntil isGreaterThan:[NSDate date]] )
    {
        NSLog( @"Skipping download of Names from IDs because of Cached Until date" );
        return;
    }
    
    IDs = [self validateIDs:IDs];
    
    if( 0 == [IDs count] )
    {
        // either IDs was empty, or we found them all in the local database
        if( ([cachedNames count] > 0) && [[self delegate] conformsToProtocol:@protocol(METIDtoNameDelegate)] )
        {
            [[self delegate] namesFromIDs:cachedNames];
        }
        return;
    }
    
	NSString *urlPath = [Config getApiUrl:XMLAPI_EVE_NAMES keyID:nil verificationCode:nil charId:nil];
    NSString *IDString = [[IDs allObjects] componentsJoinedByString:@","];
    urlPath = [NSString stringWithFormat:@"%@?ids=%@",urlPath,IDString];
	NSURL *url = [NSURL URLWithString:urlPath];
    
	NSURLRequest *request = [NSURLRequest requestWithURL:url];
    [NSURLConnection connectionWithRequest:request delegate:self];
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
	[xmlData appendData:data];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    const char *ptr = [xmlData bytes];
	NSInteger length = [xmlData length];
	
	if(length == 0){
		NSLog(@"Zero bytes returned for Names from IDs data");
		return;
	}
	
	xmlDoc *doc = xmlReadMemory(ptr, (int)length, NULL, NULL, 0);
	if( doc == NULL )
    {
		NSLog(@"Failed to read Names from IDs data");
		return;
	}
	[self parseXmlIDsToNames:doc];
	xmlFreeDoc(doc);
	[xmlData setLength:0];
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
    NSLog(@"Failed to read Names from IDs data");
	[xmlData setLength:0];
}

/* Sample xml
 <?xml version='1.0' encoding='UTF-8'?>
 <eveapi version="2">
 <currentTime>2011-03-02 15:00:07</currentTime>
 <result>
 <rowset name="characters" key="characterID" columns="name,characterID">
 <row name="CCP Garthagk" characterID="797400947" />
 <row name="CCP Prism X" characterID="1188435724" />
 </rowset>
 </result>
 <cachedUntil>2011-04-02 15:00:07</cachedUntil>
 </eveapi>
 */
-(BOOL) parseXmlIDsToNames:(xmlDoc *)doc
{
    CCPDatabase *db = [[GlobalData sharedInstance] database];
	xmlNode *root_node = xmlDocGetRootElement(doc);
    
	xmlNode *result = findChildNode(root_node,(xmlChar*)"result");
	if( NULL == result )
    {
		NSLog(@"Could not get result tag in parseXmlIDsToNames");
		
		xmlNode *xmlErrorMessage = findChildNode(root_node,(xmlChar*)"error");
		if( NULL != xmlErrorMessage )
        {
			NSLog( @"%@", getNodeText(xmlErrorMessage) );
		}
		return NO;
	}
    
    xmlNode *rowset = findChildNode(result,(xmlChar*)"rowset");
	if( NULL == result )
    {
		NSLog(@"Could not get rowset tag in parseXmlIDsToNames");
		
		xmlNode *xmlErrorMessage = findChildNode(root_node,(xmlChar*)"error");
		if( NULL != xmlErrorMessage )
        {
			NSLog( @"%@", getNodeText(xmlErrorMessage) );
		}
		return NO;
	}
    
    [db beginTransaction];
    NSMutableDictionary *idsAndNames = [NSMutableDictionary dictionary];
    
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
            NSInteger characterID;
            NSString *name = nil;
            
            for( xmlAttr *attr = cur_node->properties; attr; attr = attr->next )
            {
                NSString *value = [NSString stringWithUTF8String:(const char*) attr->children->content];
                if( xmlStrcmp(attr->name, (xmlChar *)"characterID") == 0 )
                {
                    characterID = [value integerValue];
                }
                else if( xmlStrcmp(attr->name, (xmlChar *)"name") == 0 )
                {
                    name = value;
                }
            }
            if( name )
            {
                [idsAndNames setObject:name forKey:[NSNumber numberWithInteger:characterID]];
                [db insertCharacterID:characterID name:name];
            }
        }
	}
    
    [db commitTransaction];

    // Should also grab the "cachedUntil" node so we don't re-request data until after that time.
    // 2013-05-22 22:32:5
    xmlNode *cached = findChildNode( root_node, (xmlChar *)"cachedUntil" );
    if( NULL != cached )
    {
        NSString *dtString = getNodeText( cached );
        NSDate *cacheDate = [NSDate dateWithNaturalLanguageString:dtString];
        [self setCachedUntil:cacheDate];

    }
    
    if( [[self delegate] conformsToProtocol:@protocol(METIDtoNameDelegate)] )
    {
        // we might also have some names from the local database
        [idsAndNames addEntriesFromDictionary:cachedNames];
        [[self delegate] namesFromIDs:idsAndNames];
    }
    
	return YES;
}

@end
