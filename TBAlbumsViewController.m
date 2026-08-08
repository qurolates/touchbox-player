#import "TBAlbumsViewController.h"
#import "TBLibraryManager.h"
#import "TBAlbumViewController.h"
#import "TBLoadingView.h"
#import "TBAlbumGridCell.h"
#import "TBArtworkCache.h"
#import "TBNowPlayingViewController.h"
#import "TBTheme.h"
#import "TBAlphabeticIndex.h"
#import "TBAlphabetIndexView.h"
#import "TBRecentViewController.h"

@implementation TBAlbumsViewController

@synthesize tableView = _tableView;

- (id)init {
    self = [super init];
    if (self) self.title = @"Albums";
    return self;
}

- (void)loadView {
    UIView *container = [[UIView alloc] initWithFrame:[[UIScreen mainScreen] applicationFrame]];
    container.backgroundColor = [TBTheme backgroundColor];
    self.view = container;
    [container release];
    UITableView *table = [[UITableView alloc] initWithFrame:CGRectMake(0, 0, 300,
        self.view.bounds.size.height) style:UITableViewStylePlain];
    table.autoresizingMask = UIViewAutoresizingFlexibleHeight;
    table.dataSource = self;
    table.delegate = self;
    self.tableView = table;
    [table release];
    [self.view addSubview:self.tableView];
    _alphabetIndexView = [[TBAlphabetIndexView alloc]
        initWithFrame:CGRectMake(300, 0, 20, self.view.bounds.size.height)
        titles:[TBAlphabeticIndex titles] target:self action:@selector(alphabetIndexSelected:)];
    [self.view addSubview:_alphabetIndexView];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [TBTheme styleTableView:self.tableView];
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    _searchBar = [[UISearchBar alloc] initWithFrame:CGRectMake(0, 0, 300, 44)];
    _searchBar.delegate = self; _searchBar.placeholder = @"Search Albums";
    self.tableView.tableHeaderView = _searchBar;
    self.navigationItem.rightBarButtonItem = [[[UIBarButtonItem alloc]
        initWithTitle:@"Player" style:UIBarButtonItemStyleBordered
        target:self action:@selector(showNowPlaying:)] autorelease];
    self.navigationItem.leftBarButtonItem = [[[UIBarButtonItem alloc] initWithTitle:@"Recent"
        style:UIBarButtonItemStyleBordered target:self action:@selector(showRecent:)] autorelease];
    _allArtistGroups = [[[TBLibraryManager sharedManager] artistGroups] retain];
    _artistGroups = [_allArtistGroups retain];
    _sectionIndexMap = [[TBAlphabeticIndex sectionMapForArtistGroups:_artistGroups] retain];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(indexReady:)
        name:TBLibraryIndexDidLoadNotification object:[TBLibraryManager sharedManager]];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(themeChanged:)
        name:TBThemeDidChangeNotification object:nil];
    if (![[TBLibraryManager sharedManager] indexLoaded]) {
        self.tableView.backgroundView = TBCreateLoadingView(@"Preparing Albums…");
        [[TBLibraryManager sharedManager] beginLoadingLibrary];
    }
}

- (void)themeChanged:(NSNotification *)notification { [self applyTheme]; }
- (void)applyTheme { self.view.backgroundColor = [TBTheme backgroundColor]; [TBTheme styleTableView:self.tableView]; _searchBar.tintColor = [TBTheme searchBackgroundColor]; _alphabetIndexView.backgroundColor = [TBTheme backgroundColor]; [_alphabetIndexView setNeedsDisplay]; [self.tableView reloadData]; }

- (void)showRecent:(id)sender { TBRecentViewController *controller = [[TBRecentViewController alloc] init]; [self.navigationController pushViewController:controller animated:YES]; [controller release]; }

- (void)showNowPlaying:(id)sender {
    TBNowPlayingViewController *controller = [[TBNowPlayingViewController alloc] init];
    [self.navigationController pushViewController:controller animated:YES];
    [controller release];
}

- (void)indexReady:(NSNotification *)notification {
    [_allArtistGroups release]; _allArtistGroups = [[[TBLibraryManager sharedManager] artistGroups] retain];
    [_artistGroups release]; _artistGroups = [_allArtistGroups retain];
    [_sectionIndexMap release];
    _sectionIndexMap = [[TBAlphabeticIndex sectionMapForArtistGroups:_artistGroups] retain];
    self.tableView.backgroundView = nil;
    [self.tableView reloadData];
}

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)query {
    [_artistGroups release];
    if (![query length]) _artistGroups = [_allArtistGroups retain];
    else { NSMutableArray *groups = [NSMutableArray array]; NSUInteger g, a;
        for (g = 0; g < [_allArtistGroups count]; g++) { NSDictionary *group = [_allArtistGroups objectAtIndex:g]; NSMutableArray *albums = [NSMutableArray array]; NSArray *source = [group objectForKey:TBAlbumsKey];
            for (a = 0; a < [source count]; a++) { NSDictionary *album = [source objectAtIndex:a]; NSString *title = [album objectForKey:TBAlbumTitleKey]; NSString *artist = [album objectForKey:TBAlbumArtistKey];
                if ([title rangeOfString:query options:(NSCaseInsensitiveSearch|NSDiacriticInsensitiveSearch)].location != NSNotFound || [artist rangeOfString:query options:(NSCaseInsensitiveSearch|NSDiacriticInsensitiveSearch)].location != NSNotFound) [albums addObject:album]; }
            if ([albums count]) [groups addObject:[NSDictionary dictionaryWithObjectsAndKeys:[group objectForKey:TBArtistNameKey], TBArtistNameKey, albums, TBAlbumsKey, nil]];
        } _artistGroups = [groups copy];
    }
    _alphabetIndexView.hidden = [query length] > 0; [self.tableView reloadData];
}
- (void)searchBarSearchButtonClicked:(UISearchBar *)bar { [bar resignFirstResponder]; }

- (void)alphabetIndexSelected:(NSNumber *)indexNumber {
    NSInteger index = [indexNumber integerValue];
    if (index < 0 || index >= (NSInteger)[_sectionIndexMap count] || ![_artistGroups count]) return;
    NSInteger section = [[_sectionIndexMap objectAtIndex:(NSUInteger)index] integerValue];
    if (section >= 0 && section < (NSInteger)[_artistGroups count])
        [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:section]
            atScrollPosition:UITableViewScrollPositionTop animated:NO];
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
    cell.backgroundColor = [TBTheme backgroundColor]; cell.contentView.backgroundColor = [TBTheme backgroundColor];
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
    return 175.0f;
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
    [_allArtistGroups release];
    [_sectionIndexMap release];
    [_tableView release];
    [_alphabetIndexView release];
    _searchBar.delegate = nil; [_searchBar release];
    [super dealloc];
}

@end
