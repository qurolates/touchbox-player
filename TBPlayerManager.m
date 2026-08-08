#import "TBPlayerManager.h"

@implementation TBPlayerManager

@synthesize musicPlayer = _musicPlayer;

+ (TBPlayerManager *)sharedManager {
    static TBPlayerManager *manager = nil;
    if (manager == nil) {
        manager = [[TBPlayerManager alloc] init];
    }
    return manager;
}

- (id)init {
    self = [super init];
    if (self) {
        _musicPlayer = [[MPMusicPlayerController iPodMusicPlayer] retain];
        [_musicPlayer beginGeneratingPlaybackNotifications];
    }
    return self;
}

- (void)playItems:(NSArray *)items startingAtItem:(MPMediaItem *)item {
    if ([items count] == 0 || item == nil) {
        NSLog(@"Touchbox: refusing empty playback queue");
        return;
    }
    MPMediaItemCollection *queue = [MPMediaItemCollection collectionWithItems:items];
    NSLog(@"Touchbox: creating queue with %lu items", (unsigned long)[items count]);
    [_musicPlayer setQueueWithItemCollection:queue];
    _musicPlayer.nowPlayingItem = item;
    [_musicPlayer play];
}

- (void)togglePlayPause {
    if (_musicPlayer.playbackState == MPMusicPlaybackStatePlaying) {
        [_musicPlayer pause];
    } else {
        [_musicPlayer play];
    }
}

- (void)previous { [_musicPlayer skipToPreviousItem]; }
- (void)next { [_musicPlayer skipToNextItem]; }

- (void)dealloc {
    [_musicPlayer endGeneratingPlaybackNotifications];
    [_musicPlayer release];
    [super dealloc];
}

@end
