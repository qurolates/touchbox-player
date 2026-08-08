#import <Foundation/Foundation.h>
#import <MediaPlayer/MediaPlayer.h>

@interface TBArtworkCache : NSObject {
    NSMutableDictionary *_images;
    NSMutableArray *_recentKeys;
    NSMutableSet *_pendingKeys;
}

+ (TBArtworkCache *)sharedCache;
- (UIImage *)cachedImageForKey:(NSString *)key;
- (void)requestImageForItem:(MPMediaItem *)item size:(CGSize)size key:(NSString *)key
                     target:(id)target selector:(SEL)selector;
- (void)removeAllImages;

@end
