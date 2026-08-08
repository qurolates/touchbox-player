#import <UIKit/UIKit.h>
#import <MediaPlayer/MediaPlayer.h>

@interface TBAddToPlaylistViewController : UITableViewController {
    MPMediaItem *_item;
    NSArray *_playlists;
}
- (id)initWithItem:(MPMediaItem *)item;
@end
