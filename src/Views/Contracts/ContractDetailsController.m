/*
 This file is part of Mac Eve Tools.
 
 Mac Eve Tools is free software: you can redistribute it and/or modify
 it under the terms of the GNU General Public License as published by
 the Free Software Foundation, either version 3 of the License, or
 (at your option) any later version.
 
 Mac Eve Tools is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 GNU General Public License for more details.
 
 You should have received a copy of the GNU General Public License
 along with Mac Eve Tools.  If not, see <http://www.gnu.org/licenses/>.
 
 Copyright Matt Tyson, 2009.
 */

#import "ContractDetailsController.h"
#import "Character.h"
#import "Contract.h"
#import "MTISKFormatter.h"
#import "ContractItem.h"

@interface ContractDetailsController()
@property (readwrite,retain) NSArray *labels;
@property (readwrite,retain) NSArray *values;
@end

@implementation ContractDetailsController

@synthesize labels;
@synthesize values;

-(void)awakeFromNib
{
}

-(void)dealloc
{
	[contract release];
	[character release];
	[iskFormatter release];
    [labels release];
    [values release];
    
	[super dealloc];
}

-(ContractDetailsController *)initWithType:(Contract *)_contract forCharacter:(Character*)ch
{
	if( self = [super initWithWindowNibName:@"ContractDetails"] )
    {
		contract = [_contract retain];
		character = [ch retain];
        iskFormatter = [[MTISKFormatter alloc] init];

        [_contract setDelegate:self];
        [_contract preloadItems];
        [_contract preloadNames];

        [self buildLabelsAndValues];
	}
	return self;
}

+(void) displayContract:(Contract *)_contract forCharacter:(Character*)ch;
{
    // Suppress the clang analyzer warning. There's probably a better way to do this
#ifndef __clang_analyzer__
	ContractDetailsController *wc = [[ContractDetailsController alloc] initWithType:_contract forCharacter:ch];
	
    [[wc window] makeKeyAndOrderFront:nil];
#endif
}

-(void)buildLabelsAndValues
{
    NSMutableArray *_labels = [NSMutableArray array];
    NSMutableArray *_values = [NSMutableArray array];
    BOOL isCourier = [[contract type] isEqualToString:@"Courier"];
    
    [_labels addObject:@"Type"];
    [_values addObject:[contract type]];

    [_labels addObject:@"Status"];
    [_values addObject:[contract status]];

    [_labels addObject:@"Contract ID"];
    [_values addObject:[NSString stringWithFormat:@"%ld",[contract contractID]]];

    [_labels addObject:@"Start"];
    [_values addObject:[contract startStationName]];
    
    if( isCourier )
    {
        [_labels addObject:@"End"];
        [_values addObject:[contract endStationName]];
    }

    
    id value = nil;
    
    value = [contract issuerName];
    [_labels addObject:@"Issuer"];
    [_values addObject:(value?value:[NSNumber numberWithInteger:[contract issuerID]])];

    value = [contract issuerCorpName];
    [_labels addObject:@"Corporation"];
    [_values addObject:(value?value:[NSNumber numberWithInteger:[contract issuerCorpID]])];
    
    // skip this for non-courier contracts?
    if( [contract assigneeID] != 0 )
    {
        value = [contract assigneeName];
        [_labels addObject:@"Assignee"];
        [_values addObject:(value?value:[NSNumber numberWithInteger:[contract assigneeID]])];
    }
    
    if( [contract acceptorID] != 0 )
    {
        value = [contract acceptorName];
        [_labels addObject:@"Acceptor"];
        [_values addObject:(value?value:[NSNumber numberWithInteger:[contract acceptorID]])];
    }
    
    [_labels addObject:@"Volume"];
    NSString *withSeparators = [NSNumberFormatter localizedStringFromNumber:[NSNumber numberWithDouble:[contract volume]] numberStyle:NSNumberFormatterDecimalStyle];
    // need to figure out how to specify 2 decimal places
    [_values addObject:[NSString stringWithFormat:@"%@ m\u00B3",withSeparators]];
    
    NSString *price = [iskFormatter stringFromNumber:[NSNumber numberWithDouble:[contract price]]];
    if( price )
    {
        [_labels addObject:@"Price"];
        [_values addObject:price];
    }
    
    if( isCourier )
    {
        [_labels addObject:@"Reward"];
        [_values addObject:[iskFormatter stringFromNumber:[NSNumber numberWithDouble:[contract reward]]]];

        [_labels addObject:@"Collateral"];
        [_values addObject:[iskFormatter stringFromNumber:[NSNumber numberWithDouble:[contract collateral]]]];
    }
    
    if( [[contract type] isEqualToString:@"Auction"] )
    {
        [_labels addObject:@"Buyout"];
        [_values addObject:[iskFormatter stringFromNumber:[NSNumber numberWithDouble:[contract buyout]]]];
    }
    
    [_labels addObject:@"Issued"];
    [_values addObject:[contract issued]];
    
    NSDate *completed = [contract completed];
    NSDate *expired = [contract expired];
    
    if( (!completed && expired) || (completed && ([expired compare:completed] == NSOrderedAscending)) )
    {
        BOOL future = [expired compare:[NSDate date]] == NSOrderedDescending;
        if( future )
            [_labels addObject:@"Expires"];
        else
            [_labels addObject:@"Expired"];
        [_values addObject:[contract expired]];
    }
    
    if( isCourier && [contract accepted] )
    {
        [_labels addObject:@"Accepted"];
        [_values addObject:[contract accepted]];
    }
    
    if( completed )
    {
        [_labels addObject:@"Completed"];
        [_values addObject:[contract completed]];
    }
    
    [self setLabels:_labels];
    [self setValues:_values];
}

