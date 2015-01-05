//
//  MetTableHeaderMenuManager.h
//  Vitality
//
//  Created by Andrew Salamon on 3/27/14.
//  Copyright (c) 2014 Andrew Salamon. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
 Allocate an object to manage a header menu that let's the user hide or show table columns.
 If the user re-orders columns the menu will be updated to reflect the new order.
 */
@interface MetTableHeaderMenuManager : NSObject
{
    NSTableView *_table;
    NSMenu *_menu;
}

@property (retain,readonly) NSTableView *table;
@property (retain,readonly) NSMenu *menu;

/**
 @param menu If nil a new menu will be created, otherwise menu items will be added to the end
 @param table The menu will be added to the header of this table
 */
- (id)initWithMenu:(NSMenu *)menu forTable:(NSTableView *)table;

/** If the number of columns, or the name of any column changes, call reset. */
- (void)reset;
@end
