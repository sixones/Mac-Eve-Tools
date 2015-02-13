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
#import "Helpers.h"

#import "METMail.h"
#import "METMailMessage.h"
#import "METPair.h"
#import "METMailHeaderCell.h"
#import "METMessageViewController.h"

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
        currentMessages = [[NSMutableArray alloc] init];
        
        messageController = [[METMessageViewController alloc] initWithNibName:@"METMessageView" bundle:nil];
        
        minimumPaneWidths = [[NSArray alloc] initWithObjects: @200.0f, @300.0f, @340.0f, nil];
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
    [currentMessages release];
    [messageController release];
    [super dealloc];
}

- (void)awakeFromNib
{
    NSRect detailFrame = [placeHolder frame];
    [splitView setDelegate:self];
    [placeHolder removeFromSuperview];
    [splitView addSubview:[messageController view]];
    [[messageController view] setFrame:detailFrame];
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
    NSLog( @"Possible new names" );
    if( [names count] > 0 )
    {
        [namesByID addEntriesFromDictionary:names];
        
//        NSMutableArray *newPairs = [NSMutableArray array];
//        for( METPair *aPair in mailboxPairs )
//        {
//            if( [[aPair second] length] > 0 )
//            {
//                [newPairs addObject:aPair];
//            }
//            else
//            {
//                NSString *name = [namesByID objectForKey:[aPair first]];
//                if( [name length] > 0 )
//                {
//                    METPair *newPair = [METPair pairWithFirst:[aPair first] second:name];
//                    [newPairs addObject:newPair];
//                }
//                else
//                {
//                    [newPairs addObject:aPair];
//                }
//            }
//        }
//        [mailboxPairs autorelease];
//        mailboxPairs = [newPairs retain];
//        [mailboxPairs sortUsingSelector:@selector(compare:)];
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
    
    NSMutableSet *allIDs = [NSMutableSet set];
    
    for( METMailMessage *message in messages )
    {
        sqlite3_bind_nsint( insert_mail_stmt, 1, [message messageID] );
        sqlite3_bind_nsint( insert_mail_stmt, 2, [message senderID] );
        sqlite3_bind_text( insert_mail_stmt, 3, [[message senderName] UTF8String], -1, NULL );
        sqlite3_bind_nsint( insert_mail_stmt, 4, [[message sentDate] timeIntervalSince1970] ); // truncating fractions of a second
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
        
        [allIDs unionSet:[message allIDs]];
    }
    
    [nameGetter namesForIDs:allIDs];

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
    sqlite3_finalize(read_stmt);
    
    // Need to do this again but for mailing lists
    const char getMailingLists[] = "SELECT DISTINCT toListID FROM mail WHERE toListID <> 0;";
    
    rc = sqlite3_prepare_v2(db,getMailingLists,(int)sizeof(getMailingLists),&read_stmt,NULL);
    if(rc != SQLITE_OK){
        NSLog( @"%s: sqlite error: %s", __func__, sqlite3_errmsg(db) );
        return;
    }
    
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
    sqlite3_finalize(read_stmt);

    if( [missingNames count] > 0 )
        [nameGetter namesForIDs:missingNames];
    
    [mailboxPairs addObject:[METPair pairWithFirst:[NSNumber numberWithUnsignedInteger:[character characterId]] second:@"Sent"]];

    [mailboxPairs sortUsingSelector:@selector(compare:)];
}

- (NSArray *)messagesInMailbox:(NSInteger)boxID
{
    sqlite3_stmt *read_stmt;
    int rc;
    const char getMessages[] = "SELECT * FROM mail WHERE toCorpOrAllianceID = ? OR toListID = ?;";
    const char getInboxMessages[] = "SELECT * FROM mail WHERE toCorpOrAllianceID = ? AND toListID = ?;";
    const char getSentMessages[] = "SELECT * FROM mail WHERE senderID = ?;";
    sqlite3 *db = [[character database] openDatabase];
    
    if( boxID == [character characterId] )
        rc = sqlite3_prepare_v2(db,getSentMessages,(int)sizeof(getSentMessages),&read_stmt,NULL);
    else if( 0 == boxID )
        rc = sqlite3_prepare_v2(db,getInboxMessages,(int)sizeof(getInboxMessages),&read_stmt,NULL);
    else
        rc = sqlite3_prepare_v2(db,getMessages,(int)sizeof(getMessages),&read_stmt,NULL);
    if(rc != SQLITE_OK){
        NSLog( @"%s: sqlite error: %s", __func__, sqlite3_errmsg(db) );
        return nil;
    }
    
    sqlite3_bind_nsint( read_stmt, 1, boxID );
    if( boxID != [character characterId] )
        sqlite3_bind_nsint( read_stmt, 2, boxID );

    NSMutableArray *messages = [NSMutableArray array];
    NSMutableSet *missingNames = [NSMutableSet set];

    while( sqlite3_step(read_stmt) == SQLITE_ROW )
    {
        METMailMessage *message = [[METMailMessage alloc] init];
        [message setMessageID:sqlite3_column_nsint(read_stmt,0)];
        [message setSenderID:sqlite3_column_nsint(read_stmt,1)];
        [message setSenderName:sqlite3_column_nsstr( read_stmt, 2 )];
        [message setSentDate:[NSDate dateWithTimeIntervalSince1970:sqlite3_column_nsint(read_stmt,3)]];
        [message setSubject:sqlite3_column_nsstr( read_stmt, 4 )];
        [message setBody:sqlite3_column_nsstr( read_stmt, 5 )];
        [message setToCorpOrAllianceID:sqlite3_column_nsint(read_stmt,6)];
        [message setSenderTypeID:sqlite3_column_nsint(read_stmt,7)];
        NSString *toCharIDs = sqlite3_column_nsstr( read_stmt, 8 );
        if( [toCharIDs length] > 0 )
            [message setToCharacterIDs:[toCharIDs componentsSeparatedByString:@","]];
        [message setToListID:sqlite3_column_nsint(read_stmt,9)];

        [messages addObject:message];
        [missingNames unionSet:[message allIDs]];
    }
    
    if( [missingNames count] > 0 )
        [nameGetter namesForIDs:missingNames];
    
    sqlite3_finalize(read_stmt);
    
    return messages;
}

- (BOOL)tableView:(NSTableView *)tableView shouldEditTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
    return NO;
}

