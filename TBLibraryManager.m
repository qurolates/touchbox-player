#import "TBLibraryManager.h"

NSString *const TBArtistNameKey = @"artist";
NSString *const TBAlbumsKey = @"albums";
NSString *const TBAlbumTitleKey = @"title";
NSString *const TBAlbumArtistKey = @"artist";
NSString *const TBAlbumItemsKey = @"items";

@implementation TBLibraryManager

+ (TBLibraryManager *)sharedManager {
    static TBLibraryManager *manager = nil;
    if (manager == nil) manager = [[TBLibraryManager alloc] init];
    return manager;
}

- (NSArray *)songs {
    if (_songs == nil) {
        NSTimeInterval start = [NSDate timeIntervalSinceReferenceDate];
        NSArray *items = [[MPMediaQuery songsQuery] items];
        _songs = [(items ? items : [NSArray array]) retain];
        NSLog(@"Touchbox: library count=%lu query duration=%.3f sec",
              (unsigned long)[_songs count], [NSDate timeIntervalSinceReferenceDate] - start);
    }
    return _songs;
}

- (NSComparisonResult)compareString:(NSString *)left toString:(NSString *)right {
    return [left compare:right options:NSCaseInsensitiveSearch];
}

- (NSArray *)sortedTracks:(NSArray *)items {
    return [items sortedArrayUsingFunction:TBTrackSort context:NULL];
}

static NSInteger TBTrackSort(id left, id right, void *context) {
    NSNumber *leftDisc = [left valueForProperty:MPMediaItemPropertyDiscNumber];
    NSNumber *rightDisc = [right valueForProperty:MPMediaItemPropertyDiscNumber];
    NSComparisonResult result = [leftDisc compare:rightDisc];
    if (result != NSOrderedSame) return result;
    NSNumber *leftTrack = [left valueForProperty:MPMediaItemPropertyAlbumTrackNumber];
    NSNumber *rightTrack = [right valueForProperty:MPMediaItemPropertyAlbumTrackNumber];
    result = [leftTrack compare:rightTrack];
    if (result != NSOrderedSame) return result;
    NSString *leftTitle = [left valueForProperty:MPMediaItemPropertyTitle];
    NSString *rightTitle = [right valueForProperty:MPMediaItemPropertyTitle];
    return [(leftTitle ? leftTitle : @"") compare:(rightTitle ? rightTitle : @"")
                                          options:NSCaseInsensitiveSearch];
}

static NSInteger TBNameDictionarySort(id left, id right, void *context) {
    NSString *key = (NSString *)context;
    return [[left objectForKey:key] compare:[right objectForKey:key]
                                   options:NSCaseInsensitiveSearch];
}

- (NSArray *)artistGroups {
    if (_artistGroups != nil) return _artistGroups;

    NSMutableDictionary *artists = [NSMutableDictionary dictionary];
    NSArray *allSongs = [self songs];
    NSUInteger index;
    for (index = 0; index < [allSongs count]; index++) {
        MPMediaItem *item = [allSongs objectAtIndex:index];
        NSString *artist = [item valueForProperty:MPMediaItemPropertyAlbumArtist];
        if ([artist length] == 0) artist = [item valueForProperty:MPMediaItemPropertyArtist];
        if ([artist length] == 0) artist = @"Unknown Artist";
        NSString *album = [item valueForProperty:MPMediaItemPropertyAlbumTitle];
        if ([album length] == 0) album = @"Unknown Album";

        NSMutableDictionary *albums = [artists objectForKey:artist];
        if (albums == nil) {
            albums = [NSMutableDictionary dictionary];
            [artists setObject:albums forKey:artist];
        }
        NSMutableArray *tracks = [albums objectForKey:album];
        if (tracks == nil) {
            tracks = [NSMutableArray array];
            [albums setObject:tracks forKey:album];
        }
        [tracks addObject:item];
    }

    NSMutableArray *groups = [NSMutableArray array];
    NSEnumerator *artistEnumerator = [artists keyEnumerator];
    NSString *artist;
    while ((artist = [artistEnumerator nextObject])) {
        NSDictionary *albumMap = [artists objectForKey:artist];
        NSMutableArray *albums = [NSMutableArray array];
        NSEnumerator *albumEnumerator = [albumMap keyEnumerator];
        NSString *title;
        while ((title = [albumEnumerator nextObject])) {
            NSDictionary *album = [NSDictionary dictionaryWithObjectsAndKeys:
                title, TBAlbumTitleKey, artist, TBAlbumArtistKey,
                [self sortedTracks:[albumMap objectForKey:title]], TBAlbumItemsKey, nil];
            [albums addObject:album];
        }
        [albums sortUsingFunction:TBNameDictionarySort context:(void *)TBAlbumTitleKey];
        [groups addObject:[NSDictionary dictionaryWithObjectsAndKeys:
            artist, TBArtistNameKey, albums, TBAlbumsKey, nil]];
    }
    [groups sortUsingFunction:TBNameDictionarySort context:(void *)TBArtistNameKey];
    _artistGroups = [groups retain];
    NSLog(@"Touchbox: prepared %lu artist groups", (unsigned long)[_artistGroups count]);
    return _artistGroups;
}

- (NSArray *)playlists {
    if (_playlists == nil) {
        NSArray *collections = [[MPMediaQuery playlistsQuery] collections];
        _playlists = [(collections ? collections : [NSArray array]) retain];
        NSLog(@"Touchbox: playlist count=%lu", (unsigned long)[_playlists count]);
    }
    return _playlists;
}

- (void)dealloc {
    [_songs release];
    [_artistGroups release];
    [_playlists release];
    [super dealloc];
}

@end
