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

#import "DBManager.h"
#import "Config.h"
#import "XmlHelpers.h"
#import "XmlFetcher.h"
#import "METURLRequest.h"

#import "bsd-base64.h"

#import <libxml/tree.h>
#import <bzlib.h>
#import <sqlite3.h>
#import <openssl/sha.h>

#import "CCPDatabase.h"

#define DATABASE_BZ2_FILE @"database.sql.bz2"
#define UPDATE_FILE @"database.xml"

#define DBUPDATE_DEFN @"database.xml"
#define DATABASE_SQL_BZ2 @"database.sql.bz2"
#define DATABASE_SQL @"database.sql"
#define DATABASE_SQLITE @"database.sqlite"
#define DATABASE_SQLITE_TMP @"database.sqlite.tmp"


@interface DBManager() <XmlFetcherDelegate>

-(void) xmlDocumentFinished:(BOOL)status xmlPath:(NSString*)path xmlDocName:(NSString*)docName;

/* Read the XML file and return the db version number.
 If versionOnly is true then don't set any member variables
 otherwise set availableVersion, sha1_bzip, sha1_dec, sha1_database and file;
 */
-(NSInteger) parseDBXmlVersion:(NSString*)file versionOnly:(BOOL)versionOnly;

-(void) progressThread:(double)currentProgress;
/*a message to display to the user about the current progress*/
-(void) logProgressThread:(NSString*)progressMessage;

-(void) closeWindow:(id)object;

- (BOOL)checkIncludedDB;

/*
 display the modal window and build the database
 returns immediately, signals when done
 */
-(void)buildDatabase;

@end

@implementation DBManager

-(DBManager*) init
{
    if(self = [super initWithWindowNibName:@"DatabaseUpdate"]){
        availableVersion = -1;
    }
    return self;
}

-(void) dealloc
{
    [sha1_dec release];
    [sha1_bzip release];
    [file release];
    [sha1_database release];
    [super dealloc];
}

-(void) awakeFromNib
{
    [progressIndicator setIndeterminate:NO];
    [progressIndicator setUsesThreadedAnimation:YES];
    [progressIndicator setDoubleValue:0.0];
    [progressIndicator setStyle:NSProgressIndicatorBarStyle];
}

-(NSInteger) availableVersion
{
    return availableVersion;
}

-(void) setDelegate:(id)del
{
    delegate = del;
}

-(id) delegate
{
    return delegate;
}

-(void) closeWindow:(id)object
{
	[[self window]close];
}

-(IBAction)cancel:(id)sender
{
    cancelling = YES;
    [remoteFetcher cancel];
    [dbDownload cancel];
    // cancelling an NSURLDownload doesn't provide any feedback so we have to do it ourselves
    [self download:dbDownload didFailWithError:[NSError errorWithDomain:@"User Cancelled" code:1 userInfo:nil]];
}

-(void) progressThread:(double)currentProgress
{
    dispatch_async(dispatch_get_main_queue(),^{
        [progressIndicator setDoubleValue:currentProgress];
    });
}

-(void) logProgressThread:(NSString*)progressMessage
{
    dispatch_async(dispatch_get_main_queue(),^{
        [textField setStringValue:progressMessage?progressMessage:@"Unknown Download Error"];
    });
}

