//
//  METOrganizationController.h
//  Vitality
//
//  Created by Andrew Salamon on 6/22/15.
//  Copyright (c) 2015 Sebastian Kruemling. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "METIDtoName.h"

typedef enum {
    METOrganizationCharacter,
    METOrganizationCorporation,
    METOrganizationAlliance,
    METOrganizationUnknown
} METOrganizationType;

@interface METOrganizationController : NSWindowController <NSURLDownloadDelegate,METIDtoNameDelegate>
{
    NSInteger _type;
    NSInteger _typeID;
    METOrganizationType _orgType;
    NSArray *_history;
    
    IBOutlet NSImageView *orgImage;
    IBOutlet NSTextField *charName;
    IBOutlet NSTextField *corpName;
    IBOutlet NSTextField *allianceName;
    IBOutlet NSTextField *securityStatus;
    IBOutlet NSTableView *itemsTable;
    
    NSURLDownload *down;
    
    METIDtoName *nameFetcher;
    NSNumber *_charID;
    NSNumber *_corpID;
    NSNumber *_allianceID;
}

@property (assign,readwrite) NSInteger type;
@property (assign,readwrite) NSInteger typeID;
@property (assign,readonly) METOrganizationType orgType;
@property (retain,readonly) NSNumber *charID;
@property (retain,readonly) NSNumber *corpID;
@property (retain,readonly) NSNumber *allianceID;
@property (retain,readonly) NSArray *history;

+(void) displayOrganizationWithType:(NSInteger)type andID:(NSInteger)typeID;

- (id) initWithType:(NSInteger)type andID:(NSInteger)typeID;

-(IBAction) rowDoubleClick:(id)sender;
@end
