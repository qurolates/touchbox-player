#import "TBPlaylistsViewController.h"
#import "TBLibraryManager.h"
#import "TBTrackListViewController.h"
#import "TBLoadingView.h"
#import "TBNowPlayingViewController.h"
#import "TBTheme.h"

@implementation TBPlaylistsViewController

- (id)init {
    self = [super initWithStyle:UITableViewStylePlain];
    if (self) self.title = @"Playlists";
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [TBTheme styleTableView:self.tableView];
    self.navigationItem.rightBarButtonItem = [[[UIBarButtonItem alloc]
        initWithTitle:@"Player" style:UIBarButtonItemStyleBordered
        target:self action:@selector(showNowPlaying:)] autorelease];
    _playlists = [[[TBLibraryManager sharedManager] playlists] retain];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playlistsReady:)
        name:TBLibraryPlaylistsDidLoadNotification object:[TBLibraryManager sharedManager]];
    if (![[TBLibraryManager sharedManager] playlistsLoaded]) {
        self.tableView.backgroundView = TBCreateLoadingView(@"Loading Playlists…");
        [[TBLibraryManager sharedManager] beginLoadingLibrary];
    }
}

- (void)showNowPlaying:(id)sender {
    TBNowPlayingViewController *controller = [[TBNowPlayingViewController alloc] init];
    [self.navigationController pushViewController:controller animated:YES];
    [controller release];
}

- (void)playlistsReady:(NSNotification *)notification {
    [_playlists release];
    _playlists = [[[TBLibraryManager sharedManager] playlists] retain];
    self.tableView.backgroundView = nil;
    [self.tableView reloadData];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.navigationController setToolbarHidden:YES animated:animated];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return (NSInteger)[_playlists count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *identifier = @"PlaylistCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:identifier];
    if (cell == nil) cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle
        reuseIdentifier:identifier] autorelease];
    cell.backgroundColor = [TBTheme backgroundColor];
    cell.textLabel.font = [TBTheme primaryFont];
    cell.textLabel.textColor = [TBTheme primaryTextColor];
    MPMediaPlaylist *playlist = [_playlists objectAtIndex:(NSUInteger)indexPath.row];
    NSString *name = [playlist valueForProperty:MPMediaPlaylistPropertyName];
    cell.textLabel.text = name ? name : @"Unknown Playlist";
    cell.detailTextLabel.text = nil;
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
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
    NSLog(@"Touchbox timing: selected playlist items fetch %.3f sec count=%lu",
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
    [super dealloc];
}

@end
