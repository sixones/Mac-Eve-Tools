/*
 This file is part of Vitality.
 
 Vitality is free software: you can redistribute it and/or modify
 it under the terms of the GNU General Public License as published by
 the Free Software Foundation, either version 3 of the License, or
 (at your option) any later version.
 
 Vitality is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 GNU General Public License for more details.
 
 You should have received a copy of the GNU General Public License
 along with Vitality.  If not, see <http://www.gnu.org/licenses/>.
 
 Copyright Vitality Project, 2015.
 */

#import <Cocoa/Cocoa.h>

/**
 METPair. A simple class to hold two objects.
 */
@interface METPair : NSObject <NSCoding>
{
	id first;
	id second;
}

@property (readonly,nonatomic) id first;
@property (readonly,nonatomic) id second;

+(METPair *) pairWithFirst:(id)_first second:(id)_second;

-(METPair *) initWithFirst:(id)_first second:(id)_second;

-(NSComparisonResult) compare:(METPair *)rhs;

- (void)encodeWithCoder:(NSCoder *)encoder;
- (id)initWithCoder:(NSCoder *)decoder;
@end
