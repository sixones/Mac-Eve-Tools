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

@interface ContractsViewController : NSViewController <METPluggableView,NSTableViewDataSource>
{
    IBOutlet NSTableView *orderTable;
    IBOutlet NSNumberFormatter *currencyFormatter;
    
    Character *character;
    id<METInstance> app;
    Contracts *contracts;
}
@property (readwrite,retain,nonatomic) Character *character;
@end
