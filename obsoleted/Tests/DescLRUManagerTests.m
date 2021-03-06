// -*-  Mode:ObjC; c-basic-offset:4; tab-width:8; indent-tabs-mode:nil -*-

#import "TestCommon.h"
#import "DataModel.h"
#import "DescLRUManager.h"

@interface DescLRUManagerTests : IUTTest {
    DescLRUManager *manager;
}
@end

@implementation DescLRUManagerTests

- (void)setUp
{
    [super setUp];
    [TestCommon deleteDatabase];

    [[DataModel instance] load]; // re-create DataModel
}

- (void)tearDown
{
    [super tearDown];
    
    [DataModel finalize];
    [Database shutdown];
}

- (void)setupTestData
{
    Database *db = [Database instance];
     
    [DescLRUManager addDescLRU:@"test0" category:0 date:[db dateFromString:@"20100101000000"]];
    [DescLRUManager addDescLRU:@"test1" category:1 date:[db dateFromString:@"20100101000001"]];
    [DescLRUManager addDescLRU:@"test2" category:2 date:[db dateFromString:@"20100101000002"]];
    [DescLRUManager addDescLRU:@"test3" category:0 date:[db dateFromString:@"20100101000003"]];
    [DescLRUManager addDescLRU:@"test4" category:1 date:[db dateFromString:@"20100101000004"]];
    [DescLRUManager addDescLRU:@"test5" category:2 date:[db dateFromString:@"20100101000005"]];
}

- (void) testInit {
    NSMutableArray *ary = [DescLRUManager getDescLRUs:-1];
    STAssertTrue([ary count] == 0, @"LRU count must be 0.");
}

- (void)testAnyCategory
{
    [self setupTestData];
    
    NSMutableArray *ary;
    ary = [DescLRUManager getDescLRUs:-1];
    STAssertTrue([ary count] == 6, @"LRU count must be 6.");

    DescLRU *lru;
    lru = [ary objectAtIndex:0];
    STAssertTrue([lru.description isEqualToString:@"test5"], @"first entry");
    lru = [ary objectAtIndex:5];
    STAssertTrue([lru.description isEqualToString:@"test0"], @"last entry");
}

- (void)testCategory
{
    [self setupTestData];

    NSMutableArray *ary;
    ary = [DescLRUManager getDescLRUs:1];
    STAssertTrue([ary count] == 2, @"LRU count must be 2.");

    DescLRU *lru;
    lru = [ary objectAtIndex:0];
    STAssertTrue([lru.description isEqualToString:@"test4"], @"first entry");
    lru = [ary objectAtIndex:1];
    STAssertTrue([lru.description isEqualToString:@"test1"], @"last entry");
}

- (void)testUpdateSameCategory
{
    [self setupTestData];

    [DescLRUManager addDescLRU:@"test1" category:1]; // same name/cat.

    NSMutableArray *ary;
    ary = [DescLRUManager getDescLRUs:1];
    STAssertTrue([ary count] == 2, @"LRU count must be 2.");

    DescLRU *lru;
    lru = [ary objectAtIndex:0];
    STAssertTrue([lru.description isEqualToString:@"test1"], @"first entry");
    lru = [ary objectAtIndex:1];
    STAssertTrue([lru.description isEqualToString:@"test4"], @"last entry");
}

- (void)testUpdateOtherCategory
{
    [self setupTestData];

    [DescLRUManager addDescLRU:@"test1" category:2]; // same name/other cat.

    NSMutableArray *ary;
    ary = [DescLRUManager getDescLRUs:1];
    STAssertTrue([ary count] == 1, @"LRU count must be 2.");

    DescLRU *lru;
    lru = [ary objectAtIndex:0];
    STAssertTrue([lru.description isEqualToString:@"test4"], @"first entry");

    ary = [DescLRUManager getDescLRUs:2];
    STAssertTrue([ary count] == 3, @"LRU count must be 3.");
    lru = [ary objectAtIndex:0];
    STAssertTrue([lru.description isEqualToString:@"test1"], @"new entry");
}

@end