-(NSInteger) parseDBXmlVersion:(NSString*)xmlPath versionOnly:(BOOL)versionOnly
{
    NSInteger ver = -1;
    
    if( !xmlPath )
        return ver;
    
	xmlDoc *doc = xmlReadFile([xmlPath fileSystemRepresentation], 0,0);
	if(doc == NULL){
		return ver;
	}
	
	xmlNode *node = xmlDocGetRootElement(doc);
	if(node == NULL){
		xmlFreeDoc(doc);
		return ver;
	}
	
	NSString *verStr = findAttribute(node,(xmlChar*)"version");
    ver = [verStr integerValue];
    
    if( !versionOnly )
    {
        availableVersion = ver;
        
        for(xmlNode *cur_node = node->children;
            cur_node != NULL;
            cur_node = cur_node->next)
        {
            if(cur_node->type != XML_ELEMENT_NODE){
                continue;
            }
            
            if(xmlStrcmp(cur_node->name,(xmlChar*)"file") == 0){
                file = getNodeText(cur_node);
                [file retain];
            }else if(xmlStrcmp(cur_node->name,(xmlChar*)"sha1_bzip") == 0){
                sha1_bzip = getNodeText(cur_node);
                [sha1_bzip retain];
            }else if(xmlStrcmp(cur_node->name,(xmlChar*)"sha1_dec") == 0){
                sha1_dec = getNodeText(cur_node);
                [sha1_dec retain];
            }else if(xmlStrcmp(cur_node->name,(xmlChar*)"sha1_built") == 0){
                sha1_database = getNodeText(cur_node);
                [sha1_database retain];
            }
        }
    }
	
	xmlFreeDoc(doc);
    return ver;
}

/* If a newer version of the Database is included in the app bundle, then
 copy it into the correct location and proceed as if we had downloaded it.
 */
- (BOOL)checkIncludedDB
{
    if( ![self checkAndCreateRootDirectory] )
        return NO;

    NSString *includedDBXML = [[NSBundle mainBundle] pathForResource:@"database" ofType:@"xml" inDirectory:@"Database"];
    
    if( [[NSFileManager defaultManager] fileExistsAtPath:includedDBXML] )
    {
        [self parseDBXmlVersion:includedDBXML versionOnly:NO];
		BOOL update = (availableVersion > [CCPDatabase dbVersion]);
        if( update )
        {
            NSError *error = nil;
            NSString *dbXml = [Config buildPathSingle:DBUPDATE_DEFN];
            NSString *includedDB = [[NSBundle mainBundle] pathForResource:@"database.sql" ofType:@"bz2" inDirectory:@"Database"];
            NSString *dbTarball = [Config buildPathSingle:DATABASE_SQL_BZ2];
            
            // can't copy over existing file, so remove any older version first
            if( [[NSFileManager defaultManager] fileExistsAtPath:dbXml]
               && ![[NSFileManager defaultManager] removeItemAtPath:dbXml error:&error] )
            {
                NSLog( @"Unable to remove older database XML file." );
                return NO;
            }
            if( [[NSFileManager defaultManager] fileExistsAtPath:dbTarball]
               && ![[NSFileManager defaultManager] removeItemAtPath:dbTarball error:&error] )
            {
                NSLog( @"Unable to remove older database bz2 file." );
               return NO;
            }

            if( ![[NSFileManager defaultManager] copyItemAtPath:includedDBXML toPath:dbXml error:&error] )
            {
                NSLog( @"Unable to copy included database XML file." );
                return NO;
            }
            if( ![[NSFileManager defaultManager] copyItemAtPath:includedDB toPath:dbTarball error:&error] )
            {
                NSLog( @"Unable to copy included database zip file." );
                return NO; // should delete the copied over xml file at this point
            }
            
            return YES;
        }
    }
    
    return NO;
}

#pragma mark NSURLDownload delegate methods

/*
 these delegates are called from within the main thread, so there is no need for
 performSelectorOnMainThread
 */
-(void) downloadFinished:(NSURLDownload*)download
{
    [dbDownload release];
    dbDownload = nil;
    
	[downloadResponse release];
	downloadResponse = nil;
	 
	NSNotification *not = [NSNotification notificationWithName:NOTE_DATABASE_DOWNLOAD_COMPLETE object:self];
	[[NSNotificationCenter defaultCenter]postNotification:not];
	
    [self buildDatabase];
}

- (void)download:(NSURLDownload *)download didReceiveResponse:(NSURLResponse *)response
{
	[downloadResponse release];
	downloadResponse = [response retain];
	bytesReceived = 0;
}

-(void) downloadDidBegin:(NSURLDownload *)download
{
	[self logProgressThread:@"Downloading Eve Database"];
}

