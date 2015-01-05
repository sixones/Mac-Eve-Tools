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
 */
@interface METURLRequest : NSMutableURLRequest

@end
