#import <Foundation/Foundation.h>
#import <MediaPlayer/MediaPlayer.h>

extern NSString *const TBRecentDidChangeNotification;

@interface TBRecentManager : NSObject {
    NSMutableDictionary *_playedDates;
    NSMutableDictionary *_firstSeenDates;
    NSString *_lastPlayedIdentifier;
    NSDate *_lastPlayedWriteDate;
}
+ (TBRecentManager *)sharedManager;
- (void)updateFirstSeenWithItems:(NSArray *)items;
- (NSArray *)recentlyPlayedItems;
- (NSArray *)recentlyAddedItems;
@end
