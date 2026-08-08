#import <UIKit/UIKit.h>

@interface TBPlaylistNameViewController : UIViewController {
    UITextField *_textField;
    id _target;
    SEL _action;
}
- (id)initWithTarget:(id)target action:(SEL)action;
@end
