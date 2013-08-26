//
//  Contract.h
//  Mac Eve Tools
//
//  Created by Andrew Salamon on 8/21/13.
//  Copyright (c) 2013 Andrew Salamon. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef enum {
    OrderStateActive = 0, // or open
    OrderStateClosed = 1,
    OrderStateExpired = 2, // (or fulfilled),
    OrderStateCancelled = 3,
    OrderStatePending = 4,
    OrderStateCharacterDeleted = 5,
    OrderStateUnknown = -1
} OrderStateType;

@interface Contract : NSObject

@property (assign) NSUInteger orderID;
@property (assign) NSUInteger charID;
@property (assign) NSUInteger stationID;
@property (assign) NSUInteger volEntered;
@property (assign) NSUInteger volRemaining;
@property (assign) NSUInteger minVolume;
@property (assign) OrderStateType orderState;
@property (assign) NSUInteger typeID;
@property (retain) NSString *range;
@property (assign) NSUInteger accountKey;
@property (assign) double price;
@property (assign) double escrow;
@property (assign) BOOL buy; // if false = sell order
@property (retain) NSDate *issued;
@property (readonly,retain) NSString *stationName;

- (NSString *)typeName;
- (NSString *)state;
@end
