#import "TBTrackListViewController.h"
#import "TBPlayerManager.h"
#import "TBFavoritesManager.h"
#import "TBNowPlayingViewController.h"
#import "TBTheme.h"
#import "TBIconFactory.h"

@implementation TBTrackListViewController

@synthesize items = _items;
@synthesize playPauseButton = _playPauseButton;

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
    self.navigationItem.rightBarButtonItem = [[[UIBarButtonItem alloc]
        initWithTitle:@"Player" style:UIBarButtonItemStyleBordered
        target:self action:@selector(showNowPlaying:)] autorelease];

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
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.navigationController setToolbarHidden:NO animated:animated];
    [self reloadTrackItems];
    [self.tableView reloadData];
    [self updatePlayPauseButton];
}

- (void)reloadTrackItems {}

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
}

- (void)favoritePressed:(UIButton *)sender {
    NSUInteger index = (NSUInteger)sender.tag;
    if (index >= [_items count]) return;
    [[TBFavoritesManager sharedManager] toggleFavoriteItem:[_items objectAtIndex:index]];
}

- (void)previousPressed:(id)sender { [[TBPlayerManager sharedManager] previous]; }
- (void)playPausePressed:(id)sender { [[TBPlayerManager sharedManager] togglePlayPause]; }
- (void)nextPressed:(id)sender { [[TBPlayerManager sharedManager] next]; }
- (void)showNowPlaying:(id)sender {
    TBNowPlayingViewController *controller = [[TBNowPlayingViewController alloc] init];
    [self.navigationController pushViewController:controller animated:YES];
    [controller release];
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
    [_playPauseButton release];
    [super dealloc];
}

@end
