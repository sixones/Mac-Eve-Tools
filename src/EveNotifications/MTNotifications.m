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
#import "MTNotificationCellView.h"

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
        apiGetter = [[METRowsetEnumerator alloc] initWithCharacter:nil API:@"/char/Notifications.xml.aspx" forDelegate:self];
        bodyGetter = [[METRowsetEnumerator alloc] initWithCharacter:nil API:@"/char/NotificationTexts.xml.aspx" forDelegate:self];
        // TODO: Get rid of this if/when the NotificationText API starts returning reasonable values in the cachedUntil field
        [bodyGetter setCheckCachedDate:NO];
        [[NSBundle mainBundle] loadNibNamed:@"MTNotificationsWindow" owner:self topLevelObjects:nil];
        [notificationsWindow retain];

        textStorage = [[NSTextStorage alloc] initWithString:@""];
        textContainer = [[NSTextContainer alloc] initWithContainerSize:NSMakeSize([notificationsTable frame].size.width, FLT_MAX)];
        layoutManager = [[NSLayoutManager alloc] init];
        [layoutManager addTextContainer:textContainer];
        [textStorage addLayoutManager:layoutManager];
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
    [bodyGetter release];
    [notificationsWindow release];
    [textStorage release];
    [textContainer release];
    [layoutManager release];
    [super dealloc];
}

- (void)awakeFromNib
{
    
}

