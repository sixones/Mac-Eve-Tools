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

@class Character;
@class CharacterTemplate;

/**
 *  The `AccountUpdateDelegate` protocol defines messages used to notify receivers
 *  of completed API operations.
 */

@protocol AccountUpdateDelegate

/**
*  Tells the delegate when the account has finished updating.
*
*  @param acct    The `Account` object that was updated
*  @param success `YES` on successful download, `NO` on error
*/

-(void) accountDidUpdate:(id)acct didSucceed:(BOOL)success;

@end

/**
 *  The `Account` object is used to retrieve the user's character information
 *  from the EVE Online API.
 */

@interface Account : NSObject <NSCoding> { //<NSTableViewDataSource, NSCoding> {
	NSString *keyID;
	NSString *verificationCode;
	NSString *accountName; /*user supplied name to identify this account*/
	
	/*an array of all characters that belong to this account, regardless of active state*/
	NSMutableArray *characters; //CharacterTemplates
	
	id <AccountUpdateDelegate> delegate;
}

/**
 *  The key ID for this account's API key, as provided by the EVE Online
 *  API key manangement interface.
 */
@property (retain) NSString* keyID;

/**
 *  The verification code for this account's API key, as provided by the EVE Online
 *  API key manangement interface.
 */
@property (retain) NSString* verificationCode;

/**
 *  A user-supplied label used to identify this account; not passed to the server.
 */
@property (retain) NSString* accountName;

/**
 *  The characters assigned to this account.
 */
@property (retain) NSMutableArray *characters;

/**
 *  @name Initialization
 */

/**
 *  Initializes the `Account` object; does not populate the character information.
 *
 *  @param acctID The account's key ID.
 *  @param key    The account's verification code.
 *
 *  @return A new `Account` corresponding to the provided API key.
 */
-(Account*) initWithDetails:(NSString*)acctID acctKey:(NSString*)key;

/**
 *  Initializes the `Account` object; does not populate the character information.
 *
 *  @param name The account's user-provided name.
 *
 *  @return A new `Account` with the provided account name.
 */
-(Account*) initWithName:(NSString*)name;

/**
 *  @name Load Account Details
 */

/**
 *  Loads the account's information from the API.
 *
 *  @param del An `AccountUpdateDelegate` to be notified when the update is complete.
 */
-(void) loadAccount:(id<AccountUpdateDelegate>)del;

/**
 *  Loads the account's information from the API.
 *
 *  @param del   An `AccountUpdateDelegate` to be notified when the update is complete.
 *  @param modal `YES` if the API is being called from a modal window; `NO` otherwise.
 */
-(void) loadAccount:(id<AccountUpdateDelegate>)del runForModalWindow:(BOOL)modal;

/**
 *  Loads the account's information from the API.
 *
 *  @param del An `AccountUpdateDelegate` to be notified when the update is complete.
 */
-(void) fetchCharacters:(id<AccountUpdateDelegate>)del;

/**
 *  @name Get Character Information
 */

/**
 *  Returns the number of characters on this account.
 *
 *  @return The number of characters.
 */
-(NSInteger) characterCount;

/**
 *  Returns the characters on this account.
 *
 *  @return An `NSMutableArray` containing a `CharacterTemplate` for each character
 *  on this account.
 */
-(NSMutableArray*) characters;


/*NSTableView datasource methods for displaying characters*/
	//- (NSInteger)numberOfRowsInTableView:(NSTableView *)aTableView;
	//- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex;

/**
 *  Find a character on this account.
 *
 *  @param charName The name of the desired character.
 *
 *  @return A `CharacterTemplate` corresponding to the requested character, or `nil` if not found.
 */
-(CharacterTemplate*) findCharacter:(NSString*)charName;


@end
