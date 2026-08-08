#import <UIKit/UIKit.h>
#import <MediaPlayer/MediaPlayer.h>

@interface TBTrackListViewController : UITableViewController {
    NSArray *_items;
    UIBarButtonItem *_playPauseButton;
}

@property(nonatomic, retain) NSArray *items;
@property(nonatomic, retain) UIBarButtonItem *playPauseButton;

- (id)initWithTitle:(NSString *)title items:(NSArray *)items;
- (void)reloadTrackItems;

@end
