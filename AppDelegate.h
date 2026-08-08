#import <UIKit/UIKit.h>

@interface AppDelegate : NSObject <UIApplicationDelegate> {
    UIWindow *_window;
    UITabBarController *_tabBarController;
}

@property(nonatomic, retain) UIWindow *window;
@property(nonatomic, retain) UITabBarController *tabBarController;

@end
