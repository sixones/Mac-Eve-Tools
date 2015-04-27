//
//  ContractItem.h
//  Vitality
//
//  Created by Andrew Salamon on 10/31/13.
//  Copyright (c) 2013 Sebastian Kruemling. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ContractItem : NSObject
{
    NSInteger _recordID;
    NSUInteger _typeID;
    long _quantity;
    long _rawQuantity;
    BOOL _singleton;
    BOOL _included;
    NSString *_name;
    NSString *_description;
}
@property (assign) NSInteger recordID; // unique but otherwise meaningless key
@property (assign) NSUInteger typeID;
@property (assign) long quantity;
@property (assign) long rawQuantity;
@property (assign) BOOL singleton;
@property (assign) BOOL included;
@property (readonly) NSString *name;
@property (readonly) NSString *description;
@end

