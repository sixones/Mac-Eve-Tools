//
//  MarketViewController.m
//  Mac Eve Tools
//
//  Created by Andrew Salamon on 5/20/13.
//  Copyright (c) 2013 Sebastian Kruemling. All rights reserved.
//

#import "MarketViewController.h"
#import "MarketOrders.h"
#import "MarketOrder.h"
#import "MetTableHeaderMenuManager.h"
#import "Character.h"
#import "CharacterDatabase.h"
#import <sqlite3.h>
#import "Helpers.h"

@interface MarketViewController()
@property (readwrite,retain) NSMutableArray *dbOrders;
@end

@implementation MarketViewController

@synthesize character;
@synthesize dbOrders;

-(id) init
{
	if( (self = [super initWithNibName:@"MarketView" bundle:nil]) )
    {
        orders = [[MarketOrders alloc] init];
        [orders setDelegate:self];
	}
    
	return self;
}

- (void)dealloc
{
    [orders release];
    [character release];
    [app release];
    [headerMenuManager release];
    [super dealloc];
}

- (void)awakeFromNib
{
    [currencyFormatter setCurrencySymbol:@""];
    headerMenuManager = [[MetTableHeaderMenuManager alloc] initWithMenu:nil forTable:orderTable];
}

- (void)setCharacter:(Character *)_character
{
    if( _character != character )
    {
        [character release];
        character = [_character retain];
        // if view is active we need to reload market orders
        [self createMarketOrderTables];
        [orders setCharacter:character];
        [orders reload:self];
        [app setToolbarMessage:NSLocalizedString(@"Updating Market Orders…",@"Updating Market Orders")];
        [app startLoadingAnimation];
        [self setDbOrders:[self loadMarketOrders]];
        [orderTable reloadData];
        [orderTable deselectAll:self];
    }
}

