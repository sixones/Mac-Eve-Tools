//
//  IndustryJobs.h
//  Vitality
//
//  Created by Andrew Salamon on 5/16/2016.
//  Copyright (c) 2016 The Vitality Project. All rights reserved.
//

#import <Foundation/Foundation.h>

@class Character;
@class METRowsetEnumerator;

@interface IndustryJobs : NSObject
{
    Character *_character;
    NSMutableArray *_jobs;
    METRowsetEnumerator *industryJobsAPI;

    id _delegate;    
}
@property (retain) Character *character;
@property (retain) NSMutableArray *jobs;
@property (readwrite,assign) id delegate;

- (IBAction)reload:(id)sender;
- (void)sortUsingDescriptors:(NSArray *)descriptors;

- (void)requestIndustryJob:(NSNumber *)jobID;
@end
