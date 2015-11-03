//
//  METRowsetEnumerator.h
//  Vitality
//
//  Created by Andrew Salamon on 10/19/15.
//  Copyright (c) 2015 Sebastian Kruemling. All rights reserved.
//

#import <Foundation/Foundation.h>

@class Character;
@class METXmlNode;

typedef enum
{
    METRowsetMissingCharacter = -106,
    METRowsetCached = -107
} METRowsetErrors;

/** METRowsetEnumerator
 How to use this class.
 1) Alloc/init with the API path you want to use (character isn't really needed until you call run):
    apiGetter = [[METRowsetEnumerator alloc] initWithCharacter:nil API:XMLAPI_CHAR_NOTIFICATIONS forDelegate:self];
 2) Make sure to set the character any time that changes
    [apiGetter setCharacter:newCharacter];
 3) Run the getter whenever you want to pull new data from the API
    [apiGetter run];
 4) Handle the returned error or data by implementing this delegate method:
    - (void)apiDidFinishLoading:(METRowsetEnumerator *)rowset withError:(NSError *)error
 5) First check for an error
    if( error )
       ... // Probably best to not try to use any data after this
    error code -107 means we couldn't pull from the API because of the CachedUntil date
 6) Loop through the returned rowset rows with fast enumeration:
    for( METXmlNode *row in rowset )
       ...
 
 The checkCachedDate flag defaults to YES and should only be set to NO for very specific API calls.
 For example, calling the market orders API with a single market order ID (so it's state can be updated)
   will always fail because it's called immediately after a regular market orders API call, so it will
   always be before the cached until date. Unless the checkCachedDate flag is set to NO for that particular call.
 */
@interface METRowsetEnumerator : NSObject<NSFastEnumeration>
{
    id _delegate;
    Character *_character;
    BOOL _checkCachedDate;
    NSString *apiPath;
    NSURLConnection *urlConnection;
    NSData *xmlData;
    
    void *xmlDocument;
    void *rowsetNode;
    METXmlNode *nodeWrapper;
}

@property (readonly) id delegate;
@property (readwrite,retain) Character *character;
@property (readwrite,assign) BOOL checkCachedDate;

- (METRowsetEnumerator *)initWithCharacter:(Character *)_char API:(NSString *)api forDelegate:(id)_del;

- (void)run;
- (void)runWithURLExtras:(NSString *)extraURLArgs;

- (void)cancel; ///< call cancel on the urlConnection
@end