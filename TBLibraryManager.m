#import "TBLibraryManager.h"

NSString *const TBLibrarySongsDidLoadNotification = @"TBLibrarySongsDidLoadNotification";
NSString *const TBLibraryIndexDidLoadNotification = @"TBLibraryIndexDidLoadNotification";
NSString *const TBLibraryPlaylistsDidLoadNotification = @"TBLibraryPlaylistsDidLoadNotification";

NSString *const TBArtistNameKey = @"artist";
NSString *const TBAlbumsKey = @"albums";
NSString *const TBAlbumTitleKey = @"title";
NSString *const TBAlbumArtistKey = @"artist";
NSString *const TBAlbumItemsKey = @"items";
NSString *const TBAlbumTrackRecordsKey = @"trackRecords";

static NSString *const TBCacheVersionKey = @"version";
static NSString *const TBCacheSongIDsKey = @"songSignature";
static NSString *const TBCacheGroupsKey = @"artistGroups";
static NSString *const TBTrackIDKey = @"persistentID";
static NSString *const TBTrackTitleKey = @"title";
static NSString *const TBTrackArtistKey = @"artist";
static NSString *const TBTrackAlbumArtistKey = @"albumArtist";
static NSString *const TBTrackAlbumTitleKey = @"albumTitle";
static NSString *const TBTrackNumberKey = @"trackNumber";
static NSString *const TBTrackDiscNumberKey = @"discNumber";
static NSString *const TBTrackDurationKey = @"duration";

static NSString *TBPersistentIDString(MPMediaItem *item) {
    NSNumber *number = [item valueForProperty:MPMediaItemPropertyPersistentID];
    return [NSString stringWithFormat:@"%llu", [number unsignedLongLongValue]];
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

static NSInteger TBRecordIDSort(id left, id right, void *context) {
    return [[left objectForKey:TBTrackIDKey] compare:[right objectForKey:TBTrackIDKey]];
}

@interface TBLibraryManager ()
- (void)loadPersistentCache;
- (NSString *)cachePath;
- (NSArray *)buildGroupsFromSongs:(NSArray *)songs;
- (NSArray *)hydrateGroups:(NSArray *)groups itemsByID:(NSDictionary *)itemsByID;
- (void)saveGroups:(NSArray *)groups songIDs:(NSArray *)songIDs;
- (NSDictionary *)recordForItem:(MPMediaItem *)item albumArtist:(NSString *)albumArtist;
@end

@implementation TBLibraryManager

+ (TBLibraryManager *)sharedManager {
    static TBLibraryManager *manager = nil;
    if (manager == nil) manager = [[TBLibraryManager alloc] init];
    return manager;
}

- (id)init {
    self = [super init];
    if (self) [self loadPersistentCache];
    return self;
}

- (NSArray *)songs { return _songs ? _songs : [NSArray array]; }
- (NSArray *)artistGroups { return _artistGroups ? _artistGroups : [NSArray array]; }
- (NSArray *)playlists { return _playlists ? _playlists : [NSArray array]; }
- (BOOL)songsLoaded { return _songs != nil; }
- (BOOL)indexLoaded { return _artistGroups != nil; }
- (BOOL)playlistsLoaded { return _playlists != nil; }
- (BOOL)mediaItemsReady { return _mediaItemsReady; }

- (NSString *)cachePath {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES);
    if ([paths count] == 0) return nil;
    return [[paths objectAtIndex:0] stringByAppendingPathComponent:@"TouchboxLibraryIndex.plist"];
}

