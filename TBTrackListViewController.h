#import <UIKit/UIKit.h>
#import <MediaPlayer/MediaPlayer.h>

@class TBNowPlayingViewController;

@interface TBTrackListViewController : UITableViewController <UISearchBarDelegate, UIActionSheetDelegate> {
    NSArray *_items;
    NSArray *_allItems;
    UIBarButtonItem *_playPauseButton;
    TBNowPlayingViewController *_nowPlayingController;
    UISearchBar *_searchBar;
    NSTimer *_searchTimer;
    NSString *_pendingSearchText;
    MPMediaItem *_contextItem;
    NSArray *_contextActions;
}

@property(nonatomic, retain) NSArray *items;
@property(nonatomic, retain) UIBarButtonItem *playPauseButton;

- (id)initWithTitle:(NSString *)title items:(NSArray *)items;
- (void)reloadTrackItems;
- (void)showNowPlaying:(id)sender;
- (void)shuffleCurrentItems;
- (void)applyTheme;

@end
