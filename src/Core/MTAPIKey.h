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

@protocol APIKeyValidationDelegate

/*
	Returns results of checking the given API key for validity.
    Mosly checking for the right permissions.
 */

-(void) key:(MTAPIKey *)key didValidate:(BOOL)success withError:(NSError *)error;

@end


/*
	An Account object contains all the characters for a given account
	Create this object to fetch all the characters for that account.
	then, you can pick and choose what characters you care about for that account
*/

@interface MTAPIKey : NSObject
{
	NSString *keyID;
	NSString *verificationCode;

    NSString *mask;
    NSString *type;
    NSDate *expires;

	id <APIKeyValidationDelegate> delegate;
}

@property (retain) NSString* keyID;
@property (retain) NSString* verificationCode;
@property (retain,readonly) NSString *mask;
@property (retain,readonly) NSString *type;
@property (retain,readonly) NSDate *expires;

/*This sets up the internal variables, it does not populate the characters*/
-(MTAPIKey *) initWithID:(NSString*)_keyID code:(NSString*)code delegate:(id<APIKeyValidationDelegate>)_delegate;

-(void) validate;


@end