- (void)loadPersistentCache {
    NSTimeInterval start = [NSDate timeIntervalSinceReferenceDate];
    NSString *path = [self cachePath];
    NSData *data = path ? [NSData dataWithContentsOfFile:path] : nil;
    if (data == nil) {
        NSLog(@"Touchbox cache: no persistent library index");
        return;
    }
    NSString *error = nil;
    NSPropertyListFormat format = NSPropertyListBinaryFormat_v1_0;
    NSDictionary *root = [NSPropertyListSerialization propertyListFromData:data
        mutabilityOption:NSPropertyListImmutable format:&format errorDescription:&error];
    if ([[root objectForKey:TBCacheVersionKey] integerValue] == 2 &&
        [root objectForKey:TBCacheGroupsKey] && [root objectForKey:TBCacheSongIDsKey]) {
        _artistGroups = [[root objectForKey:TBCacheGroupsKey] retain];
        _cachedSongIDs = [[root objectForKey:TBCacheSongIDsKey] retain];
        NSLog(@"Touchbox timing: persistent index load %.3f sec artists=%lu bytes=%lu",
              [NSDate timeIntervalSinceReferenceDate] - start,
              (unsigned long)[_artistGroups count], (unsigned long)[data length]);
    } else {
        NSLog(@"Touchbox cache: ignored invalid index error=%@", error);
    }
    [error release];
}

- (void)beginLoadingLibrary {
    @synchronized(self) {
        if (_loading || (_songs && _mediaItemsReady && _playlists)) return;
        _loading = YES;
    }
    [self performSelectorInBackground:@selector(loadLibraryInBackground) withObject:nil];
}

- (NSArray *)signatureForSongs:(NSArray *)songs itemsByID:(NSMutableDictionary *)itemsByID {
    NSMutableArray *signature = [NSMutableArray arrayWithCapacity:[songs count]];
    NSUInteger index;
    for (index = 0; index < [songs count]; index++) {
        MPMediaItem *item = [songs objectAtIndex:index];
        NSString *identifier = TBPersistentIDString(item);
        [itemsByID setObject:item forKey:identifier];
        NSString *albumArtist = [item valueForProperty:MPMediaItemPropertyAlbumArtist];
        if ([albumArtist length] == 0) albumArtist = [item valueForProperty:MPMediaItemPropertyArtist];
        if ([albumArtist length] == 0) albumArtist = @"Unknown Artist";
        [signature addObject:[self recordForItem:item albumArtist:albumArtist]];
    }
    [signature sortUsingFunction:TBRecordIDSort context:NULL];
    return signature;
}

- (void)loadLibraryInBackground {
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    NSTimeInterval totalStart = [NSDate timeIntervalSinceReferenceDate];
    NSTimeInterval stageStart = [NSDate timeIntervalSinceReferenceDate];
    MPMediaQuery *songsQuery = [MPMediaQuery songsQuery];
    NSLog(@"Touchbox timing: songs MPMediaQuery creation %.3f sec",
          [NSDate timeIntervalSinceReferenceDate] - stageStart);
    stageStart = [NSDate timeIntervalSinceReferenceDate];
    NSArray *queriedSongs = [songsQuery items];
    NSArray *songs = queriedSongs ? queriedSongs : [NSArray array];
    NSLog(@"Touchbox timing: songs items fetch %.3f sec count=%lu",
          [NSDate timeIntervalSinceReferenceDate] - stageStart, (unsigned long)[songs count]);
    @synchronized(self) { _songs = [songs retain]; }
    [self performSelectorOnMainThread:@selector(postSongsReady) withObject:nil waitUntilDone:NO];

    stageStart = [NSDate timeIntervalSinceReferenceDate];
    NSMutableDictionary *itemsByID = [NSMutableDictionary dictionaryWithCapacity:[songs count]];
    NSArray *currentSongIDs = [self signatureForSongs:songs itemsByID:itemsByID];
    BOOL cacheMatches = (_cachedSongIDs != nil && [_cachedSongIDs isEqualToArray:currentSongIDs]);
    NSLog(@"Touchbox timing: library identity check %.3f sec changed=%@",
          [NSDate timeIntervalSinceReferenceDate] - stageStart, cacheMatches ? @"NO" : @"YES");

    NSArray *groups;
    if (cacheMatches) {
        stageStart = [NSDate timeIntervalSinceReferenceDate];
        groups = [self hydrateGroups:_artistGroups itemsByID:itemsByID];
        NSLog(@"Touchbox timing: cached index hydration %.3f sec",
              [NSDate timeIntervalSinceReferenceDate] - stageStart);
    } else {
        groups = [self buildGroupsFromSongs:songs];
        [self saveGroups:groups songIDs:currentSongIDs];
    }
    @synchronized(self) {
        [_artistGroups release];
        _artistGroups = [groups retain];
        [_cachedSongIDs release];
        _cachedSongIDs = [currentSongIDs retain];
    }
    [self performSelectorOnMainThread:@selector(postIndexReady) withObject:nil waitUntilDone:NO];

    stageStart = [NSDate timeIntervalSinceReferenceDate];
    MPMediaQuery *playlistsQuery = [MPMediaQuery playlistsQuery];
    NSLog(@"Touchbox timing: playlists MPMediaQuery creation %.3f sec",
          [NSDate timeIntervalSinceReferenceDate] - stageStart);
    stageStart = [NSDate timeIntervalSinceReferenceDate];
    NSArray *queriedPlaylists = [playlistsQuery collections];
    NSArray *playlists = queriedPlaylists ? queriedPlaylists : [NSArray array];
    NSLog(@"Touchbox timing: playlist collections fetch %.3f sec count=%lu",
          [NSDate timeIntervalSinceReferenceDate] - stageStart, (unsigned long)[playlists count]);
    @synchronized(self) { _playlists = [playlists retain]; _loading = NO; }
    [self performSelectorOnMainThread:@selector(postPlaylistsReady) withObject:nil waitUntilDone:NO];
    NSLog(@"Touchbox timing: complete library preparation %.3f sec",
          [NSDate timeIntervalSinceReferenceDate] - totalStart);
    [pool drain];
}

