//
//  METRowsetEnumerator.m
//  Vitality
//
//  Created by Andrew Salamon on 10/19/15.
//  Copyright (c) 2015 Sebastian Kruemling. All rights reserved.
//

#import "METRowsetEnumerator.h"
#import "Character.h"
#import "METCharacter_CachedDates.h"
#import "CharacterTemplate.h"
#import "METURLRequest.h"
#import "Config.h"
#import "METXmlNode.h"

#import "XmlHelpers.h"
#include <libxml/tree.h>
#include <libxml/parser.h>

@implementation METRowsetEnumerator

@synthesize delegate = _delegate;
@synthesize character = _character;
@synthesize checkCachedDate = _checkCachedDate;

- (METRowsetEnumerator *)initWithCharacter:(Character *)_char API:(NSString *)api forDelegate:(id)_del
{
    if( self = [super init] )
    {
        _delegate = _del;
        _character = [_char retain];
        _checkCachedDate = YES;
        apiPath = [api retain];
    }
    
    return self;
}

- (void)dealloc
{
    _delegate = nil;
    [urlConnection cancel];
    [_character release];
    [apiPath release];
    [urlConnection release];
    [xmlData release];
    if( xmlDocument )
        xmlFreeDoc((xmlDocPtr)xmlDocument);

    [super dealloc];
}

- (void)run
{
    [self runWithURLExtras:nil];
}

- (void)runWithURLExtras:(NSString *)extraURLArgs
{
    // clear out old stuff
    if( xmlDocument )
    {
        xmlFreeDoc((xmlDocPtr)xmlDocument);
        xmlDocument = nil;
    }
    rowsetNode = nil;
    
    if( ![self character] )
    {
        [self reportWithError:[self errorWithCode:METRowsetMissingCharacter andMessage:@"Missing character"]];
        return;
    }
    
    if( [self checkCachedDate] && [[self character] isCachedForAPI:apiPath] )
    {
        [self reportWithError:[self errorWithCode:METRowsetCached andMessage:@"Skipping API call because of Cached Until date"]];
        return;
    }
    
    CharacterTemplate *template = [[self character] template];
    NSString *urlPath = [Config getApiUrl:apiPath
                                    keyID:[template accountId]
                         verificationCode:[template verificationCode]
                                   charId:[template characterId]];
    if( [extraURLArgs length] > 0 )
        urlPath = [urlPath stringByAppendingString:extraURLArgs];
    NSURL *url = [NSURL URLWithString:urlPath];
    
    METURLRequest *request = [METURLRequest requestWithURL:url];
    [request setDelegate:self];
    urlConnection = [[NSURLConnection connectionWithRequest:request delegate:request] retain];
}

- (void)cancel
{
    [urlConnection cancel];
}

- (NSUInteger)countByEnumeratingWithState:(NSFastEnumerationState *)state objects:(id __unsafe_unretained [])buffer count:(NSUInteger)len
{
    // plan of action: extra[0] will contain pointer to node
    // that contains next object to iterate
    // because extra[0] is a long, this involves ugly casting
    if(state->state == 0)
    {
        // state 0 means it's the first call, so get things set up
        // we won't try to detect mutations, so make mutationsPtr
        // point somewhere that's guaranteed not to change
        state->mutationsPtr = (unsigned long *)self;
        
        // set up extra[0] to point to the head to start in the right place
        if( rowsetNode )
        {
            xmlNode *tempNode = ((xmlNode *)rowsetNode)->children;
            while( tempNode && (XML_ELEMENT_NODE != tempNode->type) )
                tempNode = tempNode->next;
            state->extra[0] = (long)tempNode;
        }
        else
        {
            state->extra[0] = 0;
        }
        
        // and update state to indicate that enumeration has started
        state->state = 1;
    }
    
    // if it's NULL then we're done enumerating, return 0 to end
    if( 0 == state->extra[0] )
        return 0;
    
    // otherwise, point itemsPtr at the node's value
    xmlNode *currentNode = state->extra[0];

    [nodeWrapper release];
    nodeWrapper = [[METXmlNode nodeWithNode:currentNode] retain];
    state->itemsPtr = &nodeWrapper;
    
    currentNode = currentNode->next;
    while( currentNode
          && ((XML_ELEMENT_NODE != currentNode->type)
              || (xmlStrcmp(currentNode->name,(xmlChar*)"row") != 0)) )
        currentNode = currentNode->next;
    
    state->extra[0] = currentNode;
    
    // we're returning exactly one item
    return 1;
}

- (NSError *)errorWithCode:(NSInteger)code andMessage:(NSString *)msg
{
    return [NSError errorWithDomain:@"METRowsetEnumerator" code:code userInfo:[NSDictionary dictionaryWithObjectsAndKeys:NSLocalizedString(msg,@"Rowset Messages"), NSLocalizedDescriptionKey, nil]];
}

- (void)reportWithError:(NSError *)error
{
    if( [[self delegate] respondsToSelector:@selector(apiDidFinishLoading:withError:)] )
    {
        [[self delegate] performSelector:@selector(apiDidFinishLoading:withError:) withObject:self withObject:error];
    }
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection withError:(NSError *)error
{
    if( error )
    {
        [self reportWithError:error];
    }

    METURLRequest *request = (METURLRequest *)[connection originalRequest];
    xmlData = [[request data] copy];
    const char *ptr = [xmlData bytes];
    NSInteger length = [xmlData length];
    
    if( 0 == length )
    {
        [self reportWithError:[self errorWithCode:-100 andMessage:@"Empty string returned by API call"]];
        return;
    }
    
    xmlDoc *doc = xmlReadMemory(ptr, (int)length, NULL, NULL, 0);
    if( doc == NULL )
    {
        [self reportWithError:[self errorWithCode:-101 andMessage:@"Invalid XML document in API call"]];
        return;
    }

    xmlDocument = doc;

    xmlNode *root_node = xmlDocGetRootElement(doc);
    if( NULL == root_node )
    {
        [self reportWithError:[self errorWithCode:-102 andMessage:@"Missing root node in API call"]];
        return;
    }
    
    NSString *errorMessage = nil;
    xmlNode *xmlErrorNode = findChildNode(root_node,(xmlChar*)"error");
    if( NULL != xmlErrorNode )
    {
        errorMessage = getNodeText(xmlErrorNode);
        if( errorMessage )
        {
//            NSString *errorNum = findAttribute(xmlErrorNode,(xmlChar*)"code");

            [self reportWithError:[self errorWithCode:-103 andMessage:errorMessage]];
            return;
        }
    }

    xmlNode *result = findChildNode(root_node,(xmlChar*)"result");
    if( NULL == result )
    {
        [self reportWithError:[self errorWithCode:-104 andMessage:@"Could not get result tag in API xml"]];
        return;
    }
    
    rowsetNode = findChildNode(result,(xmlChar*)"rowset");
    if( NULL == rowsetNode )
    {
        [self reportWithError:[self errorWithCode:-105 andMessage:@"Could not get rowset tag in API xml"]];
        return;
    }
    
    xmlNode *cached = findChildNode( root_node, (xmlChar *)"cachedUntil" );
    if( NULL != cached )
    {
        NSString *dtString = getNodeText( cached );
        NSDate *cacheDate = [NSDate dateWithNaturalLanguageString:dtString];
        [[self character] setCachedUntil:cacheDate forAPI:apiPath];
    }

    /* TODO:
     At this point we could loop through all of the rowset nodes and build an array of METXmlNode's, then use that array for the fast enumeration.
     */
    
    [self reportWithError:nil];
}

@end
