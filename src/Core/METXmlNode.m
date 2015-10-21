//
//  METXmlNode.m
//  Vitality
//
//  Created by Andrew Salamon on 10/21/15.
//  Copyright (c) 2015 Sebastian Kruemling. All rights reserved.
//

#import "METXmlNode.h"

#include <libxml/tree.h>

@implementation METXmlNode

+ (METXmlNode *)nodeWithNode:(void *)xmlNode
{
    METXmlNode *node = [[METXmlNode alloc] initWithNode:xmlNode];
    return [node autorelease];
}

- (METXmlNode *)initWithNode:(void *)xmlNode
{
    if( self = [super init] )
    {
        _xmlNode = xmlNode;
    }
    return self;
}

- (void *)xmlNode
{
    return _xmlNode;
}

- (NSDictionary *)properties
{
    NSMutableDictionary *props = [NSMutableDictionary dictionary];
    xmlNode *cur_node = [self xmlNode];
    for( xmlAttr *attr = cur_node->properties; attr; attr = attr->next )
    {
        NSString *name = [NSString stringWithUTF8String:(const char *)attr->name];
        NSString *value = [NSString stringWithUTF8String:(const char *)attr->children->content];
        if( name && value )
            [props setObject:value forKey:name];
    }
    return props;
}
@end