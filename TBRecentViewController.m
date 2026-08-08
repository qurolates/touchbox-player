#import "TBRecentViewController.h"
#import "TBRecentManager.h"
#import "TBTrackListViewController.h"
#import "TBTheme.h"
#import "AppDelegate.h"
#import "TBThemeViewController.h"

@implementation TBRecentViewController
- (id)init { if ((self = [super initWithStyle:UITableViewStylePlain])) self.title = @"Recent"; return self; }
- (void)viewDidLoad { [super viewDidLoad]; [TBTheme styleTableView:self.tableView]; [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(themeChanged:) name:TBThemeDidChangeNotification object:nil]; }
- (void)themeChanged:(NSNotification *)notification { [TBTheme styleTableView:self.tableView]; [self.tableView reloadData]; }
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section { return 4; }
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)path { static NSString *identifier = @"RecentKind"; UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:identifier]; if (!cell) cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:identifier] autorelease]; cell.backgroundColor = [TBTheme backgroundColor]; cell.textLabel.textColor = [TBTheme primaryTextColor]; cell.textLabel.text = path.row == 0 ? @"Recently Played" : (path.row == 1 ? @"Recently Added" : (path.row == 2 ? @"Theme" : @"Classic Mode")); cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator; return cell; }
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)path { [tableView deselectRowAtIndexPath:path animated:YES]; if (path.row == 3) { [(AppDelegate *)[UIApplication sharedApplication].delegate showClassicMode]; return; } if (path.row == 2) { TBThemeViewController *theme = [[TBThemeViewController alloc] init]; [self.navigationController pushViewController:theme animated:YES]; [theme release]; return; } NSArray *items = path.row ? [[TBRecentManager sharedManager] recentlyAddedItems] : [[TBRecentManager sharedManager] recentlyPlayedItems]; TBTrackListViewController *controller = [[TBTrackListViewController alloc] initWithTitle:(path.row ? @"Recently Added" : @"Recently Played") items:items]; [self.navigationController pushViewController:controller animated:YES]; [controller release]; }
- (void)dealloc { [[NSNotificationCenter defaultCenter] removeObserver:self]; [super dealloc]; }
@end
