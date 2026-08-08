#import <Foundation/Foundation.h>
#import <MediaPlayer/MediaPlayer.h>

extern NSString *const TBFavoritesDidChangeNotification;

@interface TBFavoritesManager : NSObject {
    NSMutableArray *_persistentIDs;
}

+ (TBFavoritesManager *)sharedManager;
- (BOOL)isFavoriteItem:(MPMediaItem *)item;
- (void)toggleFavoriteItem:(MPMediaItem *)item;
- (NSArray *)favoriteItemsFromSongs:(NSArray *)songs;

@end
