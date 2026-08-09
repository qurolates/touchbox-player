#import "TBPlaylistsViewController.h"
#import "TBLibraryManager.h"
#import "TBTrackListViewController.h"
#import "TBLoadingView.h"
#import "TBNowPlayingViewController.h"
#import "TBTheme.h"
#import "TBUserPlaylistManager.h"
#import "TBUserPlaylistViewController.h"
#import "TBPlaylistNameViewController.h"
#import "TBPerformance.h"

@implementation TBPlaylistsViewController

- (id)init {
    self = [super initWithStyle:UITableViewStylePlain];
    if (self) self.title = @"Playlists";
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [TBTheme styleTableView:self.tableView];
    _searchBar = [[UISearchBar alloc] initWithFrame:CGRectMake(0, 0, 320, 44)]; _searchBar.delegate = self; _searchBar.placeholder = @"Search Playlists"; self.tableView.tableHeaderView = _searchBar;
    self.navigationItem.rightBarButtonItem = [[[UIBarButtonItem alloc]
        initWithTitle:@"Player" style:UIBarButtonItemStyleBordered
        target:self action:@selector(showNowPlaying:)] autorelease];
    _allPlaylists = [[[TBLibraryManager sharedManager] playlists] retain]; _playlists = [_allPlaylists retain];
    _allUserPlaylists = [[[TBUserPlaylistManager sharedManager] playlists] retain]; _userPlaylists = [_allUserPlaylists retain];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playlistsReady:)
        name:TBLibraryPlaylistsDidLoadNotification object:[TBLibraryManager sharedManager]];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(userPlaylistsChanged:)
        name:TBUserPlaylistsDidChangeNotification object:[TBUserPlaylistManager sharedManager]];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(themeChanged:)
        name:TBThemeDidChangeNotification object:nil];
    if (![[TBLibraryManager sharedManager] playlistsLoaded]) {
        self.tableView.backgroundView = TBCreateLoadingView(@"Loading Playlists…");
        [[TBLibraryManager sharedManager] beginLoadingLibrary];
    }
}
- (void)themeChanged:(NSNotification *)notification { [TBTheme styleTableView:self.tableView]; _searchBar.tintColor = [TBTheme searchBackgroundColor]; [self.tableView reloadData]; }

- (void)userPlaylistsChanged:(NSNotification *)notification {
    [_allUserPlaylists release]; _allUserPlaylists = [[[TBUserPlaylistManager sharedManager] playlists] retain];
    [self searchBar:_searchBar textDidChange:_searchBar.text];
}

- (void)newPlaylist:(id)sender {
    TBPlaylistNameViewController *nameController = [[TBPlaylistNameViewController alloc]
        initWithTarget:self action:@selector(createdPlaylistNamed:)];
    UINavigationController *navigation = [[UINavigationController alloc]
        initWithRootViewController:nameController];
    navigation.navigationBar.tintColor = [TBTheme accentColor];
    [nameController release];
    [self presentModalViewController:navigation animated:YES];
    [navigation release];
}

- (void)createdPlaylistNamed:(NSString *)name {
    [[TBUserPlaylistManager sharedManager] createPlaylistWithName:name];
}

- (void)showNowPlaying:(id)sender {
    TBNowPlayingViewController *controller = [[TBNowPlayingViewController alloc] init];
    [self.navigationController pushViewController:controller animated:YES];
    [controller release];
}

