#import "TBUserPlaylistManager.h"
#import "TBPerformance.h"

NSString *const TBUserPlaylistsDidChangeNotification = @"TBUserPlaylistsDidChangeNotification";
NSString *const TBUserPlaylistIDKey = @"id";
NSString *const TBUserPlaylistNameKey = @"name";
NSString *const TBUserPlaylistTrackIDsKey = @"trackPersistentIDs";

@implementation TBUserPlaylistManager
+ (TBUserPlaylistManager *)sharedManager {
    static TBUserPlaylistManager *manager = nil;
    if (!manager) manager = [[TBUserPlaylistManager alloc] init];
    return manager;
}
- (NSString *)storagePath {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES);
    return [paths count] ? [[paths objectAtIndex:0]
        stringByAppendingPathComponent:@"TouchboxPlaylists.plist"] : nil;
}
- (id)init {
    self = [super init];
    if (self) {
        NSData *data = [NSData dataWithContentsOfFile:[self storagePath]];
        NSString *error = nil;
        NSArray *saved = data ? [NSPropertyListSerialization propertyListFromData:data
            mutabilityOption:NSPropertyListMutableContainersAndLeaves format:NULL
            errorDescription:&error] : nil;
        _playlists = saved ? [saved mutableCopy] : [[NSMutableArray alloc] init];
        [error release];
    }
    return self;
}
- (NSArray *)playlists { return _playlists; }
- (NSDictionary *)playlistWithID:(NSString *)identifier {
    NSUInteger index;
    for (index = 0; index < [_playlists count]; index++) {
        NSDictionary *playlist = [_playlists objectAtIndex:index];
        if ([[playlist objectForKey:TBUserPlaylistIDKey] isEqualToString:identifier]) return playlist;
    }
    return nil;
}
- (void)save {
    NSString *error = nil;
    NSData *data = [NSPropertyListSerialization dataFromPropertyList:_playlists
        format:NSPropertyListBinaryFormat_v1_0 errorDescription:&error];
    BOOL saved = data && [data writeToFile:[self storagePath] atomically:YES];
    TBPerformanceLog(@"Touchbox: user playlists saved=%@ count=%lu error=%@",
        saved ? @"YES" : @"NO", (unsigned long)[_playlists count], error);
    [error release];
    [[NSNotificationCenter defaultCenter]
        postNotificationName:TBUserPlaylistsDidChangeNotification object:self];
}
- (NSDictionary *)createPlaylistWithName:(NSString *)name {
    NSString *trimmed = [name stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if (![trimmed length]) return nil;
    NSString *identifier = [NSString stringWithFormat:@"%.0f-%u",
        [NSDate timeIntervalSinceReferenceDate] * 1000.0, (unsigned)arc4random()];
    NSMutableDictionary *playlist = [NSMutableDictionary dictionaryWithObjectsAndKeys:
        identifier, TBUserPlaylistIDKey, trimmed, TBUserPlaylistNameKey,
        [NSMutableArray array], TBUserPlaylistTrackIDsKey, nil];
    [_playlists addObject:playlist];
    [self save];
    return playlist;
}
- (BOOL)addItem:(MPMediaItem *)item toPlaylistID:(NSString *)identifier {
    NSMutableDictionary *playlist = (NSMutableDictionary *)[self playlistWithID:identifier];
    if (!playlist || !item) return NO;
    NSNumber *number = [item valueForProperty:MPMediaItemPropertyPersistentID];
    NSString *trackID = [NSString stringWithFormat:@"%llu", [number unsignedLongLongValue]];
    NSMutableArray *trackIDs = [playlist objectForKey:TBUserPlaylistTrackIDsKey];
    if ([trackIDs containsObject:trackID]) return NO;
    [trackIDs addObject:trackID];
    [self save];
    return YES;
}
- (void)removeTrackAtIndex:(NSUInteger)index fromPlaylistID:(NSString *)identifier {
    NSMutableDictionary *playlist = (NSMutableDictionary *)[self playlistWithID:identifier];
    NSMutableArray *trackIDs = [playlist objectForKey:TBUserPlaylistTrackIDsKey];
    if (index >= [trackIDs count]) return;
    [trackIDs removeObjectAtIndex:index];
    [self save];
}
- (void)dealloc { [_playlists release]; [super dealloc]; }
@end
