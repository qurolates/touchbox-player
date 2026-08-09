#import "TBRecentManager.h"
#import "TBPlayerManager.h"
#import "TBLibraryManager.h"

NSString *const TBRecentDidChangeNotification = @"TBRecentDidChangeNotification";
static NSString *const TBRecentPlayedKey = @"TBRecentPlayedDates";
static NSString *const TBRecentFirstSeenKey = @"TBRecentFirstSeenDates";

@implementation TBRecentManager
+ (TBRecentManager *)sharedManager { static TBRecentManager *manager = nil; if (!manager) manager = [[TBRecentManager alloc] init]; return manager; }
- (id)init { if ((self = [super init])) {
    NSDictionary *played = [[NSUserDefaults standardUserDefaults] objectForKey:TBRecentPlayedKey];
    NSDictionary *seen = [[NSUserDefaults standardUserDefaults] objectForKey:TBRecentFirstSeenKey];
    _playedDates = [[NSMutableDictionary alloc] initWithDictionary:(played ? played : [NSDictionary dictionary])];
    _firstSeenDates = [[NSMutableDictionary alloc] initWithDictionary:(seen ? seen : [NSDictionary dictionary])];
    MPMusicPlayerController *player = [TBPlayerManager sharedManager].musicPlayer;
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playbackChanged:)
        name:MPMusicPlayerControllerPlaybackStateDidChangeNotification object:player];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playbackChanged:)
        name:MPMusicPlayerControllerNowPlayingItemDidChangeNotification object:player];
} return self; }
- (NSString *)identifier:(MPMediaItem *)item { NSNumber *n = [item valueForProperty:MPMediaItemPropertyPersistentID]; return n ? [NSString stringWithFormat:@"%llu", [n unsignedLongLongValue]] : nil; }
- (void)save { NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults]; [defaults setObject:_playedDates forKey:TBRecentPlayedKey]; [defaults setObject:_firstSeenDates forKey:TBRecentFirstSeenKey]; }
- (void)playbackChanged:(NSNotification *)notification { TBPlayerManager *manager = [TBPlayerManager sharedManager]; if (manager.musicPlayer.playbackState != MPMusicPlaybackStatePlaying) return;
    NSString *identifier = [self identifier:manager.musicPlayer.nowPlayingItem]; if (!identifier) return;
    NSDate *now = [NSDate date];
    if ([_lastPlayedIdentifier isEqualToString:identifier] && _lastPlayedWriteDate &&
        [now timeIntervalSinceDate:_lastPlayedWriteDate] < 5.0) return;
    [_lastPlayedIdentifier release]; _lastPlayedIdentifier = [identifier copy];
    [_lastPlayedWriteDate release]; _lastPlayedWriteDate = [now retain];
    [_playedDates setObject:now forKey:identifier];
    if ([_playedDates count] > 200) { NSArray *keys = [_playedDates keysSortedByValueUsingSelector:@selector(compare:)]; NSUInteger remove = [_playedDates count] - 200; NSUInteger i; for (i = 0; i < remove; i++) [_playedDates removeObjectForKey:[keys objectAtIndex:i]]; }
    [self save]; [[NSNotificationCenter defaultCenter] postNotificationName:TBRecentDidChangeNotification object:self];
}
- (void)updateFirstSeenWithItems:(NSArray *)items { NSDate *now = [NSDate date]; BOOL changed = NO; NSUInteger i; for (i = 0; i < [items count]; i++) { NSString *identifier = [self identifier:[items objectAtIndex:i]]; if (identifier && ![_firstSeenDates objectForKey:identifier]) { [_firstSeenDates setObject:now forKey:identifier]; changed = YES; } } if (changed) [self save]; }
- (NSArray *)itemsForDates:(NSDictionary *)dates { NSArray *ascending = [dates keysSortedByValueUsingSelector:@selector(compare:)]; NSMutableArray *ids = [NSMutableArray arrayWithCapacity:[ascending count]]; NSEnumerator *enumerator = [ascending reverseObjectEnumerator]; NSString *identifier; while ((identifier = [enumerator nextObject])) [ids addObject:identifier]; return [[TBLibraryManager sharedManager] itemsForPersistentIDs:ids]; }
- (NSArray *)recentlyPlayedItems { return [self itemsForDates:_playedDates]; }
- (NSArray *)recentlyAddedItems { NSArray *items = [self itemsForDates:_firstSeenDates]; return [items count] > 200 ? [items subarrayWithRange:NSMakeRange(0, 200)] : items; }
- (void)dealloc { [[NSNotificationCenter defaultCenter] removeObserver:self]; [_playedDates release]; [_firstSeenDates release]; [_lastPlayedIdentifier release]; [_lastPlayedWriteDate release]; [super dealloc]; }
@end