- (void)playlistsReady:(NSNotification *)notification {
    [_allPlaylists release]; _allPlaylists = [[[TBLibraryManager sharedManager] playlists] retain];
    [self searchBar:_searchBar textDidChange:_searchBar.text];
    self.tableView.backgroundView = nil;
    [self.tableView reloadData];
}

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)query {
    [_playlists release]; [_userPlaylists release];
    if (![query length]) { _playlists = [_allPlaylists retain]; _userPlaylists = [_allUserPlaylists retain]; }
    else { NSMutableArray *systems = [NSMutableArray array]; NSMutableArray *users = [NSMutableArray array]; NSUInteger i;
        for (i = 0; i < [_allPlaylists count]; i++) { MPMediaPlaylist *p = [_allPlaylists objectAtIndex:i]; NSString *name = [p valueForProperty:MPMediaPlaylistPropertyName]; if ([name rangeOfString:query options:(NSCaseInsensitiveSearch|NSDiacriticInsensitiveSearch)].location != NSNotFound) [systems addObject:p]; }
        for (i = 0; i < [_allUserPlaylists count]; i++) { NSDictionary *p = [_allUserPlaylists objectAtIndex:i]; if ([[p objectForKey:TBUserPlaylistNameKey] rangeOfString:query options:(NSCaseInsensitiveSearch|NSDiacriticInsensitiveSearch)].location != NSNotFound) [users addObject:p]; }
        _playlists = [systems copy]; _userPlaylists = [users copy];
    } [self.tableView reloadData];
}
- (void)searchBarSearchButtonClicked:(UISearchBar *)bar { [bar resignFirstResponder]; }

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.navigationController setToolbarHidden:YES animated:animated];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView { return 2; }

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return section == 0 ? (NSInteger)[_userPlaylists count] + 1 : (NSInteger)[_playlists count];
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    return section == 0 ? @"Touchbox Playlists" : @"System Playlists";
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *identifier = @"PlaylistCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:identifier];
    if (cell == nil) cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle
        reuseIdentifier:identifier] autorelease];
    cell.backgroundColor = [TBTheme backgroundColor];
    cell.detailTextLabel.textColor = [TBTheme secondaryTextColor];
    cell.textLabel.font = [TBTheme primaryFont];
    cell.textLabel.textColor = [TBTheme primaryTextColor];
    if (indexPath.section == 0) {
        if (indexPath.row == 0) {
            cell.textLabel.text = @"+ New Playlist";
            cell.textLabel.textColor = [TBTheme accentColor];
            cell.detailTextLabel.text = nil;
        } else {
            NSDictionary *playlist = [_userPlaylists objectAtIndex:(NSUInteger)indexPath.row - 1];
            cell.textLabel.text = [playlist objectForKey:TBUserPlaylistNameKey];
            cell.textLabel.textColor = [TBTheme primaryTextColor];
            cell.detailTextLabel.text = [NSString stringWithFormat:@"%lu tracks",
                (unsigned long)[[playlist objectForKey:TBUserPlaylistTrackIDsKey] count]];
        }
    } else {
        MPMediaPlaylist *playlist = [_playlists objectAtIndex:(NSUInteger)indexPath.row];
        NSString *name = [playlist valueForProperty:MPMediaPlaylistPropertyName];
        cell.textLabel.text = name ? name : @"Unknown Playlist";
        cell.textLabel.textColor = [TBTheme primaryTextColor];
        cell.detailTextLabel.text = nil;
    }
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    if (indexPath.section == 0) {
        if (indexPath.row == 0) { [self newPlaylist:nil]; return; }
        TBUserPlaylistViewController *controller = [[TBUserPlaylistViewController alloc]
            initWithPlaylist:[_userPlaylists objectAtIndex:(NSUInteger)indexPath.row - 1]];
        [self.navigationController pushViewController:controller animated:YES];
        [controller release];
        return;
    }
    if (_loadingPlaylistItems) return;
    MPMediaPlaylist *playlist = [_playlists objectAtIndex:(NSUInteger)indexPath.row];
    NSString *name = [playlist valueForProperty:MPMediaPlaylistPropertyName];
    _loadingPlaylistItems = YES;
    self.tableView.backgroundView = TBCreateLoadingView(@"Loading Tracks…");
    self.tableView.userInteractionEnabled = NO;
    NSDictionary *request = [NSDictionary dictionaryWithObjectsAndKeys:
        playlist, @"playlist", (name ? name : @"Playlist"), @"name", nil];
    [self performSelectorInBackground:@selector(loadPlaylistItems:) withObject:request];
}

- (void)loadPlaylistItems:(NSDictionary *)request {
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    NSTimeInterval start = [NSDate timeIntervalSinceReferenceDate];
    MPMediaPlaylist *playlist = [request objectForKey:@"playlist"];
    NSArray *items = [playlist items];
    TBPerformanceLog(@"Touchbox timing: selected playlist items fetch %.3f sec count=%lu",
          [NSDate timeIntervalSinceReferenceDate] - start, (unsigned long)[items count]);
    NSDictionary *result = [[NSDictionary alloc] initWithObjectsAndKeys:
        (items ? items : [NSArray array]), @"items", [request objectForKey:@"name"], @"name", nil];
    [self performSelectorOnMainThread:@selector(showLoadedPlaylist:) withObject:result waitUntilDone:YES];
    [result release];
    [pool drain];
}

- (void)showLoadedPlaylist:(NSDictionary *)result {
    _loadingPlaylistItems = NO;
    self.tableView.backgroundView = nil;
    self.tableView.userInteractionEnabled = YES;
    TBTrackListViewController *controller = [[TBTrackListViewController alloc]
        initWithTitle:[result objectForKey:@"name"] items:[result objectForKey:@"items"]];
    [self.navigationController pushViewController:controller animated:YES];
    [controller release];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [_playlists release];
    [_userPlaylists release];
    [_allPlaylists release]; [_allUserPlaylists release]; _searchBar.delegate = nil; [_searchBar release];
    [super dealloc];
}

@end
