#import "TBThemeViewController.h"
#import "TBTheme.h"

@implementation TBThemeViewController
- (id)init { return [self initWithDismissButton:NO]; }
- (id)initWithDismissButton:(BOOL)showsDismissButton { if ((self = [super initWithStyle:UITableViewStylePlain])) { self.title = @"Theme"; _showsDismissButton = showsDismissButton; } return self; }
- (void)viewDidLoad { [super viewDidLoad]; if (_showsDismissButton) self.navigationItem.rightBarButtonItem = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(done:)] autorelease]; [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(themeChanged:) name:TBThemeDidChangeNotification object:nil]; [self applyTheme]; }
- (void)done:(id)sender { [self dismissModalViewControllerAnimated:YES]; }
- (void)applyTheme { [TBTheme styleTableView:self.tableView]; self.navigationController.navigationBar.barStyle = [TBTheme isDarkTheme] ? UIBarStyleBlack : UIBarStyleDefault; self.navigationController.navigationBar.tintColor = [TBTheme navigationBarColor]; [self.tableView reloadData]; }
- (void)themeChanged:(NSNotification *)note { [self applyTheme]; }
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section { return 2; }
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)path { static NSString *identifier = @"ThemeCell"; UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:identifier]; if (!cell) cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:identifier] autorelease]; cell.backgroundColor = [TBTheme backgroundColor]; cell.textLabel.textColor = [TBTheme primaryTextColor]; cell.textLabel.text = path.row ? @"Dark" : @"Light"; cell.accessoryType = ([TBTheme currentTheme] == path.row) ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone; return cell; }
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)path { [tableView deselectRowAtIndexPath:path animated:YES]; [TBTheme setCurrentTheme:path.row ? TBThemeModeDark : TBThemeModeLight]; [tableView reloadData]; }
- (void)dealloc { [[NSNotificationCenter defaultCenter] removeObserver:self]; [super dealloc]; }
@end