-(BOOL) createNotificationTables
{
    if( character )
    {
        int rc;
        char *errmsg = nil;
        CharacterDatabase *charDB = [character database];
        sqlite3 *db = [charDB openDatabase];
        
        if( [charDB doesTableExist:@"notifications"] )
        {
            if( [charDB doesTable:@"notifications" haveColumn:@"body"] )
                return YES;
            
            // older version, needs to be updated
            // First we have to fix bad data caused by a bug in earlier code
            // The read/unread data was being stored in the senderID column (that data is lost)
            int rc = sqlite3_exec( db, "UPDATE notifications SET read = senderID;", NULL, NULL, &errmsg );
            if(rc != SQLITE_OK)
            {
                [charDB logError:errmsg];
                return NO;
            }

            rc = sqlite3_exec( db, "UPDATE notifications SET senderID = 0;", NULL, NULL, &errmsg );
            if(rc != SQLITE_OK)
            {
                [charDB logError:errmsg];
                return NO;
            }

            rc = sqlite3_exec( db, "ALTER TABLE notifications ADD COLUMN body TEXT;", NULL, NULL, &errmsg );
            if(rc != SQLITE_OK)
            {
                [charDB logError:errmsg];
                return NO;
            }
            return YES;
        }
        
        [charDB beginTransaction];
        
        const char createMailTable[] = "CREATE TABLE notifications ("
        "notificationID INTEGER PRIMARY KEY, "
        "typeID INTEGER, "
        "senderID INTEGER, "
        "sentDate DATETIME, "
        "read BOOLEAN DEFAULT 0,"
        "body TEXT "
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
        [bodyGetter setCharacter:_character];
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
    
    [notificationsTable reloadData];
}

- (IBAction)openNotificationsWindow:(id)sender
{
    [notificationsTable reloadData];
    [notificationsWindow makeKeyAndOrderFront:self];
    //[self activeWars];
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

- (void)activeWars
{
    // select * from notifications WHERE typeID in (5,6,7,8,27,28,29,30,31) order by sentDate;
    NSIndexSet *warIndexes = [notifications indexesOfObjectsPassingTest:^BOOL (id el, NSUInteger i, BOOL *stop)
                              {
                                  return [(MTNotification *)el isWarRelated];
                              }];
    NSArray *warNotes = [notifications objectsAtIndexes:warIndexes];
    NSLog( @"Wars: %@", warNotes );
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
        {
            NSLog( @"Skipping EVE Notifications because of Cached Until date." ); // handle cachedUntil errors differently
            if( rowset == apiGetter )
                [self getMissingNotificationBodies]; // even if the main api cached out, try getting any empty notification bodies
        }
        else
            NSLog( @"Error requesting EVE Notifications: %@", [error localizedDescription] );
        [app stopLoadingAnimation];
        [app setToolbarMessage:NSLocalizedString(@"Failed to download Notifications…",@"Failed to download notifications status line")];
        return;
    }
    
    if( rowset == apiGetter )
    {
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
        [self getMissingNotificationBodies];
    }
    else if( rowset == bodyGetter )
    {
        //[[bodyGetter xmlData] writeToFile:@"/tmp/notifications.xml" atomically:NO];
        NSMutableArray *newBodies = [NSMutableArray array];
        for( METXmlNode *row in rowset )
        {
            // <row notificationID="545014865"><![CDATA[bounty: 1000000.0 bountyPlacerID: 96143456]]></row>
            // Possible error condition?: <missingIDs>544904842,544904635</missingIDs>
            // Add code to METXmlNode to get the name of the node
            NSDictionary *properties = [row properties];
            NSInteger notificationID = [[properties objectForKey:@"notificationID"] integerValue];
            
            if( 0 != notificationID )
            {
                // get the text of the body, update the MTNotification object in memory and update the row in the database
                NSString *body = [row content];
                if( [body length] > 0 )
                {
                    MTNotification *notification = [self notificationWithID:notificationID];
                    if( notification )
                    {
                        [notification setBody:body];
                        [newBodies addObject:notification];
                    }
                }
            }
        }
        if( [newBodies count] > 0 )
            [self saveNotificationBodies:newBodies];
    }
}


- (BOOL)insertNotifications:(NSMutableArray *)newNotes
{
    CharacterDatabase *charDB = [character database];
    sqlite3 *db = [charDB openDatabase];
    const char insert_note[] = "INSERT INTO notifications VALUES (?,?,?,?,?,?);";
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
        sqlite3_bind_nsint( insert_note_stmt, 5, [notification read] );
        sqlite3_bind_text( insert_note_stmt, 6, [[notification body] UTF8String], -1, NULL );

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
        [notificationsTable reloadData];
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
        BOOL read = sqlite3_column_nsint(read_stmt,4);;
        NSString *body = sqlite3_column_nsstr( read_stmt, 5 );

        MTNotification *notification = [MTNotification notificationWithID:notificationID typeID:typeID sender:senderID sentDate:sentDate read:read];
        [notification setBody:body];
        
        [messages addObject:notification];
        [missingNames addObject:[NSNumber numberWithInteger:senderID]];
        [missingNames addObjectsFromArray:[notification missingIDs]];
    }
    
    if( [missingNames count] > 0 )
        [nameGetter namesForIDs:missingNames];
    
    sqlite3_finalize(read_stmt);
    
    return messages;
}

- (BOOL)saveNotificationBodies:(NSArray *)messages
{
    CharacterDatabase *charDB = [character database];
    sqlite3 *db = [charDB openDatabase];
    const char insert_mail[] = "UPDATE notifications SET body = ? WHERE notificationID = ?;";
    sqlite3_stmt *insert_mail_stmt;
    BOOL success = YES;
    int rc;
    
    rc = sqlite3_prepare_v2(db,insert_mail,(int)sizeof(insert_mail),&insert_mail_stmt,NULL);
    if( rc != SQLITE_OK )
    {
        NSLog( @"%s: sqlite error: %s", __func__, sqlite3_errmsg(db) );
        return NO;
    }
    
    for( MTNotification *message in messages )
    {
        if( [[message body] length] > 0 )
        {
            sqlite3_bind_text( insert_mail_stmt, 1, [[message body] UTF8String], -1, NULL );
            sqlite3_bind_nsint( insert_mail_stmt, 2, [message notificationID] );
            
            rc = sqlite3_step(insert_mail_stmt);
            if( rc != SQLITE_DONE )
            {
                NSLog(@"Error updating notification body: %ld (code: %d)", (unsigned long)[message notificationID], rc );
                success = NO;
            }
            sqlite3_reset(insert_mail_stmt);
        }
    }
    
    sqlite3_finalize(insert_mail_stmt);
    return success;
}

