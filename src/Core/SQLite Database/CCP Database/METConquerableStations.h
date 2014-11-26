//
//  METConquerableStations.h
//  Mac Eve Tools
//
//  Created by Andrew Salamon on 5/17/13.
//  Copyright (c) 2013 Sebastian Kruemling. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface METConquerableStations : NSObject
{
    NSMutableData *xmlData;
    NSDate *_cachedUntil;
}

@property (readonly,retain) NSDate *cachedUntil;

+ (NSString *)reloadNotificationName; ///< This notification will be sent when a reload is finished

- (IBAction)reload:(id)sender;
@end
