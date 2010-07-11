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

#import "Category.h"
#import "AppDelegate.h"

@implementation Category
@end

@implementation Categories

-(id)init
{
    [super init];
    categories = nil;

    return self;
}

-(void)dealloc
{
    [categories release];
    [super dealloc];
}

-(void)reload
{
    [categories release];
    categories = [Category find_cond:@"ORDER BY sorder"];
}

-(int)categoryCount
{
    return [categories count];
}

-(Category*)categoryAtIndex:(int)n
{
    ASSERT(categories != nil);
    return [categories objectAtIndex:n];
}

- (int)categoryIndexWithKey:(int)key
{
    int i, max = [categories count];
    for (i = 0; i < max; i++) {
        Category *c = [categories objectAtIndex:i];
        if (c.pkey == key) {
            return i;
        }
    }
    return -1;
}

-(NSString*)categoryStringWithKey:(int)key
{
    int idx = [self categoryIndexWithKey:key];
    if (idx < 0) {
        return @"";
    }
    Category *c = [categories objectAtIndex:idx];
    return c.name;
}

-(Category*)addCategory:(NSString *)name
{
    Category *c = [[Category alloc] init];
    c.name = name;
    [categories addObject:c];
    [c release];

    [self renumber];

    [c insert];
    return c;
}

-(void)updateCategory:(Category*)category
{
    [category update];
}

-(void)deleteCategoryAtIndex:(int)index
{
    Category *c = [categories objectAtIndex:index];
    [c delete];

    [categories removeObjectAtIndex:index];
}

- (void)reorderCategory:(int)from to:(int)to
{
    Category *c = [[categories objectAtIndex:from] retain];
    [categories removeObjectAtIndex:from];
    [categories insertObject:c atIndex:to];
    [c release];
	
    [self renumber];
}

-(void)renumber
{
    int i, max = [categories count];

    for (i = 0; i < max; i++) {
        Category *c = [categories objectAtIndex:i];
        c.sorder = i;
        [c update];
    }
}

@end
