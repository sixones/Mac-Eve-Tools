//
//  METOrganizationController.h
//  Vitality
//
//  Created by Andrew Salamon on 6/22/15.
//  Copyright (c) 2015 Sebastian Kruemling. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class Character;
@class METFitting;

@interface METOrganizationController : NSWindowController <NSURLDownloadDelegate>
{
    IBOutlet NSImageView *shipView;
    IBOutlet NSTextField *shipName;
    IBOutlet NSImageView *miniPortrait;
    IBOutlet NSTextField *trainingTime;
    IBOutlet NSTableView *itemsTable;
    
    METFitting *fitting;
    Character *character;
    NSURLDownload *down;
}

+(void) displayFitting:(METFitting *)fit forCharacter:(Character *)ch;

- (id) initWithFitting:(METFitting *)fit forCharacter:(Character *)ch;

-(IBAction) rowDoubleClick:(id)sender;
@end
