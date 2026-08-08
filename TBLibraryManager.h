#import <Foundation/Foundation.h>
#import <MediaPlayer/MediaPlayer.h>

extern NSString *const TBLibrarySongsDidLoadNotification;
extern NSString *const TBLibraryIndexDidLoadNotification;
extern NSString *const TBLibraryPlaylistsDidLoadNotification;

extern NSString *const TBArtistNameKey;
extern NSString *const TBAlbumsKey;
extern NSString *const TBAlbumTitleKey;
extern NSString *const TBAlbumArtistKey;
extern NSString *const TBAlbumItemsKey;
extern NSString *const TBAlbumTrackRecordsKey;

@interface TBLibraryManager : NSObject {
    NSArray *_songs;
    NSArray *_artistGroups;
    NSArray *_playlists;
    BOOL _loading;
    BOOL _mediaItemsReady;
    NSArray *_cachedSongIDs;
    NSDictionary *_itemsByPersistentID;
}

+ (TBLibraryManager *)sharedManager;
- (NSArray *)songs;
- (NSArray *)artistGroups;
- (NSArray *)playlists;
- (BOOL)songsLoaded;
- (BOOL)indexLoaded;
- (BOOL)playlistsLoaded;
- (BOOL)mediaItemsReady;
- (void)beginLoadingLibrary;
- (NSArray *)itemsForPersistentIDs:(NSArray *)persistentIDs;

@end
