//
//  IndustryJobsController.m
//  Vitality
//
//  Created by Andrew Salamon on 5/16/2016.
//  Copyright (c) 2016 The Vitality Project. All rights reserved.
//

#import "IndustryJobsController.h"
#import "IndustryJobs.h"
#import "IndustryJob.h"
#import "MetTableHeaderMenuManager.h"
#import "Character.h"
#import "CharacterDatabase.h"
#import <sqlite3.h>
#import "Helpers.h"

@interface IndustryJobsController()
@property (readwrite,retain) NSMutableArray *dbJobs;
@end

@implementation IndustryJobsController

@synthesize character;
@synthesize dbJobs;

-(id) init
{
	if( (self = [super initWithNibName:@"IndustryJobs" bundle:nil]) )
    {
        jobs = [[IndustryJobs alloc] init];
        [jobs setDelegate:self];
	}
    
	return self;
}

- (void)dealloc
{
    [jobs release];
    [character release];
    [app release];
    [headerMenuManager release];
    [super dealloc];
}

- (void)awakeFromNib
{
    [currencyFormatter setCurrencySymbol:@""];
    headerMenuManager = [[MetTableHeaderMenuManager alloc] initWithMenu:nil forTable:jobsTable];
}

- (void)setCharacter:(Character *)_character
{
    if( _character != character )
    {
        [character release];
        character = [_character retain];
        // if view is active we need to reload market orders
        [self createIndustryJobTables];
        [jobs setCharacter:character];
        [jobs reload:self];
        [app setToolbarMessage:NSLocalizedString(@"Updating Industry Jobs…",@"Updating Industry Jobs")];
        [app startLoadingAnimation];
        [self setDbJobs:[self loadIndustryJobs]];
        [jobsTable reloadData];
        [jobsTable deselectAll:self];
    }
}

