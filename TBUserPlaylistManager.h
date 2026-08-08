#import <Foundation/Foundation.h>
#import <MediaPlayer/MediaPlayer.h>

extern NSString *const TBUserPlaylistsDidChangeNotification;
extern NSString *const TBUserPlaylistIDKey;
extern NSString *const TBUserPlaylistNameKey;
extern NSString *const TBUserPlaylistTrackIDsKey;

@interface TBUserPlaylistManager : NSObject {
    NSMutableArray *_playlists;
}
+ (TBUserPlaylistManager *)sharedManager;
- (NSArray *)playlists;
- (NSDictionary *)playlistWithID:(NSString *)identifier;
- (NSDictionary *)createPlaylistWithName:(NSString *)name;
- (BOOL)addItem:(MPMediaItem *)item toPlaylistID:(NSString *)identifier;
- (void)removeTrackAtIndex:(NSUInteger)index fromPlaylistID:(NSString *)identifier;
@end
