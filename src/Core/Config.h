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
#import "Account.h"
#import "macros.h"

/**
 The `Config` class defines a singleton object that stores application configuration
 information.
 */
@interface Config : NSObject {
	NSString *programName;
	
		//NSString *rootPath; /*Root path to save data to*/
		
	NSMutableArray *accounts; /*a list of Account* objects*/
	
	//remove this. push into GlobalData structure
	//NSDateFormatter *dateFormatter; -> removed
		
}

@property (retain) NSMutableArray* accounts;

/**
 @name Access the Configuration Object
 */

/**
 Get the configuration object.
 
 @return A pointer to the singleton `Config` object.
 */
+(Config*) sharedInstance;

/**
 @name Construct API URLs
 */

/**
 Constructs an API URL to access character information.
 
 `macros.h` provides constants for the available API calls that can be passed as
 the `xmlPage` parameter.

 
 @param xmlPage          The API endpoint to call, e.g. `@"/account/Characters.xml.aspx"`.
 @param accountId        The account's API key ID.
 @param verificationCode The account's API verification code.
 @param characterId      The API's `characterID` value for the desired character, or `nil` if not applicable.
 
 @return A URL that will call the provided endpoint.
 */
+(NSString*) getApiUrl:(NSString*)xmlPage 
			 keyID:(NSString*)accountId 
				verificationCode:(NSString*)verificationCode 
				charId:(NSString*)characterId;

/**
 @name Work with File Paths
 */

/**
 Compose a file path in the application's local storage directory.
 
 Example:
 
 [Config getFilePath:XMLAPI_CHAR_SHEET,"foo","bar",nil]
 
 returns `@"/Users/username/Library/Application Support/Vitality/foo/bar/CharacterSheet.xml.aspx"`
 
 @warning The last parameter passed must be `nil` or Bad Things will happen.
 @param ... The components of the path to create the file under, terminated by `nil`.
 
 @param xmlApiFile The file's base name.
 
 @return The composed pathname to be created.
 */
+(NSString*) filePath:(NSString*)xmlApiFile, ...;

/**
 Get the path for the directory containing a character's information on disk.
 
 @param accountId   The character's account ID.
 @param characterId The character's character ID.
 
 @return The character's base directory.
 */
+(NSString*) charDirectoryPath:(NSString*)accountId character:(NSString*)characterId;

/**
 Get the file path for a file in the local storage directory.
 
 @param file A constant from `macros.h`.
 
 @return The requested file's full path.
 */
+(NSString*) buildPathSingle:(NSString*)file;

/**
 @name Manage API Accounts
 */

/**
 Add an API account to the configuration.
 
 @param acct The `Account` to be added.
 
 @return The index of the account if added, or -1 if already present.
 */
-(NSInteger) addAccount:(Account*)acct;

/**
 Remove an API account from the configuration.
 
 @param acct The `Account` to be removed.
 
 @return `YES` if the account was found and removed; `NO` if the account was not found.
 */
-(BOOL) removeAccount:(Account*)acct;

/**
 Remove all API accounts from the configuration.
 
 @return `TRUE`.
 */
-(BOOL) clearAccounts;

/**
 @name Manage Local Storage
 */

/**
 Check for downloaded copies of the skill and certificate trees.
 
 @return `YES` if both have been downloaded; `NO` otherwise.
 */
-(BOOL) requisiteFilesExist;

/**
 Save the configuration to disk.
 
 Doesn't actually do anything.
 
 @return `YES`
 */
-(BOOL) saveConfig;

/**
 Load the configuration from disk.
 
 @return `YES`
 */
-(BOOL) readConfig;

//-(NSString*) itemDBFallbackPath;

/**
 @name Get Active Characters
 */

/*return a list of all the active characters  (CharacterTemplate)*/
-(NSArray*) activeCharacters;


/**
 @name Ship and Icon Graphics
 */

/*functions for ship and icon graphics*/

/**
 Get the path in local storage for the image corresponding to a specified inventory type. Does not retrieve the image from EVE Online if it has not yet been downloaded.
 
 @param typeID A typeID from the InvTypes table.
 
 @return The path for the image on disk.
 */
-(NSString*) pathForImageType:(NSInteger)typeID;

/**
 Get the API URL for the image corresponding to a specified inventory type.
 
 @param typeID A typeID from the InvTypes table.
 
 @return The URL of the desired image on the EVE Online server.
 */
-(NSString*) urlForImageType:(NSInteger)typeID;

/**
 @name Database Language
 */

/**
 Get the current database language.
 
 @return A `DatabaseLanguage` corresponding to the currently-set language: `l_EN`, `l_DE`, or `l_RU`.
 */
-(enum DatabaseLanguage) dbLanguage;

/**
 Set the database language
 
 @param lang A `DatabaseLanguage`: `l_EN`, `l_DE`, or `l_RU`.
 */
-(void) setDbLanguage:(enum DatabaseLanguage)lang;

@end
