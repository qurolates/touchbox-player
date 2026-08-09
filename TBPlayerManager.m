#import "TBPlayerManager.h"
#import "TBLibraryManager.h"
#import "TBPerformance.h"
#import <math.h>

NSString *const TBPlayerQueueDidChangeNotification = @"TBPlayerQueueDidChangeNotification";

@implementation TBPlayerManager

@synthesize musicPlayer = _musicPlayer;
@synthesize queueItems = _queueItems;
@synthesize currentQueueIndex = _currentQueueIndex;
@synthesize shuffleEnabled = _shuffleEnabled;
@synthesize repeatOneEnabled = _repeatOneEnabled;

static NSString *const TBRepeatOneDefaultsKey = @"TBRepeatOneEnabled";
static NSString *const TBPlaybackStateDefaultsKey = @"TBPlaybackState";

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
        [[NSNotificationCenter defaultCenter] addObserver:self
            selector:@selector(playbackStateChanged:)
            name:MPMusicPlayerControllerPlaybackStateDidChangeNotification object:_musicPlayer];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(libraryReady:)
            name:TBLibraryIndexDidLoadNotification object:[TBLibraryManager sharedManager]];
    }
    return self;
}

- (void)playItems:(NSArray *)items startingAtItem:(MPMediaItem *)item {
    if ([items count] == 0 || item == nil) {
        TBPerformanceLog(@"Touchbox: refusing empty playback queue");
        return;
    }
    [_originalQueueItems release];
    _originalQueueItems = [items copy];
    [_queueItems release];
    _queueItems = [items copy];
    _shuffleEnabled = NO;
    _musicPlayer.shuffleMode = MPMusicShuffleModeOff;
    MPMediaItemCollection *queue = [MPMediaItemCollection collectionWithItems:_queueItems];
    TBPerformanceLog(@"Touchbox: creating queue with %lu items", (unsigned long)[items count]);
    [_musicPlayer setQueueWithItemCollection:queue];
    _musicPlayer.nowPlayingItem = item;
    [_musicPlayer play];
    [self updateCurrentQueueIndex];
    [self queueDidChange];
}

- (void)playItemsShuffled:(NSArray *)items {
    if (![items count]) return;
    NSMutableArray *shuffled = [NSMutableArray arrayWithArray:items];
    NSUInteger count = [shuffled count];
    while (count > 1) { NSUInteger other = arc4random() % count;
        [shuffled exchangeObjectAtIndex:count - 1 withObjectAtIndex:other]; count--; }
    [self playItems:shuffled startingAtItem:[shuffled objectAtIndex:0]];
    [_originalQueueItems release]; _originalQueueItems = [items copy];
    _shuffleEnabled = YES; [self queueDidChange];
}

- (void)togglePlayPause {
    if (_musicPlayer.playbackState == MPMusicPlaybackStatePlaying) {
        [_musicPlayer pause];
    } else {
        [_musicPlayer play];
    }
    [self savePlaybackState];
}

- (void)previous { [_musicPlayer skipToPreviousItem]; }
- (void)next { [_musicPlayer skipToNextItem]; }

- (void)seekToTimeWithoutSaving:(NSTimeInterval)time { _musicPlayer.currentPlaybackTime = time; }
- (void)seekToTime:(NSTimeInterval)time { [self seekToTimeWithoutSaving:time]; [self savePlaybackState]; }
- (void)beginInteractiveSeek { _interactiveSeek = YES; }
- (void)endInteractiveSeek { if (!_interactiveSeek) return; _interactiveSeek = NO; [self savePlaybackState]; }

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

- (void)nowPlayingItemChanged:(NSNotification *)notification { [self updateCurrentQueueIndex]; [self savePlaybackState]; }
- (void)playbackStateChanged:(NSNotification *)notification {
    if (!_interactiveSeek && _musicPlayer.playbackState != MPMusicPlaybackStatePlaying) [self savePlaybackState];
}

- (void)insertItem:(MPMediaItem *)item atIndex:(NSUInteger)index {
    if (!item) return;
    NSMutableArray *items = [NSMutableArray arrayWithArray:(_queueItems ? _queueItems : [NSArray array])];
    NSInteger existing = [self indexOfItem:item inItems:items];
    if (existing != NSNotFound) { [items removeObjectAtIndex:(NSUInteger)existing]; if ((NSUInteger)existing < index && index) index--; }
    if (index > [items count]) index = [items count];
    [items insertObject:item atIndex:index];
    [self applyQueue:items keepingItem:_musicPlayer.nowPlayingItem];
    [_originalQueueItems release]; _originalQueueItems = [items copy];
    [self queueDidChange];
}
- (void)playNextItem:(MPMediaItem *)item { [self insertItem:item atIndex:(_currentQueueIndex == NSNotFound ? 0 : (NSUInteger)_currentQueueIndex + 1)]; }
- (void)addItemToQueue:(MPMediaItem *)item { [self insertItem:item atIndex:[_queueItems count]]; }

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
    [self queueDidChange];
}

