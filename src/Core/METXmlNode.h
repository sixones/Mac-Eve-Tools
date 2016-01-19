//
//  METXmlNode.h
//  Vitality
//
//  Created by Andrew Salamon on 10/21/15.
//  Copyright (c) 2015 Sebastian Kruemling. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface METXmlNode : NSObject
{
    void *_xmlNode;
}

+ (METXmlNode *)nodeWithNode:(void *)xmlNode;

- (METXmlNode *)initWithNode:(void *)xmlNode;
- (void *)xmlNode;

- (NSDictionary *)properties;
- (NSString *)content;
@end