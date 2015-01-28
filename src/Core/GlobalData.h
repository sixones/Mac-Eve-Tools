/*
 This file is part of Mac Eve Tools.
 
 Mac Eve Tools is free software: you can redistribute it and/or modify
 it under the terms of the GNU General Public License as published by
 the Free Software Foundation, either version 3 of the License, or
 (at your option) any later version.
 
 Mac Eve Tools is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 GNU General Public License for more details.
 
 You should have received a copy of the GNU General Public License
 along with Mac Eve Tools.  If not, see <http://www.gnu.org/licenses/>.
 
 Copyright Matt Tyson, 2009.
 */


#import <Cocoa/Cocoa.h>

#import "SkillTree.h"

/**
 The `GlobalData` singleton object holds global lookup data, such as the
 skill tree and certificates information.
 */

@class SkillTree;
@class CertTree;
@class CCPDatabase;

@interface GlobalData : NSObject {
	SkillTree *skillTree;
	CertTree *certTree;
	
	CCPDatabase *database;
	
	NSDateFormatter *dateFormatter;
}

@property (nonatomic, retain) SkillTree* skillTree;
@property (nonatomic, retain) CertTree* certTree;
@property (nonatomic, retain) CCPDatabase* database;
@property (nonatomic, retain) NSDateFormatter* dateFormatter;

+ (NSString *)userAgent;

/**
 @name Access the GlobalData Object
 */

/**
 Get the data object.
 
 @return A pointer to the singleton `GlobalData` object.
 */
+(GlobalData*) sharedInstance;

-(NSString*) formatDate:(NSDate*)date;

/**
 @name Check Database Version
 */

/**
 Return the local database copy's version number.
 
 @return The database version.
 */
-(NSInteger) databaseVersion;

/**
 Check whether the database is sufficiently current.
 
 @return `YES` if the local database copy meets this program's minimum version requirement; `NO` otherwise.
 */
-(BOOL) databaseUpToDate;

@end
