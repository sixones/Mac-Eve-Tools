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

@class MTAPIKey;

/**
 The method specified by `APIKeyValidationDelegate` can be used to receive the results
 of API-key validation.
 */
@protocol APIKeyValidationDelegate


/**
 Report the results of API-key validation.
 
 @param key     The API key that was checked for validity.
 @param success `YES` if the key is valid; `NO` otherwise.
 @param error   If unsuccessful, may provide additional information about the failure.
 */
-(void) key:(MTAPIKey *)key didValidate:(BOOL)success withError:(NSError *)error;

@end


/**
 The `MTAPIKey` object is used by the `AccountPrefDetailController` to store an API key.
 */
@interface MTAPIKey : NSObject
{
	NSString *keyID;
	NSString *verificationCode;

    NSString *mask;
    NSString *type;
    NSDate *expires;

	id <APIKeyValidationDelegate> delegate;
    
    NSString *savePath;
}

/**
 @name Properties
 */

/**
 The API key ID.
 */
@property (retain) NSString* keyID;

/**
 The API key verification code.
 */
@property (retain) NSString* verificationCode;

/**
 The API key access mask.
 */
@property (retain,readonly) NSString *mask;

/**
 The API key's type.
 
 Valid types:
 
 - `@"Character"`
 - `@"Corporation"`
 
 */
@property (retain,readonly) NSString *type;

/**
 The API key's expiration date.
 */
@property (retain,readonly) NSDate *expires;

/**
 @name Initialization
 */

/**
 Initialize the `MTAPIKey` object; does not call the API.
 
 @param _keyID    The API key ID.
 @param code      The API validation code.
 @param _delegate The delegate to be called when the `validate` method completes.
 
 @return Self.
 */
-(MTAPIKey *) initWithID:(NSString*)_keyID code:(NSString*)code delegate:(id<APIKeyValidationDelegate>)_delegate;

/**
 @name Validate Key
 */

/**
 Validate the provided key against the EVE Online server.
 */
-(void) validate;


@end
