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
 
 Copyright The Vitality Project, 2105.
 */

#import <Cocoa/Cocoa.h>

@class CCPDatabase;
@class CCPCategory;

#import "SkillSearchView.h"

@interface SkillSearchModuleDatasource : NSObject<SkillSearchDatasource>
{
    CCPDatabase *database;
    CCPCategory *category;
    NSString *_displayName; ///< E.g. Modules, or Charges
    
    NSString *searchString;
    NSMutableArray *searchObjects;
}

@property (retain,readwrite) NSString *displayName;

-(NSString*) skillSearchName;
-(void) skillSearchFilter:(id)sender;

-(id)initWithCategory:(NSInteger)cat;

@end
