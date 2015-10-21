//
//  METCharacter_CachedDates.m
//  Vitality
//
//  Created by Andrew Salamon on 10/20/15.
//  Copyright (c) 2015 Vitality Project. All rights reserved.
//

#import "METCharacter_CachedDates.h"
#import "CharacterDatabase.h"
#import <sqlite3.h>

@implementation Character(CachedDates)
-(BOOL) createCachedDateTable
{
    if( [[self database] doesTableExist:@"cachedDates"] )
        return YES;

    char *errmsg;
    const char createMasterTable[] = "CREATE TABLE cachedDates ( apiPath VARCHAR(1000) PRIMARY KEY, cachedUntilDate INTEGER );";
    
    sqlite3 *db = [[self database] openDatabase];
    
    [[self database] beginTransaction];
    
    int rc = sqlite3_exec(db,createMasterTable,NULL,NULL,&errmsg);
    if( SQLITE_OK != rc )
    {
        [[self database] logError:errmsg];
        [[self database] rollbackTransaction];
        return NO;
    }
    
    [[self database] commitTransaction];
    return YES;
}

- (void)setCachedUntil:(NSDate *)date forAPI:(NSString *)apiPath
{
    if( ![self createCachedDateTable] )
        return;
    
    CharacterDatabase *charDB = [self database];
    sqlite3 *db = [charDB openDatabase];
    const char insert_string[] = "INSERT OR REPLACE INTO cachedDates (apiPath, cachedUntilDate) VALUES (?,?);";
    sqlite3_stmt *insert_stmt;
    BOOL success = YES;
    int rc;
    
    rc = sqlite3_prepare_v2(db,insert_string,(int)sizeof(insert_string),&insert_stmt,NULL);
    if( rc != SQLITE_OK )
    {
        NSLog( @"%s: sqlite error: %s", __func__, sqlite3_errmsg(db) );
        return;
    }
    
    sqlite3_bind_text( insert_stmt, 1, [apiPath UTF8String], -1, NULL );
    sqlite3_bind_nsint( insert_stmt, 2, [date timeIntervalSince1970] ); // truncating fractions of a second
    
    rc = sqlite3_step(insert_stmt);
    if( (rc != SQLITE_DONE) && (rc != SQLITE_CONSTRAINT) )
    {
        NSLog(@"Error updating cachedDates table: %@ (code: %d)", apiPath, rc );
        success = NO;
    }
    
    sqlite3_finalize(insert_stmt);
    return;
}

- (BOOL)isCachedForAPI:(NSString *)apiPath
{
    if( ![self createCachedDateTable] )
        return NO;
    
    sqlite3_stmt *read_stmt;
    int rc;
    const char getMessages[] = "SELECT cachedUntilDate FROM cachedDates WHERE apiPath = ?;";
    sqlite3 *db = [[self database] openDatabase];
    
    rc = sqlite3_prepare_v2(db,getMessages,(int)sizeof(getMessages),&read_stmt,NULL);
    if( SQLITE_OK != rc )
    {
        NSLog( @"%s: sqlite error: %s", __func__, sqlite3_errmsg(db) );
        return NO;
    }
    
    sqlite3_bind_text( read_stmt, 1, [apiPath UTF8String], -1, NULL );
    
    NSDate *cachedDate = [NSDate distantPast];
    
    while( sqlite3_step(read_stmt) == SQLITE_ROW )
    {
        cachedDate = [NSDate dateWithTimeIntervalSince1970:sqlite3_column_nsint(read_stmt,0)];
    }
    
    sqlite3_finalize(read_stmt);
    
    return [cachedDate isGreaterThan:[NSDate date]];
}
@end
