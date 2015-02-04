//
//  VitalityMail.m
//  VitalityMail
//
//  Created by Andrew Salamon on 10/8/14.
//  Copyright (c) 2014 Sebastian Kruemling. All rights reserved.
//

#import "VitalityMail.h"
#import "CharacterDatabase.h"
#import "Character.h"
#import <sqlite3.h>

#import "METMail.h"
#import "METMailMessage.h"
#import "METPair.h"

@implementation VitalityMail

-(id) init
{
    if( (self = [super initWithNibName:@"MailView" bundle:nil]) )
    {
        mail = [[METMail alloc] init];
        [mail setDelegate:self];
        namesByID = [[NSMutableDictionary alloc] init];
        [namesByID setObject:@"Inbox" forKey:[NSNumber numberWithInt:0]];
        nameGetter = [[METIDtoName alloc] init];
        [nameGetter setDelegate:self];
        
        mailboxPairs = [[NSMutableArray alloc] init];
    }
    
    return self;
}

-(BOOL) createMailTables
{
    if( character )
    {
        int rc;
        char *errmsg;
        CharacterDatabase *charDB = [character database];
        sqlite3 *db = [charDB openDatabase];
        
        if( [charDB doesTableExist:@"mail"] )
            return YES;
        
        // TODO: also make sure it's the right version
        
        [charDB beginTransaction];
        
        const char createMailTable[] = "CREATE TABLE mail ("
        "messageID INTEGER PRIMARY KEY, "
        "senderID INTEGER, "
        "senderName VARCHAR(255), "
        "sentDate DATETIME, "
        "subject VARCHAR(255), "
        "body TEXT, "
        "toCorpOrAllianceID INTEGER, "
        "senderTypeID INTEGER, "
        "toCharacterIDs TEXT, "
        "toListID INTEGER "
        ");";
        
        /*
         NSUInteger messageID;
         NSUInteger senderID;
         NSString *senderName;
         NSDate *sentDate;
         NSString *subject;
         NSString *body;
         NSUInteger toCorpOrAllianceID;
         NSUInteger senderTypeID;
         NSArray *toCharacterIDs;
         NSUInteger toListID;
         */
        
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

- (void)dealloc
{
    [character release];
    [mail release];
    [nameGetter release];
    [namesByID release];
    [mailboxPairs release];
    [super dealloc];
}

- (void)setCharacter:(Character *)_character
{
    if( _character != character )
    {
        [character release];
        character = [_character retain];
        [self createMailTables];
        [mail setCharacter:character];
        [mail reload:self];
        [self getAllMailboxNames];
        [app setToolbarMessage:NSLocalizedString(@"Getting Mail…",@"Getting Mail status line")];
        [app startLoadingAnimation];
        [self reload];
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
    [app setToolbarMessage:NSLocalizedString(@"Getting Mail…",@"Getting Mail status line")];
    [app startLoadingAnimation];
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
        [namesByID addEntriesFromDictionary:names];
        
        NSMutableArray *newPairs = [NSMutableArray array];
        for( METPair *aPair in mailboxPairs )
        {
            if( [[aPair second] length] > 0 )
            {
                [newPairs addObject:aPair];
            }
            else
            {
                NSString *name = [namesByID objectForKey:[aPair first]];
                if( [name length] > 0 )
                {
                    METPair *newPair = [METPair pairWithFirst:[aPair first] second:name];
                    [newPairs addObject:newPair];
                }
                else
                {
                    [newPairs addObject:aPair];
                }
            }
        }
        [mailboxPairs autorelease];
        mailboxPairs = [newPairs retain];
    }
}

- (void)reload
{
    [mailboxView reloadData];
}

- (void)mailFinishedUpdating
{
//    NSArray *newDescriptors = [contractsTable sortDescriptors];
//    [contracts sortUsingDescriptors:newDescriptors];
//    [contractsTable reloadData];
    [self saveMailMessages:[mail messages]];
    [app setToolbarMessage:NSLocalizedString(@"Finished Updating Mail Headers…",@"Finished Updating Mail status line") time:5];
    [app stopLoadingAnimation];
    [self reload];
}

- (void)mailSkippedUpdating
{
    [app setToolbarMessage:NSLocalizedString(@"Using Cached Mail…",@"Using Cached Mail status line") time:5];
    [app stopLoadingAnimation];
    [self reload];
}

- (void)mailBodiesFinishedUpdating
{
    // update all messages in the database, saving any mail bodies we just downloaded
    [self saveMailBodies:[mail messages]];
    [self reload];
}

/*
 "messageID INTEGER PRIMARY KEY, "
 "senderID INTEGER, "
 "senderName VARCHAR(255), "
 "sentDate DATETIME, "
 "subject VARCHAR(255), "
 "body TEXT, "
 "toCorpOrAllianceID INTEGER, "
 "senderTypeID INTEGER, "
 "toCharacterIDs TEXT, "
 "toListID INTEGER "
*/
- (BOOL)saveMailMessages:(NSArray *)messages
{
    CharacterDatabase *charDB = [character database];
    sqlite3 *db = [charDB openDatabase];
    const char insert_mail[] = "INSERT INTO mail VALUES (?,?,?,?,?,?,?,?,?,?);";
    sqlite3_stmt *insert_mail_stmt;
    BOOL success = YES;
    int rc;
    
    rc = sqlite3_prepare_v2(db,insert_mail,(int)sizeof(insert_mail),&insert_mail_stmt,NULL);
    if( rc != SQLITE_OK )
    {
        NSLog( @"%s: sqlite error: %s", __func__, sqlite3_errmsg(db) );
        return NO;
    }
    
    for( METMailMessage *message in messages )
    {
        sqlite3_bind_nsint( insert_mail_stmt, 1, [message messageID] );
        sqlite3_bind_nsint( insert_mail_stmt, 2, [message senderID] );
        sqlite3_bind_text( insert_mail_stmt, 3, [[message senderName] UTF8String], -1, NULL );
        sqlite3_bind_nsint( insert_mail_stmt, 4, [message sentDate] );
        sqlite3_bind_text( insert_mail_stmt, 5, [[message subject] UTF8String], -1, NULL );
        sqlite3_bind_text( insert_mail_stmt, 6, [[message body] UTF8String], -1, NULL );
        sqlite3_bind_nsint( insert_mail_stmt, 7, [message toCorpOrAllianceID] );
        sqlite3_bind_nsint( insert_mail_stmt, 8, [message senderTypeID] );
        NSString *toIDS = [[message toCharacterIDs] componentsJoinedByString:@","];
        sqlite3_bind_text( insert_mail_stmt, 9, [toIDS UTF8String], -1, NULL );
        sqlite3_bind_nsint( insert_mail_stmt, 10, [message toListID] );
        
        rc = sqlite3_step(insert_mail_stmt);
        if( (rc != SQLITE_DONE) && (rc != SQLITE_CONSTRAINT) )
        {
            // constraint violation probably means that this message ID is already in the database
            NSLog(@"Error inserting mail message ID: %ld (code: %d)", (unsigned long)[message messageID], rc );
            success = NO;
        }
        sqlite3_reset(insert_mail_stmt);
    }
    
    sqlite3_finalize(insert_mail_stmt);
    return success;
}

/* Because message bodies can only be downloaded shortly after the matching message header has
 been downloaded, this probably won't be of any use.
 */
- (NSArray *)messagesWithEmptyBody
{
    CharacterDatabase *charDB = [character database];
    sqlite3 *db = [charDB openDatabase];
    const char query[] = "SELECT messageID FROM mail WHERE body IS NULL OR body = '' ORDER BY sentDate;";
    sqlite3_stmt *read_stmt;
    int rc;
    
    rc = sqlite3_prepare_v2(db,query,(int)sizeof(query),&read_stmt,NULL);
    if(rc != SQLITE_OK){
        NSLog( @"%s: sqlite error: %s", __func__, sqlite3_errmsg(db) );
        return nil;
    }
    
    NSMutableArray *emptyMessages = [NSMutableArray array];
    
    if(sqlite3_step(read_stmt) == SQLITE_ROW){
        NSInteger mID = sqlite3_column_nsint(read_stmt,0);
        [emptyMessages addObject:[NSNumber numberWithInteger:mID]];
    }
    
    sqlite3_finalize(read_stmt);
    
    return emptyMessages;

}

- (BOOL)saveMailBodies:(NSArray *)messages
{
    CharacterDatabase *charDB = [character database];
    sqlite3 *db = [charDB openDatabase];
    const char insert_mail[] = "UPDATE mail SET body = ? WHERE messageID = ?;";
    sqlite3_stmt *insert_mail_stmt;
    BOOL success = YES;
    int rc;
    
    rc = sqlite3_prepare_v2(db,insert_mail,(int)sizeof(insert_mail),&insert_mail_stmt,NULL);
    if( rc != SQLITE_OK )
    {
        NSLog( @"%s: sqlite error: %s", __func__, sqlite3_errmsg(db) );
        return NO;
    }
    
    for( METMailMessage *message in messages )
    {
        // skip any message that already has a body in the database?
        
        sqlite3_bind_text( insert_mail_stmt, 1, [[message body] UTF8String], -1, NULL );
        sqlite3_bind_nsint( insert_mail_stmt, 2, [message messageID] );
        
        rc = sqlite3_step(insert_mail_stmt);
        if( rc != SQLITE_DONE )
        {
            NSLog(@"Error updating mail body: %ld (code: %d)", (unsigned long)[message messageID], rc );
            success = NO;
        }
        sqlite3_reset(insert_mail_stmt);
    }
    
    sqlite3_finalize(insert_mail_stmt);
    return success;
}

- (void)getAllMailboxNames
{
    sqlite3_stmt *read_stmt;
    int rc;
    const char getCorpOrAlliance[] = "SELECT DISTINCT toCorpOrAllianceID FROM mail;";
    sqlite3 *db = [[character database] openDatabase];
    
    rc = sqlite3_prepare_v2(db,getCorpOrAlliance,(int)sizeof(getCorpOrAlliance),&read_stmt,NULL);
    if(rc != SQLITE_OK){
        NSLog( @"%s: sqlite error: %s", __func__, sqlite3_errmsg(db) );
        return;
    }
    
    [mailboxPairs removeAllObjects];
    NSMutableSet *missingNames = [NSMutableSet set];
    
    while( sqlite3_step(read_stmt) == SQLITE_ROW )
    {
        NSNumber *toID = [NSNumber numberWithInteger:sqlite3_column_nsint(read_stmt,0)];
        NSString *name = [namesByID objectForKey:toID];
        if( 0 == [name length] )
        {
            [missingNames addObject:toID];
        }
        METPair *pair = [METPair pairWithFirst:toID second:name];
        [mailboxPairs addObject:pair];
    }
    
    if( [missingNames count] > 0 )
        [nameGetter namesForIDs:missingNames];
    
    sqlite3_finalize(read_stmt);
}

- (NSInteger)outlineView:(NSOutlineView *)outlineView numberOfChildrenOfItem:(id)item
{
    if( !item )
    {
        // how many 'mailboxes' are there?
        return [mailboxPairs count];
    }
    return 0;
}

- (id)outlineView:(NSOutlineView *)outlineView child:(NSInteger)index ofItem:(id)item
{
    if( !item )
    {
        METPair *pair = [mailboxPairs objectAtIndex:index];
        return pair;
    }
    return nil;
}

- (BOOL)outlineView:(NSOutlineView *)outlineView isItemExpandable:(id)item
{
    if( [item isKindOfClass:[METPair class]] )
        return YES;
    return NO;
}

- (id)outlineView:(NSOutlineView *)outlineView objectValueForTableColumn:(NSTableColumn *)tableColumn byItem:(id)item
{
    //NSLog(@"%@",[tableColumn identifier] );
    
    if( [item isKindOfClass:[METPair class]] )
    {
        METPair *pair = (METPair *)item;
        return [pair second];
    }
    //NSLog(@"id: %@ class %@",[tableColumn identifier],[item class]);
    return nil;
}

@end
