#import <UIKit/UIKit.h>

@interface TBNowPlayingViewController : UIViewController {
    UIImageView *_artworkView;
    UILabel *_titleLabel;
    UILabel *_artistLabel;
    UILabel *_albumLabel;
    UILabel *_elapsedLabel;
    UILabel *_remainingLabel;
    UISlider *_progressSlider;
    UIButton *_playPauseButton;
    UIButton *_shuffleButton;
    UIButton *_repeatButton;
    NSTimer *_progressTimer;
    BOOL _seeking;
    NSString *_artworkKey;
}
@end
