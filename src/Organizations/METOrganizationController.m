//
//  METOrganizationController.m
//  Vitality
//
//  Created by Andrew Salamon on 6/22/15.
//  Copyright (c) 2015 The Vitality Project. All rights reserved.
//

#import "METOrganizationController.h"

#import "CCPType.h"
#import "Config.h"
#import "SkillPlan.h"
#import "Character.h"
#import "Helpers.h"
#import "METURLRequest.h"
#import "METFitting.h"
#import "METDetailWindowController.h"
#import "METIDtoName.h"

/*
 // All typeID's between 1373 and 1386
 // This is a character. Open in evewho.com? Or use their API?
 // Another possibility is something like: https://gate.eveonline.com/Profile/Alcogol%20Hibra
 // or https://gate.eveonline.com/Alliance/Empyreus
 // or https://gate.eveonline.com/Corporation/Synapse. (had to convert an underscore to a period to get that to work)

 From: http://evewho.com/faq/
 Required parameters: type and id
 Optional Parameters: page (default 0)
 Defined Parameters: limit of 200 characters per call
 
 Valid types: corplist, allilist, character, corporation, alliance
 
 Examples:
 Squizz Caphinator: http://evewho.com/api.php?type=character&id=1633218082
 Woopatang [--W--]: http://evewho.com/api.php?type=corplist&id=869043665
 Woopatang [--W--]: http://evewho.com/api.php?type=corporation&id=869043665
 Happy Endings <FONDL>: http://evewho.com/api.php?type=allilist&id=99001433
 Happy Endings <FONDL>: http://evewho.com/api.php?type=alliance&id=99001433

  Make this asynchronous once we have a way to display the info
 NSString *urlString = [NSString stringWithFormat:@"http://evewho.com/api.php?type=character&id=%ld", (long int)typeID];
 NSURL *url = [NSURL URLWithString:urlString];
 //                NSURLRequest *urlRequest = [NSURLRequest requestWithURL:url];
 //                NSURLResponse* response = nil;
 //                NSData* data = [NSURLConnection sendSynchronousRequest:urlRequest returningResponse:&response error:nil];
 NSError *error = nil;
 NSString *datString = [NSString stringWithContentsOfURL:url encoding:NSUTF8StringEncoding error:&error];
 NSLog( @"character data: %@", datString );

 Example character data:
 {
 "info": {
 "character_id":"93347663",
 "corporation_id":"1000009",
 "alliance_id":"0",
 "faction_id":"0",
 "name":"Rintin Enaka",
 "sec_status":"0.1"
 },
 "history": [
 {
 "corporation_id":"1000045",
 "start_date":"2013-05-16 02:57:00",
 "end_date":"2014-01-23 02:06:00"
 },{
 "corporation_id":"98134538",
 "start_date":"2014-01-23 02:07:00",
 "end_date":"2014-07-04 10:29:00"
 },{
 "corporation_id":"1000009",
 "start_date":"2014-07-04 10:30:00",
 "end_date":null
 }]
 }

*/

static const NSInteger orgImageSize = 128;

@interface METOrganizationController ()
@property (retain,readwrite) NSNumber *charID;
@property (retain,readwrite) NSNumber *corpID;
@property (retain,readwrite) NSNumber *allianceID;
@property (retain,readwrite) NSArray *history;
@end

@implementation METOrganizationController

@synthesize type = _type;
@synthesize typeID = _typeID;
@synthesize orgType = _orgType;
@synthesize charID = _charID;
@synthesize corpID = _corpID;
@synthesize allianceID = _allianceID;
@synthesize history = _history;

+(void) displayOrganizationWithType:(NSInteger)type andID:(NSInteger)typeID
{
#ifndef __clang_analyzer__
    METOrganizationController *wc = [[METOrganizationController alloc] initWithType:type andID:typeID];
    
    [[wc window] makeKeyAndOrderFront:nil];
#endif
}

