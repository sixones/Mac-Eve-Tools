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
#import "Helpers.h"
#import "Config.h"
#import "GlobalData.h"
#import "CCPDatabase.h"
#import "MTNotification.h"

#import "METRowsetEnumerator.h"
#import "METXmlNode.h"

#import <sqlite3.h>

@interface MTNotifications()
@property (readwrite,retain) NSArray *notifications;
@end

@implementation MTNotifications

@synthesize notifications;

+ (NSString *)newNotificationName
{
    return @"MTNewNotificationName";
}

-(id) init
{
    if( (self = [super initWithNibName:@"MTNotificationTicker" bundle:nil]) )
    {
        nameGetter = [[METIDtoName alloc] initWithDelegate:self];
        notifications = [[NSMutableArray alloc] init];
        nextNotification = 0;
        tickerTimer = [[NSTimer scheduledTimerWithTimeInterval:5.0 target:self selector:@selector(tickerTimerFired:) userInfo:nil repeats:YES] retain];
        apiGetter = [[METRowsetEnumerator alloc] initWithCharacter:nil API:XMLAPI_CHAR_NOTIFICATIONS forDelegate:self];
    }
    
    return self;
}

- (void)dealloc
{
    [nameGetter release];
    [notifications release];
    [tickerTimer invalidate];
    [tickerTimer release];
    [apiGetter release];
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
        [apiGetter setCharacter:_character];
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
    
    [apiGetter run];
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
- (void)apiDidFinishLoading:(METRowsetEnumerator *)rowset withError:(NSError *)error
{
    if( error )
    {
        if( [error code] == -107 )
            NSLog( @"Skipping EVE Notifications because of Cached Until date." ); // handle cachedUntil errors differently
        else
            NSLog( @"Error requesting EVE Notifications: %@", [error localizedDescription] );
        [app stopLoadingAnimation];
        [app setToolbarMessage:NSLocalizedString(@"Failed to download Notifications…",@"Failed to download notifications status line")];
        return;
    }
    
    NSMutableArray *newNotes = [NSMutableArray array];
    NSMutableSet *missingNames = [NSMutableSet set];

    for( METXmlNode *row in rowset )
    {
        //  <row notificationID="304084087" typeID="16" senderID="797400947" sentDate="2010-04-12 12:32:00" read="0"/>
        NSDictionary *properties = [row properties];
        NSInteger notificationID = [[properties objectForKey:@"notificationID"] integerValue];

        if( 0 != notificationID )
        {
            NSInteger typeID = [[properties objectForKey:@"typeID"] integerValue];
            NSInteger senderID = [[properties objectForKey:@"senderID"] integerValue];
            NSDate *sentDate = [NSDate dateWithNaturalLanguageString:[properties objectForKey:@"sentDate"]];
            BOOL read = (0 == [[properties objectForKey:@"read"] integerValue]);

            MTNotification *notification = [MTNotification notificationWithID:notificationID typeID:typeID sender:senderID sentDate:sentDate read:read];
            [newNotes addObject:notification];
            [missingNames addObject:[NSNumber numberWithInteger:senderID]];
        }
    }
    
    if( [missingNames count] > 0 )
        [nameGetter namesForIDs:missingNames];
    
    [self insertNotifications:newNotes];
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
            NSLog( @"New Notification: %@ %@ %@", [notification notificationTypeDescription], [notification sentDate], ([notification read]?@"Read":@"Unread") );
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
