//
//  MetTableHeaderMenuManager.m
//  Vitality
//
//  Created by Andrew Salamon on 3/27/14.
//  Copyright (c) 2014 Andrew Salamon. All rights reserved.
//

#import "MetTableHeaderMenuManager.h"

@interface MetTableHeaderMenuManager()
@property (retain,readwrite) NSTableView *table;
@property (retain,readwrite) NSMenu *menu;
@end

@implementation MetTableHeaderMenuManager

@synthesize table;
@synthesize menu;

- (id)initWithMenu:(NSMenu *)_menu forTable:(NSTableView *)_table
{
    if( self = [super init] )
    {
        if( !_menu )
            _menu = [[[NSMenu alloc] init] autorelease];
        [self setTable:_table];
        [self setMenu:_menu];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(tableViewColumnDidMove:) name:NSTableViewColumnDidMoveNotification object:[self table]];

        [self reset];
    }
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [menu release];
    [table release];
    [super dealloc];
}

- (void)reset
{
    [self clearMenu];
    [[[self table] headerView] setMenu:[self menu]];
    
    //loop through columns, creating a menu item for each
    for( NSTableColumn *col in [[self table] tableColumns] )
    {
        // TODO: Use something like this if we want some columns to be un-hideable
        //        if ([[col identifier] isEqualToString:COLUMNID_NAME])
        //            continue;   // Cannot hide name column
        NSMenuItem *mi = [[NSMenuItem alloc] initWithTitle:[col.headerCell stringValue] action:@selector(toggleColumn:)  keyEquivalent:@""];
        mi.target = self;
        mi.representedObject = col;
        [[self menu] addItem:mi];
    }
}

- (void)clearMenu
{
    for( NSMenuItem *item in [[self menu] itemArray] )
    {
        if( ([item target] == self) && ([item action] == @selector(toggleColumn:)) )
        {
            [[self menu] removeItem:item];
        }
    }
}

- (IBAction)toggleColumn:(id)sender
{
    NSTableColumn *col = [sender representedObject];
    [col setHidden:![col isHidden]];
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

- (void)tableViewColumnDidMove:(NSNotification *)notification
{
    [self reset];
}
@end
