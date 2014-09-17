/*
 This file is part of Mac Eve Tools.
 
 Mac Eve Tools is free software: you can redistribute it and/or modify
 it under the terms of the GNU General Public License as published by
 the Free Software Foundation, either version 3 of the License, or
 (at your option) any later version.
 
 Mac Eve Tools is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 GNU General Public License for more details.
 
 You should have received a copy of the GNU General Public License
 along with Mac Eve Tools.  If not, see <http://www.gnu.org/licenses/>.
 
 Copyright Matt Tyson, 2009.
 */

#import "MTAPIKey.h"
#import "Config.h"
#import "XmlFetcher.h"
#import "XmlHelpers.h"

#import <libxml/parser.h>
#import <libxml/tree.h>

/* I haven't been able to find a reference for the mask values, so this is all pulled from the EveOnline API web page.
 Download the API key creation page and run the following shell script to extract all of the masks:
 */
 // grep apiEndPointControl APIKeyMasks.html | cut -d'<' -f3- | sed -e 's/ class="apiEndPointControl">/ /' | sed -e 's/a mask="\([0-9]*\)" \([^<]*\).*/\2 \1/' > masks.txt

/*
 === Character Masks ===
 Account and Market:
 WalletTransactions 4194304
 WalletJournal 2097152
 MarketOrders 4096
 AccountBalance 1
 
 Communications:
 NotificationTexts 32768
 Notifications 16384
 MailMessages 2048
 MailingLists 1024
 MailBodies 512
 ContactNotifications 32
 ContactList 16
 
 Private Information:
 Locations 134217728
 Contracts 67108864
 AccountStatus 33554432
 CharacterInfo 16777216
 UpcomingCalendarEvents 1048576
 SkillQueue 262144
 SkillInTraining 131072
 CharacterSheet 8
 CalendarEventAttendees 4
 AssetList 2
 
 Public Information:
 CharacterInfo 8388608
 Standings 524288
 Medals 8192
 KillLog 256
 FacWarStats 64
 
 Science and Industry:
 Research 65536
 IndustryJobs 128
 
 
 === Coporation Masks ===
 
 Account and Market:
 WalletTransactions 2097152
 WalletJournal 1048576
 Shareholders 65536
 MarketOrders 4096
 AccountBalance 1
 
 Communications:
 ContactList 16
 
 Corporation Members:
 MemberTrackingExtended 33554432
 Titles 4194304
 MemberTrackingLimited 2048
 MemberSecurityLog 1024
 MemberSecurity 512
 MemberMedals 4
 
 Outposts and Starbases:
 StarbaseList 524288
 StarbaseDetail 131072
 OutpostServiceDetail 32768
 OutpostList 16384
 
 Private Information:
 Locations 16777216
 Contracts 8388608
 ContainerLog 32
 CorporationSheet 8
 AssetList 2
 
 Public Information:
 Standings 262144
 Medals 8192
 KillLog 256
 FacWarStats 64
 
 Science and Industry:
 IndustryJobs 128

 */

static const long SkillQueueMask = 262144;
static const long SkillInTrainingMask = 131072;
static const long CharacterSheetMask = 8;
static const long ContractsMask = 67108864;
static const long MarketOrdersMask = 4096;

@interface MTAPIKey() <XmlFetcherDelegate>
@property (retain,readwrite) NSString *savePath;
@property (retain,readwrite) NSString *mask;
@property (retain,readwrite) NSString *type;
@property (retain,readwrite) NSDate *expires;

-(void) xmlDocumentFinished:(BOOL)status xmlPath:(NSString*)path xmlDocName:(NSString*)docName;

-(void) downloadXml;

-(NSString*)savePath;

-(BOOL) parseXmlDocument:(xmlDoc*) doc;
-(BOOL) loadXmlDocument;

@end

@implementation MTAPIKey

@synthesize keyID;
@synthesize verificationCode;
@synthesize savePath;
@synthesize mask;
@synthesize type;
@synthesize expires;

-(MTAPIKey *) initWithID:(NSString*)_keyID code:(NSString*)code delegate:(id<APIKeyValidationDelegate>)_delegate
{
    if( self = [super init] )
    {
        self.keyID = [_keyID retain];
        self.verificationCode = [code retain];
        self.savePath = [Config filePath:XMLAPI_ACCT_KEY,keyID,nil];
        delegate = _delegate;
    }
    return self;
}

-(void) validate
{
    // check cache time, then either download again or just read from disk
    [self downloadXml];
}

