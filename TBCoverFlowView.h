#import <UIKit/UIKit.h>

@interface TBCoverFlowView : UIView {
    UIScrollView *_scrollView;
    NSMutableArray *_coverViews;
    UILabel *_albumLabel;
    UILabel *_artistLabel;
    NSArray *_albums;
    NSInteger _selectedIndex;
    NSInteger _previousSelectedIndex;
    NSUInteger _animationGeneration;
    BOOL _animationInProgress;
}
- (void)setAlbums:(NSArray *)albums selectedIndex:(NSInteger)index;
- (void)selectIndex:(NSInteger)index animated:(BOOL)animated;
- (void)applyTheme;
@end
