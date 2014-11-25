//
//  METConquerableStations.m
//  Mac Eve Tools
//
//  Created by Andrew Salamon on 5/17/13.
//  Copyright (c) 2013 Sebastian Kruemling. All rights reserved.
//

#import "METConquerableStations.h"

#import "Config.h"
#import "GlobalData.h"
#import "XmlHelpers.h"
#import "CCPDatabase.h"
#import "METURLRequest.h"

#include <assert.h>
#include <libxml/tree.h>
#include <libxml/parser.h>
#import <sqlite3.h>

@interface METConquerableStations()
@property (readwrite,retain) NSDate *cachedUntil;
-(BOOL) parseXmlConquerableStations:(xmlDoc *)data;
@end

@implementation METConquerableStations

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
    }
    return self;
}

- (void)dealloc
{
    [xmlData release];
    [cachedUntil release];
    [super dealloc];
}

- (IBAction)reload:(id)sender
{    
    if( [cachedUntil isGreaterThan:[NSDate date]] )
    {
        NSLog( @"Skipping download of Conquerable Stations because of Cached Until date" );
        return;
    }
    
	NSString *urlPath = [Config getApiUrl:XMLAPI_STATIONS keyID:nil verificationCode:nil charId:nil];
	NSURL *url = [NSURL URLWithString:urlPath];
	METURLRequest *request = [METURLRequest requestWithURL:url];
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
		NSLog(@"Zero bytes returned for Conquerable Stations data");
		return;
	}
	
	xmlDoc *doc = xmlReadMemory(ptr, (int)length, NULL, NULL, 0);
	if( doc == NULL )
    {
		NSLog(@"Failed to read Conquerable Stations data");
		return;
	}
	[self parseXmlConquerableStations:doc];
	xmlFreeDoc(doc);
	[xmlData setLength:0];
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
    NSLog(@"Failed to read Conquerable Stations data");
	[xmlData setLength:0];
}

/* Sample xml
 <?xml version='1.0' encoding='UTF-8'?>
 <eveapi version="1">
 <currentTime>2007-12-02 19:55:38</currentTime>
 <result>
 <rowset name="outposts" key="stationID" columns="stationID,stationName,stationTypeID,solarSystemID,corporationID,corporationName">
 <row stationID="60014862" stationName="0-G8NO VIII - Moon 1 - Manufacturing Outpost" stationTypeID="12242" solarSystemID="30000480" corporationID="1000135" corporationName="Serpentis Corporation" />
 <row stationID="60014863" stationName="4-EFLU VII - Moon 3 - Manufacturing Outpost" stationTypeID="12242" solarSystemID="30000576" corporationID="1000135" corporationName="Serpentis Corporation" />
 <row stationID="60014928" stationName="6T3I-L VII - Moon 5 - Cloning Outpost" stationTypeID="12295" solarSystemID="30004908" corporationID="1000135" corporationName="Serpentis Corporation" />
 <row stationID="61000001" stationName="DB1R-4 II - duperTum Corp Minmatar Service Outpost" stationTypeID="21646" solarSystemID="30004470" corporationID="150020944" corporationName="duperTum Corp" />
 <row stationID="61000002" stationName="ZS-2LT XI - duperTum Corp Minmatar Service Outpost" stationTypeID="21646" solarSystemID="30004469" corporationID="150020944" corporationName="duperTum Corp" />
 </rowset>
 </result>
 <cachedUntil>2007-12-02 20:55:38</cachedUntil>
 </eveapi>
 */
-(BOOL) parseXmlConquerableStations:(xmlDoc *)doc
{
    CCPDatabase *db = [[GlobalData sharedInstance] database];
	xmlNode *root_node = xmlDocGetRootElement(doc);
    
	xmlNode *result = findChildNode(root_node,(xmlChar*)"result");
	if( NULL == result )
    {
		NSLog(@"Could not get result tag in parseXmlConquerableStations");
		
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
		NSLog(@"Could not get rowset tag in parseXmlConquerableStations");
		
		xmlNode *xmlErrorMessage = findChildNode(root_node,(xmlChar*)"error");
		if( NULL != xmlErrorMessage )
        {
			NSLog( @"%@", getNodeText(xmlErrorMessage) );
		}
		return NO;
	}
    
    [db beginTransaction];
    
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
            NSUInteger stationID = 0;
            NSUInteger solarSystemID = 0;
            NSString *stationName = nil;
            
            for( xmlAttr *attr = cur_node->properties; attr; attr = attr->next )
            {
                NSString *value = [NSString stringWithUTF8String:(const char*) attr->children->content];
                if( xmlStrcmp(attr->name, (xmlChar *)"stationID") == 0 )
                {
                    stationID = [value integerValue];
                }
                else if( xmlStrcmp(attr->name, (xmlChar *)"solarSystemID") == 0 )
                {
                    solarSystemID = [value integerValue];
                }
                else if( xmlStrcmp(attr->name, (xmlChar *)"stationName") == 0 )
                {
                    stationName = value;
                }
            }
            if( stationName )
            {
                [db insertStationID:stationID name:stationName system:solarSystemID];
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
    
    [[NSNotificationCenter defaultCenter] postNotificationName:[METConquerableStations reloadNotificationName] object:self];
    
	return YES;
}

@end
