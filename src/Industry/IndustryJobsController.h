//
//  IndustryJobsController.h
//  Vitality
//
//  Created by Andrew Salamon on 5/16/2016.
//  Copyright (c) 2016 The Vitality Project. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "METPluggableView.h"

@class IndustryJobs;
@class MetTableHeaderMenuManager;

@interface IndustryJobsController : NSViewController <METPluggableView,NSTableViewDataSource>
{
    IBOutlet NSTableView *jobsTable;
    IBOutlet NSNumberFormatter *currencyFormatter;
    
    Character *character;
    id<METInstance> app;
    IndustryJobs *jobs;
    MetTableHeaderMenuManager *headerMenuManager;
    NSMutableArray *dbJobs; // orders pulled from the database
}
@property (readwrite,retain,nonatomic) Character *character;
@property (readonly,retain) NSMutableArray *dbJobs;
@end
