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

#import "GlobalData.h"


#import "SkillTree.h"
#import "CertTree.h"
#import "Config.h"
#import "macros.h"
#import "CCPDatabase.h"


@implementation GlobalData

@synthesize skillTree;
@synthesize dateFormatter;
@synthesize certTree;
@synthesize database;

static GlobalData *_privateDataSingleton = nil;

/// See Also: https://developers.eveonline.com/resource/xml-api
// Default User-Agent would be something like: "Vitality/0.3.0a CFNetwork/673.3 Darwin/13.4.0 (x86_64) (MacPro6%2C1)"
+ (NSString *)userAgent
{
    static NSString *userAgent = nil;
    
    @synchronized(self)
    {
        if( !userAgent )
            userAgent = [[NSString alloc] initWithFormat:@"Vitality/%@ (https://github.com/sixones/vitality)", [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"]];
    }
    return userAgent;
}

/*not that this will ever be called*/
-(void)dealloc
{
	[skillTree release];
	[certTree release];
	[dateFormatter release];
	[database release];
	[super dealloc];
}

-(id) init
{
	self = [super init];
    _privateDataSingleton = self;
	 
	database = [[CCPDatabase alloc] initWithPath:[[NSUserDefaults standardUserDefaults] stringForKey:UD_ITEM_DB_PATH]];
	
    SkillTree *st = [database buildSkillTree];
	CertTree *ct = [database buildCertTree];
	
	if(st == nil){
		NSLog(@"Error: Failed to construct skill tree");
		return nil;
	}
	
	if(ct == nil){
		NSLog(@"Error: Failed to construct cert tree");
		return nil;
	}
		
	[NSDateFormatter setDefaultFormatterBehavior:NSDateFormatterBehavior10_4];
	
	dateFormatter = [[NSDateFormatter alloc] init];
	[dateFormatter setDateStyle:NSDateFormatterShortStyle];
	[dateFormatter setTimeStyle:NSDateFormatterShortStyle];
	
	skillTree = [st retain];
	certTree = [ct retain];
    
    return self;
}

+(id)allocWithZone:(NSZone *)zone {
    @synchronized(self) {
        if (_privateDataSingleton == nil) {
            _privateDataSingleton = [super allocWithZone:zone];
            return _privateDataSingleton;  // assignment and return on first allocation
        }
    }
    return nil; //on subsequent allocation attempts return nil
}

-(id)copyWithZone:(NSZone *)zone {
    return self;
}

-(id)retain {
    return self;
}


-(NSUInteger)retainCount {
    return UINT_MAX;  //denotes an object that cannot be release
}


-(oneway void)release {
    //do nothing    
}


-(id)autorelease {
    return self;    
}

+(GlobalData*) sharedInstance
{
	@synchronized(self) {
        if (_privateDataSingleton == nil) {
            [[self alloc] init]; // assignment not done here
        }
    }
    return _privateDataSingleton;	
}

-(NSString*) formatDate:(NSDate*)date
{
	return [dateFormatter stringFromDate:date];
}

-(NSInteger) databaseVersion
{
	NSString *path = [[NSUserDefaults standardUserDefaults] stringForKey:UD_ITEM_DB_PATH];
	
	if(![[NSFileManager defaultManager]fileExistsAtPath:path]){
		return 0;
	}
	
	CCPDatabase *db = [[CCPDatabase alloc]initWithPath:path];
	
	NSInteger version = [db dbVersion];
	
	[db release];
	
	return version;
	
}

-(BOOL) databaseUpToDate
{
	NSInteger version = [self databaseVersion];
	
	if(version >= [[NSUserDefaults standardUserDefaults] integerForKey:UD_DATABASE_MIN_VERSION]){
		return YES;
	}
	
	return NO;
}

@end
