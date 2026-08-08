#import <UIKit/UIKit.h>

@interface AppDelegate : NSObject <UIApplicationDelegate> {
    UIWindow *_window;
    UITabBarController *_tabBarController;
    UIViewController *_classicViewController;
}

@property(nonatomic, retain) UIWindow *window;
@property(nonatomic, retain) UITabBarController *tabBarController;
- (void)showClassicMode;
- (void)showStandardMode;

@end
