#import "TBTrackListViewController.h"
#import "TBPlayerManager.h"
#import "TBFavoritesManager.h"
#import "TBNowPlayingViewController.h"
#import "TBTheme.h"
#import "TBIconFactory.h"
#import "TBAddToPlaylistViewController.h"
#import "TBLibraryManager.h"
#import "TBAlbumViewController.h"
#import "TBArtistsViewController.h"

@implementation TBTrackListViewController

@synthesize playPauseButton = _playPauseButton;

- (NSArray *)items { return _items; }
- (void)setItems:(NSArray *)items {
    if (_allItems != items) { [_allItems release]; _allItems = [items retain]; }
    [_items release]; _items = [items retain];
    if ([_searchBar.text length]) [self performSearch:_searchBar.text];
}

- (id)initWithTitle:(NSString *)title items:(NSArray *)items {
    self = [super initWithStyle:UITableViewStylePlain];
    if (self) {
        self.title = title;
        self.items = items;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [TBTheme styleTableView:self.tableView];
    _searchBar = [[UISearchBar alloc] initWithFrame:CGRectMake(0, 0, 320, 44)];
    _searchBar.delegate = self;
    _searchBar.placeholder = @"Search";
    self.tableView.tableHeaderView = _searchBar;
    UILongPressGestureRecognizer *longPress = [[UILongPressGestureRecognizer alloc]
        initWithTarget:self action:@selector(trackLongPressed:)];
    longPress.minimumPressDuration = 0.55;
    [self.tableView addGestureRecognizer:longPress];
    [longPress release];
    TBPlayerManager *player = [TBPlayerManager sharedManager];
    NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
    [center addObserver:self selector:@selector(playbackChanged:)
                   name:MPMusicPlayerControllerPlaybackStateDidChangeNotification
                 object:player.musicPlayer];
    [center addObserver:self selector:@selector(nowPlayingChanged:)
                   name:MPMusicPlayerControllerNowPlayingItemDidChangeNotification
                 object:player.musicPlayer];
    [center addObserver:self selector:@selector(favoritesChanged:)
                   name:TBFavoritesDidChangeNotification object:nil];
    [center addObserver:self selector:@selector(themeChanged:)
                   name:TBThemeDidChangeNotification object:nil];
    self.navigationItem.rightBarButtonItem = [[[UIBarButtonItem alloc]
        initWithTitle:@"Player" style:UIBarButtonItemStyleBordered
        target:self action:@selector(showNowPlaying:)] autorelease];
    self.navigationItem.leftBarButtonItem = [[[UIBarButtonItem alloc]
        initWithTitle:@"Shuffle" style:UIBarButtonItemStyleBordered
        target:self action:@selector(shuffleCurrentItems)] autorelease];

    UIBarButtonItem *previous = [[UIBarButtonItem alloc]
        initWithImage:[TBIconFactory iconNamed:@"previous" active:NO]
        style:UIBarButtonItemStylePlain target:self action:@selector(previousPressed:)];
    UIBarButtonItem *playPause = [[UIBarButtonItem alloc]
        initWithImage:[TBIconFactory iconNamed:@"play" active:NO]
        style:UIBarButtonItemStylePlain target:self action:@selector(playPausePressed:)];
    self.playPauseButton = playPause;
    [playPause release];
    UIBarButtonItem *next = [[UIBarButtonItem alloc]
        initWithImage:[TBIconFactory iconNamed:@"next" active:NO]
        style:UIBarButtonItemStylePlain target:self action:@selector(nextPressed:)];
    UIBarButtonItem *space1 = [[UIBarButtonItem alloc]
        initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    UIBarButtonItem *space2 = [[UIBarButtonItem alloc]
        initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    self.toolbarItems = [NSArray arrayWithObjects:previous, space1, self.playPauseButton,
                         space2, next, nil];
    [previous release]; [next release]; [space1 release]; [space2 release];
    [self updatePlayPauseButton];
    [self applyTheme];
}

- (void)themeChanged:(NSNotification *)notification { [self applyTheme]; }
- (void)applyTheme {
    [TBTheme styleTableView:self.tableView]; _searchBar.tintColor = [TBTheme searchBackgroundColor];
    if ([self.toolbarItems count] >= 5) { ((UIBarButtonItem *)[self.toolbarItems objectAtIndex:0]).image = [TBIconFactory iconNamed:@"previous" active:NO]; ((UIBarButtonItem *)[self.toolbarItems objectAtIndex:4]).image = [TBIconFactory iconNamed:@"next" active:NO]; }
    [self.tableView reloadData]; [self updatePlayPauseButton];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.navigationController setToolbarHidden:NO animated:animated];
    [self reloadTrackItems];
    [self.tableView reloadData];
    [self updatePlayPauseButton];
}

- (void)reloadTrackItems {}

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText {
    [_searchTimer invalidate]; [_searchTimer release]; _searchTimer = nil;
    [_pendingSearchText release]; _pendingSearchText = [searchText copy];
    _searchTimer = [[NSTimer scheduledTimerWithTimeInterval:0.20 target:self
        selector:@selector(searchTimerFired:) userInfo:nil repeats:NO] retain];
}
- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar { [searchBar resignFirstResponder]; }
- (void)searchTimerFired:(NSTimer *)timer {
    [_searchTimer release]; _searchTimer = nil;
    [self performSearch:_pendingSearchText];
}
- (BOOL)string:(NSString *)value contains:(NSString *)query {
    return value && [value rangeOfString:query options:(NSCaseInsensitiveSearch |
        NSDiacriticInsensitiveSearch)].location != NSNotFound;
}
- (void)performSearch:(NSString *)query {
    [_items release];
    if (![query length]) _items = [_allItems retain];
    else {
        NSMutableArray *results = [NSMutableArray array];
        NSUInteger index;
        for (index = 0; index < [_allItems count]; index++) {
            MPMediaItem *item = [_allItems objectAtIndex:index];
            if ([self string:[item valueForProperty:MPMediaItemPropertyTitle] contains:query] ||
                [self string:[item valueForProperty:MPMediaItemPropertyArtist] contains:query] ||
                [self string:[item valueForProperty:MPMediaItemPropertyAlbumTitle] contains:query])
                [results addObject:item];
        }
        _items = [results copy];
    }
    [self.tableView reloadData];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return (NSInteger)[_items count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *identifier = @"TrackCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:identifier];
    UIButton *favoriteButton;
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle
                                      reuseIdentifier:identifier] autorelease];
        favoriteButton = [UIButton buttonWithType:UIButtonTypeCustom];
        favoriteButton.frame = CGRectMake(0, 0, 44, 44);
        [favoriteButton addTarget:self action:@selector(favoritePressed:)
                 forControlEvents:UIControlEventTouchUpInside];
        cell.accessoryView = favoriteButton;
        cell.textLabel.font = [TBTheme primaryFont];
        cell.textLabel.textColor = [TBTheme primaryTextColor];
        cell.detailTextLabel.font = [TBTheme secondaryFont];
        cell.detailTextLabel.textColor = [TBTheme secondaryTextColor];
        cell.backgroundColor = [TBTheme backgroundColor];
    } else {
        favoriteButton = (UIButton *)cell.accessoryView;
    }
    cell.backgroundColor = [TBTheme backgroundColor];
    cell.textLabel.textColor = [TBTheme primaryTextColor];
    cell.detailTextLabel.textColor = [TBTheme secondaryTextColor];
    MPMediaItem *item = [_items objectAtIndex:(NSUInteger)indexPath.row];
    NSString *title = [item valueForProperty:MPMediaItemPropertyTitle];
    NSString *artist = [item valueForProperty:MPMediaItemPropertyArtist];
    NSString *album = [item valueForProperty:MPMediaItemPropertyAlbumTitle];
    cell.textLabel.text = title ? title : @"Unknown Title";
    cell.detailTextLabel.text = [NSString stringWithFormat:@"%@ • %@",
        artist ? artist : @"Unknown Artist", album ? album : @"Unknown Album"];
    NSNumber *itemID = [item valueForProperty:MPMediaItemPropertyPersistentID];
    NSNumber *playingID = [[TBPlayerManager sharedManager].musicPlayer.nowPlayingItem
        valueForProperty:MPMediaItemPropertyPersistentID];
    cell.imageView.image = (playingID && [itemID isEqualToNumber:playingID])
        ? [TBIconFactory iconNamed:@"play" active:YES] : nil;
    favoriteButton.tag = indexPath.row;
    BOOL favorite = [[TBFavoritesManager sharedManager] isFavoriteItem:item];
    [favoriteButton setImage:[TBIconFactory iconNamed:@"star" active:favorite]
                    forState:UIControlStateNormal];
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    MPMediaItem *item = [_items objectAtIndex:(NSUInteger)indexPath.row];
    NSNumber *persistentID = [item valueForProperty:MPMediaItemPropertyPersistentID];
    NSLog(@"Touchbox: selected persistentID=%llu title=%@ artist=%@",
          [persistentID unsignedLongLongValue],
          [item valueForProperty:MPMediaItemPropertyTitle],
          [item valueForProperty:MPMediaItemPropertyArtist]);
    [[TBPlayerManager sharedManager] playItems:_items startingAtItem:item];
    [self showNowPlaying:nil];
}

