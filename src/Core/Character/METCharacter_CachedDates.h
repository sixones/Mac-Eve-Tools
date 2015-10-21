//
//  METCharacter_CachedDates.h
//  Vitality
//
//  Created by Andrew Salamon on 10/20/15.
//  Copyright (c) 2015 Vitality Project. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Character.h"

@interface Character(CachedDates)
- (void)setCachedUntil:(NSDate *)date forAPI:(NSString *)apiPath;
- (BOOL)isCachedForAPI:(NSString *)apiPath;
@end
