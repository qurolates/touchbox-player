#import <UIKit/UIKit.h>
#import "TBClickWheelView.h"
@class TBCoverFlowView;

@interface TBClassicViewController : UIViewController <TBClickWheelViewDelegate> {
    NSMutableArray *_navigationStack;
    NSArray *_currentItems;
    NSInteger _screenType;
    NSString *_screenTitle;
    NSMutableArray *_rowLabels;
    UILabel *_titleLabel;
    UILabel *_queuePositionLabel;
    UILabel *_statusLabel;
    TBClickWheelView *_wheelView;
    NSInteger _selectedIndex;
    UIView *_nowPlayingView;
    TBCoverFlowView *_coverFlowView;
    UIImageView *_nowPlayingArtworkView;
    UILabel *_nowPlayingTitleLabel;
    UILabel *_nowPlayingArtistLabel;
    UILabel *_nowPlayingAlbumLabel;
    UILabel *_nowPlayingElapsedLabel;
    UILabel *_nowPlayingRemainingLabel;
    UIView *_progressFillView;
    NSTimer *_progressTimer;
    NSString *_nowPlayingArtworkKey;
    BOOL _creatingPlaylistForCurrentItem;
    BOOL _loadingClassicPlaylist;
    BOOL _visible;
    BOOL _classicSeekChanged;
}
@end