- (void)favoritePressed:(UIButton *)sender {
    NSUInteger index = (NSUInteger)sender.tag;
    if (index >= [_items count]) return;
    [[TBFavoritesManager sharedManager] toggleFavoriteItem:[_items objectAtIndex:index]];
}

- (void)previousPressed:(id)sender { [[TBPlayerManager sharedManager] previous]; }
- (void)playPausePressed:(id)sender { [[TBPlayerManager sharedManager] togglePlayPause]; }
- (void)nextPressed:(id)sender { [[TBPlayerManager sharedManager] next]; }
- (void)shuffleCurrentItems {
    if (![_items count]) return;
    [[TBPlayerManager sharedManager] playItemsShuffled:_items];
    [self showNowPlaying:nil];
}

- (NSDictionary *)albumForItem:(MPMediaItem *)item artistGroup:(NSDictionary **)artistGroup {
    NSNumber *identifier = [item valueForProperty:MPMediaItemPropertyPersistentID];
    NSArray *groups = [[TBLibraryManager sharedManager] artistGroups]; NSUInteger g, a, t;
    for (g = 0; g < [groups count]; g++) {
        NSDictionary *group = [groups objectAtIndex:g]; NSArray *albums = [group objectForKey:TBAlbumsKey];
        for (a = 0; a < [albums count]; a++) {
            NSDictionary *album = [albums objectAtIndex:a]; NSArray *tracks = [album objectForKey:TBAlbumItemsKey];
            for (t = 0; t < [tracks count]; t++)
                if ([[[tracks objectAtIndex:t] valueForProperty:MPMediaItemPropertyPersistentID] isEqualToNumber:identifier]) {
                    if (artistGroup) *artistGroup = group; return album;
                }
        }
    }
    return nil;
}

