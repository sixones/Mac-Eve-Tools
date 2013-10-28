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

@implementation ContractDetailsController

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
    	
	[super dealloc];
}

-(ContractDetailsController *)initWithType:(Contract *)_contract forCharacter:(Character*)ch
{
	if( self = [super initWithWindowNibName:@"ContractDetails"] )
    {
		contract = [_contract retain];
		character = [ch retain];
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
    
    [self setVolumeLabel];
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
@end
