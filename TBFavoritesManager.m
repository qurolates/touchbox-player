#import "TBFavoritesManager.h"
#import "TBPerformance.h"

NSString *const TBFavoritesDidChangeNotification = @"TBFavoritesDidChangeNotification";
static NSString *const TBFavoritesDefaultsKey = @"TBFavoritePersistentIDs";

@implementation TBFavoritesManager

+ (TBFavoritesManager *)sharedManager {
    static TBFavoritesManager *manager = nil;
    if (manager == nil) manager = [[TBFavoritesManager alloc] init];
    return manager;
}

- (id)init {
    self = [super init];
    if (self) {
        NSArray *saved = [[NSUserDefaults standardUserDefaults] arrayForKey:TBFavoritesDefaultsKey];
        _persistentIDs = saved ? [saved mutableCopy] : [[NSMutableArray alloc] init];
    }
    return self;
}

- (NSString *)keyForItem:(MPMediaItem *)item {
    NSNumber *number = [item valueForProperty:MPMediaItemPropertyPersistentID];
    return [NSString stringWithFormat:@"%llu", [number unsignedLongLongValue]];
}

- (BOOL)isFavoriteItem:(MPMediaItem *)item {
    return [_persistentIDs containsObject:[self keyForItem:item]];
}

- (void)toggleFavoriteItem:(MPMediaItem *)item {
    NSString *key = [self keyForItem:item];
    if ([_persistentIDs containsObject:key]) {
        [_persistentIDs removeObject:key];
        NSUInteger index;
        for (index = 0; index < [_resolvedItems count]; index++) {
            if ([[self keyForItem:[_resolvedItems objectAtIndex:index]] isEqualToString:key]) {
                [_resolvedItems removeObjectAtIndex:index];
                break;
            }
        }
        TBPerformanceLog(@"Touchbox: favorite removed persistentID=%@", key);
    } else {
        [_persistentIDs addObject:key];
        if (_resolvedItems) [_resolvedItems addObject:item];
        TBPerformanceLog(@"Touchbox: favorite added persistentID=%@", key);
    }
    [[NSUserDefaults standardUserDefaults] setObject:_persistentIDs forKey:TBFavoritesDefaultsKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
    [[NSNotificationCenter defaultCenter] postNotificationName:TBFavoritesDidChangeNotification object:self];
}

- (NSArray *)favoriteItemsFromSongs:(NSArray *)songs {
    if (_resolvedItems != nil && _resolvedSongs == songs) return _resolvedItems;
    [_resolvedItems release];
    _resolvedItems = nil;
    [_resolvedSongs release];
    _resolvedSongs = [songs retain];

    NSTimeInterval start = [NSDate timeIntervalSinceReferenceDate];
    NSMutableDictionary *itemsByID = [NSMutableDictionary dictionaryWithCapacity:[songs count]];
    NSUInteger index;
    for (index = 0; index < [songs count]; index++) {
        MPMediaItem *item = [songs objectAtIndex:index];
        [itemsByID setObject:item forKey:[self keyForItem:item]];
    }
    NSMutableArray *items = [NSMutableArray arrayWithCapacity:[_persistentIDs count]];
    NSMutableArray *validIDs = [NSMutableArray array];
    for (index = 0; index < [_persistentIDs count]; index++) {
        NSString *key = [_persistentIDs objectAtIndex:index];
        MPMediaItem *item = [itemsByID objectForKey:key];
        if (item) {
            [items addObject:item];
            [validIDs addObject:key];
        } else {
            TBPerformanceLog(@"Touchbox: removing orphaned favorite persistentID=%@", key);
        }
    }
    if ([validIDs count] != [_persistentIDs count]) {
        [_persistentIDs setArray:validIDs];
        [[NSUserDefaults standardUserDefaults] setObject:_persistentIDs forKey:TBFavoritesDefaultsKey];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
    _resolvedItems = [items mutableCopy];
    TBPerformanceLog(@"Touchbox timing: favorites initial resolve %.3f sec favorites=%lu",
          [NSDate timeIntervalSinceReferenceDate] - start, (unsigned long)[_resolvedItems count]);
    return _resolvedItems;
}

- (void)dealloc {
    [_persistentIDs release];
    [_resolvedItems release];
    [_resolvedSongs release];
    [super dealloc];
}

@end
