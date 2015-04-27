//
//  MarketViewController.h
//  Mac Eve Tools
//
//  Created by Andrew Salamon on 5/20/13.
//  Copyright (c) 2013 Sebastian Kruemling. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "METPluggableView.h"

@class Contracts;
@class MetTableHeaderMenuManager;

@interface ContractsViewController : NSViewController <METPluggableView,NSTableViewDataSource>
{
    IBOutlet NSTableView *contractsTable;
    IBOutlet NSNumberFormatter *currencyFormatter;
    
    Character *character;
    id<METInstance> app;
    Contracts *contracts;
    MetTableHeaderMenuManager *headerMenuManager;
    NSMutableArray *dbContracts; // contracts pulled from the database
}
@property (readwrite,retain,nonatomic) Character *character;
@property (readwrite,retain) NSMutableArray *dbContracts;
@end