#pragma mark Delegates

-(void) windowDidLoad
{
	//[[self window] setTitle:[NSString stringWithFormat:@"%@ - %@",[[self window]title],[ship typeName]]];
	
	[[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(windowWillClose:)
                                                 name:NSWindowWillCloseNotification
                                               object:[self window]];		
}

-(void) windowWillClose:(NSNotification*)sender
{
	[[NSNotificationCenter defaultCenter]removeObserver:self];
	[self autorelease];
}

#pragma mark Table View methods

- (BOOL)tableView:(NSTableView *)aTableView 
shouldEditTableColumn:(NSTableColumn *)aTableColumn 
			  row:(NSInteger)rowIndex
{
	return NO;
}

- (void)contractItemsFinishedUpdating
{
    [itemTable reloadData];
}

- (void)contractNamesFinishedUpdating
{
    [self buildLabelsAndValues];
    [valuesTable reloadData];
}

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView
{
    if( valuesTable == tableView )
        return [[self labels] count];
    else if( itemTable == tableView )
        return [[contract items] count];
    return 0;
}

- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
    NSString *colID = [tableColumn identifier];
    id value = nil;

    if( valuesTable == tableView )
    {
        if( [colID isEqualToString:@"label"] )
        {
            value = [[self labels] objectAtIndex:row];
        }
        else if( [colID isEqualToString:@"value"] )
        {
            value = [[self values] objectAtIndex:row];
            if( [value isKindOfClass:[NSDate class]] )
                value = [NSDateFormatter localizedStringFromDate:value dateStyle:NSDateFormatterLongStyle timeStyle:NSDateFormatterShortStyle];
        }
        return value;
    }
    else if( itemTable == tableView )
    {
        if( row >= [[contract items] count] )
            return nil;
        
        ContractItem *item = [[contract items] objectAtIndex:row];
        
        if( [colID isEqualToString:@"name"] )
        {
            value = [item name];
        }
        else if( [colID isEqualToString:@"quantity"] )
        {
            value = [NSNumber numberWithInteger:[item quantity]];
        }
        
        return value;
    }
    
    return nil;
}

-(void)tableView:(NSTableView *)tableView sortDescriptorsDidChange: (NSArray *)oldDescriptors
{
    NSArray *newDescriptors = [tableView sortDescriptors];
    [[contract items] sortUsingDescriptors:newDescriptors];
    [tableView reloadData];
}

- (NSString *)tableView:(NSTableView *)tableView toolTipForCell:(NSCell *)cell rect:(NSRectPointer)rect tableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row mouseLocation:(NSPoint)mouseLocation
{
    if( valuesTable == tableView )
    {
        return nil;
    }
    else if( itemTable == tableView )
    {
        
        if( 0 == [[contract items] count] )
            return nil;
        
        ContractItem *item = [[contract items] objectAtIndex:row];
        return [item description];
    }
    return nil;
}

- (IBAction)copy:(id)sender
{
    NSPasteboard *pboard = [NSPasteboard generalPasteboard];
    [pboard declareTypes:[NSArray arrayWithObject:NSStringPboardType] owner:self];

    NSString *str = [contract description];
    NSData *data = [str dataUsingEncoding:NSUTF8StringEncoding];
    
    [pboard setData:data forType:NSStringPboardType];
}
@end
