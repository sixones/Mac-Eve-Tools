//
//  ContractsViewController.m
//  Mac Eve Tools
//
//  Created by Andrew Salamon on 5/20/13.
//  Copyright (c) 2013 Sebastian Kruemling. All rights reserved.
//

#import "ContractsViewController.h"
#import "Contracts.h"
#import "Contract.h"
#import "ContractDetailsController.h"
#import "MetTableHeaderMenuManager.h"
#import "Character.h"
#import "CharacterDatabase.h"
#import <sqlite3.h>
#import "Helpers.h"

@implementation ContractsViewController

@synthesize character;
@synthesize dbContracts;

-(id) init
{
	if( (self = [super initWithNibName:@"ContractsView" bundle:nil]) )
    {
        contracts = [[Contracts alloc] init];
        [contracts setDelegate:self];
//        NSSortDescriptor *defaultSort = [NSSortDescriptor sortDescriptorWithKey:@"issued" ascending:YES selector:@selector(compare:)];
//        [contracts sortUsingDescriptors:[NSArray arrayWithObject:defaultSort]];
	}
    
	return self;
}

- (void)dealloc
{
    [contracts release];
    [character release];
    [app release];
    [headerMenuManager release];
    [super dealloc];
}

- (void)awakeFromNib
{
    [currencyFormatter setCurrencySymbol:@""];
    [contractsTable setDoubleAction:@selector(contractsDoubleClick:)];
    [contractsTable setTarget:self];
    headerMenuManager = [[MetTableHeaderMenuManager alloc] initWithMenu:nil forTable:contractsTable];
}

-(BOOL) createContractTables
{
    if( character )
    {
        int rc;
        char *errmsg;
        CharacterDatabase *charDB = [[self character] database];
        sqlite3 *db = [charDB openDatabase];
        
        if( [charDB doesTableExist:@"contracts"] )
            return YES;
        
        // TODO: also make sure it's the right version
        
        [charDB beginTransaction];
        
        const char createContractsTable[] = "CREATE TABLE contracts ("
        "contractID INTEGER PRIMARY KEY, "
        "type VARCHAR(255), "
        "status VARCHAR(255), "
        "startStationID INTEGER, "
        "endStationID INTEGER, "
        "volume DOUBLE, "
        "price DOUBLE, "
        "reward DOUBLE, "
        "collateral DOUBLE, "
        "buyout DOUBLE, "
        "issuerID INTEGER, "
        "issuerCorpID INTEGER, "
        "assigneeID INTEGER, "
        "acceptorID INTEGER, "
        "issued DATETIME, "
        "expired DATETIME, "
        "accepted DATETIME, "
        "completed DATETIME, "
        "availability VARCHAR(255), "
        "title VARCHAR(255), "
        "days INTEGER, "
        "forCorp BOOLEAN "
        ");";
        
        rc = sqlite3_exec(db,createContractsTable,NULL,NULL,&errmsg);
        if(rc != SQLITE_OK){
            [charDB logError:errmsg];
            [charDB rollbackTransaction];
            return NO;
        }
        
        
        const char createContractItemsTable[] = "CREATE TABLE contractItems ("
        "recordID INTEGER PRIMARY KEY, "
        "contractID INTEGER, "
        "typeID Integer, "
        "quantity Integer, "
        "rawQuantity Integer, "
        "singleton BOOLEAN, "
        "included BOOLEAN "
        "); "
        "CREATE INDEX contractIDIndex ON contractItems(contractID);";
        
        rc = sqlite3_exec(db,createContractItemsTable,NULL,NULL,&errmsg);
        if(rc != SQLITE_OK){
            [charDB logError:errmsg];
            [charDB rollbackTransaction];
            return NO;
        }

        [charDB commitTransaction];
    }
    
    return YES;
}