- (id) initWithType:(NSInteger)type andID:(NSInteger)typeID
{
    if( (self = [super initWithWindowNibName:@"METOrganizationWindow"]) )
    {
        nameFetcher = [[METIDtoName alloc] init];
        [nameFetcher setDelegate:self];

        NSString *whoType = nil;
        
        _type = type;
        _typeID = typeID;
        _orgType = METOrganizationUnknown;
        
        if( (type >= 1373) && (type <= 1386) )
        {
            whoType = @"character";
            _orgType = METOrganizationCharacter;
        }
        else if( 2 == type )
        {
            whoType = @"corporation";
            _orgType = METOrganizationCorporation;
        }
        else if( 16159 == type )
        {
            whoType = @"alliance";
            _orgType = METOrganizationAlliance;
        }
        
        /*
        Valid types: corplist, allilist, character, corporation, alliance
        
    Examples:
        Squizz Caphinator: http://evewho.com/api.php?type=character&id=1633218082
        Woopatang [--W--]: http://evewho.com/api.php?type=corplist&id=869043665
        Woopatang [--W--]: http://evewho.com/api.php?type=corporation&id=869043665
        Happy Endings <FONDL>: http://evewho.com/api.php?type=allilist&id=99001433
        Happy Endings <FONDL>: http://evewho.com/api.php?type=alliance&id=99001433
        */
        /*  Make this asynchronous once we have a way to display the info
         NSString *urlString = [NSString stringWithFormat:@"http://evewho.com/api.php?type=character&id=%ld", (long int)typeID];
         NSURL *url = [NSURL URLWithString:urlString];
         //                NSURLRequest *urlRequest = [NSURLRequest requestWithURL:url];
         */
        
        NSString *urlString = [NSString stringWithFormat:@"http://evewho.com/api.php?type=%@&id=%ld", whoType, (long int)typeID];
        NSURL *url = [NSURL URLWithString:urlString];
        METURLRequest *request = [METURLRequest requestWithURL:url];
        [request setDelegate:self];
        [NSURLConnection connectionWithRequest:request delegate:request];
    }
    return self;

}

- (void)dealloc
{
    [nameFetcher release];
    [super dealloc];
}

- (void)awakeFromNib
{
    [itemsTable setDoubleAction:@selector(rowDoubleClick:)];
}

- (void)windowDidLoad
{
    [super windowDidLoad];
    
    [[self window] setTitle:[self windowTitleWithName:nil]];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(windowWillClose:)
                                                 name:NSWindowWillCloseNotification
                                               object:[self window]];
    
    [self testImage];
    
    [self setLabels];
}

-(void) windowWillClose:(NSNotification*)sender
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [self autorelease];
}

- (NSString *)windowTitleWithName:(NSString *)name
{
    NSString *windowTitle = nil;
    
    if( nil == name )
        name = NSLocalizedString( @"Loading...", @"Window is loading indicator");
    
    if( [self orgType] == METOrganizationCharacter )
    {
        windowTitle = [NSString stringWithFormat:@"%@ - %@", NSLocalizedString(@"Character Details", @"Character Details window title"), name];
    }
    else if( [self orgType] == METOrganizationCorporation )
    {
        windowTitle = [NSString stringWithFormat:@"%@ - %@", NSLocalizedString(@"Corporation Details", @"Corporation Details window title"), name];
    }
    else if( [self orgType] == METOrganizationAlliance )
    {
        windowTitle = [NSString stringWithFormat:@"%@ - %@", NSLocalizedString(@"Alliance Details", @"Alliance Details window title"), name];
    }
    
    return windowTitle;
}

-(void) setLabels
{
}

-(BOOL) displayImage
{
    NSString *orgString = nil;
    
    if( [self orgType] == METOrganizationCharacter )
    {
        orgString = @"Character";
    }
    else if( [self orgType] == METOrganizationCorporation )
    {
        orgString = @"Corporation";
    }
    else if( [self orgType] == METOrganizationAlliance )
    {
        orgString = @"Alliance";
    }
    
    NSString *imagePath = [[Config sharedInstance] pathForImageType:[self typeID] ofKind:orgString andSize:orgImageSize];
    
    NSFileManager *fm = [NSFileManager defaultManager];
    
    if( ![fm fileExistsAtPath:[imagePath stringByDeletingLastPathComponent]] )
    {
        [fm createDirectoryAtPath:[imagePath stringByDeletingLastPathComponent]
      withIntermediateDirectories:YES
                       attributes:nil
                            error:NULL];
    }
    
    if( [fm fileExistsAtPath:imagePath] )
    {
        NSImage *image = [[NSImage alloc] initWithContentsOfFile:imagePath];
        [orgImage setImage:image];
        [image release];
        return YES;
    }
    
    return NO;
}

