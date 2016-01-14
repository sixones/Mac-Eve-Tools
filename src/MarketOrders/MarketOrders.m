//
//  MarketOrders.m
//  Mac Eve Tools
//
//  Created by Andrew Salamon on 5/17/13.
//  Copyright (c) 2013 Sebastian Kruemling. All rights reserved.
//

#import "MarketOrders.h"

#import "Config.h"
#import "GlobalData.h"
#import "XmlHelpers.h"
#import "Character.h"
#import "CharacterTemplate.h"
#import "MarketOrder.h"
#import "METURLRequest.h"

#import "METRowsetEnumerator.h"
#import "METXmlNode.h"

#import "XMLDownloadOperation.h"
#import "XMLParseOperation.h"

#include <assert.h>

#include <libxml/tree.h>
#include <libxml/parser.h>

@interface MarketOrders()
@property (readwrite,retain) NSString *xmlPath;
@property (readwrite,retain) NSDate *cachedUntil;
@end

@implementation MarketOrders

@synthesize character = _character;
@synthesize orders = _orders;
@synthesize xmlPath = _xmlPath;
@synthesize cachedUntil = _cachedUntil;
@synthesize delegate = _delegate;

- (id)init
{
    if( self = [super init] )
    {
        _orders = [[NSMutableArray alloc] init];
        _cachedUntil = [[NSDate distantPast] retain];
        ordersAPI = [[METRowsetEnumerator alloc] initWithCharacter:nil API:XMLAPI_CHAR_ORDERS forDelegate:self];
    }
    return self;
}

- (void)dealloc
{
    [_orders release];
    [_cachedUntil release];
    [ordersAPI release];
    [super dealloc];
}

- (Character *)character
{
    return [[_character retain] autorelease];
}

- (void)setCharacter:(Character *)character
{
    if( _character != character )
    {
        [_character release];
        _character = [character retain];
        [[self orders] removeAllObjects];
        [self setCachedUntil:[NSDate distantPast]];
        [ordersAPI cancel];
        [ordersAPI setCharacter:character];
    }
}

- (void)sortUsingDescriptors:(NSArray *)descriptors
{
    [[self orders] sortUsingDescriptors:descriptors];
}

- (IBAction)reload:(id)sender
{
    [ordersAPI run];
}

- (void)requestMarketOrder:(NSNumber *)orderID
{
    NSAssert( nil != orderID, @"Missing order ID in [MarketOrders requestMarketOrder]" );
    METRowsetEnumerator *temp = [[METRowsetEnumerator alloc] initWithCharacter:[self character] API:XMLAPI_CHAR_ORDERS forDelegate:self];
    [temp setCheckCachedDate:NO];
    [temp runWithURLExtras:[NSString stringWithFormat:@"&orderID=%ld", (unsigned long)[orderID unsignedIntegerValue]]];
}

- (void)apiDidFinishLoading:(METRowsetEnumerator *)rowset withError:(NSError *)error
{
    if( error )
    {
        if( [error code] == METRowsetCached )
            NSLog( @"Skipping Market Orders because of Cached Until date." ); // handle cachedUntil errors differently
        else if( [error code] == METRowsetMissingCharacter )
            ; // don't bother logging an error but maybe add an assert?
        else
            NSLog( @"Error requesting Market Orders: %@", [error localizedDescription] );
        
        if( [[self delegate] respondsToSelector:@selector(ordersSkippedUpdating)] )
        {
            [[self delegate] performSelector:@selector(ordersSkippedUpdating)];
        }
        
        if( rowset != ordersAPI )
            [rowset release];
        return;
    }
    
    NSArray *newOrders = [self marketOrdersFromRowset:rowset];
    
    if( rowset == ordersAPI )
    {
        [[self orders] removeAllObjects];
        [[self orders] addObjectsFromArray:newOrders];
        
        if( [[self delegate] respondsToSelector:@selector(ordersFinishedUpdating:)] )
        {
            [[self delegate] performSelector:@selector(ordersFinishedUpdating:) withObject:[self orders]];
        }
    }
    else
    {
        if( [[self delegate] respondsToSelector:@selector(orderFinishedUpdating:)] )
        {
            [[self delegate] performSelector:@selector(orderFinishedUpdating:) withObject:newOrders];
        }
        [rowset release];
    }
}

