#import "TBArtistsViewController.h"
#import "TBLibraryManager.h"
#import "TBAlbumViewController.h"
#import "TBLoadingView.h"
#import "TBNowPlayingViewController.h"
#import "TBTheme.h"
#import "TBAlphabeticIndex.h"
#import "TBPlayerManager.h"
#import "TBAlphabetIndexView.h"
#import "TBIconFactory.h"

@implementation TBArtistsViewController

@synthesize tableView = _tableView;

- (id)init {
    self = [super init];
    if (self) self.title = @"Artists";
    return self;
}

- (id)initWithArtist:(NSDictionary *)artist {
    self = [super init];
    if (self) {
        _selectedArtist = [artist retain];
        self.title = [artist objectForKey:TBArtistNameKey];
    }
    return self;
}

- (void)loadView {
    UIView *container = [[UIView alloc] initWithFrame:[[UIScreen mainScreen] applicationFrame]];
    container.backgroundColor = [TBTheme backgroundColor]; self.view = container; [container release];
    CGFloat width = _selectedArtist ? self.view.bounds.size.width : MAX(0.0f, self.view.bounds.size.width - 20.0f);
    UITableView *table = [[UITableView alloc] initWithFrame:CGRectMake(0, 0, width, self.view.bounds.size.height)
        style:UITableViewStylePlain];
    table.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight; table.dataSource = self; table.delegate = self;
    self.tableView = table; [table release]; [self.view addSubview:self.tableView];
    if (!_selectedArtist) {
        _alphabetIndexView = [[TBAlphabetIndexView alloc] initWithFrame:CGRectMake(width, 0, 20, self.view.bounds.size.height)
            titles:[TBAlphabeticIndex titlesForArtistGroups:[[TBLibraryManager sharedManager] artistGroups]]
            target:self action:@selector(alphabetIndexSelected:)];
        [self.view addSubview:_alphabetIndexView];
    }
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [TBTheme styleTableView:self.tableView];
    self.navigationItem.rightBarButtonItem = [[[UIBarButtonItem alloc]
        initWithTitle:@"Player" style:UIBarButtonItemStyleBordered
        target:self action:@selector(showNowPlaying:)] autorelease];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(indexReady:)
        name:TBLibraryIndexDidLoadNotification object:[TBLibraryManager sharedManager]];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(themeChanged:)
        name:TBThemeDidChangeNotification object:nil];
    if (_selectedArtist == nil) {
        _allArtistGroups = [[[TBLibraryManager sharedManager] artistGroups] retain];
        _artistGroups = [_allArtistGroups retain];
        _searchBar = [[UISearchBar alloc] initWithFrame:CGRectMake(0, 0, self.tableView.bounds.size.width, 44)]; _searchBar.autoresizingMask = UIViewAutoresizingFlexibleWidth; _searchBar.delegate = self; _searchBar.placeholder = @"Search Artists"; self.tableView.tableHeaderView = _searchBar;
        _sectionIndexMap = [[TBAlphabeticIndex sectionMapForArtistGroups:_artistGroups] retain];
        [_alphabetIndexView setTitles:[TBAlphabeticIndex titlesForArtistGroups:_artistGroups]];
        if (![[TBLibraryManager sharedManager] indexLoaded]) {
            self.tableView.backgroundView = TBCreateLoadingView(@"Preparing Artists…");
            [[TBLibraryManager sharedManager] beginLoadingLibrary];
        }
    }
    if (_selectedArtist) {
        self.navigationItem.leftBarButtonItem = [[[UIBarButtonItem alloc] initWithTitle:@"Shuffle"
            style:UIBarButtonItemStyleBordered target:self action:@selector(shuffleArtist:)] autorelease];
        UIView *header = [[[UIView alloc] initWithFrame:CGRectMake(0, 0, self.tableView.bounds.size.width, 54)] autorelease];
        UILabel *label = [[[UILabel alloc] initWithFrame:CGRectMake(15, 7, MAX(0.0f, self.tableView.bounds.size.width - 30), 40)] autorelease];
        label.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        label.backgroundColor = [TBTheme backgroundColor];
        label.textColor = [TBTheme primaryTextColor];
        label.font = [TBTheme sectionTitleFont];
        label.text = [NSString stringWithFormat:@"%@\n%lu albums",
            [_selectedArtist objectForKey:TBArtistNameKey],
            (unsigned long)[[self selectedAlbums] count]];
        label.numberOfLines = 2;
        [header addSubview:label];
        self.tableView.tableHeaderView = header;
    }
}

