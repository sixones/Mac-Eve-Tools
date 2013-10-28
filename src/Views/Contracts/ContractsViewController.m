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

@implementation ContractsViewController

@synthesize character;

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
    [super dealloc];
}

- (void)awakeFromNib
{
    [currencyFormatter setCurrencySymbol:@""];
    [orderTable setDoubleAction:@selector(contractsDoubleClick:)];
    [orderTable setTarget:self];
}

- (void)setCharacter:(Character *)_character
{
    if( _character != character )
    {
        [character release];
        character = [_character retain];
        // if view is active we need to reload contracts
        [contracts setCharacter:character];
        [contracts reload:self];
        [app setToolbarMessage:NSLocalizedString(@"Updating Contracts…",@"Updating Contracts status line")];
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
    [contracts reload:self];
    [app setToolbarMessage:NSLocalizedString(@"Updating Contracts…",@"Updating Contracts status line")];
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

- (void)contractsFinishedUpdating
{
    NSArray *newDescriptors = [orderTable sortDescriptors];
    [contracts sortUsingDescriptors:newDescriptors];
    [orderTable reloadData];
    [app setToolbarMessage:NSLocalizedString(@"Finished Updating Contracts…",@"Finished Updating Contracts status line") time:5];
    [app stopLoadingAnimation];
}

- (void)contractsDoubleClick:(id)sender
{
    NSInteger rowNumber = [orderTable clickedRow];
    Contract *contract = [[contracts contracts] objectAtIndex:rowNumber];
    [ContractDetailsController displayContract:contract forCharacter:character];
}

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView
{
    return [[contracts contracts] count];
}

/* This method is required for the "Cell Based" TableView, and is optional for the "View Based" TableView. If implemented in the latter case, the value will be set to the view at a given row/column if the view responds to -setObjectValue: (such as NSControl and NSTableCellView).
 */
- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
    if( 0 == [[contracts contracts] count] )
        return nil;
        
    Contract *contract = [[contracts contracts] objectAtIndex:row];
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
    [tableView reloadData];
}
@end
