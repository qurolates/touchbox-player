#import <Foundation/Foundation.h>
#import <MediaPlayer/MediaPlayer.h>

extern NSString *const TBPlayerQueueDidChangeNotification;

@interface TBPlayerManager : NSObject {
    MPMusicPlayerController *_musicPlayer;
    NSArray *_originalQueueItems;
    NSArray *_queueItems;
    NSInteger _currentQueueIndex;
    BOOL _shuffleEnabled;
    BOOL _repeatOneEnabled;
    NSDictionary *_lastSavedState;
    BOOL _interactiveSeek;
}

@property(nonatomic, retain, readonly) MPMusicPlayerController *musicPlayer;
@property(nonatomic, retain, readonly) NSArray *queueItems;
@property(nonatomic, readonly) NSInteger currentQueueIndex;
@property(nonatomic, readonly) BOOL shuffleEnabled;
@property(nonatomic, readonly) BOOL repeatOneEnabled;

+ (TBPlayerManager *)sharedManager;
- (void)playItems:(NSArray *)items startingAtItem:(MPMediaItem *)item;
- (void)playItemsShuffled:(NSArray *)items;
- (void)playNextItem:(MPMediaItem *)item;
- (void)addItemToQueue:(MPMediaItem *)item;
- (void)savePlaybackState;
- (void)togglePlayPause;
- (void)previous;
- (void)next;
- (void)seekToTime:(NSTimeInterval)time;
- (void)seekToTimeWithoutSaving:(NSTimeInterval)time;
- (void)beginInteractiveSeek;
- (void)endInteractiveSeek;
- (void)playQueueItemAtIndex:(NSInteger)index;
- (void)toggleShuffle;
- (void)toggleRepeatOne;

@end
