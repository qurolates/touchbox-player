#import "TBPlayerManager.h"

@implementation TBPlayerManager

@synthesize musicPlayer = _musicPlayer;
@synthesize queueItems = _queueItems;
@synthesize currentQueueIndex = _currentQueueIndex;
@synthesize shuffleEnabled = _shuffleEnabled;
@synthesize repeatOneEnabled = _repeatOneEnabled;

static NSString *const TBRepeatOneDefaultsKey = @"TBRepeatOneEnabled";

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
        _currentQueueIndex = NSNotFound;
        _shuffleEnabled = NO;
        _repeatOneEnabled = [[NSUserDefaults standardUserDefaults]
            boolForKey:TBRepeatOneDefaultsKey];
        _musicPlayer.shuffleMode = MPMusicShuffleModeOff;
        _musicPlayer.repeatMode = _repeatOneEnabled ? MPMusicRepeatModeOne : MPMusicRepeatModeNone;
        [[NSNotificationCenter defaultCenter] addObserver:self
            selector:@selector(nowPlayingItemChanged:)
            name:MPMusicPlayerControllerNowPlayingItemDidChangeNotification object:_musicPlayer];
    }
    return self;
}

- (void)playItems:(NSArray *)items startingAtItem:(MPMediaItem *)item {
    if ([items count] == 0 || item == nil) {
        NSLog(@"Touchbox: refusing empty playback queue");
        return;
    }
    [_originalQueueItems release];
    _originalQueueItems = [items copy];
    [_queueItems release];
    _queueItems = [items copy];
    _shuffleEnabled = NO;
    _musicPlayer.shuffleMode = MPMusicShuffleModeOff;
    MPMediaItemCollection *queue = [MPMediaItemCollection collectionWithItems:_queueItems];
    NSLog(@"Touchbox: creating queue with %lu items", (unsigned long)[items count]);
    [_musicPlayer setQueueWithItemCollection:queue];
    _musicPlayer.nowPlayingItem = item;
    [_musicPlayer play];
    [self updateCurrentQueueIndex];
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

- (void)seekToTime:(NSTimeInterval)time { _musicPlayer.currentPlaybackTime = time; }

- (NSString *)persistentIDForItem:(MPMediaItem *)item {
    NSNumber *number = [item valueForProperty:MPMediaItemPropertyPersistentID];
    return [NSString stringWithFormat:@"%llu", [number unsignedLongLongValue]];
}

- (NSInteger)indexOfItem:(MPMediaItem *)item inItems:(NSArray *)items {
    if (!item) return NSNotFound;
    NSString *identifier = [self persistentIDForItem:item];
    NSUInteger index;
    for (index = 0; index < [items count]; index++) {
        if ([[self persistentIDForItem:[items objectAtIndex:index]] isEqualToString:identifier])
            return (NSInteger)index;
    }
    return NSNotFound;
}

- (void)updateCurrentQueueIndex {
    _currentQueueIndex = [self indexOfItem:_musicPlayer.nowPlayingItem inItems:_queueItems];
}

- (void)nowPlayingItemChanged:(NSNotification *)notification { [self updateCurrentQueueIndex]; }

- (void)playQueueItemAtIndex:(NSInteger)index {
    if (index < 0 || index >= (NSInteger)[_queueItems count]) return;
    MPMediaItem *item = [_queueItems objectAtIndex:(NSUInteger)index];
    _musicPlayer.nowPlayingItem = item;
    [_musicPlayer play];
    _currentQueueIndex = index;
}

- (void)applyQueue:(NSArray *)items keepingItem:(MPMediaItem *)currentItem {
    NSTimeInterval playbackTime = _musicPlayer.currentPlaybackTime;
    BOOL wasPlaying = (_musicPlayer.playbackState == MPMusicPlaybackStatePlaying);
    [_queueItems release];
    _queueItems = [items copy];
    MPMediaItemCollection *collection = [MPMediaItemCollection collectionWithItems:_queueItems];
    [_musicPlayer setQueueWithItemCollection:collection];
    _musicPlayer.nowPlayingItem = currentItem;
    _musicPlayer.currentPlaybackTime = playbackTime;
    if (wasPlaying) [_musicPlayer play]; else [_musicPlayer pause];
    [self updateCurrentQueueIndex];
}

- (void)toggleShuffle {
    if ([_originalQueueItems count] < 2 || !_musicPlayer.nowPlayingItem) return;
    MPMediaItem *currentItem = _musicPlayer.nowPlayingItem;
    if (!_shuffleEnabled) {
        NSMutableArray *remaining = [NSMutableArray arrayWithArray:_originalQueueItems];
        NSInteger currentIndex = [self indexOfItem:currentItem inItems:remaining];
        if (currentIndex != NSNotFound) [remaining removeObjectAtIndex:(NSUInteger)currentIndex];
        NSUInteger count = [remaining count];
        while (count > 1) {
            NSUInteger other = (NSUInteger)(arc4random() % count);
            [remaining exchangeObjectAtIndex:count - 1 withObjectAtIndex:other];
            count--;
        }
        NSMutableArray *shuffled = [NSMutableArray arrayWithObject:currentItem];
        [shuffled addObjectsFromArray:remaining];
        [self applyQueue:shuffled keepingItem:currentItem];
        _shuffleEnabled = YES;
    } else {
        [self applyQueue:_originalQueueItems keepingItem:currentItem];
        _shuffleEnabled = NO;
    }
    _musicPlayer.shuffleMode = MPMusicShuffleModeOff;
}

- (void)toggleRepeatOne {
    _repeatOneEnabled = !_repeatOneEnabled;
    _musicPlayer.repeatMode = _repeatOneEnabled ? MPMusicRepeatModeOne : MPMusicRepeatModeNone;
    [[NSUserDefaults standardUserDefaults] setBool:_repeatOneEnabled forKey:TBRepeatOneDefaultsKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [_musicPlayer endGeneratingPlaybackNotifications];
    [_originalQueueItems release];
    [_queueItems release];
    [_musicPlayer release];
    [super dealloc];
}

@end