- (void)themeChanged:(NSNotification *)notification { [self applyTheme]; }
- (void)applyTheme { self.view.backgroundColor = [TBTheme backgroundColor]; [TBTheme styleTableView:self.tableView]; _searchBar.tintColor = [TBTheme searchBackgroundColor]; _alphabetIndexView.backgroundColor = [TBTheme backgroundColor]; [_alphabetIndexView setNeedsDisplay];
    if (_selectedArtist && self.tableView.tableHeaderView) { self.tableView.tableHeaderView.backgroundColor = [TBTheme backgroundColor]; UILabel *label = [[self.tableView.tableHeaderView subviews] count] ? [[self.tableView.tableHeaderView subviews] objectAtIndex:0] : nil; label.backgroundColor = [TBTheme backgroundColor]; label.textColor = [TBTheme primaryTextColor]; } [self.tableView reloadData]; }

- (void)shuffleArtist:(id)sender { NSMutableArray *items = [NSMutableArray array]; NSUInteger i; NSArray *albums = [self selectedAlbums]; for (i = 0; i < [albums count]; i++) [items addObjectsFromArray:[[albums objectAtIndex:i] objectForKey:TBAlbumItemsKey]]; if (![items count]) return; [[TBPlayerManager sharedManager] playItemsShuffled:items]; [self showNowPlaying:nil]; }

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)query {
    [_artistGroups release];
    if (![query length]) _artistGroups = [_allArtistGroups retain];
    else { NSMutableArray *results = [NSMutableArray array]; NSUInteger i; for (i = 0; i < [_allArtistGroups count]; i++) { NSDictionary *group = [_allArtistGroups objectAtIndex:i];
        if ([[group objectForKey:TBArtistNameKey] rangeOfString:query options:(NSCaseInsensitiveSearch|NSDiacriticInsensitiveSearch)].location != NSNotFound) [results addObject:group]; } _artistGroups = [results copy]; }
    [_sectionIndexMap release]; _sectionIndexMap = [[TBAlphabeticIndex sectionMapForArtistGroups:_artistGroups] retain];
    [_alphabetIndexView setTitles:[TBAlphabeticIndex titlesForArtistGroups:_artistGroups]]; [self.tableView reloadData];
    _alphabetIndexView.hidden = [query length] > 0;
}
- (void)searchBarSearchButtonClicked:(UISearchBar *)bar { [bar resignFirstResponder]; }

- (void)showNowPlaying:(id)sender {
    TBNowPlayingViewController *controller = [[TBNowPlayingViewController alloc] init];
    [self.navigationController pushViewController:controller animated:YES];
    [controller release];
}

- (void)indexReady:(NSNotification *)notification {
    if (_selectedArtist) {
        NSString *name = [_selectedArtist objectForKey:TBArtistNameKey];
        NSArray *groups = [[TBLibraryManager sharedManager] artistGroups];
        NSUInteger index;
        for (index = 0; index < [groups count]; index++) {
            NSDictionary *group = [groups objectAtIndex:index];
            if ([[group objectForKey:TBArtistNameKey] isEqualToString:name]) {
                [_selectedArtist release];
                _selectedArtist = [group retain];
                break;
            }
        }
    } else {
        [_allArtistGroups release]; _allArtistGroups = [[[TBLibraryManager sharedManager] artistGroups] retain];
        [_artistGroups release]; _artistGroups = [_allArtistGroups retain];
        [_sectionIndexMap release];
        _sectionIndexMap = [[TBAlphabeticIndex sectionMapForArtistGroups:_artistGroups] retain];
        [_alphabetIndexView setTitles:[TBAlphabeticIndex titlesForArtistGroups:_artistGroups]];
    }
    self.tableView.backgroundView = nil;
    [self.tableView reloadData];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.navigationController setToolbarHidden:YES animated:animated];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return _selectedArtist ? 1 : (NSInteger)[_artistGroups count];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (_selectedArtist) return (NSInteger)[[self selectedAlbums] count];
    return [_artistGroups count] ? 1 : 0;
}

