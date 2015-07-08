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

@interface METOrganizationController ()

@end

@implementation METOrganizationController

+(void) displayFitting:(METFitting *)fit forCharacter:(Character *)ch
{
#ifndef __clang_analyzer__
    METOrganizationController *wc = [[METOrganizationController alloc] initWithFitting:fit forCharacter:ch];
    
    [[wc window] makeKeyAndOrderFront:nil];
#endif
}

- (id) initWithFitting:(METFitting *)fit forCharacter:(Character *)ch
{
    if( (self = [super initWithWindowNibName:@"METFittingWindow"]) )
    {
        fitting = [fit retain];
        character = [ch retain];
    }
    return self;

}

- (void)dealloc
{
    [fitting release];
    [character release];
    [super dealloc];
}

- (void)awakeFromNib
{
    [itemsTable setDoubleAction:@selector(rowDoubleClick:)];
}

- (void)windowDidLoad
{
    [super windowDidLoad];
    
    [[self window] setTitle:[NSString stringWithFormat:@"%@",[fitting name]]];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(windowWillClose:)
                                                 name:NSWindowWillCloseNotification
                                               object:[self window]];
    
    [self testImage];
    
    [self setLabels];
    
    [self calculateTimeToTrain];
}

-(void) windowWillClose:(NSNotification*)sender
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [self autorelease];
}


-(void) setLabels
{
    [shipName setStringValue:[[fitting ship] typeName]];
    
}

-(BOOL) displayImage
{
    NSString *imagePath = [[Config sharedInstance] pathForImageType:[[fitting ship] typeID]];
    
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
        [shipView setImage:image];
        [image release];
        return YES;
    }
    
    return NO;
}

-(void) calculateTimeToTrain
{
    //Normally skill plans should be created using the character object, but we don't
    //want to save this plan
    SkillPlan *plan = [[SkillPlan alloc]initWithName:@"--TEST--" character:character];
    [plan addSkillArrayToPlan:[[fitting ship] prereqs]];
    
    NSInteger timeToTrain = [plan trainingTime];
    
    [plan release];
    
    if(timeToTrain == 0)
    {
        //Can use this ship now.
        [trainingTime setStringValue:[NSString stringWithFormat:NSLocalizedString(@"%@ can fly this ship",@"<@CharacterName>"), [character characterName]]];
    }
    else
    {
        NSString *timeToTrainString = stringTrainingTime(timeToTrain);
        
        [trainingTime setStringValue:[NSString stringWithFormat:NSLocalizedString(@"%@ could fly this ship in %@",@"<@CharacterName>"), [character characterName],timeToTrainString]];
    }
    
    [miniPortrait setImage:[character portrait]];
}

/*test to see if the image already exists.  fetch it if not*/
-(void) testImage
{
    if( [self displayImage] )
    {
        return;
    }
    
    NSString *imageUrl = [[Config sharedInstance] urlForImageType:[[fitting ship] typeID]] ;
    NSString *filePath = [[Config sharedInstance] pathForImageType:[[fitting ship] typeID]];
    
    NSLog(@"Downloading %@ to %@",imageUrl,filePath);
    
    /*image does not exist. download it and display it when it's done.*/
    NSURL *url = [NSURL URLWithString:imageUrl];
    METURLRequest *request = [METURLRequest requestWithURL:url];
    NSURLDownload *download = [[NSURLDownload alloc]initWithRequest:request delegate:self];
    [download setDestination:filePath allowOverwrite:NO];
    
    down = download;
}

#pragma mark Delegates for the items table

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView
{
    return [[fitting items] count];
}

- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
    if( [[tableColumn identifier] isEqualToString:@"FIT_COUNT_COLUMN"] )
    {
        return [NSNumber numberWithInteger:[fitting countOfItem:[[fitting items] objectAtIndex:row]]];
    }
    else if( [[tableColumn identifier] isEqualToString:@"FIT_TYPE_COLUMN"] )
    {
        return [[[fitting items] objectAtIndex:row] typeName];
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
    CCPType *type = [[fitting items] objectAtIndex:selectedRow];
    [METDetailWindowController displayDetailsOfType:type forCharacter:character];
    return;
    
//    /* Display a popup window for the clicked skill */
//    NSNumber *typeID = [[[character skillPlanById:[pvDatasource planId]] skillAtIndex:selectedRow] typeID];
//    [SkillDetailsWindowController displayWindowForTypeID:typeID forCharacter:character];
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
    NSMutableArray *array = [NSMutableArray array];
        
    for( CCPType *type in [[fitting items] objectsAtIndexes:rowIndexes] )
    {
        if( [type isKindOfClass:[CCPType class]] )
        {
            [array addObjectsFromArray:[type prereqs]];
        }
        else
        {
            return NO;
        }
    }
    
    [pboard declareTypes:[NSArray arrayWithObject:MTSkillArrayPBoardType] owner:self];
    
    NSMutableData *data = [[NSMutableData alloc]init];
    
    NSKeyedArchiver *archiver = [[NSKeyedArchiver alloc]initForWritingWithMutableData:data];
    [archiver setOutputFormat:NSPropertyListBinaryFormat_v1_0];
    [archiver encodeObject:array];
    [archiver finishEncoding];
    
    [pboard setData:data forType:MTSkillArrayPBoardType];
    
    [archiver release];
    [data release];
    
    return YES;
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

@end