- (NSDictionary *)recordForItem:(MPMediaItem *)item albumArtist:(NSString *)albumArtist {
    NSString *title = [item valueForProperty:MPMediaItemPropertyTitle];
    NSString *artist = [item valueForProperty:MPMediaItemPropertyArtist];
    NSString *albumTitle = [item valueForProperty:MPMediaItemPropertyAlbumTitle];
    NSNumber *track = [item valueForProperty:MPMediaItemPropertyAlbumTrackNumber];
    NSNumber *disc = [item valueForProperty:MPMediaItemPropertyDiscNumber];
    NSNumber *duration = [item valueForProperty:MPMediaItemPropertyPlaybackDuration];
    return [NSDictionary dictionaryWithObjectsAndKeys:
        TBPersistentIDString(item), TBTrackIDKey,
        (title ? title : @"Unknown Title"), TBTrackTitleKey,
        (artist ? artist : @"Unknown Artist"), TBTrackArtistKey,
        (albumArtist ? albumArtist : @"Unknown Artist"), TBTrackAlbumArtistKey,
        (albumTitle ? albumTitle : @"Unknown Album"), TBTrackAlbumTitleKey,
        (track ? track : [NSNumber numberWithInt:0]), TBTrackNumberKey,
        (disc ? disc : [NSNumber numberWithInt:0]), TBTrackDiscNumberKey,
        (duration ? duration : [NSNumber numberWithDouble:0.0]), TBTrackDurationKey, nil];
}

