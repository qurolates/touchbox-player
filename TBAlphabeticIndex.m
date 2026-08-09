#import "TBAlphabeticIndex.h"
#import "TBLibraryManager.h"

@implementation TBAlphabeticIndex
+ (NSArray *)titles {
    static NSArray *titles = nil;
    if (!titles) titles = [[NSArray alloc] initWithObjects:@"#", @"A", @"B", @"C", @"D", @"E",
        @"F", @"G", @"H", @"I", @"J", @"K", @"L", @"M", @"N", @"O", @"P",
        @"Q", @"R", @"S", @"T", @"U", @"V", @"W", @"X", @"Y", @"Z", nil];
    return titles;
}
+ (NSString *)bucketForName:(NSString *)name {
    if (![name length]) return @"#";
    NSString *letter = [[name substringToIndex:1] uppercaseString];
    unichar character = [letter characterAtIndex:0];
    return (character >= 'A' && character <= 'Z') ? letter : @"#";
}
+ (NSArray *)titlesForArtistGroups:(NSArray *)groups {
    NSMutableSet *available = [NSMutableSet set];
    NSUInteger section;
    for (section = 0; section < [groups count]; section++) {
        [available addObject:[self bucketForName:[[groups objectAtIndex:section]
            objectForKey:TBArtistNameKey]]];
    }
    NSMutableArray *result = [NSMutableArray array];
    NSUInteger index;
    for (index = 0; index < [[self titles] count]; index++) {
        NSString *title = [[self titles] objectAtIndex:index];
        if ([available containsObject:title]) [result addObject:title];
    }
    return result;
}
+ (NSArray *)sectionMapForArtistGroups:(NSArray *)groups {
    NSArray *titles = [self titlesForArtistGroups:groups];
    NSMutableArray *map = [NSMutableArray arrayWithCapacity:[titles count]];
    NSUInteger titleIndex;
    for (titleIndex = 0; titleIndex < [titles count]; titleIndex++) {
        NSString *wanted = [titles objectAtIndex:titleIndex];
        NSInteger match = NSNotFound;
        NSUInteger section;
        for (section = 0; section < [groups count]; section++) {
            NSString *bucket = [self bucketForName:[[groups objectAtIndex:section]
                objectForKey:TBArtistNameKey]];
            if ([bucket isEqualToString:wanted]) { match = (NSInteger)section; break; }
        }
        if (match != NSNotFound) [map addObject:[NSNumber numberWithInteger:match]];
    }
    return map;
}
@end