/*test to see if the image already exists.  fetch it if not*/
/*
 Known valid sizes (from: https://github.com/Regner/eveimageserver/blob/master/eveimageserver/main.py ):
 Character: 32, 64, 128, 256, 512, 1024
 Corporation: 32, 64, 128, 256
 Alliance: 32, 64, 128
 Faction: 32, 64, 128
 Types: 32, 64, 128, 256, 512
 */
-(void) testImage
{
    if( [self displayImage] )
    {
        return;
    }

    // Return if we're already downloading this image
    @synchronized(self)
    {
        if(down)
            return;
    }
    
    NSString *orgString = nil;
    
    if( [self orgType] == METOrganizationCharacter )
    {
        orgString = @"Character";
    }
    else if( [self orgType] == METOrganizationCorporation )
    {
        orgString = @"Corporation";
    }
    else if( [self orgType] == METOrganizationAlliance )
    {
        orgString = @"Alliance";
    }

    NSString *imageUrl = [[Config sharedInstance] urlForImageType:[self typeID] ofKind:orgString andSize:orgImageSize];
    NSString *filePath = [[Config sharedInstance] pathForImageType:[self typeID] ofKind:orgString andSize:orgImageSize];

    NSLog(@"Downloading %@ to %@",imageUrl,filePath);
    
    NSURL *url = [NSURL URLWithString:imageUrl];
    METURLRequest *request = [METURLRequest requestWithURL:url];
    NSURLDownload *download = [[NSURLDownload alloc]initWithRequest:request delegate:self];
    [download setDestination:filePath allowOverwrite:NO];
    
    down = download;
}

#pragma mark Delegates for the items table

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView
{
    return [[self history] count];
}

- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
    NSDictionary *entry = [[self history] objectAtIndex:row];
    if( [[tableColumn identifier] isEqualToString:@"ORG_NAME_COLUMN"] )
    {
        return [entry objectForKey:@"corporation_id"];
    }
    else if( [[tableColumn identifier] isEqualToString:@"ORG_START_COLUMN"] )
    {
        return [NSDate dateWithNaturalLanguageString:[entry objectForKey:@"start_date"]];
    }
    else if( [[tableColumn identifier] isEqualToString:@"ORG_END_COLUMN"] )
    {
        NSString *dtString = [entry objectForKey:@"end_date"]; // Could be an NSNull object
        if( [dtString isKindOfClass:[NSString class]] )
        {
            NSDate *endDt = [NSDate dateWithNaturalLanguageString:dtString];
            return endDt;
        }
    }
    return nil;
}

-(void) rowDoubleClick:(id)sender
{
    NSInteger selectedRow = [sender selectedRow];
    
    if( selectedRow == -1 )
    {
        return;
    }
    
    // Display a detail window for the selected item
//    CCPType *type = [[fitting items] objectAtIndex:selectedRow];
//    [METDetailWindowController displayDetailsOfType:type forCharacter:character];
    return;
}

- (BOOL)tableView:(NSTableView *)aTableView
shouldEditTableColumn:(NSTableColumn *)aTableColumn
              row:(NSInteger)rowIndex
{
    return NO;
}

- (BOOL)outlineView:(NSOutlineView *)outlineView
shouldEditTableColumn:(NSTableColumn *)tableColumn
               item:(id)item
{
    return NO;
}

#pragma mark drag and drop support

- (BOOL)tableView:(NSTableView *)tv
writeRowsWithIndexes:(NSIndexSet *)rowIndexes
     toPasteboard:(NSPasteboard*)pboard
{
    return NO;
//    NSMutableArray *array = [NSMutableArray array];
//        
//    for( CCPType *type in [[fitting items] objectsAtIndexes:rowIndexes] )
//    {
//        if( [type isKindOfClass:[CCPType class]] )
//        {
//            [array addObjectsFromArray:[type prereqs]];
//        }
//        else
//        {
//            return NO;
//        }
//    }
//    
//    [pboard declareTypes:[NSArray arrayWithObject:MTSkillArrayPBoardType] owner:self];
//    
//    NSMutableData *data = [[NSMutableData alloc]init];
//    
//    NSKeyedArchiver *archiver = [[NSKeyedArchiver alloc]initForWritingWithMutableData:data];
//    [archiver setOutputFormat:NSPropertyListBinaryFormat_v1_0];
//    [archiver encodeObject:array];
//    [archiver finishEncoding];
//    
//    [pboard setData:data forType:MTSkillArrayPBoardType];
//    
//    [archiver release];
//    [data release];
//    
//    return YES;
}