- (void)tableViewSelectionDidChange:(NSNotification *)notification
{
    if( [notification object] == mailboxView )
    {
        NSIndexSet *rows = [mailboxView selectedRowIndexes];
        [currentMessages removeAllObjects];
        for( NSUInteger currentIndex = [rows firstIndex]; currentIndex != NSNotFound; currentIndex = [rows indexGreaterThanIndex:currentIndex] )
        {
            if( currentIndex < [mailboxPairs count] )
            {
                NSArray *messages = [self messagesInMailbox:[[[mailboxPairs objectAtIndex:currentIndex] first] integerValue]];
                [currentMessages addObjectsFromArray:messages];
            }
        }
        
        // sort messages with newest ones at the top
        [currentMessages sortUsingComparator:^( METMailMessage *lhs, METMailMessage *rhs )
         {
             return [[rhs sentDate] compare:[lhs sentDate]];
         }];
        
        [mailHeadersView reloadData];
        [mailHeadersView selectRowIndexes:[NSIndexSet indexSetWithIndex:0] byExtendingSelection:NO];
        if( [currentMessages count] > 0 )
            [messageController setMessage:[currentMessages objectAtIndex:0]];
        else
            [messageController setMessage:nil];
    }
    else if( [notification object] == mailHeadersView )
    {
        if( [mailHeadersView selectedRow] < [currentMessages count] )
            [messageController setMessage:[currentMessages objectAtIndex:[mailHeadersView selectedRow]]];
    }
}

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView
{
    if( tableView == mailboxView )
    {
        return [mailboxPairs count];
    }
    else if( tableView == mailHeadersView )
    {
        return [currentMessages count];
    }
    return 0;
}

- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
    if( tableView == mailboxView )
    {
        METPair *pair = [mailboxPairs objectAtIndex:row];
        if( 0 == [[pair second] length] )
        {
            NSString *name = [namesByID objectForKey:[pair first]];
            if( [name length] > 0 )
            {
                METPair *newPair = [METPair pairWithFirst:[pair first] second:name];
                [mailboxPairs replaceObjectAtIndex:row withObject:newPair];
                pair = newPair;
            }
        }
        return [pair second];
    }
    else if( tableView == mailHeadersView )
    {
//        METMailMessage *message = [currentMessages objectAtIndex:row];
//        return message;
//        if( [[tableColumn identifier] isEqualToString:@"SENDER_NAME"] )
//        {
//            return [message senderName];
//        }
//        else if( [[tableColumn identifier] isEqualToString:@"SENT_DATE"] )
//        {
//            return [message sentDate];
//        }
    }
    return nil;
}

- (void)tableView:(NSTableView *)tableView willDisplayCell:(id)cell forTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
    if( tableView == mailHeadersView )
    {
        if( [cell isKindOfClass:[METMailHeaderCell class]] && ([currentMessages count] > row) )
            [cell setMessage:[currentMessages objectAtIndex:row]];
    }
}

#pragma mark SplitView delegate methods
- (CGFloat)splitView:(NSSplitView *)_splitView constrainMinCoordinate:(CGFloat)proposedMin ofSubviewAt:(NSInteger)dividerIndex {
    // When the divider is dragged left only the pane immediately to the
    // divider's left is resized. So the way this works is that we first
    // calculate the width of all panes up to but *not* including that pane.
    CGFloat widthUpToSubview = 0;
    NSArray *subviews = [_splitView subviews];
    for (NSUInteger i = 0; i < dividerIndex; i++) {
        NSView *pane = [subviews objectAtIndex:i];
        CGFloat paneWidth = [pane frame].size.width;
        widthUpToSubview += paneWidth;
    }
    
    // Now when we add the pane's minimum width we get the, in absolute terms,
    // the minimum width for the width constraints to be met.
    CGFloat minAllowedWidth = widthUpToSubview + [[minimumPaneWidths objectAtIndex:dividerIndex] floatValue];
    
    // Finally we accept the proposed width only if it doesn't undercut the
    // minimum allowed width
    return proposedMin < minAllowedWidth ? minAllowedWidth : proposedMin;
}

- (CGFloat)splitView:(NSSplitView *)_splitView constrainMaxCoordinate:(CGFloat)proposedMax ofSubviewAt:(NSInteger)dividerIndex{
    
    // This works similar to how we work out the minimum constrained width. When
    // the divider is dragged right, only the pane immediately to the divider's
    // right is resized. Thus we first calculate the width consumed by all panes
    // after that pane.
    CGFloat widthDownToSubview = 0;
    NSArray *subviews = [_splitView subviews];
    for (NSUInteger i = [subviews count] - 1; i > dividerIndex + 1; i--) {
        NSView *pane = [subviews objectAtIndex:i];
        CGFloat paneWidth = [pane frame].size.width;
        widthDownToSubview += paneWidth;
    }
    
    // Now when we add the pane's minimum width on top of the consumed width
    // after it, we get the maximum width allowed for the constraints to be met.
    // But we need a position from the left of the split view, so we translate
    // that by deducting it from the split view's total width.
    CGFloat splitViewWidth = [_splitView frame].size.width;
    CGFloat minPaneWidth = [[minimumPaneWidths objectAtIndex:dividerIndex+1] floatValue];
    CGFloat maxAllowedWidth = splitViewWidth - (widthDownToSubview + minPaneWidth);
    
    // This is the converse of the minimum constraint method: accept the proposed
    // maximum only if it doesn't exced the maximum allowed width
    return proposedMax > maxAllowedWidth ? maxAllowedWidth : proposedMax;
}
@end
