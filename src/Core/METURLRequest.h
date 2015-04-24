//
//  METURLRequest.h
//  Vitality
//
//  Created by Andrew Salamon on 11/25/14.
//  Copyright (c) 2014 Sebastian Kruemling. All rights reserved.
//

#import <Foundation/Foundation.h>

/** This class will use a custom User-Agent string
 and should be used in all cases when we contact a CCP server.
 See Also: https://developers.eveonline.com/resource/xml-api
 
 The data member can be used to store data for this request.
 
 METURLRequest can be set as the delegate of an NSURLConnection object and it will handle all data related to the request.
 When finished it will call:
 - (void)connectionDidFinishLoading:(NSURLConnection *)connection withError:(NSError *)error
on the request's delegate. The error argument will be nil if there was no error.
 Data can be retrieved with [[connection originalRequest] data]
 */
@interface METURLRequest : NSMutableURLRequest
{
    id _delegate;
    NSMutableData *_data;
}

@property (retain,readonly) NSMutableData *data;
@property (assign,readwrite) id delegate;
@end
