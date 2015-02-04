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

#import "METPair.h"

@implementation METPair

@synthesize first;
@synthesize second;

+(METPair *) pairWithFirst:(id)_first second:(id)_second
{
    METPair *pair = [[METPair alloc] initWithFirst:_first second:_second];
    return [pair autorelease];
}

-(METPair *) initWithFirst:(id)_first second:(id)_second
{
	if( self = [super init] )
    {
		first = [_first retain];
		second = [_second retain];
	}
	
	return self;
}

-(void) dealloc
{
	[first release];
    [second release];
	[super dealloc];
}

-(NSString*) description
{
	return [NSString stringWithFormat:@"%@ %@", [first description], [second description]];
}

-(NSComparisonResult) compare:(METPair*)rhs
{
    NSComparisonResult res = [first compare:[rhs first]];
	if( NSOrderedSame == res )
    {
		res = [second compare:[rhs second]];
	}
	return res;
}

- (void)encodeWithCoder:(NSCoder *)encoder
{
	[encoder encodeObject:first forKey:@"first"];
	[encoder encodeObject:second forKey:@"second"];
}
- (id)initWithCoder:(NSCoder *)decoder
{
    [first release];
    [second release];
	id _first = [decoder decodeObjectForKey:@"first"];
	id _second = [decoder decodeObjectForKey:@"second"];
	return [self initWithFirst:_first second:_second];
}

@end