- (void)downloadDidFinish:(NSURLDownload *)download
{
	[self logProgressThread:@"Download finished - Please restart to apply the new database"];
	[self downloadFinished:download];
}

- (void)download:(NSURLDownload *)download didReceiveDataOfLength:(NSUInteger)length
{
	long long expectedLength = [downloadResponse expectedContentLength];
	
	bytesReceived += length;
	
	if(expectedLength != NSURLResponseUnknownLength){
		double percentComplete = (bytesReceived / (double)expectedLength) * (double)100.0;
		[self progressThread:percentComplete];
	}else{
		[self logProgressThread:[NSString stringWithFormat:@"Received %lu bytes", (unsigned long)length]];
	}
}

- (void)download:(NSURLDownload *)download didFailWithError:(NSError *)error
{
    NSLog( @"Database download failed: %@", [error localizedDescription] );
	[self logProgressThread:[error localizedFailureReason]];
	[self downloadFinished:download];
}


#pragma mark Ugly bastard function to build the new database

/*any resemblance to this function and good OO coding practice is purely coincedental */

-(BOOL) privateBuildDatabase
{
	int bzerror;
	NSString *str;
	unsigned char *buffer;
	int bytes_read;
	//int rc;
	//sqlite3 *db;
	//char *error = NULL;
	FILE *fin;
	FILE *fout;
	SHA_CTX digest_ctx;
	size_t len;
	unsigned char sha_digest[SHA_DIGEST_LENGTH];
	BOOL status = NO;
	
	
#define MEGABYTE 1048576
	
	/*read the SHA1 hashes*/
	str = [Config buildPathSingle:DBUPDATE_DEFN];
	[self parseDBXmlVersion:str versionOnly:NO];
	
	
	str = [Config buildPathSingle:DATABASE_SQL_BZ2];
	if(![[NSFileManager defaultManager]
		 fileExistsAtPath:str])
	{
		NSLog(@"Can't find new database archive. aborting");
		goto _finish_cleanup;
	}
	
	fin = fopen([str fileSystemRepresentation],"rb");
	if(fin == NULL){
		NSLog(@"Couldn't open database archive");
		goto _finish_cleanup;
	}
	
	buffer = malloc(MEGABYTE);
	
	if(buffer == NULL){
		/*yeah, right*/
		fclose(fin);
		goto _finish_cleanup;
	}
	
	[self logProgressThread:NSLocalizedString(@"Verifying tarball",@"database verification process")];
	[self progressThread:1.0];
	
	SHA1_Init(&digest_ctx);
	while ((len = fread(buffer,1,MEGABYTE,fin))) {
		SHA1_Update(&digest_ctx,buffer,len);
	}
	SHA1_Final(sha_digest,&digest_ctx);
	
	b64_ntop(sha_digest,SHA_DIGEST_LENGTH,(char*)buffer,MEGABYTE);
	
	if(![sha1_bzip isEqualToString:[NSString stringWithUTF8String:(const char*)buffer]]){
		/*SHA1 Digest failed!*/
		NSLog(@"SHA1 bz2 hashing failed ('%@' != '%s')",sha1_bzip,buffer);
		[self logProgressThread:@"Tarball verification failed"];
		fclose(fin);
		free(buffer);
		goto _finish_cleanup;
	}
	
	[self logProgressThread:@"Tarball verification succeeded"];
	[self progressThread:2.0];
	
	rewind(fin);
	
	str = [Config buildPathSingle:DATABASE_SQL];
	fout = fopen([str fileSystemRepresentation],"w+");
	if(fout == NULL){
		fclose(fin);
		fclose(fout);
		free(buffer);
		NSLog(@"Couldn't open output file");
		goto _finish_cleanup;
	}
	
	[self logProgressThread:@"Extracting & Verifying Tarball"];
	[self progressThread:3.0];
	
	
	BZFILE *compress = BZ2_bzReadOpen(&bzerror,fin,0,0,NULL,0);
	if(bzerror != BZ_OK){
		[self logProgressThread:@"Decompression error"];
		NSLog(@"Bzip2 error!");
		free(buffer);
		fclose(fin);
		fclose(fout);
		goto _finish_cleanup;
	}
	
	bzerror = BZ_OK;
	SHA1_Init(&digest_ctx);
	while (bzerror == BZ_OK) {
		bytes_read = BZ2_bzRead(&bzerror,compress,buffer,MEGABYTE);
		if(bzerror == BZ_OK || bzerror == BZ_STREAM_END){
			fwrite(buffer, 1, bytes_read, fout);
			SHA1_Update(&digest_ctx,buffer,bytes_read);
		}
	}
	SHA1_Final(sha_digest,&digest_ctx);
	
	//close the uncompressed output file
	fclose(fout);
		
	b64_ntop(sha_digest,SHA_DIGEST_LENGTH,(char*)buffer,MEGABYTE);
	
	if(![sha1_dec isEqualToString:[NSString stringWithUTF8String:(char*)buffer]]){
		/*SHA1 Digest failed!*/
		NSLog(@"SHA1 sql hashing failed ('%@' != '%s')",sha1_dec,buffer);
		[self logProgressThread:@"SQL verification failed"];
		fclose(fin);
		free(buffer);
		//[delegate newDatabaseBuilt:self status:NO];
		goto _finish_cleanup;
	}
	
	free(buffer);
	
	BZ2_bzReadClose(&bzerror,compress);
	fclose(fin);
	
	[self logProgressThread:
	 NSLocalizedString(@"Tarball extracted and verified",)
	 ];
	[self progressThread:4.0];
	
	str = [Config buildPathSingle:DATABASE_SQLITE_TMP];
	
	[[NSFileManager defaultManager] 
	 removeItemAtPath:str error:nil];
	
	[self logProgressThread:NSLocalizedString(@"Building Database",)];
	[self progressThread:5.0];

	/*
	 fork and exec sqlite to build the database.
	 the old approach used C code to read the file and manually
	 read the queries and build the DB, which was slow and crap.
	 */
	NSTask *task = [[NSTask alloc]init];
	[task setLaunchPath:@"/usr/bin/sqlite3"];

	NSArray *args = [NSArray arrayWithObjects:
					 @"-init",
					 [Config buildPathSingle:DATABASE_SQL],
					 str,
					 @".quit",nil];
	
	[task setArguments:args];
	[task launch];
	[task waitUntilExit];
	[task release];
	
	[self progressThread:7.0];
	
	NSLog(@"Database successfully built!");
	
	/*remove the old database*/
	str = [Config buildPathSingle:DATABASE_SQLITE];
	[[NSFileManager defaultManager] 
	 removeItemAtPath:str error:nil];
	
	/*rename the file*/
	str = [Config buildPathSingle:DATABASE_SQLITE_TMP];
	NSString *str2 = [Config buildPathSingle:DATABASE_SQLITE];
	[[NSFileManager defaultManager]
	 moveItemAtPath:str
	 toPath:str2 
	 error:NULL];
	
	[self logProgressThread:NSLocalizedString(@"All done!  Please Restart.",
											  @"Database construction complete")
	 ];
		
	status = YES;
	
_finish_cleanup:
	/*remove xml defn*/
	str = [Config buildPathSingle:DBUPDATE_DEFN];
	[[NSFileManager defaultManager]
	 removeItemAtPath:str error:nil];
	/*remove sql*/
	str = [Config buildPathSingle:DATABASE_SQL];
	[[NSFileManager defaultManager] 
	 removeItemAtPath:str error:nil];
	/*remove bzip sql*/
	str = [Config buildPathSingle:DATABASE_SQL_BZ2];
	[[NSFileManager defaultManager] 
	 removeItemAtPath:str error:nil];
	
	return status;
}

