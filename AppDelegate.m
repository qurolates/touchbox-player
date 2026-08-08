#import "AppDelegate.h"
#import "TBSongsViewController.h"
#import "TBAlbumsViewController.h"
#import "TBArtistsViewController.h"
#import "TBFavoritesViewController.h"
#import "TBPlaylistsViewController.h"
#import "TBLibraryManager.h"
#import "TBTheme.h"
#import "TBPlayerManager.h"
#import "TBRecentManager.h"
#import "TBClassicViewController.h"

@implementation AppDelegate

static NSString *const TBClassicModeDefaultsKey = @"TBClassicModeEnabled";

@synthesize window = _window;
@synthesize tabBarController = _tabBarController;

- (void)applicationDidFinishLaunching:(UIApplication *)application {
    UIWindow *window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    self.window = window;
    [window release];

    UIViewController *roots[5];
    roots[0] = [[TBAlbumsViewController alloc] init];
    roots[1] = [[TBArtistsViewController alloc] init];
    roots[2] = [[TBSongsViewController alloc] init];
    roots[3] = [[TBFavoritesViewController alloc] init];
    roots[4] = [[TBPlaylistsViewController alloc] init];
    NSArray *tabImages = [NSArray arrayWithObjects:
        [UIImage imageNamed:@"albums.png"],
        [UIImage imageNamed:@"artists.png"],
        [UIImage imageNamed:@"songs.png"],
        [UIImage imageNamed:@"favorite.png"],
        [UIImage imageNamed:@"playlists.png"], nil];
    NSMutableArray *controllers = [NSMutableArray arrayWithCapacity:5];
    NSUInteger index;
    for (index = 0; index < 5; index++) {
        UINavigationController *navigation = [[UINavigationController alloc]
            initWithRootViewController:roots[index]];
        navigation.navigationBar.tintColor = [TBTheme accentColor];
        navigation.toolbar.tintColor = [TBTheme accentColor];
        navigation.tabBarItem.title = roots[index].title;
        navigation.tabBarItem.image = [tabImages objectAtIndex:index];
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
    [TBRecentManager sharedManager];
    [[TBLibraryManager sharedManager] beginLoadingLibrary];
    if ([[NSUserDefaults standardUserDefaults] boolForKey:TBClassicModeDefaultsKey])
        [self showClassicMode];
}

- (void)applicationDidEnterBackground:(UIApplication *)application { [[TBPlayerManager sharedManager] savePlaybackState]; }
- (void)applicationWillTerminate:(UIApplication *)application { [[TBPlayerManager sharedManager] savePlaybackState]; }

- (void)showClassicMode {
    if (!_classicViewController) _classicViewController = [[TBClassicViewController alloc] init];
    [[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:UIStatusBarAnimationNone];
    self.window.rootViewController = _classicViewController;
    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:TBClassicModeDefaultsKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
    NSLog(@"Touchbox Classic: prototype shown; playback queue unchanged");
}
- (void)showStandardMode { [[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:UIStatusBarAnimationNone]; self.window.rootViewController = self.tabBarController; [[NSUserDefaults standardUserDefaults] setBool:NO forKey:TBClassicModeDefaultsKey]; [[NSUserDefaults standardUserDefaults] synchronize]; NSLog(@"Touchbox Classic: returned to Standard Mode"); }

- (void)dealloc {
    [_window release];
    [_tabBarController release];
    [_classicViewController release];
    [super dealloc];
}

@end