-(BOOL) parseXmlDocument:(xmlDoc*)doc
{
	xmlNode *root = xmlDocGetRootElement(doc);
	if(root == NULL){
		NSLog(@"error parsing XML document");
        NSRunAlertPanel(@"Unable to parse XML", @"This does not look like EVE Online's API. Perhaps the API is down or something is getting in the way of the request.", @"Close", nil, nil);
        
		return NO;
	}
	xmlNode *result = findChildNode(root,(xmlChar*)"result");
	if(result == NULL){
		NSLog(@"error parsing XML document");
        NSRunAlertPanel(@"Unable to parse XML", @"This does not look like EVE Online's API. Perhaps the API is down or something is getting in the way of the request.", @"Close", nil, nil);
        
		return NO;
	}
	xmlNode *key = findChildNode(result,(xmlChar*)"key");
	if(key == NULL){
		NSLog(@"error parsing XML document");
        NSRunAlertPanel(@"Unable to parse XML", @"This does not look like EVE Online's API. Perhaps the API is down or something is getting in the way of the request.", @"Close", nil, nil);
        
		return NO;
	}
    
    [self setMask:findAttribute(key,(xmlChar*)"accessMask")];
    [self setType:findAttribute(key,(xmlChar*)"type")];
    NSString *expireString = findAttribute(key,(xmlChar*)"expires");

    if( NULL != expireString )
    {
        NSDate *expiresDate = [NSDate dateWithNaturalLanguageString:expireString];
        [self setExpires:expiresDate];
    }

	return YES;
}

-(void) downloadXml
{
	XmlFetcher *f = [[XmlFetcher alloc]initWithDelegate:self];
	
	NSString *apiUrl = [Config getApiUrl:XMLAPI_ACCT_KEY
                                   keyID:self.keyID
                        verificationCode:self.verificationCode
								  charId:nil];
	
    [f saveXmlDocument:apiUrl
			   docName:XMLAPI_ACCT_KEY
			  savePath:[self savePath]];
	
	[f release];	
}

-(BOOL)loadXmlDocument
{
	xmlDoc *doc = xmlReadFile([[self savePath] fileSystemRepresentation],NULL, 0);
	
	if(doc == NULL){
		NSLog(@"Failed to read %@",[self savePath]);
		return NO;
	}
	
	BOOL rc = [self parseXmlDocument:doc];
	
	xmlFreeDoc(doc);
	
	return rc;
}

- (BOOL) validateOneMask:(long)_mask name:(NSString *)maskName status:(BOOL)rc errorString:(NSMutableString *)errorString
{
    if( !([[self mask] integerValue] &_mask) )
    {
        [errorString appendFormat:@"%@\n", maskName];
        rc = NO;
    }
    return rc;
}

-(void) xmlDocumentFinished:(BOOL)status xmlPath:(NSString*)path xmlDocName:(NSString*)docName
{
	if(status == NO){
		NSLog(@"Failed to download %@ to %@",docName,path);
		[delegate key:self didValidate:NO withError:nil];
        
		return;
	}
	
    NSMutableString *errorString = nil;
    NSError *error = nil;
	BOOL rc = [self loadXmlDocument];
	
    if( rc )
    {
        errorString = [NSMutableString stringWithString:@"API Key is missing the following permissions:\n"];
        
        rc = [self validateOneMask:CharacterSheetMask name:@"CharacterSheet" status:rc errorString:errorString];
        rc = [self validateOneMask:SkillQueueMask name:@"SkillQueue" status:rc errorString:errorString];
        rc = [self validateOneMask:SkillInTrainingMask name:@"SkillInTraining" status:rc errorString:errorString];
        rc = [self validateOneMask:ContractsMask name:@"Contracts" status:rc errorString:errorString];
        rc = [self validateOneMask:MarketOrdersMask name:@"MarketOrders" status:rc errorString:errorString];
    }
    
    if( !rc )
    {
        error = [NSError errorWithDomain:@"Vitality API Key" code:-100 userInfo:[NSDictionary dictionaryWithObjectsAndKeys:errorString, NSLocalizedDescriptionKey, nil]];
    }
    
	[delegate key:self didValidate:rc withError:error];
}

-(BOOL) xmlValidateData:(NSData*)xmlData xmlPath:(NSString*)path xmlDocName:(NSString*)docName
{
	BOOL rc = YES;
	const char *bytes = [xmlData bytes];
	
	xmlDoc *doc = xmlReadMemory(bytes,(int)[xmlData length], NULL, NULL, 0);
	
	xmlNode *root_node = xmlDocGetRootElement(doc);
	xmlNode *result = findChildNode(root_node,(xmlChar*)"error");
	
	if(result != NULL){
		NSLog(@"%@",getNodeText(result));
		rc = NO;
        
        NSRunAlertPanel(@"API Error", @"%@",@"Close",nil,nil, getNodeText(result));
	}
	
	xmlFreeDoc(doc);
	return rc;
}

-(void) xmlDidFailWithError:(NSError*)xmlErrorMessage xmlPath:(NSString*)path xmlDocName:(NSString*)docName
{
	NSLog(@"Connection failed! (%@)",[xmlErrorMessage localizedDescription]);
	
	NSRunAlertPanel(@"API Connection Error", @"%@",@"Close",nil,nil, [xmlErrorMessage localizedDescription]);
}

@end