- (NSArray *)notificationsWithEmptyBody
{
    CharacterDatabase *charDB = [character database];
    sqlite3 *db = [charDB openDatabase];
    const char query[] = "SELECT notificationID FROM notifications WHERE body IS NULL OR body = '' ORDER BY sentDate DESC;";
    sqlite3_stmt *read_stmt;
    int rc;
    
    rc = sqlite3_prepare_v2(db,query,(int)sizeof(query),&read_stmt,NULL);
    if(rc != SQLITE_OK){
        NSLog( @"%s: sqlite error: %s", __func__, sqlite3_errmsg(db) );
        return nil;
    }
    
    NSMutableArray *emptyMessages = [NSMutableArray array];
    
    while( sqlite3_step(read_stmt) == SQLITE_ROW )
    {
        NSInteger mID = sqlite3_column_nsint(read_stmt,0);
        [emptyMessages addObject:[NSNumber numberWithInteger:mID]];
    }
    
    sqlite3_finalize(read_stmt);
    
    return emptyMessages;
}

- (void)getMissingNotificationBodies
{
    NSArray *emptyBodies = [self notificationsWithEmptyBody];
    
    if( [emptyBodies count] == 0 )
        return;
    
    // Limit it to 50? ids
    emptyBodies = [emptyBodies subarrayWithRange:NSMakeRange(0, MIN(50, [emptyBodies count]))];
    NSString *IDString = [NSString stringWithFormat:@"ids=%@", [emptyBodies componentsJoinedByString:@","]];
    [bodyGetter runWithURLExtras:IDString];
}

- (MTNotification *)notificationWithID:(NSInteger)notificationID
{
    NSUInteger index = [notifications indexOfObjectPassingTest:^BOOL (id el, NSUInteger i, BOOL *stop)
                        {
                            BOOL res = [(MTNotification *)el notificationID] == notificationID;
                            if( res )
                                *stop = YES;
                            return res;
                        }];
    if( NSNotFound == index )
        return nil;
    return [notifications objectAtIndex:index];
}

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView
{
    return [notifications count];
}

- (NSView *)tableView:(NSTableView *)tableView
   viewForTableColumn:(NSTableColumn *)tableColumn
                  row:(NSInteger)row
{
    
    // Get an existing cell with my identifier if it exists
    MTNotificationCellView *result = [tableView makeViewWithIdentifier:@"MTNotificationCellView" owner:self];
    
    // There is no existing cell to reuse so create a new one
    if( nil == result )
    {
        
        // Create the new view with a frame of the {0,0} with the width of the table.
        // Note that the height of the frame is not really relevant, because the row height will modify the height.
        result = [[MTNotificationCellView alloc] initWithFrame:NSMakeRect(0.0, 0.0, [notificationsTable frame].size.width, 20.0)];
        
        // The identifier of the view instance is set to my identifier.
        // This allows the cell to be reused.
        result.identifier = @"MTNotificationCellView";
    }
    
    [result setNotification:[[self notifications] objectAtIndex:row]];
    
    return result;
}

- (CGFloat)heightForString:(NSAttributedString *)myString atWidth:(float)myWidth
{
    [textStorage setAttributedString:myString];
    [textContainer setContainerSize:NSMakeSize(myWidth, FLT_MAX)];
    [layoutManager glyphRangeForTextContainer:textContainer];
    return [layoutManager usedRectForTextContainer:textContainer].size.height;
}

- (CGFloat)tableView:(NSTableView *)tableView heightOfRow:(NSInteger)row
{
    MTNotification *notification = [[self notifications] objectAtIndex:row];
    if( notification )
    {
//        NSAttributedString *attrStr = [notification attributedBody];
//        CGFloat width = 300; // whatever your desired width is
//        CGFloat height = [self heightForString:attrStr atWidth:width];
//        return height + 20;
        return ([notification rows] * 20) + 5;
    }
    return 50.0;
}

@end
