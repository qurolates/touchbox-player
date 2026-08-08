#import "TBAlphabeticIndex.h"
#import "TBLibraryManager.h"

@implementation TBAlphabeticIndex
+ (NSArray *)titles {
    static NSArray *titles = nil;
    if (!titles) titles = [[NSArray alloc] initWithObjects:@"A", @"B", @"C", @"D", @"E",
        @"F", @"G", @"H", @"I", @"J", @"K", @"L", @"M", @"N", @"O", @"P",
        @"Q", @"R", @"S", @"T", @"U", @"V", @"W", @"X", @"Y", @"Z", @"#", nil];
    return titles;
}
+ (NSString *)bucketForName:(NSString *)name {
    if (![name length]) return @"#";
    NSString *letter = [[name substringToIndex:1] uppercaseString];
    unichar character = [letter characterAtIndex:0];
    return (character >= 'A' && character <= 'Z') ? letter : @"#";
}
+ (NSArray *)sectionMapForArtistGroups:(NSArray *)groups {
    NSMutableArray *map = [NSMutableArray arrayWithCapacity:[[self titles] count]];
    NSArray *titles = [self titles];
    NSUInteger titleIndex;
    for (titleIndex = 0; titleIndex < [titles count]; titleIndex++) {
        NSString *wanted = [titles objectAtIndex:titleIndex];
        NSInteger match = NSNotFound;
        NSUInteger section;
        for (section = 0; section < [groups count]; section++) {
            NSString *bucket = [self bucketForName:[[groups objectAtIndex:section]
                objectForKey:TBArtistNameKey]];
            if ([bucket isEqualToString:wanted]) { match = (NSInteger)section; break; }
            if (![wanted isEqualToString:@"#"] && ![bucket isEqualToString:@"#"] &&
                [bucket compare:wanted] == NSOrderedDescending) { match = (NSInteger)section; break; }
        }
        if (match == NSNotFound) match = [groups count] ? (NSInteger)[groups count] - 1 : 0;
        [map addObject:[NSNumber numberWithInteger:match]];
    }
    return map;
}
@end
