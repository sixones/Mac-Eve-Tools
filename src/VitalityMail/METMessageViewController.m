//
//  METMessageViewController.m
//  Vitality
//
//  Created by Andrew Salamon on 2/12/15.
//  Copyright (c) 2015 Sebastian Kruemling. All rights reserved.
//

#import "METMessageViewController.h"

#import "METMailMessage.h"

@interface METMessageViewController ()

@end

@implementation METMessageViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self loadFields];
}

- (void)setMessage:(METMailMessage *)_message
{
    if( _message != message )
    {
        [message release];
        message = [_message retain];
        [self loadFields];
    }
}

- (METMailMessage *)message
{
    return [[message retain] autorelease];
}

- (void)clearFields
{
    [from setStringValue:@""];
    [sentDate setStringValue:@""];
    [to setStringValue:@""];
    [subject setStringValue:@""];
    
    NSAttributedString *emptyString = [[NSAttributedString alloc] init];
    [[body textStorage] setAttributedString:emptyString];
    [emptyString release];
}

- (void)loadFields
{
    if( nil == message )
    {
        [self clearFields];
        return;
    }
    
    [from setStringValue:[message senderName]];
    [sentDate setObjectValue:[message sentDate]];
    [to setStringValue:[message toDisplayName]];
    [subject setStringValue:[message subject]];
    
    NSAttributedString *bodyString = [[NSAttributedString alloc] initWithHTML:[[message body] dataUsingEncoding:NSUTF8StringEncoding allowLossyConversion:YES] options:nil documentAttributes:nil];
    [[body textStorage] setAttributedString:bodyString];
    [bodyString release];
}
@end