-(void) threadBuildDatabase:(NSCondition*)sig
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc]init];
	
	[self privateBuildDatabase];
		
	//Database has been built.  close the window
	
	[self performSelectorOnMainThread:@selector(closeWindow:) 
						   withObject:nil 
						waitUntilDone:YES];
	
	//Notifiy the app it may continue its next stage of execution.
    dispatch_async(dispatch_get_main_queue(),^{
        NSNotification *not = [NSNotification notificationWithName:NOTE_DATABASE_BUILD_COMPLETE object:self];
        [[NSNotificationCenter defaultCenter] postNotification:not];
    });

	[pool drain];
}

-(void)buildDatabase
{
	[[self window] makeKeyAndOrderFront:nil];

	[progressIndicator setMinValue:0.0];
	[progressIndicator setMaxValue:7.0];
	[progressIndicator setDoubleValue:0.0];
	[title setStringValue:NSLocalizedString(@"Building Database", @"database constuction start")];
    
	[NSThread detachNewThreadSelector:@selector(threadBuildDatabase:) 
							 toTarget:self 
						   withObject:nil];
	
}

/* Return YES if it exists or if we create it. */
-(BOOL) checkAndCreateRootDirectory
{
    NSString *savePath = [[NSUserDefaults standardUserDefaults] stringForKey:UD_ROOT_PATH];
    if(![[NSFileManager defaultManager] fileExistsAtPath:savePath])
    {
        NSError *error = nil;
        // Directory does not exist. create it.
        if( ![[NSFileManager defaultManager] createDirectoryAtPath:savePath
                                       withIntermediateDirectories:YES
                                                        attributes:nil
                                                             error:&error] )
        {
            NSLog( @"Unable to create root directory: %@", [error debugDescription] );
            return NO;
        }
    }
    return YES;
}

