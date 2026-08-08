#import "TBAlbumsViewController.h"
#import "TBLibraryManager.h"
#import "TBAlbumViewController.h"
#import "TBLoadingView.h"
#import "TBAlbumGridCell.h"
#import "TBArtworkCache.h"
#import "TBNowPlayingViewController.h"
#import "TBTheme.h"

@implementation TBAlbumsViewController

- (id)init {
    self = [super initWithStyle:UITableViewStylePlain];
    if (self) self.title = @"Albums";
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [TBTheme styleTableView:self.tableView];
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.navigationItem.rightBarButtonItem = [[[UIBarButtonItem alloc]
        initWithTitle:@"Player" style:UIBarButtonItemStyleBordered
        target:self action:@selector(showNowPlaying:)] autorelease];
    _artistGroups = [[[TBLibraryManager sharedManager] artistGroups] retain];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(indexReady:)
        name:TBLibraryIndexDidLoadNotification object:[TBLibraryManager sharedManager]];
    if (![[TBLibraryManager sharedManager] indexLoaded]) {
        self.tableView.backgroundView = TBCreateLoadingView(@"Preparing Albums…");
        [[TBLibraryManager sharedManager] beginLoadingLibrary];
    }
}

- (void)showNowPlaying:(id)sender {
    TBNowPlayingViewController *controller = [[TBNowPlayingViewController alloc] init];
    [self.navigationController pushViewController:controller animated:YES];
    [controller release];
}

- (void)indexReady:(NSNotification *)notification {
    [_artistGroups release];
    _artistGroups = [[[TBLibraryManager sharedManager] artistGroups] retain];
    self.tableView.backgroundView = nil;
    [self.tableView reloadData];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.navigationController setToolbarHidden:YES animated:animated];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return (NSInteger)[_artistGroups count];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    NSUInteger count = [[[_artistGroups objectAtIndex:(NSUInteger)section]
        objectForKey:TBAlbumsKey] count];
    return (NSInteger)((count + 1) / 2);
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    return [[_artistGroups objectAtIndex:(NSUInteger)section] objectForKey:TBArtistNameKey];
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return 28.0f;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    UIView *header = [[[UIView alloc] initWithFrame:CGRectMake(0, 0, 320, 28)] autorelease];
    header.backgroundColor = [TBTheme backgroundColor];
    UILabel *label = [[[UILabel alloc] initWithFrame:CGRectMake(10, 3, 300, 22)] autorelease];
    label.backgroundColor = [UIColor clearColor];
    label.font = [TBTheme sectionTitleFont];
    label.textColor = [TBTheme primaryTextColor];
    label.lineBreakMode = UILineBreakModeTailTruncation;
    label.text = [[_artistGroups objectAtIndex:(NSUInteger)section] objectForKey:TBArtistNameKey];
    [header addSubview:label];
    return header;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *identifier = @"AlbumGridCell";
    TBAlbumGridCell *cell = (TBAlbumGridCell *)[tableView dequeueReusableCellWithIdentifier:identifier];
    if (cell == nil) {
        cell = [[[TBAlbumGridCell alloc] initWithStyle:UITableViewCellStyleDefault
            reuseIdentifier:identifier] autorelease];
        [cell.leftItem addTarget:self action:@selector(albumItemPressed:)
            forControlEvents:UIControlEventTouchUpInside];
        [cell.rightItem addTarget:self action:@selector(albumItemPressed:)
            forControlEvents:UIControlEventTouchUpInside];
    }
    NSArray *albums = [[_artistGroups objectAtIndex:(NSUInteger)indexPath.section]
        objectForKey:TBAlbumsKey];
    NSUInteger firstIndex = (NSUInteger)indexPath.row * 2;
    [cell.leftItem configureWithAlbum:[albums objectAtIndex:firstIndex]];
    if (firstIndex + 1 < [albums count]) {
        [cell.rightItem configureWithAlbum:[albums objectAtIndex:firstIndex + 1]];
    } else {
        [cell.rightItem resetContent];
        cell.rightItem.hidden = YES;
    }
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 180.0f;
}

- (void)albumItemPressed:(TBAlbumItemControl *)sender {
    if (![[TBLibraryManager sharedManager] mediaItemsReady]) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Library Loading"
            message:@"Tracks will be available in a moment." delegate:nil
            cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [alert show];
        [alert release];
        return;
    }
    TBAlbumViewController *controller = [[TBAlbumViewController alloc]
        initWithAlbum:sender.album];
    [self.navigationController pushViewController:controller animated:YES];
    [controller release];
}

- (void)didReceiveMemoryWarning {
    [[TBArtworkCache sharedCache] removeAllImages];
    NSLog(@"Touchbox: cleared album thumbnail cache after memory warning");
    [super didReceiveMemoryWarning];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [_artistGroups release];
    [super dealloc];
}

@end