-(BOOL) createIndustryJobTables
{
    if( character )
    {
        int rc;
        char *errmsg;
        CharacterDatabase *charDB = [[self character] database];
        sqlite3 *db = [charDB openDatabase];
        
        if( [charDB doesTableExist:@"industryJobs"] )
            return YES;
        
        // TODO: also make sure it's the right version
        
        [charDB beginTransaction];
        
        const char createMailTable[] = "CREATE TABLE industryJobs ("
        "jobID INTEGER PRIMARY KEY, "
        "installerID INTEGER, "
        "installerName longtext, "
        "facilityID INTEGER, "
        "solarSystemID INTEGER, "
        "solarSystemName longtext, "
        "stationID INTEGER, "
        "activityID INTEGER, "
        "blueprintID INTEGER, "
        "blueprintTypeID INTEGER, "
        "blueprintTypeName longtext, "
        "blueprintLocationID INTEGER, "
        "outputLocationID INTEGER, "
        "runs INTEGER, "
        "cost DOUBLE, "
        "teamID INTEGER, "
        "licensedRuns INTEGER, "
        "probability INTEGER, "
        "productTypeID INTEGER, "
        "productTypeName longtext, "
        "status INTEGER, "
        "timeInSeconds INTEGER, "
        "startDate DATETIME, "
        "endDate DATETIME, "
        "pauseDate DATETIME, "
        "completedDate DATETIME, "
        "completedCharacterID INTEGER "
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
    [app setToolbarMessage:NSLocalizedString(@"Updating Industry Jobs…",@"Updating Industry Jobs")];
    [app startLoadingAnimation];
    if( [self character] )
        [jobs reload:self];
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

// The default market order API call finished updating, so all open or recent market orders should be in newOrders
- (void)jobsFinishedUpdating:(NSArray *)newJobs
{
    [self saveIndustryJobs:newJobs];
    [self setDbJobs:[self loadIndustryJobs]]; // TODO: This is wasteful. We could try just adding new market orders to dbOrders (don't allow duplicate orderID's)
    [[self dbJobs] sortUsingDescriptors:[jobsTable sortDescriptors]];
    [jobsTable reloadData];
    [app setToolbarMessage:NSLocalizedString(@"Finished Updating Industry Jobs…",@"Finished Updating Industry Jobs") time:5];
    [app stopLoadingAnimation];
}

- (void)jobsSkippedUpdating
{
    [app setToolbarMessage:NSLocalizedString(@"Using Cached Industry Jobs…",@"Using Cached Industry Jobs status line") time:5];
    [app stopLoadingAnimation];
}

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView
{
    return [[self dbJobs] count];
}

/* This method is required for the "Cell Based" TableView, and is optional for the "View Based" TableView. If implemented in the latter case, the value will be set to the view at a given row/column if the view responds to -setObjectValue: (such as NSControl and NSTableCellView).
 */
- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
    if( 0 == [[self dbJobs] count] || row >= [[self dbJobs] count] )
        return nil;
    
    IndustryJob *job = [[self dbJobs] objectAtIndex:row];
    NSString *colID = [tableColumn identifier];
    id value = nil;
    
    if( [colID isEqualToString:@"typeName"] )
    {
        value = [job blueprintTypeName];
    }
    else if( [colID isEqualToString:@"runs"] )
    {
        value = [NSNumber numberWithInteger:[job runs]];
    }
    else if( [colID isEqualToString:@"stationID"] )
    {
        value = [job stationName];
    }
    else if( [colID isEqualToString:@"activityID"] )
    {
        value = [NSNumber numberWithInteger:[job activityID]];
    }
    else if( [colID isEqualToString:@"status"] )
    {
        value = [job jobStatus];
    }
    
    return value;
}

-(void)tableView:(NSTableView *)tableView sortDescriptorsDidChange: (NSArray *)oldDescriptors
{
    NSArray *newDescriptors = [tableView sortDescriptors];
    [[self dbJobs] sortUsingDescriptors:newDescriptors];
    [tableView reloadData];
}

- (IBAction)toggleColumn:(id)sender
{
    NSTableColumn *col = [sender representedObject];
    [col setHidden:![col isHidden]];
}

// Setup a contextual menu for showing/hiding table columns
- (void)setupMenu:(NSMenu *)menu forTable:(NSTableView *)table
{
    if( nil == menu )
    {
        menu = [[NSMenu alloc] init];
        [[table headerView] setMenu:menu];
        [menu release];
    }
    
    //loop through columns, creating a menu item for each
    for (NSTableColumn *col in [table tableColumns])
    {
        // Use something like this if we want some columns to be un-hideable
//        if ([[col identifier] isEqualToString:COLUMNID_NAME])
//            continue;   // Cannot hide name column
        NSMenuItem *mi = [[NSMenuItem alloc] initWithTitle:[col.headerCell stringValue] action:@selector(toggleColumn:)  keyEquivalent:@""];
        mi.target = self;
        mi.representedObject = col;
        [menu addItem:mi];
    }
}

- (BOOL)validateMenuItem:(NSMenuItem *)menuItem
{
    if( [menuItem action] == @selector(toggleColumn:) )
    {
        NSTableColumn *col = [menuItem representedObject];
        [menuItem setState:col.isHidden ? NSOffState : NSOnState];
    }
    return YES;
}

- (NSMutableArray *)loadIndustryJobs
{
    sqlite3_stmt *read_stmt;
    int rc;
    const char getIndustryJobs[] = "SELECT * FROM industryJobs;";
    sqlite3 *db = [[character database] openDatabase];
    
    rc = sqlite3_prepare_v2(db,getIndustryJobs,(int)sizeof(getIndustryJobs),&read_stmt,NULL);
    if(rc != SQLITE_OK){
        NSLog( @"%s: sqlite error: %s", __func__, sqlite3_errmsg(db) );
        return nil;
    }
    
    NSMutableArray *existingItems = [NSMutableArray array];
    
    while( sqlite3_step(read_stmt) == SQLITE_ROW )
    {
        IndustryJob *job = [[IndustryJob alloc] init];
        
        [job setJobID:sqlite3_column_nsint(read_stmt,0)];
        [job setInstallerID:sqlite3_column_nsint(read_stmt,1)];
        [job setInstallerName:sqlite3_column_nsstr( read_stmt, 2 )];
        [job setFacilityID:sqlite3_column_nsint(read_stmt,3)];
        [job setSolarSystemID:sqlite3_column_nsint(read_stmt,4)];
        [job setSolarSystemName:sqlite3_column_nsstr( read_stmt, 5 )];
        [job setStationID:sqlite3_column_nsint(read_stmt,6)];
        [job setActivityID:sqlite3_column_nsint(read_stmt,7)];
        [job setBlueprintID:sqlite3_column_nsint(read_stmt,8)];
        [job setBlueprintTypeID:sqlite3_column_nsint(read_stmt,9)];
        [job setBlueprintTypeName:sqlite3_column_nsstr( read_stmt, 10 )];
        [job setBlueprintLocationID:sqlite3_column_nsint(read_stmt,11)];
        [job setOutputLocationID:sqlite3_column_nsint(read_stmt,12)];
        [job setRuns:sqlite3_column_nsint(read_stmt,13)];
        [job setCost:sqlite3_column_double(read_stmt,14)];
        [job setTeamID:sqlite3_column_nsint(read_stmt,15)];
        [job setLicensedRuns:sqlite3_column_nsint(read_stmt,16)];
        [job setProbability:sqlite3_column_nsint(read_stmt,17)];
        [job setProductTypeID:sqlite3_column_nsint(read_stmt,18)];
        [job setProductTypeName:sqlite3_column_nsstr( read_stmt, 19 )];
        [job setStatus:sqlite3_column_int(read_stmt,20)];
        [job setTimeInSeconds:sqlite3_column_nsint(read_stmt,21)];
        [job setStartDate:[NSDate dateWithTimeIntervalSince1970:sqlite3_column_nsint(read_stmt,22)]];
        [job setEndDate:[NSDate dateWithTimeIntervalSince1970:sqlite3_column_nsint(read_stmt,23)]];
        [job setPauseDate:[NSDate dateWithTimeIntervalSince1970:sqlite3_column_nsint(read_stmt,24)]];
        [job setCompletedDate:[NSDate dateWithTimeIntervalSince1970:sqlite3_column_nsint(read_stmt,25)]];
        [job setCompletedCharacterID:sqlite3_column_nsint(read_stmt,26)];

        [existingItems addObject:job];
    }
    
    sqlite3_finalize(read_stmt);
    
    return existingItems;
}


- (BOOL)saveIndustryJobs:(NSArray *)newItems
{
    CharacterDatabase *charDB = [character database];
    sqlite3 *db = [charDB openDatabase];
    const char insert_market_order[] = "INSERT INTO industryJobs VALUES (?,?,?,?,?, ?,?,?,?,?, ?,?,?,?,?, ?,?,?,?,?, ?,?,?,?,?, ?,?);";
    sqlite3_stmt *insert_item_stmt;
    const char update_order[] = "UPDATE industryJobs SET status = ?, endDate = ?, pauseDate = ?, completedDate = ?, completedCharacterID =? WHERE jobID = ?;";
    sqlite3_stmt *update_item_stmt;
    BOOL success = YES;
    int rc;
    
    rc = sqlite3_prepare_v2(db,insert_market_order,(int)sizeof(insert_market_order),&insert_item_stmt,NULL);
    if( rc != SQLITE_OK )
    {
        NSLog( @"%s: sqlite error: %s", __func__, sqlite3_errmsg(db) );
        return NO;
    }
    
    rc = sqlite3_prepare_v2(db,update_order,(int)sizeof(update_order),&update_item_stmt,NULL);
    if( rc != SQLITE_OK )
    {
        NSLog( @"%s: sqlite error: %s", __func__, sqlite3_errmsg(db) );
        sqlite3_finalize(insert_item_stmt);
        return NO;
    }

    for( IndustryJob *item in newItems )
    {
        if( [item installerID] != [[self character] characterId] )
            continue; // this might happen if we switch characters while an API request is outstanding
        
        sqlite3_bind_nsint( insert_item_stmt, 1, [item jobID] );
        sqlite3_bind_nsint( insert_item_stmt, 2, [item installerID] );
        sqlite3_bind_text( insert_item_stmt, 3, [[item installerName] UTF8String], -1, NULL );
        sqlite3_bind_nsint( insert_item_stmt, 4, [item facilityID] );
        sqlite3_bind_nsint( insert_item_stmt, 5, [item solarSystemID] );
        sqlite3_bind_text( insert_item_stmt, 6, [[item solarSystemName] UTF8String], -1, NULL );
        sqlite3_bind_nsint( insert_item_stmt, 7, [item stationID] );
        sqlite3_bind_nsint( insert_item_stmt, 8, [item activityID] );
        sqlite3_bind_nsint( insert_item_stmt, 9, [item blueprintID] );
        sqlite3_bind_nsint( insert_item_stmt, 10, [item blueprintTypeID] );
        sqlite3_bind_text( insert_item_stmt, 11, [[item blueprintTypeName] UTF8String], -1, NULL );
        sqlite3_bind_nsint( insert_item_stmt, 12, [item blueprintLocationID] );
        sqlite3_bind_nsint( insert_item_stmt, 13, [item outputLocationID] );
        sqlite3_bind_nsint( insert_item_stmt, 14, [item runs] );
        sqlite3_bind_double( insert_item_stmt, 15, [item cost] );
        sqlite3_bind_nsint( insert_item_stmt, 16, [item teamID] );
        sqlite3_bind_nsint( insert_item_stmt, 17, [item licensedRuns] );
        sqlite3_bind_nsint( insert_item_stmt, 18, [item probability] );
        sqlite3_bind_nsint( insert_item_stmt, 19, [item productTypeID] );
        sqlite3_bind_text( insert_item_stmt, 20, [[item productTypeName] UTF8String], -1, NULL );
        sqlite3_bind_nsint( insert_item_stmt, 21, [item status] );
        sqlite3_bind_nsint( insert_item_stmt, 22, [item timeInSeconds] );
        sqlite3_bind_nsint( insert_item_stmt, 23, [[item startDate] timeIntervalSince1970] );
        sqlite3_bind_nsint( insert_item_stmt, 24, [[item endDate] timeIntervalSince1970] );
        sqlite3_bind_nsint( insert_item_stmt, 25, [[item pauseDate] timeIntervalSince1970] );
        sqlite3_bind_nsint( insert_item_stmt, 26, [[item completedDate] timeIntervalSince1970] );
        sqlite3_bind_nsint( insert_item_stmt, 27, [item completedCharacterID] );
        
        rc = sqlite3_step(insert_item_stmt);
        if( SQLITE_CONSTRAINT == rc )
        {
            // Update the order in case anything has changed: volRemaining, orderState, price and escrow?
            sqlite3_bind_nsint( update_item_stmt, 1, [item status] );
            sqlite3_bind_nsint( update_item_stmt, 2, [[item endDate] timeIntervalSince1970] );
            sqlite3_bind_nsint( update_item_stmt, 3, [[item pauseDate] timeIntervalSince1970] );
            sqlite3_bind_nsint( update_item_stmt, 4, [[item completedDate] timeIntervalSince1970] );
            sqlite3_bind_nsint( update_item_stmt, 5, [item completedCharacterID] );
            sqlite3_bind_nsint( update_item_stmt, 5, [item jobID] );
            
            if( (rc = sqlite3_step(update_item_stmt)) != SQLITE_DONE )
            {
                NSLog( @"Error updating industry job ID: %ld", (long)[item jobID] );
                success = NO;
            }
            
            sqlite3_reset(update_item_stmt);
            
        }
        else if( rc != SQLITE_DONE )
        {
            NSLog(@"Error inserting industry job ID: %ld (code: %d)", (unsigned long)[item jobID], rc );
            success = NO;
        }
        sqlite3_reset(insert_item_stmt);
    }
    
    sqlite3_finalize(insert_item_stmt);
    sqlite3_finalize(update_item_stmt);
    return success;
}

@end
