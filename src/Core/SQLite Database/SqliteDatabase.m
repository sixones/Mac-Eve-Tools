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

#import "SqliteDatabase.h"

#import <sqlite3.h>
#import "macros.h"

@implementation SqliteDatabase

-(SqliteDatabase*) initWithPath:(NSString*)dbPath
{
	if((self = [super init])){
		
		databasePath = [dbPath retain];
		path = strdup([dbPath fileSystemRepresentation]);
		pathLength = strlen(path);
	}
	return self;
}

-(void) dealloc
{
	[self closeDatabase];
	free(path);
	[databasePath release];
	[super dealloc];
}

-(sqlite3 *) openDatabase
{
	if(db == NULL){
		int rc  = sqlite3_open(path,&db);
		if(rc != SQLITE_OK){
			NSLog(@"%@ error: %s",[self className],sqlite3_errmsg(db));
			[self closeDatabase];
		}
	}
    return db;
}
-(void) closeDatabase
{	
	if(db != NULL){
		int rc;
				
		if((rc = sqlite3_close(db)) != SQLITE_OK){
			NSLog(@"%@ error: (%d) %s",[self className],rc,sqlite3_errmsg(db));
		}
		db = NULL;
	}
}

-(NSInteger) performCount:(const char*)query
{
	int rows,cols;
	int rc;
	BOOL isNull = (db == NULL);
	NSInteger count = 0;
	char **results;
	char *errormsg;
	
	if(isNull){
		[self openDatabase];
	}
	
	rc = sqlite3_get_table(db,query,&results,&rows,&cols,&errormsg);
	if(rc == SQLITE_OK){
		count = strtol(results[1],NULL,10);
		sqlite3_free_table(results);
	}
	
	if(isNull){
		[self closeDatabase];
	}
	return count;
}

-(BOOL) doesTableExist:(NSString *)tableName
{
    const char checkTable[] = "SELECT COUNT(*) FROM sqlite_master WHERE type='table' AND name=%Q;";
    sqlite3_stmt *checkStatement = NULL;
    char *strbuf = sqlite3_mprintf( checkTable, [tableName UTF8String] );

    int rc = sqlite3_prepare_v2( db, strbuf, (int)strlen(strbuf), &checkStatement, NULL );

    sqlite3_free(strbuf);

    if(rc != SQLITE_OK){
        
        NSLog(@"Error preparing check table statement: (%d) %s",rc,sqlite3_errmsg(db));
        if(checkStatement != NULL){
            sqlite3_finalize(checkStatement);
        }
        
        return NO;
    }
    
    while(sqlite3_step(checkStatement) == SQLITE_ROW)
    {
        NSInteger count = sqlite3_column_nsint(checkStatement,0);
        if( count > 0 )
        {
            sqlite3_finalize(checkStatement);
            return YES;
        }
    }
    
    sqlite3_finalize(checkStatement);

    return NO;
}

-(BOOL) doesTable:(NSString *)tableName haveColumn:(NSString *)colName
{
    const char checkTable[] = "SELECT %q FROM %q LIMIT 1;";
    sqlite3_stmt *checkStatement = NULL;
    char *strbuf = sqlite3_mprintf( checkTable, [colName UTF8String], [tableName UTF8String] );
    
    int rc = sqlite3_prepare_v2( db, strbuf, (int)strlen(strbuf), &checkStatement, NULL );
    
    sqlite3_free(strbuf);
    
    if( rc != SQLITE_OK )
    {
        if( checkStatement != NULL )
        {
            sqlite3_finalize(checkStatement);
        }
        return NO;
    }
    
    sqlite3_finalize(checkStatement);

    return YES;
}

-(BOOL) beginTransaction
{
	const char query[] = "BEGIN;";
	char *errmsg;
	
	int rc = sqlite3_exec(db,query,NULL,NULL,&errmsg);
	if(errmsg != NULL){
		[self logError:errmsg];
	}
	return (rc == SQLITE_OK);
}

-(BOOL) commitTransaction
{
	const char query[] = "COMMIT;";
	char *errmsg;
	
	int rc = sqlite3_exec(db,query,NULL,NULL,&errmsg);
	if(errmsg != NULL){
		[self logError:errmsg];
	}
	
	return (rc == SQLITE_OK);
}

-(BOOL) rollbackTransaction
{
	const char query[] = "ROLLBACK;";
	char *errmsg;
	
	int rc = sqlite3_exec(db,query,NULL,NULL,&errmsg);
	if(errmsg != NULL){
		[self logError:errmsg];
	}
	return (rc == SQLITE_OK);
}

-(void) logError:(char*)errmsg
{
	if(errmsg != NULL){
		NSLog(@"SQL Error: %s",errmsg);
		sqlite3_free(errmsg);
	}
}

@end
