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
#import "MetLabelValueTableCellView.h"

@interface ContractDetailsController()
@property (readwrite,retain) NSArray *labels;
@property (readwrite,retain) NSArray *values;
@end

@implementation ContractDetailsController

@synthesize labels;
@synthesize values;

-(void)awakeFromNib
{
    iskFormatter = [[MTISKFormatter alloc] init];
    [priceField setFormatter:iskFormatter];
    [rewardField setFormatter:iskFormatter];
    [collateralField setFormatter:iskFormatter];
    [buyoutField setFormatter:iskFormatter];
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
        [_contract setDelegate:self];
        [_contract preloadItems];
        [self buildLabelsAndValues];
	}
	return self;
}

+(void) displayContract:(Contract *)_contract forCharacter:(Character*)ch;
{
	ContractDetailsController *wc = [[ContractDetailsController alloc] initWithType:_contract forCharacter:ch];
	
    [[wc window] makeKeyAndOrderFront:nil];
}

-(void) setVolumeLabel
{
    // display using the unicode character for a superscripted 3
    NSString *volString = [NSString stringWithFormat:@"%.2lf m\u00B3",[contract volume]]; // this should be changed to use a custom "cubic meter" number formatter
    [volumeField setStringValue:volString];
}

-(void) setLabels
{    
    [typeField setStringValue:[contract type]];
    [statusField setStringValue:[contract status]];
    [contractIDField setIntegerValue:[contract contractID]];
    [startStationField setStringValue:[contract startStationName]];
    [endStationField setStringValue:[contract endStationName]];
    [priceField setDoubleValue:[contract price]];
    [rewardField setDoubleValue:[contract reward]];
    [collateralField setDoubleValue:[contract collateral]];
    [buyoutField setDoubleValue:[contract buyout]];
    [issuedField setObjectValue:[contract issued]];
    [expiredField setObjectValue:[contract expired]];
    [acceptedField setObjectValue:[contract accepted]];
    [completedField setObjectValue:[contract completed]];
    
    [self setVolumeLabel];
}

-(void)buildLabelsAndValues
{
    NSMutableArray *_labels = [NSMutableArray array];
    NSMutableArray *_values = [NSMutableArray array];
    
    [_labels addObject:@"Type"];
    [_values addObject:[contract type]];

    [_labels addObject:@"Status"];
    [_values addObject:[contract status]];

    [_labels addObject:@"Contract ID"];
    [_values addObject:[NSString stringWithFormat:@"%ld",[contract contractID]]];

    [_labels addObject:@"Start"];
    [_values addObject:[contract startStationName]];
    
    if( [[contract type] isEqualToString:@"Courier"] )
    {
        [_labels addObject:@"End"];
        [_values addObject:[contract endStationName]];
    }

#pragma mark TODO Finish building the labels and values arrays
    
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
		
	[self setLabels];		
}

-(void) windowWillClose:(NSNotification*)sender
{
	[[NSNotificationCenter defaultCenter]removeObserver:self];
	[self autorelease];
}

#pragma mark Delegates for the attributes

- (BOOL)tableView:(NSTableView *)aTableView 
shouldEditTableColumn:(NSTableColumn *)aTableColumn 
			  row:(NSInteger)rowIndex
{
	return NO;
}

- (BOOL)outlineView:(NSOutlineView *)outlineView 
shouldEditTableColumn:(NSTableColumn *)tableColumn 
			   item:(id)item
{
	return NO;
}

#pragma mark Table View methods
- (void)contractItemsFinishedUpdating
{
    [itemTable reloadData];
}

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView
{
    if( valuesTable == tableView )
        return [[self labels] count];
    return [[contract items] count];
}

- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
    if( 0 == [[contract items] count] )
        return nil;
    
    ContractItem *item = [[contract items] objectAtIndex:row];
    NSString *colID = [tableColumn identifier];
    id value = nil;
    
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

- (id)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
    if( tableView == itemTable )
        return nil;
    
    if( tableView == valuesTable )
    {
        MetLabelValueTableCellView *cellView = [tableView makeViewWithIdentifier:@"LabelValue" owner:self];
        cellView.labelTextField.stringValue = [[self labels] objectAtIndex:row]; // localize this
        cellView.valueTextField.stringValue = [[self values] objectAtIndex:row];
        return cellView;
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
    if( 0 == [[contract items] count] )
        return nil;

    ContractItem *item = [[contract items] objectAtIndex:row];
    return [item description];
}

@end
