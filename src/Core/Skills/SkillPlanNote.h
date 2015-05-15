//
//  SkillPlanNote.h
//  Vitality
//
//  Created by Andrew Salamon on 5/14/15.
//  Copyright (c) 2015 Sebastian Kruemling. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SkillPlanNote : NSObject<NSCoding>
{
    NSString *_note;
}
@property (retain,readwrite) NSString *note;

+ (SkillPlanNote *)skillPlanNoteWithString:(NSString *)note;

- (id)initWithString:(NSString *)note;
@end
