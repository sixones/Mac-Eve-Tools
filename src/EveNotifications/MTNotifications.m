//
//  MTNotifications.m
//  Vitality
//
//  Created by Andrew Salamon on 10/8/15.
//  Copyright (c) 2015 Sebastian Kruemling. All rights reserved.
//

#import "MTNotifications.h"
#import "CharacterDatabase.h"
#import "Character.h"
#import "CharacterTemplate.h"
#import "Helpers.h"
#import "Config.h"
#import "GlobalData.h"
#import "XmlHelpers.h"
#import "CCPDatabase.h"
#import "METURLRequest.h"
#import "MTNotification.h"

#include <assert.h>
#include <libxml/tree.h>
#include <libxml/parser.h>
#import <sqlite3.h>

@interface MTNotifications()
@property (readwrite,retain) NSDate *cachedUntil;
@property (readwrite,retain) NSArray *notifications;
@end

@implementation MTNotifications

@synthesize cachedUntil;
@synthesize notifications;

+ (NSString *)newNotificationName
{
    return @"MTNewNotificationName";
}

-(id) init
{
    if( (self = [super initWithNibName:@"MTNotificationTicker" bundle:nil]) )
    {
        xmlData = [[NSMutableData alloc] init];
        nameGetter = [[METIDtoName alloc] init];
        [nameGetter setDelegate:self];        
        cachedUntil = [[NSDate distantPast] retain];
        notifications = [[NSMutableArray alloc] init];
        nextNotification = 0;
        tickerTimer = [[NSTimer scheduledTimerWithTimeInterval:5.0 target:self selector:@selector(tickerTimerFired:) userInfo:nil repeats:YES] retain];
    }
    
    return self;
}

- (void)dealloc
{
    [xmlData release];
    [nameGetter release];
    [cachedUntil release];
    [notifications release];
    [tickerTimer invalidate];
    [tickerTimer release];
    [super dealloc];
}

-(BOOL) createNotificationTables
{
    if( character )
    {
        int rc;
        char *errmsg;
        CharacterDatabase *charDB = [character database];
        sqlite3 *db = [charDB openDatabase];
        
        if( [charDB doesTableExist:@"notifications"] )
            return YES;
        
        // TODO: also make sure it's the right version
        
        [charDB beginTransaction];
        
        const char createMailTable[] = "CREATE TABLE notifications ("
        "notificationID INTEGER PRIMARY KEY, "
        "typeID INTEGER, "
        "senderID INTEGER, "
        "sentDate DATETIME, "
        "read BOOLEAN DEFAULT 0"
        ");";
        
        rc = sqlite3_exec(db,createMailTable,NULL,NULL,&errmsg);
        if(rc != SQLITE_OK){
            [charDB logError:errmsg];
            [charDB rollbackTransaction];
            return NO;
        }
        
        [charDB commitTransaction];
    }
    
    return YES;
}

- (Character *)character
{
    return [[character retain] autorelease];
}

- (void)setCharacter:(Character *)_character
{
    if( _character != character )
    {
        [character release];
        character = [_character retain];
        [self createNotificationTables];
        [app setToolbarMessage:NSLocalizedString(@"Getting Notifications…",@"Getting Notifications status line")];
        [app startLoadingAnimation];
        [tickerField setStringValue:@""];
        [self reload:self];
    }
}


//called after the window has become active
-(void) viewIsActive
{
    
}

-(void) viewIsInactive
{
    
}

-(void) viewWillBeDeactivated
{
    
}

-(void) viewWillBeActivated
{
    [app setToolbarMessage:NSLocalizedString(@"Getting Notifications…",@"Getting Notifications status line")];
    [app startLoadingAnimation];
    [self reload:self];
}

-(void) setInstance:(id<METInstance>)instance
{
    if( instance != app )
    {
        [app release];
        app = [instance retain];
    }
}

-(NSMenuItem*) menuItems
{
    return nil;
}

- (void)namesFromIDs:(NSDictionary *)names
{
    if( [names count] > 0 )
    {
//        [self reload:self];
    }
}

- (IBAction)reload:(id)sender
{
    [notifications removeAllObjects];
    [notifications addObjectsFromArray:[self loadNotifications]];
 
    nextNotification = 0;
    
    [self getNotifications];
}

- (void)tickerTimerFired:(NSTimer *)timer
{
    MTNotification *notification = nil;
    if( [[self notifications] count] > 0 )
    {
        notification = [[self notifications] objectAtIndex:nextNotification++];
        if( nextNotification >= [[self notifications] count] )
            nextNotification = 0;
    }
    [tickerField setStringValue:(notification)?[notification tickerDescription]:@""];
}

