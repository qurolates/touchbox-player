#import <UIKit/UIKit.h>

@interface TBAlphabetIndexView : UIView {
    NSArray *_titles;
    id _target;
    SEL _action;
    NSInteger _selectedIndex;
}
- (id)initWithFrame:(CGRect)frame titles:(NSArray *)titles target:(id)target action:(SEL)action;
- (void)setTitles:(NSArray *)titles;
@end
