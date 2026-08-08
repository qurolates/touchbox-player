#import <Foundation/Foundation.h>
#import <MediaPlayer/MediaPlayer.h>

@interface TBPlayerManager : NSObject {
    MPMusicPlayerController *_musicPlayer;
    NSArray *_originalQueueItems;
    NSArray *_queueItems;
    NSInteger _currentQueueIndex;
    BOOL _shuffleEnabled;
    BOOL _repeatOneEnabled;
}

@property(nonatomic, retain, readonly) MPMusicPlayerController *musicPlayer;
@property(nonatomic, retain, readonly) NSArray *queueItems;
@property(nonatomic, readonly) NSInteger currentQueueIndex;
@property(nonatomic, readonly) BOOL shuffleEnabled;
@property(nonatomic, readonly) BOOL repeatOneEnabled;

+ (TBPlayerManager *)sharedManager;
- (void)playItems:(NSArray *)items startingAtItem:(MPMediaItem *)item;
- (void)togglePlayPause;
- (void)previous;
- (void)next;
- (void)seekToTime:(NSTimeInterval)time;
- (void)playQueueItemAtIndex:(NSInteger)index;
- (void)toggleShuffle;
- (void)toggleRepeatOne;

@end
