#import <Foundation/Foundation.h>
#import <MediaPlayer/MediaPlayer.h>

extern NSString *const TBArtistNameKey;
extern NSString *const TBAlbumsKey;
extern NSString *const TBAlbumTitleKey;
extern NSString *const TBAlbumArtistKey;
extern NSString *const TBAlbumItemsKey;

@interface TBLibraryManager : NSObject {
    NSArray *_songs;
    NSArray *_artistGroups;
    NSArray *_playlists;
}

+ (TBLibraryManager *)sharedManager;
- (NSArray *)songs;
- (NSArray *)artistGroups;
- (NSArray *)playlists;

@end
