//
//  METTrait.h
//  Vitality
//
//  Created by Andrew Salamon on 7/21/14.
//  Copyright (c) 2014 Sebastian Kruemling. All rights reserved.
//

#import <Foundation/Foundation.h>

/*
 sqlite> .schema invTraitsCREATE TABLE "invTraits" (
 "typeID" int(11) NOT NULL,
 "skillID" int(11) DEFAULT NULL,
 "bonus" double DEFAULT NULL,
 "bonusText" varchar(3000),
 "unitID" int(11) DEFAULT NULL
 */

@interface METTrait : NSObject
{
    NSString *_skillName;
    double _bonus;
    NSString *_bonusString;
    NSString *_unitString;
}

@property (readwrite,retain) NSString *skillName;
@property (readwrite) double bonus;
@property (readwrite,retain) NSString *bonusString;
@property (readwrite,retain) NSString *unitString;

- (NSComparisonResult)compare:(id)other;
@end