- (void)getNotifications
{
    if( [[self cachedUntil] isGreaterThan:[NSDate date]] )
    {
        NSLog( @"Skipping download of Notifications because of Cached Until date" );
        return;
    }
    
    CharacterTemplate *template = [[self character] template];
    NSString *urlPath = [Config getApiUrl:XMLAPI_CHAR_NOTIFICATIONS
                                   keyID:[template accountId]
                        verificationCode:[template verificationCode]
                                  charId:[template characterId]];
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
    
    [app setToolbarMessage:@""];
    [app stopLoadingAnimation];
    
    if(length == 0){
        NSLog(@"Zero bytes returned for Notifications data");
        return;
    }
    
    xmlDoc *doc = xmlReadMemory(ptr, (int)length, NULL, NULL, 0);
    if( doc == NULL )
    {
        NSLog(@"Failed to read Notifications data");
        return;
    }
    [self parseXmlNotifications:doc];
    xmlFreeDoc(doc);
    [xmlData setLength:0];
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
    NSLog(@"Failed to read Notifications data");
    [xmlData setLength:0];
    [app stopLoadingAnimation];
    [app setToolbarMessage:NSLocalizedString(@"Failed to download Notifications…",@"Failed to download notifications status line")];
}

/* http://wiki.eve-id.net/APIv2_Char_Notifications_XML
 <eveapi version="2">
 <currentTime>2010-04-16 20:16:57</currentTime>
 <result>
 <rowset name="notifications" key="notificationID" columns="notificationID,typeID,senderID,sentDate,read">
 <row notificationID="304084087" typeID="16" senderID="797400947" sentDate="2010-04-12 12:32:00" read="0"/>
 <row notificationID="303795523" typeID="16" senderID="671216635" sentDate="2010-04-09 18:04:00" read="1"/>
 </rowset>
 </result>
 <cachedUntil>2010-04-16 20:46:57</cachedUntil>
 </eveapi>
 */
-(BOOL) parseXmlNotifications:(xmlDoc *)doc
{
    xmlNode *root_node = xmlDocGetRootElement(doc);
    
    xmlNode *result = findChildNode(root_node,(xmlChar*)"result");
    if( NULL == result )
    {
        NSLog(@"Could not get result tag in parseXmlNotifications");
        
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
        NSLog(@"Could not get rowset tag in parseXmlNotifications");
        
        xmlNode *xmlErrorMessage = findChildNode(root_node,(xmlChar*)"error");
        if( NULL != xmlErrorMessage )
        {
            NSLog( @"%@", getNodeText(xmlErrorMessage) );
        }
        return NO;
    }
    
    NSMutableArray *newNotes = [NSMutableArray array];
    NSMutableSet *missingNames = [NSMutableSet set];

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
            NSInteger notificationID = 0;
            NSInteger typeID = 0;
            NSInteger senderID = 0;
            NSDate *sentDate = nil;
            BOOL read = NO;
            //  <row notificationID="304084087" typeID="16" senderID="797400947" sentDate="2010-04-12 12:32:00" read="0"/>
            for( xmlAttr *attr = cur_node->properties; attr; attr = attr->next )
            {
                NSString *value = [NSString stringWithUTF8String:(const char*) attr->children->content];
                if( xmlStrcmp(attr->name, (xmlChar *)"notificationID") == 0 )
                {
                    notificationID = [value integerValue];
                }
                else if( xmlStrcmp(attr->name, (xmlChar *)"typeID") == 0 )
                {
                    typeID = [value integerValue];
                }
                else if( xmlStrcmp(attr->name, (xmlChar *)"senderID") == 0 )
                {
                    senderID = [value integerValue];
                }
                else if( xmlStrcmp(attr->name, (xmlChar *)"sentDate") == 0 )
                {
                    sentDate = [NSDate dateWithNaturalLanguageString:value];
                }
                else if( xmlStrcmp(attr->name, (xmlChar *)"read") == 0 )
                {
                    read = (0 == [value integerValue])?NO:YES;
                }
            }
            if( 0 != notificationID )
            {
                MTNotification *notification = [MTNotification notificationWithID:notificationID typeID:typeID sender:senderID sentDate:sentDate read:read];
                [newNotes addObject:notification];
                [missingNames addObject:[NSNumber numberWithInteger:senderID]];
                NSLog( @"Notification: %@ %@ %@", [notification notificationTypeDescription], sentDate, (read?@"Read":@"Unread") );
            }
        }
    }
    
    xmlNode *cached = findChildNode( root_node, (xmlChar *)"cachedUntil" );
    if( NULL != cached )
    {
        NSString *dtString = getNodeText( cached );
        NSDate *cacheDate = [NSDate dateWithNaturalLanguageString:dtString];
        [self setCachedUntil:cacheDate];
    }
    
    if( [missingNames count] > 0 )
        [nameGetter namesForIDs:missingNames];
    
    [self insertNotifications:newNotes];
    
    return YES;
}