-(BOOL) createMarketOrderTables
{
    if( character )
    {
        int rc;
        char *errmsg;
        CharacterDatabase *charDB = [[self character] database];
        sqlite3 *db = [charDB openDatabase];
        
        if( [charDB doesTableExist:@"marketOrders"] )
            return YES;
        
        // TODO: also make sure it's the right version
        
        [charDB beginTransaction];
        
        const char createMailTable[] = "CREATE TABLE marketOrders ("
        "orderID INTEGER PRIMARY KEY, "
        "charID INTEGER, "
        "stationID INTEGER, "
        "volEntered INTEGER, "
        "volRemaining INTEGER, "
        "minVolume INTEGER, "
        "orderState INTEGER, "
        "typeID INTEGER, "
        "range VARCHAR(255), "
        "accountKey INTEGER, "
        "duration INTEGER, "
        "price DOUBLE, "
        "escrow DOUBLE, "
        "buy BOOLEAN, "
        "issued DATETIME "
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
    [app setToolbarMessage:NSLocalizedString(@"Updating Market Orders…",@"Updating Market Orders status line")];
    [app startLoadingAnimation];
    [orders reload:self];
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

- (void)updateOrders:(NSArray *)newOrders andClose:(BOOL)close
{
    [self saveMarketOrders:newOrders];
    [self setDbOrders:[self loadMarketOrders]]; // TODO: This is wasteful. We could try just adding new market orders to dbOrders (don't allow duplicate orderID's)
    [[self dbOrders] sortUsingDescriptors:[orderTable sortDescriptors]];
    if( close )
        [self closeOlderOrders:newOrders];
    [orderTable reloadData];
    [app setToolbarMessage:NSLocalizedString(@"Finished Updating Market Orders…",@"Finished Updating Market Orders status line") time:5];
    [app stopLoadingAnimation];
}


// The default market order API call finished updating, so all open or recent market orders should be in newOrders
- (void)ordersFinishedUpdating:(NSArray *)newOrders
{
    [self updateOrders:newOrders andClose:YES];
}

// A single market order was updated
- (void)orderFinishedUpdating:(NSArray *)newOrders
{
    [self updateOrders:newOrders andClose:NO];
}

- (void)ordersSkippedUpdating
{
    [app setToolbarMessage:NSLocalizedString(@"Using Cached Market Orders…",@"Using Cached Market Orders status line") time:5];
    [app stopLoadingAnimation];
}

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView
{
    return [[self dbOrders] count];
}

/* This method is required for the "Cell Based" TableView, and is optional for the "View Based" TableView. If implemented in the latter case, the value will be set to the view at a given row/column if the view responds to -setObjectValue: (such as NSControl and NSTableCellView).
 */
- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
    if( 0 == [[self dbOrders] count] || row >= [[self dbOrders] count] )
        return nil;
    
    MarketOrder *order = [[self dbOrders] objectAtIndex:row];
    NSString *colID = [tableColumn identifier];
    id value = nil;
    
    if( [colID isEqualToString:@"typeID"] )
    {
        value = [order typeName];
    }
    else if( [colID isEqualToString:@"volEntered"] )
    {
        value = [NSNumber numberWithInteger:[order volEntered]];
    }
    else if( [colID isEqualToString:@"orderState"] )
    {
        value = [order state];
    }
    else if( [colID isEqualToString:@"stationID"] )
    {
//        value = [NSNumber numberWithUnsignedLong:[order stationID]];
        value = [order stationName];
    }
    else if( [colID isEqualToString:@"minVolume"] )
    {
        value = [NSNumber numberWithUnsignedLong:[order minVolume]];
    }
    else if( [colID isEqualToString:@"price"] )
    {
        value = [NSNumber numberWithDouble:[order price]];
    }
    else if( [colID isEqualToString:@"escrow"] )
    {
        value = [NSNumber numberWithDouble:[order escrow]];
    }
   else if( [colID isEqualToString:@"volRemaining"] )
    {
        value = [NSNumber numberWithUnsignedLong:[order volRemaining]];
    }
    else if( [colID isEqualToString:@"bid"] )
    {
        if( [order buy] )
            value = NSLocalizedString( @"Buy", @"Order Buy label" );
        else
            value = NSLocalizedString( @"Sell", @"Order Sell label" );
    }
    else if( [colID isEqualToString:@"issued"] )
    {
        value = [order issued];
    }
    else if( [colID isEqualToString:@"totalValue"] )
    {
        value = [NSNumber numberWithDouble:[order totalValue]];
    }
    else if( [colID isEqualToString:@"remainingValue"] )
    {
        value = [NSNumber numberWithDouble:[order remainingValue]];
    }

    return value;
}

-(void)tableView:(NSTableView *)tableView sortDescriptorsDidChange: (NSArray *)oldDescriptors
{
    NSArray *newDescriptors = [tableView sortDescriptors];
    [[self dbOrders] sortUsingDescriptors:newDescriptors];
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

- (NSMutableArray *)loadMarketOrders
{
    sqlite3_stmt *read_stmt;
    int rc;
    const char getMarketOrders[] = "SELECT * FROM marketOrders;";
    sqlite3 *db = [[character database] openDatabase];
    
    rc = sqlite3_prepare_v2(db,getMarketOrders,(int)sizeof(getMarketOrders),&read_stmt,NULL);
    if(rc != SQLITE_OK){
        NSLog( @"%s: sqlite error: %s", __func__, sqlite3_errmsg(db) );
        return nil;
    }
    
    NSMutableArray *messages = [NSMutableArray array];
    
    while( sqlite3_step(read_stmt) == SQLITE_ROW )
    {
        MarketOrder *order = [[MarketOrder alloc] init];
        

        [order setOrderID:sqlite3_column_nsint(read_stmt,0)];
        [order setCharID:sqlite3_column_nsint(read_stmt,1)];
        [order setStationID:sqlite3_column_nsint(read_stmt,2)];
        [order setVolEntered:sqlite3_column_nsint(read_stmt,3)];
        [order setVolRemaining:sqlite3_column_nsint(read_stmt,4)];
        [order setMinVolume:sqlite3_column_nsint(read_stmt,5)];
        [order setOrderState:(int)sqlite3_column_nsint(read_stmt,6)];
        [order setTypeID:sqlite3_column_nsint(read_stmt,7)];
        [order setRange:sqlite3_column_nsstr( read_stmt, 8 )];
        [order setAccountKey:sqlite3_column_nsint(read_stmt,9)];
        [order setDuration:sqlite3_column_nsint(read_stmt,10)];
        [order setPrice:sqlite3_column_double(read_stmt,11)];
        [order setEscrow:sqlite3_column_double(read_stmt,12)];
        [order setBuy:sqlite3_column_nsint(read_stmt,13)];
        [order setIssued:[NSDate dateWithTimeIntervalSince1970:sqlite3_column_nsint(read_stmt,14)]];
        
        [messages addObject:order];
        
        if( [order orderState] == OrderStateUnknown )
        {
            [orders requestMarketOrder:[NSNumber numberWithInteger:[order orderID]]];
        }
    }
    
    sqlite3_finalize(read_stmt);
    
    return messages;
}


- (BOOL)saveMarketOrders:(NSArray *)newOrders
{
    CharacterDatabase *charDB = [character database];
    sqlite3 *db = [charDB openDatabase];
    const char insert_market_order[] = "INSERT INTO marketOrders VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?);";
    sqlite3_stmt *insert_order_stmt;
    const char update_order[] = "UPDATE marketOrders SET volRemaining = ?, orderState = ?, price = ?, escrow = ? WHERE orderID = ?;";
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

    for( MarketOrder *order in newOrders )
    {
        sqlite3_bind_nsint( insert_order_stmt, 1, [order orderID] );
        sqlite3_bind_nsint( insert_order_stmt, 2, [order charID] );
        sqlite3_bind_nsint( insert_order_stmt, 3, [order stationID] );
        sqlite3_bind_nsint( insert_order_stmt, 4, [order volEntered] );
        sqlite3_bind_nsint( insert_order_stmt, 5, [order volRemaining] );
        sqlite3_bind_nsint( insert_order_stmt, 6, [order minVolume] );
        sqlite3_bind_nsint( insert_order_stmt, 7, [order orderState] );
        sqlite3_bind_nsint( insert_order_stmt, 8, [order typeID] );
        sqlite3_bind_text( insert_order_stmt, 9, [[order range] UTF8String], -1, NULL );
        sqlite3_bind_nsint( insert_order_stmt, 10, [order accountKey] );
        sqlite3_bind_nsint( insert_order_stmt, 11, [order duration] );
        sqlite3_bind_double( insert_order_stmt, 12, [order price] );
        sqlite3_bind_double( insert_order_stmt, 13, [order escrow] );
        sqlite3_bind_nsint( insert_order_stmt, 14, [order buy]?1:0 );
        sqlite3_bind_nsint( insert_order_stmt, 15, [[order issued] timeIntervalSince1970] ); // truncating fractions of a second
        
        rc = sqlite3_step(insert_order_stmt);
        if( SQLITE_CONSTRAINT == rc )
        {
            // Update the order in case anything has changed: volRemaining, orderState, price and escrow?
            sqlite3_bind_nsint( update_order_stmt, 1, [order volRemaining] );
            sqlite3_bind_nsint( update_order_stmt, 2, [order orderState] );
            sqlite3_bind_double( update_order_stmt, 3, [order price] );
            sqlite3_bind_double( update_order_stmt, 4, [order escrow] );
            sqlite3_bind_nsint( update_order_stmt, 5, [order orderID] );
            
            if( (rc = sqlite3_step(update_order_stmt)) != SQLITE_DONE )
            {
                NSLog( @"Error updating market order ID: %ld", (long)[order orderID] );
                success = NO;
            }
            
            sqlite3_reset(update_order_stmt);
            
        }
        else if( rc != SQLITE_DONE )
        {
            NSLog(@"Error inserting market order ID: %ld (code: %d)", (unsigned long)[order orderID], rc );
            success = NO;
        }
        sqlite3_reset(insert_order_stmt);
    }
    
    sqlite3_finalize(insert_order_stmt);
    sqlite3_finalize(update_order_stmt);
    return success;
}

- (BOOL)orders:(NSArray *)localOrders containsOrderID:(NSInteger)orderID
{
    NSUInteger index = [localOrders indexOfObjectPassingTest:^BOOL (id el, NSUInteger i, BOOL *stop)
     {
         BOOL res = [(MarketOrder *)el orderID] == orderID;
         if( res )
             *stop = YES;
         return res;
     }];
    return NSNotFound != index;
}

// Try to find orders that slipped through the cracks and see if they are closed or expired
- (BOOL)closeOlderOrders:(NSArray *)newOrders
{
    NSMutableArray *changes = [NSMutableArray array];
    // filter dbOrders for ones that have state open or unknown
    // for each, if it is not in newOrders, then request that order specifically from the API
    NSIndexSet *indexes = [[self dbOrders] indexesOfObjectsPassingTest:^BOOL (id el, NSUInteger i, BOOL *stop)
    {
        if( [(MarketOrder *)el orderState] == OrderStateActive )
            return YES;
        else if( [(MarketOrder *)el orderState] == OrderStateUnknown )
            return YES;
        return NO;
    }];
    NSArray *openOrders = [[self dbOrders] objectsAtIndexes:indexes];
    
    for( MarketOrder *order in openOrders )
    {
        BOOL res = [self orders:newOrders containsOrderID:[order orderID]];
        if( !res )
        {
            // request this market order by id
            [order setOrderState:OrderStateUnknown]; // for now just set it to unknown
            [orders requestMarketOrder:[NSNumber numberWithInteger:[order orderID]]];
            [changes addObject:order];
        }
    }
    
//    if( [changes count] > 0 )
//        [self saveMarketOrders:changes];
    
    return YES;
}
@end
