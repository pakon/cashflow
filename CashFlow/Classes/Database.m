// -*-  Mode:ObjC; c-basic-offset:4; tab-width:8; indent-tabs-mode:nil -*-
/*
  CashFlow for iPhone/iPod touch

  Copyright (c) 2008, Takuya Murakami, All rights reserved.

  Redistribution and use in source and binary forms, with or without
  modification, are permitted provided that the following conditions are
  met:

  1. Redistributions of source code must retain the above copyright notice,
  this list of conditions and the following disclaimer. 

  2. Redistributions in binary form must reproduce the above copyright
  notice, this list of conditions and the following disclaimer in the
  documentation and/or other materials provided with the distribution. 

  3. Neither the name of the project nor the names of its contributors
  may be used to endorse or promote products derived from this software
  without specific prior written permission. 

  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
  "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
  LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
  A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR
  CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
  EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
  PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
  PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
  LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
  NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
  SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/

// SQLite データベース版

#import "Database.h"
#import "AppDelegate.h"
#import "DateFormatter2.h"

@implementation DBStatement

- (id)initWithStatement:(sqlite3_stmt *)st
{
    self = [super init];
    if (self != nil) {
        stmt = st;
    }
    return self;
}

- (void)dealloc
{
    if (stmt) {
        sqlite3_finalize(stmt);
    }
    [super dealloc];
}

- (int)step
{
    return sqlite3_step(stmt);
}

- (void)reset
{
    sqlite3_reset(stmt);
}

- (void)bindInt:(int)idx val:(int)val
{
    sqlite3_bind_int(stmt, idx+1, val);
}

- (void)bindDouble:(int)idx val:(double)val
{
    sqlite3_bind_double(stmt, idx+1, val);
}

- (void)bindCString:(int)idx val:(const char *)val
{
    sqlite3_bind_text(stmt, idx+1, val, -1, SQLITE_TRANSIENT);
}

- (void)bindString:(int)idx val:(NSString*)val
{
    sqlite3_bind_text(stmt, idx+1, [val UTF8String], -1, SQLITE_TRANSIENT);
}

- (void)bindDate:(int)idx val:(NSDate*)date
{
    [self bindCString:idx val:[Database cstringFromDate:date]];
}

- (int)colInt:(int)idx
{
    return sqlite3_column_int(stmt, idx);
}

- (double)colDouble:(int)idx
{
    return sqlite3_column_double(stmt, idx);
}

- (const char *)colCString:(int)idx
{
    const char *s = (const char*)sqlite3_column_text(stmt, idx);
    return s;
}

- (NSString*)colString:(int)idx
{
    const char *s = (const char*)sqlite3_column_text(stmt, idx);
    if (!s) {
        return @"";
    }
    NSString *ns = [NSString stringWithCString:s encoding:NSUTF8StringEncoding];
    return ns;
}

- (NSDate*)colDate:(int)idx
{
    NSDate *date = nil;
    const char *ds = [self colCString:idx];
    if (ds) {
        date = [Database dateFromCString:ds];
    }
    return date;
}

@end


/////////////////////////////////////////////////////////////////////////

@implementation Database

@synthesize handle;

static DateFormatter2 *dateFormatter = nil;
static Database *theDatabase = nil;

// singleton
+ (Database *)instance
{
    if (theDatabase == nil) {
        theDatabase = [[Database alloc] init];
    }
    return theDatabase;
}

+ (void)shutdown
{
    if (theDatabase) {
        [theDatabase release];
        theDatabase = nil;
    }
    // sqlite3_shutdown
}

- (id)init
{
    self = [super init];
    if (self != nil) {
        handle = 0;

        if (dateFormatter == nil) {
            dateFormatter = [[DateFormatter2 alloc] init];
            [dateFormatter setTimeZone: [NSTimeZone timeZoneWithAbbreviation:@"UTC"]];
            [dateFormatter setDateFormat: @"yyyyMMddHHmm"];
        }
    }
	
    return self;
}

- (void)dealloc
{
    if (handle != nil) {
        sqlite3_close(handle);
    }
    if (dateFormatter != nil) {
        [dateFormatter release];
        dateFormatter = nil;
    }
    [super dealloc];
}

- (void)execSql:(const char *)sql
{
    ASSERT(handle != 0);
	
    int result = sqlite3_exec(handle, sql, NULL, NULL, NULL);
    if (result != SQLITE_OK) {
        NSLog(@"sqlite3: %s", sqlite3_errmsg(handle));
        ASSERT(0);
    }
}

- (DBStatement *)prepare:(const char *)sql
{
    sqlite3_stmt *stmt;
    int result = sqlite3_prepare_v2(handle, sql, -1, &stmt, NULL);
    if (result != SQLITE_OK) {
        NSLog(@"sqlite3: %s", sqlite3_errmsg(handle));
        ASSERT(0);
    }

    DBStatement *dbs = [[[DBStatement alloc] initWithStatement:stmt] autorelease];
    return dbs;
}

- (int)lastInsertRowId
{
    return sqlite3_last_insert_rowid(handle);
}

- (void)beginTransaction
{
    [self execSql:"BEGIN;"];
}

- (void)commitTransaction
{
    [self execSql:"COMMIT;"];
}

+ (NSString *)dataFilePath
{
    NSString *dbPath = [AppDelegate pathOfDataFile:@"CashFlow.db"];
    return dbPath;
}

// データベースを開く
//   データベースがあったときは YES を返す。
//   なかったときは新規作成して NO を返す
- (BOOL)openDB
{
    // Load from DB
    NSString *dbPath = [Database dataFilePath];
	
    NSFileManager *fileManager = [NSFileManager defaultManager];
    BOOL isExistedDb = [fileManager fileExistsAtPath:dbPath];
	
    if (sqlite3_open([dbPath UTF8String], &handle) != 0) {
        // ouch!
        ASSERT(0);
    }
    return isExistedDb;
}

- (void)initializeDB
{
    // テーブル作成＆初期データ作成
    [Transaction createTable];
    [Asset createTable];
    [Category createTable];
}

//////////////////////////////////////////////////////////////////////////////////
// Utility

+ (NSDate*)dateFromCString:(const char *)str
{
    NSDate *date = [dateFormatter dateFromString:
                                      [NSString stringWithCString:str encoding:NSUTF8StringEncoding]];
    return date;
}

+ (const char *)cstringFromDate:(NSDate*)date
{
    const char *s = [[dateFormatter stringFromDate:date] UTF8String];
    return s;
}

@end