#pragma mark NSURLDownload delegate

-(void) downloadDidFinish:(NSURLDownload *)download
{
    [self displayImage];
    
    @synchronized(self){
        [down release];
        down = nil;
    }
}

-(void) download:(NSURLDownload *)download didFailWithError:(NSError *)error
{
    NSLog(@"Error downloading image (%@): %@",[[download request]URL], error);
    
    @synchronized(self){
        [down release];
        down = nil;
    }
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection withError:(NSError *)error
{
    if( error )
    {
        NSLog( @"Error requesting Character/Organization details: %@", [error localizedDescription] );
        return;
    }
    
    METURLRequest *request = (METURLRequest *)[connection originalRequest];
    NSMutableData *data = [request data];
    
    if( NSClassFromString(@"NSJSONSerialization") )
    {
        NSError *jsonParsingError = nil;
        NSDictionary *publicTimeline = [NSJSONSerialization JSONObjectWithData:data options:0 error:&jsonParsingError];
        NSLog( @"Org:\n%@", publicTimeline );
        /*
         Character:
         {
         history =     (
         {
         "corporation_id" = 1000045;
         "end_date" = "2014-01-23 02:06:00";
         "start_date" = "2013-05-16 02:57:00";
         },
         {
         "corporation_id" = 98134538;
         "end_date" = "2014-07-04 10:29:00";
         "start_date" = "2014-01-23 02:07:00";
         },
         {
         "corporation_id" = 1000009;
         "end_date" = "<null>";
         "start_date" = "2014-07-04 10:30:00";
         }
         );
         info =     {
         "alliance_id" = 0;
         "character_id" = 93347663;
         "corporation_id" = 1000009;
         "faction_id" = 0;
         name = "Rintin Enaka";
         "sec_status" = "0.1";
         };
         }
         
         Corporation:
         info =     {
         active = 3;
         "alliance_id" = 0;
         "avg_sec_status" = "2.7";
         ceoID = 91671093;
         "corporation_id" = 98160107;
         description = "<font  ></font><font  ><b>Chaos</b></font><font  > isn't a pit.<br></font><font  ><b>Chaos</b></font><font  > is a ladder.<br>Many who try to <b>climb</b> it fail<br>and never get to try again.<br>The fall breaks them.<br>And some are given<br>a chance to <b>climb</b>,<br>but they refuse.<br>They cling to the realm<br>or the gods<br>or love.<br></font><font  ><b>Illusions.</b><br></font><font  >Only the ladder is real.<br>The <b>climb</b> is all there is<br>--------------------------------------------<br></font><font  ><b>CEO/Diplomat:<br></font><font  ><a href=\"showinfo:1385//91671093\">Abinus Sertan</a><br></font><font  >Directors/Recruitment:<br></font><font  ><a href=\"showinfo:1377//91900089\">Edward Brodeur</a><br><a href=\"showinfo:1380//247300162\">Kel Davarit</a><br><a href=\"showinfo:1377//93679643\">Lalu Multipass</a></b></font><font  clor=\"#ffffff00\">  <br></font><font  ><a href=\"showinfo:1383//566231994\">Sorcha Majir</a></font><font  clor=\"#ffffff00\"> <br></font><font  ><a href=\"showinfo:1383//1502580589\">Ryikan</a><br><a href=\"showinfo:1377//92554408\">Otori Dresden</a></font><font  clor=\"#ffffff00\"> </font>";
         "is_npc_corp" = 0;
         "member_count" = 95;
         name = "Synapse.";
         taxRate = 15;
         ticker = SYYN;
         };

         Alliance:
         info =     {
         "alliance_id" = 99005559;
         "avg_sec_status" = "1.5";
         "executor_corp" = 98401994;
         "faction_id" = 0;
         "member_count" = 255;
         name = Empyreus;
         ticker = PYRE;
         };

         */
        NSDictionary *info = [publicTimeline objectForKey:@"info"];
        if( ![info isKindOfClass:[NSDictionary class]] )
        {
            NSString *orgType = @"unknown";
            if( [self orgType] == METOrganizationCharacter )
                orgType = NSLocalizedString( @"character", @"" );
            else if( [self orgType] == METOrganizationCorporation )
                orgType = NSLocalizedString( @"corporation", @"" );
            else if( [self orgType] == METOrganizationAlliance )
                orgType = NSLocalizedString( @"alliance", @"" );
            [charName setStringValue:[NSString stringWithFormat:@"Error loading %@ data", orgType]];
            return;
        }
        
        [self setCharID:[info objectForKey:@"character_id"]];
        [self setCorpID:[info objectForKey:@"corporation_id"]];
        [self setAllianceID:[info objectForKey:@"alliance_id"]];
        NSString *orgNameStr = [info objectForKey:@"name"];
        NSMutableSet *names = [NSMutableSet set];
        
        if( [self orgType] == METOrganizationCharacter )
        {
            [charName setStringValue:orgNameStr];
            [corpName setObjectValue:[self corpID]];
            [allianceName setObjectValue:[self allianceID]];
            [securityStatus setStringValue:[info objectForKey:@"sec_status"]];
            NSArray *tempHistory = [publicTimeline objectForKey:@"history"];
            [self setHistory:tempHistory];
            // history: corporation_id, end_date (can be "<null>"), start_date
            for( NSDictionary *corp in tempHistory )
            {
                if( ![corp isKindOfClass:[NSDictionary class]] )
                    continue;
                id cid = [corp objectForKey:@"corporation_id"];
                if( cid )
                    [names addObject:cid];
            }
        }
        else if( [self orgType] == METOrganizationCorporation )
        {
            [charName setStringValue:@""];
            [corpName setStringValue:orgNameStr];
            [allianceName setObjectValue:[self allianceID]];
            [securityStatus setStringValue:[info objectForKey:@"avg_sec_status"]];
            [self setHistory:[publicTimeline objectForKey:@"history"]];
            // ticker
            // ceoID
        }
        else if( [self orgType] == METOrganizationAlliance )
        {
            [charName setStringValue:@""];
            [corpName setStringValue:@""];
            [allianceName setStringValue:orgNameStr];
            [securityStatus setStringValue:[info objectForKey:@"avg_sec_status"]];
            // ticker
            // executor_corp
        }

        [[self window] setTitle:[self windowTitleWithName:orgNameStr]];

        if( [self charID] )
            [names addObject:[self charID]];
        if( [self corpID] )
            [names addObject:[self corpID]];
        if( [self allianceID] )
            [names addObject:[self allianceID]];
        [nameFetcher namesForIDs:names];
        [itemsTable reloadData];
        [self testImage];
    }
}

- (void)namesFromIDs:(NSDictionary *)names
{
    NSString *name = nil;
    BOOL changed = NO;
    
    name = [names objectForKey:[self charID]];
    if( name )
    {
        [charName setStringValue:name];
        changed = YES;
    }
    name = [names objectForKey:[self corpID]];
    if( name )
    {
        [corpName setStringValue:name];
        changed = YES;
    }
    name = [names objectForKey:[self allianceID]];
    if( name )
    {
        [allianceName setStringValue:name];
        changed = YES;
    }
    
    NSMutableArray *newHistory = [NSMutableArray arrayWithCapacity:[[self history] count]];
    for( NSDictionary *corp in [self history] )
    {
        NSNumber *corpID = [corp objectForKey:@"corporation_id"];
        name = [names objectForKey:corpID];
        if( name )
        {
            // we have a name for this ID
            NSMutableDictionary *newCorp = [corp mutableCopy];
            [newCorp setObject:name forKey:@"corporation_id"];
            [newHistory addObject:newCorp];
            [newCorp release];
        }
        else
        {
            [newHistory addObject:corp];
        }
    }
    [self setHistory:newHistory];
    [itemsTable reloadData];
}


@end
