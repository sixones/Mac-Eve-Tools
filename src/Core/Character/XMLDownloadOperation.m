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

#import "XMLDownloadOperation.h"
#import "METURLRequest.h"

@implementation XMLDownloadOperation

@synthesize xmlDoc;
@synthesize xmlDocUrl;


-(BOOL) downloadXmlData:(NSString*)fullDocUrl
{
	NSError *error = nil;
	NSURLResponse *response = nil;
	
	NSURL *url = [NSURL URLWithString:fullDocUrl];
	
	METURLRequest *request = [[[METURLRequest alloc] initWithURL:url]autorelease];
	
	NSData *data = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
		
	if(data == nil){
		NSLog(@"Error downloading %@.  %@",fullDocUrl,[error description]);
		xmlDownloadError = [error retain];
		return NO;
	}
	
	xmlData = [data retain];
	
	return YES;
}

/*
 xmlData pointer must not be nil
 write the XML document to the pending directory.
 */
-(BOOL) writeXmlDocument:(NSString*)savePath
{
	//NSFileManager *fm = [NSFileManager defaultManager];
    NSError *error = nil;
    
	BOOL rc = [xmlData writeToFile:savePath options:0 error:&error];
// NSDataWritingAtomic
	if(!rc){
		NSLog(@"Failed to write XML document %@\n%@",savePath, [error localizedDescription]);
	}
	
	return rc;
}

-(void) main
{
	if( ![self downloadXmlData:xmlDocUrl] )
    {
		NSLog(@"Downloading error");
		return;
	}
	
	NSString *fileName = [xmlDoc lastPathComponent];
	NSString *filePath = [[self pendingDirectory]stringByAppendingFormat:@"/%@",fileName];
	
	[self writeXmlDocument:filePath];
}

-(void) dealloc
{
	[xmlData release];
	
	if(xmlDownloadError != nil){
		[xmlDownloadError release];
	}
	
	[xmlDoc release];
	[xmlDocUrl release];
	
	[super dealloc];
}

@end
