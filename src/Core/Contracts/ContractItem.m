//
//  ContractItem.m
//  Vitality
//
//  Created by Andrew Salamon on 10/31/13.
//  Copyright (c) 2013 Sebastian Kruemling. All rights reserved.
//

#import "ContractItem.h"

#import "GlobalData.h"
#import "CCPType.h"
#import "CCPDatabase.h"

@interface ContractItem()
@property (readwrite,retain) NSString *name;
@property (readwrite,retain) NSString *description;
@end

@implementation ContractItem
@synthesize typeID;
@synthesize quantity;
@synthesize rawQuantity;
@synthesize singleton;
@synthesize included;
@synthesize name = _name;
@synthesize description = _description;

- (void)pullFromDB
{
    CCPDatabase *db = [[GlobalData sharedInstance] database];
    NSString *desc = nil;
    NSString *nm = [db typeName:[self typeID] andDescription:&desc];
    [self setName:nm];
    [self setDescription:desc];
}

- (NSString *)name
{
    if( nil == _name )
    {
        [self pullFromDB];
    }
    if( nil == _name )
    {
        return [NSString stringWithFormat:@"(id=%ld)",[self typeID]];
    }
    return _name;
}

- (void)setName:(NSString *)newName
{
    if( newName != _name )
    {
        [_name release];
        _name = [newName retain];
    }
}

- (NSString *)description
{
    if( nil == _description )
    {
        [self pullFromDB];
    }
    return _description;
}

- (void)setDescription:(NSString *)newDescription
{
    if( newDescription != _description )
    {
        [_description release];
        _description = [newDescription retain];
    }
}
@end
