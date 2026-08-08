#import "TBRecentViewController.h"
#import "TBRecentManager.h"
#import "TBTrackListViewController.h"
#import "TBTheme.h"
#import "AppDelegate.h"

@implementation TBRecentViewController
- (id)init { if ((self = [super initWithStyle:UITableViewStylePlain])) self.title = @"Recent"; return self; }
- (void)viewDidLoad { [super viewDidLoad]; [TBTheme styleTableView:self.tableView]; }
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section { return 3; }
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)path { static NSString *identifier = @"RecentKind"; UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:identifier]; if (!cell) cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:identifier] autorelease]; cell.textLabel.text = path.row == 0 ? @"Recently Played" : (path.row == 1 ? @"Recently Added" : @"Classic Mode"); cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator; return cell; }
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)path { [tableView deselectRowAtIndexPath:path animated:YES]; if (path.row == 2) { [(AppDelegate *)[UIApplication sharedApplication].delegate showClassicMode]; return; } NSArray *items = path.row ? [[TBRecentManager sharedManager] recentlyAddedItems] : [[TBRecentManager sharedManager] recentlyPlayedItems]; TBTrackListViewController *controller = [[TBTrackListViewController alloc] initWithTitle:(path.row ? @"Recently Added" : @"Recently Played") items:items]; [self.navigationController pushViewController:controller animated:YES]; [controller release]; }
@end