-(BOOL) downloadDatabase
{
    if( ![self checkAndCreateRootDirectory] )
        return NO;
    
    [progressIndicator setMinValue:0.0];
    [progressIndicator setMaxValue:100.0];
    [progressIndicator setDoubleValue:0.0];
    [title setStringValue:NSLocalizedString(@"Downloading database",@"download new database export")];
    
    [[self window] makeKeyAndOrderFront:nil];

	NSURL *url = [NSURL URLWithString:[[NSUserDefaults standardUserDefaults] stringForKey:UD_DB_SQL_URL]];
    METURLRequest *request = [METURLRequest requestWithURL:url];
	dbDownload = [[NSURLDownload alloc]initWithRequest:request delegate:self];
	
	if(dbDownload == nil){
		[self logProgressThread:@"Error creating connection!"];
        return NO;
	}else{
		NSString *dest = [Config filePath:DATABASE_SQL_BZ2,nil];
		[dbDownload setDestination:dest allowOverwrite:YES];
		[dbDownload setDeletesFileUponFailure:YES];
	}
    return YES;
}

-(void) xmlDocumentFinished:(BOOL)status
                    xmlPath:(NSString*)path
                 xmlDocName:(NSString*)docName
{
    if( [docName isEqualToString:UPDATE_FILE] )
    {
        [self databaseCheckAndUpdate2];
    }
}

-(void) xmlDidFailWithError:(NSError*)xmlErrorMessage
                    xmlPath:(NSString*)path
                 xmlDocName:(NSString*)docName
{
    NSLog(@"Database XML connection failed! (%@)",[xmlErrorMessage localizedDescription]);
}

-(BOOL) xmlValidateData:(NSData*)xmlData xmlPath:(NSString*)path xmlDocName:(NSString*)docName
{
    return YES;
}

- (NSString *)temporaryFilePath
{
    NSString *guid = [[NSProcessInfo processInfo] globallyUniqueString];
    return [NSTemporaryDirectory() stringByAppendingPathComponent:guid];
}

/* Start download of the database xml from the URL stored in user defaults
   When the XmlFetcher is done (fail or succeed) it will call databaseCheckAndUpdate2
 */
