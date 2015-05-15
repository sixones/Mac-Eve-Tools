//
//  SkillPlanNote.m
//  Vitality
//
//  Created by Andrew Salamon on 5/14/15.
//  Copyright (c) 2015 Sebastian Kruemling. All rights reserved.
//

#import "SkillPlanNote.h"

@interface SkillPlanNote()
@property (retain,readwrite) NSString *note;
@end

@implementation SkillPlanNote

@synthesize note = _note;

+ (SkillPlanNote *)skillPlanNoteWithString:(NSString *)note
{
    return [[[SkillPlanNote alloc] initWithString:note] autorelease];
}

- (id)initWithString:(NSString *)note
{
    if( self = [super init] )
    {
        _note = [note retain];
    }
    return self;
}

- (NSNumber *)typeID
{
    return [NSNumber numberWithInt:-1];
}

- (NSInteger)skillLevel
{
    return 0;
}

- (void)encodeWithCoder:(NSCoder *)encoder
{
    [encoder encodeObject:[self note] forKey:@"noteString"];
}

- (id)initWithCoder:(NSCoder *)decoder
{
    NSString *newNote = [decoder decodeObjectForKey:@"noteString"];
    return [self initWithString:newNote];
}

@end
