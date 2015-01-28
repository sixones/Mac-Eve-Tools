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

#import <Cocoa/Cocoa.h>

@class DBManager;
@class XmlFetcher;

@protocol DBManagerDelegate

/*
	called if a new database is ready
	returns YES if a new version is ready to download.
 */
-(void) newDatabaseAvailable:(DBManager*)manager status:(BOOL)status;

@end


@interface DBManager : NSWindowController <NSURLDownloadDelegate>
{
    NSInteger currentVersion;
	NSInteger availableVersion;
    
	NSString *sha1_bzip;
	NSString *sha1_dec;
	NSString *sha1_database;
	NSString *file;
	
	id<DBManagerDelegate> delegate;
	
	IBOutlet NSPanel *progressPanel;
	IBOutlet NSButton *closeButton;
	IBOutlet NSTextField *textField;
	IBOutlet NSProgressIndicator *progressIndicator;
	IBOutlet NSTextField *title;
	
    NSURLDownload *dbDownload;
    NSURLResponse *downloadResponse;
	long long bytesReceived;
    
    XmlFetcher *remoteFetcher;
    
    NSTask *buildDBTask;
    
    BOOL cancelling;
}

- (void) databaseCheckAndUpdate:(BOOL)force; ///< If force is true, then check included and remote databases even if our current version is greater than or equal to the minimum version

-(void) setDelegate:(id<DBManagerDelegate>)del;
-(id<DBManagerDelegate>) delegate;

-(IBAction)cancel:(id)sender; ///< Cancel any download or build that is in progress

@end