- (void) databaseCheckAndUpdate:(BOOL)force
{
    cancelling = NO;
    
    NSInteger minVer = [[NSUserDefaults standardUserDefaults] integerForKey:UD_DATABASE_MIN_VERSION];
    currentVersion = [CCPDatabase dbVersion];
    
    if( !force && (currentVersion >= minVer) )
    {
        dispatch_async(dispatch_get_main_queue(),^{
            NSNotification *not = [NSNotification notificationWithName:NOTE_DATABASE_BUILD_COMPLETE object:self];
            [[NSNotificationCenter defaultCenter] postNotification:not];
        });
        return;
    }
    
    [[self window] makeKeyAndOrderFront:nil];
    [title setStringValue:NSLocalizedString(@"Checking Database Versions",@"checking database versions")];    
    [self logProgressThread:NSLocalizedString(@"Checking remote version",)];

    NSString *url = [NSString stringWithString:[[NSUserDefaults standardUserDefaults] stringForKey:UD_DB_UPDATE_URL]];
    
    remoteFetcher = [[XmlFetcher alloc] initWithDelegate:self];
    NSString *tempXMLPath = [[self temporaryFilePath] stringByAppendingPathExtension:@"xml"];
    [remoteFetcher saveXmlDocument:url docName:UPDATE_FILE savePath:tempXMLPath];
}

/*
 Check two different versions and compare to min version
 2) db included in application
 3) db at URL in preferences
 */
- (void) databaseCheckAndUpdate2
{
    NSInteger minVer = [[NSUserDefaults standardUserDefaults] integerForKey:UD_DATABASE_MIN_VERSION];
    NSString *remoteXMLPath = [[[remoteFetcher savePath] retain] autorelease];
    
    // make sure this goes away. Or we could keep it around if it can be used multiple times.
    [remoteFetcher autorelease];
    remoteFetcher = nil;
    
    NSInteger includedVer = [self parseDBXmlVersion:[[NSBundle mainBundle] pathForResource:@"database" ofType:@"xml" inDirectory:@"Database"] versionOnly:YES];
    NSInteger remoteVer = [self parseDBXmlVersion:remoteXMLPath versionOnly:YES];
    
    NSLog( @"Database check min/current/included/external: %ld/%ld/%ld/%ld", (long)minVer, (long)currentVersion, (long)includedVer, (long)remoteVer );
    [self logProgressThread:NSLocalizedString(@"Comparing versions",)];

    if( (includedVer >= remoteVer) && (includedVer > currentVersion) )
    {
        [title setStringValue:NSLocalizedString(@"Building Database", @"database constuction start")];
        [self logProgressThread:NSLocalizedString(@"Using built-in database",)];
        if( [self checkIncludedDB] )
        {
            [self buildDatabase];
            return; // notification will be sent when the DB is built
        }
    }
    if( (remoteVer > includedVer) && (remoteVer > currentVersion) )
    {
        // install remoteVer
        BOOL failed = NO;
        NSString *path = [Config buildPathSingle:DBUPDATE_DEFN];
        NSError *error = nil;
        
        if( ![self checkAndCreateRootDirectory] )
            failed = YES;

        // can't copy over existing file, so remove any older version first
        if( [[NSFileManager defaultManager] fileExistsAtPath:path]
           && ![[NSFileManager defaultManager] removeItemAtPath:path error:&error] )
        {
            NSLog( @"Unable to remove older database XML file." );
            failed = YES;
        }
        
        if( ![[NSFileManager defaultManager] moveItemAtPath:remoteXMLPath toPath:path error:&error] )
        {
            NSLog( @"Unable to move temporary database XML file: %@", [error localizedDescription] );
            failed = YES;
        }
        if( !failed )
        {
            [self parseDBXmlVersion:path versionOnly:NO];
            
            if( [self downloadDatabase] )
                return; // notification will be sent when the DB is built
        }
    }
    
    [self closeWindow:self];
    
    // If we got here either we're up-to-date, or we failed.
    // Either way the main controller needs to know to proceed.
    dispatch_async(dispatch_get_main_queue(),^{
        NSNotification *not = [NSNotification notificationWithName:NOTE_DATABASE_BUILD_COMPLETE object:self];
        [[NSNotificationCenter defaultCenter] postNotification:not];
    });
}
@end
