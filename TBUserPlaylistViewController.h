#import "TBTrackListViewController.h"

@interface TBUserPlaylistViewController : TBTrackListViewController {
    NSString *_playlistID;
}
- (id)initWithPlaylist:(NSDictionary *)playlist;
@end