- (void)toggleRepeatOne {
    _repeatOneEnabled = !_repeatOneEnabled;
    _musicPlayer.repeatMode = _repeatOneEnabled ? MPMusicRepeatModeOne : MPMusicRepeatModeNone;
    [[NSUserDefaults standardUserDefaults] setBool:_repeatOneEnabled forKey:TBRepeatOneDefaultsKey];
    [self savePlaybackState];
}

- (void)queueDidChange {
    [[NSNotificationCenter defaultCenter] postNotificationName:TBPlayerQueueDidChangeNotification object:self];
    [self savePlaybackState];
}

- (void)savePlaybackState {
    if (![_queueItems count]) return;
    NSMutableArray *ids = [NSMutableArray arrayWithCapacity:[_queueItems count]]; NSUInteger i;
    for (i = 0; i < [_queueItems count]; i++) [ids addObject:[self persistentIDForItem:[_queueItems objectAtIndex:i]]];
    NSString *current = [self persistentIDForItem:_musicPlayer.nowPlayingItem];
    NSDictionary *state = [NSDictionary dictionaryWithObjectsAndKeys:ids, @"queue", (current ? current : @""), @"current",
        [NSNumber numberWithUnsignedInteger:(NSUInteger)MAX(0.0, floor(_musicPlayer.currentPlaybackTime))], @"time",
        [NSNumber numberWithBool:_shuffleEnabled], @"shuffle",
        [NSNumber numberWithBool:_repeatOneEnabled], @"repeat", [NSNumber numberWithInteger:_currentQueueIndex], @"queueIndex",
        [NSNumber numberWithBool:(_musicPlayer.playbackState == MPMusicPlaybackStatePlaying)], @"wasPlaying",
        @"TouchboxQueue", @"queueContext", nil];
    if ([_lastSavedState isEqualToDictionary:state]) return;
    [_lastSavedState release];
    _lastSavedState = [state copy];
    [[NSUserDefaults standardUserDefaults] setObject:state forKey:TBPlaybackStateDefaultsKey];
}

- (void)libraryReady:(NSNotification *)notification {
    if ([_queueItems count]) return;
    NSDictionary *state = [[NSUserDefaults standardUserDefaults] objectForKey:TBPlaybackStateDefaultsKey];
    NSArray *items = [[TBLibraryManager sharedManager] itemsForPersistentIDs:[state objectForKey:@"queue"]];
    if (![items count]) return;
    NSString *wanted = [state objectForKey:@"current"]; MPMediaItem *current = nil; NSUInteger i;
    for (i = 0; i < [items count]; i++) if ([[self persistentIDForItem:[items objectAtIndex:i]] isEqualToString:wanted]) { current = [items objectAtIndex:i]; break; }
    if (!current) current = [items objectAtIndex:0];
    [_originalQueueItems release]; _originalQueueItems = [items copy]; [_queueItems release]; _queueItems = [items copy];
    _shuffleEnabled = [[state objectForKey:@"shuffle"] boolValue]; _repeatOneEnabled = [[state objectForKey:@"repeat"] boolValue];
    [_musicPlayer setQueueWithItemCollection:[MPMediaItemCollection collectionWithItems:items]]; _musicPlayer.nowPlayingItem = current;
    NSTimeInterval time = [[state objectForKey:@"time"] doubleValue]; NSTimeInterval duration = [[current valueForProperty:MPMediaItemPropertyPlaybackDuration] doubleValue];
    _musicPlayer.currentPlaybackTime = (duration > 0 && duration - time < 5.0) ? 0 : time;
    _musicPlayer.repeatMode = _repeatOneEnabled ? MPMusicRepeatModeOne : MPMusicRepeatModeNone; [_musicPlayer pause];
    [self updateCurrentQueueIndex]; [[NSNotificationCenter defaultCenter] postNotificationName:TBPlayerQueueDidChangeNotification object:self];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [_musicPlayer endGeneratingPlaybackNotifications];
    [_originalQueueItems release];
    [_queueItems release];
    [_lastSavedState release];
    [_musicPlayer release];
    [super dealloc];
}

@end
