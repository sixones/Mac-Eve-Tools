//
//  METFitting.h
//  Vitality
//
//  Created by Andrew Salamon on 6/22/15.
//  Copyright (c) 2015 Sebastian Kruemling. All rights reserved.
//

#import <Foundation/Foundation.h>

@class CCPType;

@interface METFitting : NSObject
{
    NSString *_name;
    CCPType *_ship;
    NSMutableArray *items;
    NSCountedSet *itemCounts;
}
@property (retain,readwrite) NSString *name;
@property (retain,readwrite) CCPType *ship;

+ (METFitting *)fittingFromDNA:(NSString *)dna;

- (void)addCount:(NSInteger)count ofType:(CCPType *)type;

- (NSArray *)items;
- (NSInteger)countOfItem:(CCPType *)item;
@end