- (NSArray *)buildGroupsFromSongs:(NSArray *)songs {
    NSTimeInterval stageStart = [NSDate timeIntervalSinceReferenceDate];
    NSMutableDictionary *artists = [NSMutableDictionary dictionary];
    NSUInteger index;
    for (index = 0; index < [songs count]; index++) {
        MPMediaItem *item = [songs objectAtIndex:index];
        NSString *artist = [item valueForProperty:MPMediaItemPropertyAlbumArtist];
        if ([artist length] == 0) artist = [item valueForProperty:MPMediaItemPropertyArtist];
        if ([artist length] == 0) artist = @"Unknown Artist";
        NSString *albumTitle = [item valueForProperty:MPMediaItemPropertyAlbumTitle];
        if ([albumTitle length] == 0) albumTitle = @"Unknown Album";
        NSMutableDictionary *albums = [artists objectForKey:artist];
        if (!albums) { albums = [NSMutableDictionary dictionary]; [artists setObject:albums forKey:artist]; }
        NSMutableArray *tracks = [albums objectForKey:albumTitle];
        if (!tracks) { tracks = [NSMutableArray array]; [albums setObject:tracks forKey:albumTitle]; }
        [tracks addObject:item];
    }
    NSLog(@"Touchbox timing: grouping one-pass %.3f sec artists=%lu",
          [NSDate timeIntervalSinceReferenceDate] - stageStart, (unsigned long)[artists count]);

    stageStart = [NSDate timeIntervalSinceReferenceDate];
    NSMutableArray *groups = [NSMutableArray arrayWithCapacity:[artists count]];
    NSEnumerator *artistEnumerator = [artists keyEnumerator];
    NSString *artist;
    while ((artist = [artistEnumerator nextObject])) {
        NSDictionary *albumMap = [artists objectForKey:artist];
        NSMutableArray *albums = [NSMutableArray arrayWithCapacity:[albumMap count]];
        NSEnumerator *albumEnumerator = [albumMap keyEnumerator];
        NSString *title;
        while ((title = [albumEnumerator nextObject])) {
            NSMutableArray *items = [albumMap objectForKey:title];
            NSMutableArray *records = [NSMutableArray arrayWithCapacity:[items count]];
            NSUInteger itemIndex;
            for (itemIndex = 0; itemIndex < [items count]; itemIndex++)
                [records addObject:[self recordForItem:[items objectAtIndex:itemIndex] albumArtist:artist]];
            [albums addObject:[NSMutableDictionary dictionaryWithObjectsAndKeys:
                title, TBAlbumTitleKey, artist, TBAlbumArtistKey, items, TBAlbumItemsKey,
                records, TBAlbumTrackRecordsKey, nil]];
        }
        [groups addObject:[NSMutableDictionary dictionaryWithObjectsAndKeys:
            artist, TBArtistNameKey, albums, TBAlbumsKey, nil]];
    }
    NSLog(@"Touchbox timing: model arrays %.3f sec", [NSDate timeIntervalSinceReferenceDate] - stageStart);
    stageStart = [NSDate timeIntervalSinceReferenceDate];
    for (index = 0; index < [groups count]; index++) {
        NSMutableArray *albums = [[groups objectAtIndex:index] objectForKey:TBAlbumsKey];
        NSUInteger albumIndex;
        for (albumIndex = 0; albumIndex < [albums count]; albumIndex++) {
            NSMutableDictionary *album = [albums objectAtIndex:albumIndex];
            NSMutableArray *items = [album objectForKey:TBAlbumItemsKey];
            NSArray *oldRecords = [album objectForKey:TBAlbumTrackRecordsKey];
            NSMutableDictionary *recordsByID = [NSMutableDictionary dictionaryWithCapacity:[oldRecords count]];
            NSUInteger recordIndex;
            for (recordIndex = 0; recordIndex < [oldRecords count]; recordIndex++) {
                NSDictionary *record = [oldRecords objectAtIndex:recordIndex];
                [recordsByID setObject:record forKey:[record objectForKey:TBTrackIDKey]];
            }
            [items sortUsingFunction:TBTrackSort context:NULL];
            NSMutableArray *records = [NSMutableArray arrayWithCapacity:[items count]];
            NSUInteger itemIndex;
            for (itemIndex = 0; itemIndex < [items count]; itemIndex++) {
                NSDictionary *record = [recordsByID objectForKey:TBPersistentIDString([items objectAtIndex:itemIndex])];
                if (record) [records addObject:record];
            }
            [album setObject:records forKey:TBAlbumTrackRecordsKey];
        }
        [albums sortUsingFunction:TBNameDictionarySort context:(void *)TBAlbumTitleKey];
    }
    [groups sortUsingFunction:TBNameDictionarySort context:(void *)TBArtistNameKey];
    NSLog(@"Touchbox timing: sorting %.3f sec", [NSDate timeIntervalSinceReferenceDate] - stageStart);
    return groups;
}

