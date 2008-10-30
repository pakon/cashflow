// -*-  Mode:ObjC; c-basic-offset:4; tab-width:4; indent-tabs-mode:t -*-
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
// まだ試作中、、、

#import "DataModel2.h"
#import <sqlite3.h>

@implementation DataModel

@synthesize transactions;

// Factory
+ (DataModel*)allocWithLoad
{
	DataModel *dm = nil;

	// Load from DB
	Database *db = [[Database alloc] init];
	if ([db openDB]) {
		dm = [[DataModel alloc] init];
		dm.db = db;
		[db release];

		[dm reload];

		return dm;
	}

	// Backward compatibility
	NSString *dataPath = [CashFlowAppDelegate pathOfDataFile:@"Transactions.dat"];

	NSData *data = [NSData dataWithContentsOfFile:dataPath];
	if (data != nil) {
		NSKeyedUnarchiver *ar = [[[NSKeyedUnarchiver alloc] initForReadingWithData:data] autorelease];

		dm = [ar decodeObjectForKey:@"DataModel"];
		if (dm != nil) {
			[dm retain];
			[ar finishDecoding];
		
			[dm recalcBalance];
		}
	}
	if (dm == nil) {
		// initial or some error...
		dm = [[DataModel alloc] init];
	}

	// Ok, write database
	dm.db = db;
	[dm save];

	return dm;
}

// private
- (void)reload
{
	if (transactions) {
		[transactions release];
	}
	self.transactions = [db loadFromDB:0];
}

// private
- (void)save
{
	[db saveToDB:transactions asset:0];
}

- (BOOL)saveToStorage
{
	// do nothing
	return YES;
}

- (id)init
{
	[super init];

	transactions = [[NSMutableArray alloc] init];
	serialCounter = 0;

	return self;
}

- (void)dealloc 
{
	[transactions release];
	[db release];

	[super dealloc];
}

- (int)getTransactionCount
{
	return transactions.count;
}

- (Transaction*)getTransactionAt:(int)n
{
	return [transactions objectAtIndex:n];
}

- (void)assignSerial:(Transaction*)tr
{
	// do nothing
	// primary key is assigned by SQLite
}

- (void)insertTransaction:(Transaction*)tr
{
	int i;
	int max = [transactions count];
	Transaction *t = nil;

	// 挿入位置を探す
	for (i = 0; i < max; i++) {
		t = [transactions objectAtIndex:i];
		if ([tr.date compare:t.date] == NSOrderedAscending) {
			break;
		}
	}

	// 挿入
	[transactions insertObject:tr atIndex:i];

	// 全残高再計算
	[self recalcBalance];
	
	// 上限チェック
	if ([transactions count] > MAX_TRANSACTIONS) {
		[self deleteTransactionAt:0];
	}

	// DB 追加
	[db insertTransactionDB:tr];
}

- (void)replaceTransactionAtIndex:(int)index withObject:(Transaction*)t
{
	// copy serial
	Transaction *old = [transactions objectAtIndex:index];
	t.serial = old.serial;

	[transactions replaceObjectAtIndex:index withObject:t];

	// update DB
	[db updateTransaction:t];
}

- (void)deleteTransactionAt:(int)n
{
	char sql[128];

	Transaction *t = [transactions objectAtIndex:n];

	[db deleteTransaction:t];

	[transactions removeObjectAtIndex:n];
	[self recalcBalance];
}

- (void)deleteOldTransactionsBefore:(NSDate*)date
{
	[db deleteOldTransactionsBefore:date];
	[self reload];
}

- (int)firstTransactionByDate:(NSDate*)date
{
	for (int i = 0; i < transactions.count; i++) {
		Transaction *t = [transactions objectAtIndex:i];
		if ([t.date compare:date] != NSOrderedAscending) {
			return i;
		}
	}
	return -1;
}

// sort
static int compareByDate(Transaction *t1, Transaction *t2, void *context)
{
	return [t1.date compare:t2.date];
}

- (void)sortByDate
{
	[transactions sortUsingFunction:compareByDate context:NULL];
	[self recalcBalance];
}

- (void)recalcBalance
{
	Transaction *t;
	double bal;
	int max = [transactions count];
	int i;

	if (max == 0) return;

	// Get initial balance from first transaction
	t = [transactions objectAtindex:0];
	bal = t.balance;

	[db beginTransaction];

	// Recalculate balances
	for (i = 1; i < max; i++) {
		t = [transactions objectAtIndex:i];

		switch (t.type) {
		case TYPE_INCOME:
			bal += t.value;
			t.balance = bal;
			break;

		case TYPE_OUTGO:
			bal -= t.value;
			t.balance = bal;
			break;

		case TYPE_ADJ:
			t.value = t.balance - bal;
			bal = t.balance;
			break;
		}

		[db updateTransaction:t];
	}

	[db commitTransaction];
}

- (double)lastBalance
{
	int max = [transactions count];
	if (max == 0) {
		return 0.0;
	}
	return [[transactions objectAtIndex:max - 1] balance];
}

// Utility
+ (NSString*)currencyString:(double)x
{
	NSNumberFormatter *f = [[[NSNumberFormatter alloc] init] autorelease];
	[f setNumberStyle:NSNumberFormatterCurrencyStyle];
	[f setLocale:[NSLocale currentLocale]];
	NSString *bstr = [f stringFromNumber:[NSNumber numberWithDouble:x]];
	return bstr;
}

- (NSMutableArray *)allocDescList
{
	int i, max;
	max = [transactions count];
	
	NSMutableArray *ary = [[NSMutableArray alloc] init];
	if (max == 0) return ary;
	
	for (i = max - 1; i >= 0; i--) {
		[ary addObject:[[transactions objectAtIndex:i] description]];
	}
	
	[ary sortUsingSelector:@selector(compare:)];
	
	// uniq
	NSString *prev = [ary objectAtIndex:0];
	for (i = 1; i < [ary count]; i++) {
		if ([prev isEqualToString:[ary objectAtIndex:i]]) {
			[ary removeObjectAtIndex:i];
			i--;
		} else {
			prev = [ary objectAtIndex:i];
		}
	}
	
	return ary;
}

//
// Archive / Unarchive
//
- (id)initWithCoder:(NSCoder *)decoder
{
	self = [super init];
	if (self) {
		self.serialCounter = [decoder decodeIntForKey:@"serialCounter"];
		self.transactions = [decoder decodeObjectForKey:@"Transactions"];
		[self recalcBalance];
	}
	return self;
}

#if 0
- (void)encodeWithCoder:(NSCoder *)coder
{
	[coder encodeInt:serialCounter forKey:@"serialCounter"];
	[coder encodeObject:transactions forKey:@"Transactions"];
}
#endif

@end