- (void)trackLongPressed:(UILongPressGestureRecognizer *)gesture {
    if (gesture.state != UIGestureRecognizerStateBegan) return;
    NSIndexPath *path = [self.tableView indexPathForRowAtPoint:[gesture locationInView:self.tableView]];
    if (!path || path.row >= (NSInteger)[_items count]) return;
    [_contextItem release]; _contextItem = [[_items objectAtIndex:(NSUInteger)path.row] retain];
    BOOL favorite = [[TBFavoritesManager sharedManager] isFavoriteItem:_contextItem];
    NSMutableArray *actions = [NSMutableArray arrayWithObjects:@"Play Next", @"Add to Queue", @"Add to Playlist",
        favorite ? @"Remove from Favorites" : @"Add to Favorites", nil];
    NSDictionary *artist = nil; NSDictionary *album = [self albumForItem:_contextItem artistGroup:&artist];
    if (album) [actions addObject:@"Go to Album"];
    if (artist) [actions addObject:@"Go to Artist"];
    [_contextActions release]; _contextActions = [actions copy];
    UIActionSheet *sheet = [[UIActionSheet alloc] initWithTitle:[_contextItem valueForProperty:MPMediaItemPropertyTitle]
        delegate:self cancelButtonTitle:nil destructiveButtonTitle:nil otherButtonTitles:nil];
    NSUInteger i; for (i = 0; i < [_contextActions count]; i++) [sheet addButtonWithTitle:[_contextActions objectAtIndex:i]];
    sheet.cancelButtonIndex = [sheet addButtonWithTitle:@"Cancel"];
    [sheet showInView:self.view.window]; [sheet release];
}