- (NSArray *)hydrateGroups:(NSArray *)groups itemsByID:(NSDictionary *)itemsByID {
    NSMutableArray *hydratedGroups = [NSMutableArray arrayWithCapacity:[groups count]];
    NSUInteger groupIndex;
    for (groupIndex = 0; groupIndex < [groups count]; groupIndex++) {
        NSDictionary *group = [groups objectAtIndex:groupIndex];
        NSArray *cachedAlbums = [group objectForKey:TBAlbumsKey];
        NSMutableArray *albums = [NSMutableArray arrayWithCapacity:[cachedAlbums count]];
        NSUInteger albumIndex;
        for (albumIndex = 0; albumIndex < [cachedAlbums count]; albumIndex++) {
            NSDictionary *album = [cachedAlbums objectAtIndex:albumIndex];
            NSArray *records = [album objectForKey:TBAlbumTrackRecordsKey];
            NSMutableArray *items = [NSMutableArray arrayWithCapacity:[records count]];
            NSUInteger recordIndex;
            for (recordIndex = 0; recordIndex < [records count]; recordIndex++) {
                MPMediaItem *item = [itemsByID objectForKey:[[records objectAtIndex:recordIndex] objectForKey:TBTrackIDKey]];
                if (item) [items addObject:item];
            }
            [albums addObject:[NSDictionary dictionaryWithObjectsAndKeys:
                [album objectForKey:TBAlbumTitleKey], TBAlbumTitleKey,
                [album objectForKey:TBAlbumArtistKey], TBAlbumArtistKey,
                records, TBAlbumTrackRecordsKey, items, TBAlbumItemsKey, nil]];
        }
        [hydratedGroups addObject:[NSDictionary dictionaryWithObjectsAndKeys:
            [group objectForKey:TBArtistNameKey], TBArtistNameKey, albums, TBAlbumsKey, nil]];
    }
    return hydratedGroups;
}

- (void)saveGroups:(NSArray *)groups songIDs:(NSArray *)songIDs {
    NSTimeInterval start = [NSDate timeIntervalSinceReferenceDate];
    NSMutableArray *cacheGroups = [NSMutableArray arrayWithCapacity:[groups count]];
    NSUInteger groupIndex;
    for (groupIndex = 0; groupIndex < [groups count]; groupIndex++) {
        NSDictionary *group = [groups objectAtIndex:groupIndex];
        NSMutableArray *albums = [NSMutableArray array];
        NSEnumerator *enumerator = [[group objectForKey:TBAlbumsKey] objectEnumerator];
        NSDictionary *album;
        while ((album = [enumerator nextObject])) {
            [albums addObject:[NSDictionary dictionaryWithObjectsAndKeys:
                [album objectForKey:TBAlbumTitleKey], TBAlbumTitleKey,
                [album objectForKey:TBAlbumArtistKey], TBAlbumArtistKey,
                [album objectForKey:TBAlbumTrackRecordsKey], TBAlbumTrackRecordsKey, nil]];
        }
        [cacheGroups addObject:[NSDictionary dictionaryWithObjectsAndKeys:
            [group objectForKey:TBArtistNameKey], TBArtistNameKey, albums, TBAlbumsKey, nil]];
    }
    NSDictionary *root = [NSDictionary dictionaryWithObjectsAndKeys:
        [NSNumber numberWithInt:2], TBCacheVersionKey, songIDs, TBCacheSongIDsKey,
        cacheGroups, TBCacheGroupsKey, nil];
    NSString *error = nil;
    NSData *data = [NSPropertyListSerialization dataFromPropertyList:root
        format:NSPropertyListBinaryFormat_v1_0 errorDescription:&error];
    BOOL saved = data && [data writeToFile:[self cachePath] atomically:YES];
    NSLog(@"Touchbox timing: persistent index save %.3f sec bytes=%lu success=%@ error=%@",
          [NSDate timeIntervalSinceReferenceDate] - start, (unsigned long)[data length],
          saved ? @"YES" : @"NO", error);
    [error release];
}

- (void)postSongsReady { [[NSNotificationCenter defaultCenter]
    postNotificationName:TBLibrarySongsDidLoadNotification object:self]; }
- (void)postIndexReady {
    _mediaItemsReady = YES;
    [[NSNotificationCenter defaultCenter]
        postNotificationName:TBLibraryIndexDidLoadNotification object:self];
}
- (void)postPlaylistsReady { [[NSNotificationCenter defaultCenter]
    postNotificationName:TBLibraryPlaylistsDidLoadNotification object:self]; }

- (void)dealloc {
    [_songs release]; [_artistGroups release]; [_playlists release]; [_cachedSongIDs release];
    [super dealloc];
}

@end