- (BOOL)insertNotifications:(NSMutableArray *)newNotes
{
    CharacterDatabase *charDB = [character database];
    sqlite3 *db = [charDB openDatabase];
    const char insert_note[] = "INSERT INTO notifications VALUES (?,?,?,?,?);";
    sqlite3_stmt *insert_note_stmt;
    BOOL success = YES;
    BOOL anyNew = NO;
    int rc;
    
    rc = sqlite3_prepare_v2(db,insert_note,(int)sizeof(insert_note),&insert_note_stmt,NULL);
    if( rc != SQLITE_OK )
    {
        NSLog( @"%s: sqlite error: %s", __func__, sqlite3_errmsg(db) );
        return NO;
    }

    for( MTNotification *notification in newNotes )
    {
        sqlite3_bind_nsint( insert_note_stmt, 1, [notification notificationID] );
        sqlite3_bind_nsint( insert_note_stmt, 2, [notification typeID] );
        sqlite3_bind_nsint( insert_note_stmt, 3, [notification senderID] );
        sqlite3_bind_nsint( insert_note_stmt, 4, [[notification sentDate] timeIntervalSince1970] ); // truncating fractions of a second
        sqlite3_bind_nsint( insert_note_stmt, 3, [notification read] );
        
        rc = sqlite3_step(insert_note_stmt);
        if( SQLITE_DONE == rc )
        {
            // This should mean that this noticiation was not already in the database
            [notifications addObject:notification];
            anyNew = YES;
            [NSUserNotificationCenter defaultUserNotificationCenter];
        }
        else if( (rc != SQLITE_DONE) && (rc != SQLITE_CONSTRAINT) )
        {
            // constraint violation probably means that this notification ID is already in the database
            NSLog(@"Error inserting notification with ID: %ld (code: %d)", (unsigned long)[notification notificationID], rc );
            success = NO;
        }
        sqlite3_reset(insert_note_stmt);
    }
    
    sqlite3_finalize(insert_note_stmt);
    
    if( anyNew )
    {
        // send out a cocoa notification so any UI elements can update
        [[NSNotificationCenter defaultCenter] postNotificationName:[[self class] newNotificationName] object:self];
    }
    return success;
}

- (NSArray *)loadNotifications
{
    sqlite3_stmt *read_stmt;
    int rc;
    const char getMessages[] = "SELECT * FROM notifications ORDER BY sentDate DESC;"; // newest notifications first
    sqlite3 *db = [[character database] openDatabase];
    
    rc = sqlite3_prepare_v2(db,getMessages,(int)sizeof(getMessages),&read_stmt,NULL);
    if(rc != SQLITE_OK){
        NSLog( @"%s: sqlite error: %s", __func__, sqlite3_errmsg(db) );
        return nil;
    }
    
    NSMutableArray *messages = [NSMutableArray array];
    NSMutableSet *missingNames = [NSMutableSet set];
    
    while( sqlite3_step(read_stmt) == SQLITE_ROW )
    {
        NSInteger notificationID = sqlite3_column_nsint(read_stmt,0);
        NSInteger typeID = sqlite3_column_nsint(read_stmt,1);
        NSInteger senderID = sqlite3_column_nsint(read_stmt,2);
        NSDate *sentDate = [NSDate dateWithTimeIntervalSince1970:sqlite3_column_nsint(read_stmt,3)];
        BOOL read = sqlite3_column_nsint(read_stmt,2);;

        MTNotification *notification = [MTNotification notificationWithID:notificationID typeID:typeID sender:senderID sentDate:sentDate read:read];

        [messages addObject:notification];
        [missingNames addObject:[NSNumber numberWithInteger:senderID]];
    }
    
    if( [missingNames count] > 0 )
        [nameGetter namesForIDs:missingNames];
    
    sqlite3_finalize(read_stmt);
    
    return messages;
}
@end
