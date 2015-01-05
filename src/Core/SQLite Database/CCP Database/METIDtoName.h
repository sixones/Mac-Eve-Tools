//
//  METIDtoName.h
//  Vitality
//
//  Created by Andrew Salamon on 5/17/13.
//  Copyright (c) 2013 Sebastian Kruemling. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol METIDtoNameDelegate<NSObject>
- (void)namesFromIDs:(NSDictionary *)names;
@end

@interface METIDtoName : NSObject
{
    NSMutableData *xmlData;
    NSMutableDictionary *cachedNames; // temporary cache only. Actual data is pulled from the local database or an API call

    id _delegate;
    NSDate *_cachedUntil;
}

@property (readwrite,assign) id delegate;
@property (readonly,retain) NSDate *cachedUntil;

// Check the local database first.
// If all of the ID's are found, immediately call namesFromIDs: on the delegate
// If some of the ID's are not found, start an API request
// when an API request is finished call namesFromIDs: on the delegate
- (void)namesForIDs:(NSSet *)IDs;
@end