- (void)actionSheet:(UIActionSheet *)sheet clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (buttonIndex < 0 || buttonIndex >= (NSInteger)[_contextActions count] || !_contextItem) return;
    NSString *action = [_contextActions objectAtIndex:(NSUInteger)buttonIndex];
    if ([action isEqualToString:@"Play Next"]) [[TBPlayerManager sharedManager] playNextItem:_contextItem];
    else if ([action isEqualToString:@"Add to Queue"]) [[TBPlayerManager sharedManager] addItemToQueue:_contextItem];
    else if ([action isEqualToString:@"Add to Playlist"]) {
        TBAddToPlaylistViewController *controller = [[TBAddToPlaylistViewController alloc] initWithItem:_contextItem];
        [self.navigationController pushViewController:controller animated:YES]; [controller release];
    } else if ([action rangeOfString:@"Favorites"].location != NSNotFound) {
        [[TBFavoritesManager sharedManager] toggleFavoriteItem:_contextItem];
    } else {
        NSDictionary *artist = nil; NSDictionary *album = [self albumForItem:_contextItem artistGroup:&artist]; UIViewController *controller = nil;
        if ([action isEqualToString:@"Go to Album"] && album) controller = [[TBAlbumViewController alloc] initWithAlbum:album];
        else if ([action isEqualToString:@"Go to Artist"] && artist) controller = [[TBArtistsViewController alloc] initWithArtist:artist];
        if (controller) { [self.navigationController pushViewController:controller animated:YES]; [controller release]; }
    }
}
- (void)showNowPlaying:(id)sender {
    if ([self.navigationController.topViewController isKindOfClass:[TBNowPlayingViewController class]]) return;
    if (!_nowPlayingController) _nowPlayingController = [[TBNowPlayingViewController alloc] init];
    if (![_nowPlayingController.navigationController isEqual:self.navigationController])
        [self.navigationController pushViewController:_nowPlayingController animated:YES];
}

- (void)playbackChanged:(NSNotification *)notification {
    NSLog(@"Touchbox: playback state=%ld",
          (long)[TBPlayerManager sharedManager].musicPlayer.playbackState);
    [self updatePlayPauseButton];
}

- (void)nowPlayingChanged:(NSNotification *)notification {
    MPMediaItem *item = [TBPlayerManager sharedManager].musicPlayer.nowPlayingItem;
    NSNumber *persistentID = [item valueForProperty:MPMediaItemPropertyPersistentID];
    NSLog(@"Touchbox: nowPlayingItem=%@ artist=%@ persistentID=%llu",
          [item valueForProperty:MPMediaItemPropertyTitle],
          [item valueForProperty:MPMediaItemPropertyArtist],
          [persistentID unsignedLongLongValue]);
    [self.tableView reloadData];
}

- (void)favoritesChanged:(NSNotification *)notification {
    [self reloadTrackItems];
    [self.tableView reloadData];
}

- (void)updatePlayPauseButton {
    BOOL playing = [TBPlayerManager sharedManager].musicPlayer.playbackState == MPMusicPlaybackStatePlaying;
    self.playPauseButton.image = [TBIconFactory iconNamed:(playing ? @"pause" : @"play") active:NO];
}

- (void)didReceiveMemoryWarning {
    NSLog(@"Touchbox: memory warning in %@", NSStringFromClass([self class]));
    [super didReceiveMemoryWarning];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [_items release];
    [_allItems release];
    [_playPauseButton release];
    [_nowPlayingController release];
    _searchBar.delegate = nil;
    [_searchBar release];
    [_searchTimer invalidate]; [_searchTimer release];
    [_pendingSearchText release]; [_contextItem release]; [_contextActions release];
    [super dealloc];
}

@end