/* Sample xml for market orders:
 <eveapi version="2">
 <currentTime>2008-02-04 13:28:18</currentTime>
 <result>
 <rowset name="orders" key="orderID" columns="orderID,charID,stationID,volEntered,volRemaining,minVolume,orderState,typeID,range,accountKey,duration,escrow,price,bid,issued">
 <row orderID="639356913" charID="118406849" stationID="60008494" volEntered="25" volRemaining="18" minVolume="1" orderState="0" typeID="26082" range="32767" accountKey="1000" duration="3" escrow="0.00" price="3398000.00" bid="0" issued="2008-02-03 13:54:11"/>
 <row orderID="639477821" charID="118406849" stationID="60004357" volEntered="25" volRemaining="24" minVolume="1" orderState="0" typeID="26082" range="32767" accountKey="1000" duration="3" escrow="0.00" price="3200000.00" bid="0" issued="2008-02-02 16:39:25"/>
 <row orderID="639587440" charID="118406849" stationID="60003760" volEntered="25" volRemaining="4" minVolume="1" orderState="0" typeID="26082" range="32767" accountKey="1000" duration="1" escrow="0.00" price="3399999.98" bid="0" issued="2008-02-03 22:35:54"/>
 </rowset>
 </result>
 <cachedUntil>2008-02-04 14:28:18</cachedUntil>
 </eveapi>
 */-(NSArray *) marketOrdersFromRowset:(METRowsetEnumerator *)rowset
{
    NSMutableArray *localOrders = [NSMutableArray array];
    
    for( METXmlNode *row in rowset )
    {
        //  <row notificationID="304084087" typeID="16" senderID="797400947" sentDate="2010-04-12 12:32:00" read="0"/>
        NSDictionary *properties = [row properties];
        NSUInteger orderID = [[properties objectForKey:@"orderID"] integerValue];
        if( 0 != orderID )
        {
            MarketOrder *order = [[[MarketOrder alloc] init] autorelease];
            [order setOrderID:orderID];
            [order setCharID:[[properties objectForKey:@"charID"] integerValue]];
            [order setStationID:[[properties objectForKey:@"stationID"] integerValue]];
            [order setVolEntered:[[properties objectForKey:@"volEntered"] integerValue]];
            [order setMinVolume:[[properties objectForKey:@"minVolume"] integerValue]];
            [order setVolRemaining:[[properties objectForKey:@"volRemaining"] integerValue]];
            [order setAccountKey:[[properties objectForKey:@"accountKey"] integerValue]];
            [order setDuration:[[properties objectForKey:@"duration"] integerValue]];
            [order setTypeID:[[properties objectForKey:@"typeID"] integerValue]];
            [order setPrice:[[properties objectForKey:@"price"] doubleValue]];
            [order setEscrow:[[properties objectForKey:@"escrow"] doubleValue]];
            [order setIssued:[NSDate dateWithNaturalLanguageString:[properties objectForKey:@"issued"]]];

            NSInteger intValue = [[properties objectForKey:@"orderState"] integerValue];
            OrderStateType stType = OrderStateUnknown;
            switch( intValue )
            {
                case 0: stType = OrderStateActive; break;
                case 1: stType = OrderStateClosed; break;
                case 2: stType = OrderStateExpired; break;
                case 3: stType = OrderStateCancelled; break;
                case 4: stType = OrderStatePending; break;
                case 5: stType = OrderStateCharacterDeleted; break;
                default: stType = OrderStateUnknown; break;
                    
            }
            [order setOrderState:stType];

            if( [[properties objectForKey:@"bid"] isEqualToString:@"0"] )
                [order setBuy:NO];
            else
                [order setBuy:YES];

            {
                // The range this order is good for. For sell orders, this is always 32767.
                // For buy orders, allowed values are: -1 = station, 0 = solar system, 5/10/20/40 Jumps, 32767 = region.
                NSInteger range = [[properties objectForKey:@"range"] integerValue];
                NSString *rangeString = nil;
                // TODO: I think 1, 2 and 3 are also valid values.
                switch( range )
                {
                    case -1: rangeString = NSLocalizedString( @"Station", @"Market Order Range: Station" ); break;
                    case 0: rangeString = NSLocalizedString( @"Solar System", @"Market Order Range: Solar System" ); break;
                    case 1: rangeString = NSLocalizedString( @"1 Jump", @"Market Order Range: 1 Jump" ); break;
                    case 2: rangeString = NSLocalizedString( @"2 Jumps", @"Market Order Range: 2 Jumps" ); break;
                    case 3: rangeString = NSLocalizedString( @"3 Jumps", @"Market Order Range: 3 Jumps" ); break;
                    case 5: rangeString = NSLocalizedString( @"5 Jumps", @"Market Order Range: 5 Jumps" ); break;
                    case 10: rangeString = NSLocalizedString( @"10 Jumps", @"Market Order Range: 10 Jumps" ); break;
                    case 20: rangeString = NSLocalizedString( @"20 Jumps", @"Market Order Range: 20 Jumps" ); break;
                    case 40: rangeString = NSLocalizedString( @"40 Jumps", @"Market Order Range: 40 Jumps" ); break;
                    case 32767: rangeString = NSLocalizedString( @"Region", @"Market Order Range: Region" ); break;
                    default:
                        rangeString = @"Unknown";
                        NSLog( @"Unknown range when reading market orders: %ld", (long)range );
                        break;
                }
                [order setRange:rangeString];
            }
            
            [localOrders addObject:order];
        }
    }
    
    return localOrders;
}

@end