- (void)setCharacter:(Character *)_character
{
    if( _character != character )
    {
        [character release];
        character = [_character retain];
        [self createContractTables];
        // if view is active we need to reload contracts
        [self setDbContracts:nil];
        [contracts setCharacter:character];
        [contracts reload:self];
        [app setToolbarMessage:NSLocalizedString(@"Updating Contracts…",@"Updating Contracts status line")];
        [app startLoadingAnimation];
        [self setDbContracts:[self loadContracts]];
        [contractsTable reloadData];
        [contractsTable deselectAll:self];
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
    [app setToolbarMessage:NSLocalizedString(@"Updating Contracts…",@"Updating Contracts status line")];
    [app startLoadingAnimation];
    [contracts reload:self];
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

- (void)updateContracts:(NSArray *)newContracts andClose:(BOOL)close
{
    [self saveContracts:newContracts];
    [self setDbContracts:[self loadContracts]];
    NSArray *newDescriptors = [contractsTable sortDescriptors];
    [contracts sortUsingDescriptors:newDescriptors];
    [[self dbContracts] sortUsingDescriptors:newDescriptors];
    if( close )
        [self closeOlderContracts:newContracts];
    [contractsTable reloadData];
    [app setToolbarMessage:NSLocalizedString(@"Finished Updating Contracts…",@"Finished Updating Contracts status line") time:5];
    [app stopLoadingAnimation];
}

- (void)contractsFinishedUpdating:(NSArray *)newContracts
{
    [self updateContracts:newContracts andClose:YES];
}

- (void)contractFinishedUpdating:(NSArray *)newContracts
{
    [self updateContracts:newContracts andClose:NO];
}

- (void)contractsSkippedUpdating
{
    [app setToolbarMessage:NSLocalizedString(@"Using Cached Contracts…",@"Using Cached Contracts status line") time:5];
    [app stopLoadingAnimation];
}

- (void)contractsDoubleClick:(id)sender
{
    NSInteger rowNumber = [contractsTable clickedRow];
    Contract *contract = [[self dbContracts] objectAtIndex:rowNumber];
    [ContractDetailsController displayContract:contract forCharacter:character];
}

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView
{
    return [[self dbContracts] count];
}

/* This method is required for the "Cell Based" TableView, and is optional for the "View Based" TableView. If implemented in the latter case, the value will be set to the view at a given row/column if the view responds to -setObjectValue: (such as NSControl and NSTableCellView).
 */
- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
    if( 0 == [[self dbContracts] count] )
        return nil;
    
    if( row >= [[self dbContracts] count] )
        return nil;
    
    Contract *contract = [[self dbContracts] objectAtIndex:row];
    NSString *colID = [tableColumn identifier];
    id value = nil;
    
    if( [colID isEqualToString:@"type"] )
    {
        value = [contract type];
    }
    else if( [colID isEqualToString:@"status"] )
    {
        value = [contract status];
    }
    else if( [colID isEqualToString:@"startStation"] )
    {
        value = [contract startStationName];
    }
    else if( [colID isEqualToString:@"endStation"] )
    {
        value = [contract endStationName];
    }

    return value;
}

-(void)tableView:(NSTableView *)tableView sortDescriptorsDidChange: (NSArray *)oldDescriptors
{
    NSArray *newDescriptors = [tableView sortDescriptors];
    [contracts sortUsingDescriptors:newDescriptors];
    [[self dbContracts] sortUsingDescriptors:newDescriptors];
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

- (NSMutableArray *)loadContracts
{
    sqlite3_stmt *read_stmt;
    int rc;
    const char getMarketOrders[] = "SELECT * FROM contracts;";
    sqlite3 *db = [[character database] openDatabase];
    
    rc = sqlite3_prepare_v2(db,getMarketOrders,(int)sizeof(getMarketOrders),&read_stmt,NULL);
    if(rc != SQLITE_OK){
        NSLog( @"%s: sqlite error: %s", __func__, sqlite3_errmsg(db) );
        return nil;
    }
    
    NSMutableArray *tempContracts = [NSMutableArray array];
    
    while( sqlite3_step(read_stmt) == SQLITE_ROW )
    {
        Contract *aContract = [[Contract alloc] init];
        
        [aContract setContractID:sqlite3_column_nsint( read_stmt, 0 )];
        [aContract setType:sqlite3_column_nsstr( read_stmt, 1 )];
        [aContract setStatus:sqlite3_column_nsstr( read_stmt, 2 )];
        [aContract setStartStationID:sqlite3_column_nsint( read_stmt,3 )];
        [aContract setEndStationID:sqlite3_column_nsint( read_stmt,4 )];
        [aContract setVolume:sqlite3_column_double(read_stmt,5)];
        [aContract setPrice:sqlite3_column_double(read_stmt,6)];
        [aContract setReward:sqlite3_column_double(read_stmt,7)];
        [aContract setCollateral:sqlite3_column_double(read_stmt,8)];
        [aContract setBuyout:sqlite3_column_double(read_stmt,9)];
        [aContract setIssuerID:sqlite3_column_nsint( read_stmt, 10 )];
        [aContract setIssuerCorpID:sqlite3_column_nsint( read_stmt, 11 )];
        [aContract setAssigneeID:sqlite3_column_nsint( read_stmt, 12 )];
        [aContract setAcceptorID:sqlite3_column_nsint( read_stmt, 13 )];
        [aContract setIssued:sqlite3_column_nsdate(read_stmt,14)];
        [aContract setExpired:sqlite3_column_nsdate(read_stmt,15)];
        [aContract setAccepted:sqlite3_column_nsdate(read_stmt,16)];
        [aContract setCompleted:sqlite3_column_nsdate(read_stmt,17)];
        [aContract setAvailability:sqlite3_column_nsstr(read_stmt,18)];
        [aContract setTitle:sqlite3_column_nsstr(read_stmt,19)];
        [aContract setDays:sqlite3_column_nsint(read_stmt,20)];
        [aContract setForCorp:sqlite3_column_nsint(read_stmt,21)];

        [aContract setCharacter:[self character]];
        [tempContracts addObject:aContract];
    }
    
    sqlite3_finalize(read_stmt);
    
    return tempContracts;
}


- (BOOL)saveContracts:(NSArray *)newOrders
{
    CharacterDatabase *charDB = [character database];
    sqlite3 *db = [charDB openDatabase];
    const char insert_market_order[] = "INSERT INTO contracts VALUES (?,?,?,?,?, ?,?,?,?,?, ?,?,?,?,?, ?,?,?,?,?, ?,?);";
    sqlite3_stmt *insert_order_stmt;
    const char update_order[] = "UPDATE contracts SET status = ?, expired = ?, accepted = ?, completed = ? WHERE contractID = ?;";
    sqlite3_stmt *update_order_stmt;
    BOOL success = YES;
    int rc;
    
    rc = sqlite3_prepare_v2(db,insert_market_order,(int)sizeof(insert_market_order),&insert_order_stmt,NULL);
    if( rc != SQLITE_OK )
    {
        NSLog( @"%s: sqlite error: %s", __func__, sqlite3_errmsg(db) );
        return NO;
    }
    
    rc = sqlite3_prepare_v2(db,update_order,(int)sizeof(update_order),&update_order_stmt,NULL);
    if( rc != SQLITE_OK )
    {
        NSLog( @"%s: sqlite error: %s", __func__, sqlite3_errmsg(db) );
        sqlite3_finalize(insert_order_stmt);
        return NO;
    }
    
    for( Contract *contract in newOrders )
    {
        sqlite3_bind_nsint( insert_order_stmt, 1, [contract contractID] );
        sqlite3_bind_text( insert_order_stmt, 2, [[contract type] UTF8String], -1, NULL );
        sqlite3_bind_text( insert_order_stmt, 3, [[contract status] UTF8String], -1, NULL );
        sqlite3_bind_nsint( insert_order_stmt, 4, [contract startStationID] );
        sqlite3_bind_nsint( insert_order_stmt, 5, [contract endStationID] );
        sqlite3_bind_double( insert_order_stmt, 6, [contract volume] );
        sqlite3_bind_double( insert_order_stmt, 7, [contract price] );
        sqlite3_bind_double( insert_order_stmt, 8, [contract reward] );
        sqlite3_bind_double( insert_order_stmt, 9, [contract collateral] );
        sqlite3_bind_double( insert_order_stmt, 10, [contract buyout] );
        sqlite3_bind_nsint( insert_order_stmt, 11, [contract issuerID] );
        sqlite3_bind_nsint( insert_order_stmt, 12, [contract issuerCorpID] );
        sqlite3_bind_nsint( insert_order_stmt, 13, [contract assigneeID] );
        sqlite3_bind_nsint( insert_order_stmt, 14, [contract acceptorID] );
        sqlite3_bind_nsint( insert_order_stmt, 15, [[contract issued] timeIntervalSince1970] );
        sqlite3_bind_nsint( insert_order_stmt, 16, [[contract expired] timeIntervalSince1970] );
        sqlite3_bind_nsint( insert_order_stmt, 17, [[contract accepted] timeIntervalSince1970] );
        sqlite3_bind_nsint( insert_order_stmt, 18, [[contract completed] timeIntervalSince1970] );
        sqlite3_bind_text( insert_order_stmt, 19, [[contract availability] UTF8String], -1, NULL );
        sqlite3_bind_text( insert_order_stmt, 20, [[contract title] UTF8String], -1, NULL );
        sqlite3_bind_nsint( insert_order_stmt, 21, [contract days] );
        sqlite3_bind_nsint( insert_order_stmt, 22, [contract forCorp] );
        
        rc = sqlite3_step(insert_order_stmt);
        if( SQLITE_CONSTRAINT == rc )
        {
            // Update the order in case anything has changed: volRemaining, orderState, price and escrow?
            sqlite3_bind_text( update_order_stmt, 1, [[contract status] UTF8String], -1, NULL );
            sqlite3_bind_nsint( update_order_stmt, 2, [[contract expired] timeIntervalSince1970] );
            sqlite3_bind_nsint( update_order_stmt, 3, [[contract accepted] timeIntervalSince1970] );
            sqlite3_bind_nsint( update_order_stmt, 4, [[contract completed] timeIntervalSince1970] );
            sqlite3_bind_nsint( update_order_stmt, 5, [contract contractID] );
            
            if( (rc = sqlite3_step(update_order_stmt)) != SQLITE_DONE )
            {
                NSLog( @"Error updating contract ID: %ld", (long)[contract contractID] );
                success = NO;
            }
            
            sqlite3_reset(update_order_stmt);
            
        }
        else if( rc != SQLITE_DONE )
        {
            NSLog(@"Error inserting contract ID: %ld (code: %d)", (unsigned long)[contract contractID], rc );
            success = NO;
        }
        sqlite3_reset(insert_order_stmt);
    }
    
    sqlite3_finalize(insert_order_stmt);
    sqlite3_finalize(update_order_stmt);
    return success;
}

- (BOOL)contracts:(NSArray *)localContracts containContractID:(NSInteger)contractID
{
    NSUInteger index = [localContracts indexOfObjectPassingTest:^BOOL (id el, NSUInteger i, BOOL *stop)
                        {
                            BOOL res = [(Contract *)el contractID] == contractID;
                            if( res )
                                *stop = YES;
                            return res;
                        }];
    return NSNotFound != index;
}

// Try to find orders that slipped through the cracks and see if they are closed or expired
- (BOOL)closeOlderContracts:(NSArray *)newOrders
{
    NSMutableArray *changes = [NSMutableArray array];
    // filter dbOrders for ones that are open
    // for each, if it is not in newOrders, then request that order specifically from the API
    NSIndexSet *indexes = [[self dbContracts] indexesOfObjectsPassingTest:^BOOL (id el, NSUInteger i, BOOL *stop)
                           {
                               return [@"Outstanding" isEqualToString:[(Contract *)el status]];
                           }];
    NSArray *openOrders = [[self dbContracts] objectsAtIndexes:indexes];
    
    for( Contract *aContract in openOrders )
    {
        BOOL res = [self contracts:newOrders containContractID:[aContract contractID]];
        if( !res )
        {
            // request this market order by id
            [aContract setStatus:@"Unknown"]; // for now just set it to unknown
            [contracts requestContract:[NSNumber numberWithInteger:[aContract contractID]]];
            [changes addObject:aContract];
        }
    }
    
    //    if( [changes count] > 0 )
    //        [self saveMarketOrders:changes];
    
    return YES;
}

@end
