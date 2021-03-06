// -*-  Mode:ObjC; c-basic-offset:4; tab-width:8; indent-tabs-mode:nil -*-

#import "TestCommon.h"

@interface TimeTest : IUTTest {
}
@end

@implementation TimeTest

- (void)setUp
{
}

- (void)tearDown
{
}

- (void)testAPMPM
{
    NSDateFormatter *f = [[[NSDateFormatter alloc] init] autorelease];
    [f setDateFormat:@"HH"];
    NSDate *d = [NSDate dateWithTimeIntervalSinceReferenceDate:60*60*13];

    NSLog(@"%@", [f stringFromDate:d]);

    [f setLocale:nil];
    NSLog(@"%@", [f stringFromDate:d]);
    
#define T(x) [f setLocale:[[[NSLocale alloc] initWithLocaleIdentifier:@ #x] autorelease]]; NSLog(@"%s %@", #x, [f stringFromDate:d])
    T(ja_JP);
}

@end
