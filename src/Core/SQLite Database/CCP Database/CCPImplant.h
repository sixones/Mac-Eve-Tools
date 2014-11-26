//
//  CCPImplant.h
//  Vitality
//
//  Created by Andrew Salamon on 11/24/14.
//  Copyright (c) 2014 Sebastian Kruemling. All rights reserved.
//

@class CCPType;

/* Represents an implant or booster.
 Currently it only handles the attribute modifier effects,
 ignoring any fitting, damage or other effects.
 */
@interface CCPImplant : NSObject
{
    CCPType *_type;
    NSInteger charisma;
    NSInteger intelligence;
    NSInteger memory;
    NSInteger perception;
    NSInteger willpower;
}

@property (retain,readwrite) CCPType *type;
@property (assign) NSInteger charisma;
@property (assign) NSInteger intelligence;
@property (assign) NSInteger memory;
@property (assign) NSInteger perception;
@property (assign) NSInteger willpower;

/* Because of the way types are read from the database we can't sub-class CCPImplant from CCType the
 way we should. Instead we'll just retain a pointer to the underlying type which will hold typeID, name, etc.
 */
- (id)initWithType:(CCPType *)_type;

- (NSInteger)typeID;
- (NSString *)typeName;
- (NSString *)typeDescription;

@end
