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

@implementation MarketViewController

@synthesize character;

-(id) init
{
	if( (self = [super initWithNibName:@"MarketView" bundle:nil]) )
    {
        orders = [[MarketOrders alloc] init];
        [orders setDelegate:self];
//        NSSortDescriptor *defaultSort = [NSSortDescriptor sortDescriptorWithKey:@"issued" ascending:YES selector:@selector(compare:)];
//        [orders sortUsingDescriptors:[NSArray arrayWithObject:defaultSort]];
	}
    
	return self;
}

- (void)dealloc
{
    [orders release];
    [character release];
    [app release];
    [super dealloc];
}

- (void)awakeFromNib
{
    [currencyFormatter setCurrencySymbol:@""];
}

- (void)setCharacter:(Character *)_character
{
    if( _character != character )
    {
        [character release];
        character = [_character retain];
        // if view is active we need to reload market orders
        [orders setCharacter:character];
        [orders reload:self];
        [app setToolbarMessage:NSLocalizedString(@"Updating Market Orders…",@"Updating Market Orders")];
        [app startLoadingAnimation];
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

- (void)ordersFinishedUpdating
{
    NSArray *newDescriptors = [orderTable sortDescriptors];
    [orders sortUsingDescriptors:newDescriptors];
    [orderTable reloadData];
    [app setToolbarMessage:NSLocalizedString(@"Finished Updating Market Orders…",@"Finished Updating Market Orders status line") time:5];
    [app stopLoadingAnimation];
}

- (void)ordersSkippedUpdating
{
    [app setToolbarMessage:NSLocalizedString(@"Using Cached Market Orders…",@"Using Cached Market Orders status line") time:5];
    [app stopLoadingAnimation];
}

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView
{
    return [[orders orders] count];
}

/* This method is required for the "Cell Based" TableView, and is optional for the "View Based" TableView. If implemented in the latter case, the value will be set to the view at a given row/column if the view responds to -setObjectValue: (such as NSControl and NSTableCellView).
 */
- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
    if( 0 == [[orders orders] count] )
        return nil;
    
    MarketOrder *order = [[orders orders] objectAtIndex:row];
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

    return value;
}

-(void)tableView:(NSTableView *)tableView sortDescriptorsDidChange: (NSArray *)oldDescriptors
{
    NSArray *newDescriptors = [tableView sortDescriptors];
    [orders sortUsingDescriptors:newDescriptors];
    [tableView reloadData];
}
@end
