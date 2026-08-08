#import <Foundation/Foundation.h>
#import <MediaPlayer/MediaPlayer.h>

@interface TBPlayerManager : NSObject {
    MPMusicPlayerController *_musicPlayer;
}

@property(nonatomic, retain, readonly) MPMusicPlayerController *musicPlayer;

+ (TBPlayerManager *)sharedManager;
- (void)playItems:(NSArray *)items startingAtItem:(MPMediaItem *)item;
- (void)togglePlayPause;
- (void)previous;
- (void)next;

@end
