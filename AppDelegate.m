#import "AppDelegate.h"
#import "TBSongsViewController.h"
#import "TBAlbumsViewController.h"
#import "TBArtistsViewController.h"
#import "TBFavoritesViewController.h"
#import "TBPlaylistsViewController.h"
#import "TBLibraryManager.h"

@implementation AppDelegate

@synthesize window = _window;
@synthesize tabBarController = _tabBarController;

- (void)applicationDidFinishLaunching:(UIApplication *)application {
    UIWindow *window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    self.window = window;
    [window release];

    UIViewController *roots[5];
    roots[0] = [[TBSongsViewController alloc] init];
    roots[1] = [[TBAlbumsViewController alloc] init];
    roots[2] = [[TBArtistsViewController alloc] init];
    roots[3] = [[TBFavoritesViewController alloc] init];
    roots[4] = [[TBPlaylistsViewController alloc] init];
    NSMutableArray *controllers = [NSMutableArray arrayWithCapacity:5];
    NSUInteger index;
    for (index = 0; index < 5; index++) {
        UINavigationController *navigation = [[UINavigationController alloc]
            initWithRootViewController:roots[index]];
        navigation.tabBarItem.title = roots[index].title;
        [controllers addObject:navigation];
        [navigation release];
        [roots[index] release];
    }
    UITabBarController *tabs = [[UITabBarController alloc] init];
    tabs.viewControllers = controllers;
    self.tabBarController = tabs;
    [tabs release];
    self.window.rootViewController = self.tabBarController;

    [self.window makeKeyAndVisible];
    NSLog(@"Touchbox: app launch complete");
    [[TBLibraryManager sharedManager] beginLoadingLibrary];
}

- (void)dealloc {
    [_window release];
    [_tabBarController release];
    [super dealloc];
}

@end