- (void)alphabetIndexSelected:(NSNumber *)indexNumber {
    NSInteger index = [indexNumber integerValue];
    if (index < 0 || index >= (NSInteger)[_sectionIndexMap count]) return;
    NSInteger section = [[_sectionIndexMap objectAtIndex:(NSUInteger)index] integerValue];
    if (section >= 0 && section < (NSInteger)[_artistGroups count])
        [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:section]
            atScrollPosition:UITableViewScrollPositionTop animated:NO];
}

- (NSArray *)selectedAlbums { return [_selectedArtist objectForKey:TBAlbumsKey]; }

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *identifier = @"ArtistCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:identifier];
    if (cell == nil) cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle
        reuseIdentifier:identifier] autorelease];
    cell.backgroundColor = [TBTheme backgroundColor];
    cell.textLabel.font = [TBTheme primaryFont];
    cell.textLabel.textColor = [TBTheme primaryTextColor];
    cell.detailTextLabel.font = [TBTheme secondaryFont];
    cell.detailTextLabel.textColor = [TBTheme secondaryTextColor];
    if (_selectedArtist) {
        NSDictionary *album = [[self selectedAlbums] objectAtIndex:(NSUInteger)indexPath.row];
        cell.textLabel.text = [album objectForKey:TBAlbumTitleKey];
        NSArray *tracks = [album objectForKey:TBAlbumItemsKey];
        if (tracks == nil) tracks = [album objectForKey:TBAlbumTrackRecordsKey];
        cell.detailTextLabel.text = [NSString stringWithFormat:@"%lu tracks",
            (unsigned long)[tracks count]];
    } else {
        NSDictionary *artist = [_artistGroups objectAtIndex:(NSUInteger)indexPath.section];
        cell.textLabel.text = [artist objectForKey:TBArtistNameKey];
        cell.detailTextLabel.text = [NSString stringWithFormat:@"%lu albums",
            (unsigned long)[[artist objectForKey:TBAlbumsKey] count]];
    }
    cell.accessoryType = UITableViewCellAccessoryNone;
    UIImageView *disclosure = (UIImageView *)cell.accessoryView;
    if (![disclosure isKindOfClass:[UIImageView class]]) {
        disclosure = [[[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 20, 28)] autorelease];
        disclosure.contentMode = UIViewContentModeCenter;
        cell.accessoryView = disclosure;
    }
    disclosure.image = [TBIconFactory iconNamed:@"disclosure" active:NO];
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    UIViewController *controller;
    if (_selectedArtist) {
        if (![[TBLibraryManager sharedManager] mediaItemsReady]) {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Library Loading"
                message:@"Tracks will be available in a moment." delegate:nil
                cancelButtonTitle:@"OK" otherButtonTitles:nil];
            [alert show];
            [alert release];
            return;
        }
        controller = [[TBAlbumViewController alloc]
            initWithAlbum:[[self selectedAlbums] objectAtIndex:(NSUInteger)indexPath.row]];
    } else {
        controller = [[TBArtistsViewController alloc]
            initWithArtist:[_artistGroups objectAtIndex:(NSUInteger)indexPath.section]];
    }
    [self.navigationController pushViewController:controller animated:YES];
    [controller release];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [_artistGroups release];
    [_allArtistGroups release];
    [_selectedArtist release];
    [_sectionIndexMap release];
    _searchBar.delegate = nil; [_searchBar release];
    [_tableView release]; [_alphabetIndexView release];
    [super dealloc];
}

@end
