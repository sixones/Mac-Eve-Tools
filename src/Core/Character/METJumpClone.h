//
//  METJumpClone.h
//  Vitality
//
//  Created by Andrew Salamon on 5/5/15.
//  Copyright (c) 2015 Sebastian Kruemling. All rights reserved.
//

#import <Foundation/Foundation.h>

@class CCPImplant;

/* TODO: Parse and display jump clones
 <rowset name="jumpClones" key="jumpCloneID" columns="jumpCloneID,typeID,locationID,cloneName">
 <row jumpCloneID="19933997" typeID="164" locationID="60010825" cloneName="" />
 <row jumpCloneID="20412514" typeID="164" locationID="60010861" cloneName="" />
 <row jumpCloneID="20842890" typeID="164" locationID="61000260" cloneName="" />
 </rowset>
 <rowset name="jumpCloneImplants" key="jumpCloneID" columns="jumpCloneID,typeID,typeName">
 <row jumpCloneID="19933997" typeID="9899" typeName="Ocular Filter - Basic" />
 <row jumpCloneID="19933997" typeID="9941" typeName="Memory Augmentation - Basic" />
 <row jumpCloneID="19933997" typeID="9942" typeName="Neural Boost - Basic" />
 <row jumpCloneID="19933997" typeID="9943" typeName="Cybernetic Subprocessor - Basic" />
 </rowset>
 */
@interface METJumpClone : NSObject
{
    NSInteger _jumpCloneID;
    NSInteger _typeID; // always 164?
    NSInteger _locationID;
    NSString *_cloneName;
    NSMutableArray *_implants;
    NSString *_locationName;
}

@property (assign, readonly) NSInteger jumpCloneID;
@property (assign, readwrite) NSInteger typeID;
@property (assign, readwrite) NSInteger locationID;
@property (retain, readwrite) NSString *cloneName;

- (id)initWithID:(NSInteger)_id;

- (void)addImplant:(CCPImplant *)implant;
- (NSArray *)implants;

- (NSString *)locationName;
@end
