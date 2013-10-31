//
//  ContractItem.h
//  Vitality
//
//  Created by Andrew Salamon on 10/31/13.
//  Copyright (c) 2013 Sebastian Kruemling. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ContractItem : NSObject
@property (assign) NSUInteger typeID;
@property (assign) long quantity;
@property (assign) long rawQuantity;
@property (assign) BOOL singleton;
@property (assign) BOOL included;
@property (readonly) NSString *name;
@property (readonly) NSString *description;
@end

