#import "TBTrackListViewController.h"
#import "TBPlayerManager.h"
#import "TBFavoritesManager.h"
#import "TBNowPlayingViewController.h"

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
        initWithTitle:@"Now Playing" style:UIBarButtonItemStyleBordered
        target:self action:@selector(showNowPlaying:)] autorelease];

    UIBarButtonItem *previous = [[UIBarButtonItem alloc] initWithTitle:@"Previous"
        style:UIBarButtonItemStyleBordered target:self action:@selector(previousPressed:)];
    UIBarButtonItem *playPause = [[UIBarButtonItem alloc] initWithTitle:@"Play"
        style:UIBarButtonItemStyleBordered target:self action:@selector(playPausePressed:)];
    self.playPauseButton = playPause;
    [playPause release];
    UIBarButtonItem *next = [[UIBarButtonItem alloc] initWithTitle:@"Next"
        style:UIBarButtonItemStyleBordered target:self action:@selector(nextPressed:)];
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
        favoriteButton.titleLabel.font = [UIFont systemFontOfSize:24.0f];
        [favoriteButton setTitleColor:[UIColor darkGrayColor] forState:UIControlStateNormal];
        [favoriteButton addTarget:self action:@selector(favoritePressed:)
                 forControlEvents:UIControlEventTouchUpInside];
        cell.accessoryView = favoriteButton;
    } else {
        favoriteButton = (UIButton *)cell.accessoryView;
    }
    MPMediaItem *item = [_items objectAtIndex:(NSUInteger)indexPath.row];
    NSString *title = [item valueForProperty:MPMediaItemPropertyTitle];
    NSString *artist = [item valueForProperty:MPMediaItemPropertyArtist];
    cell.textLabel.text = title ? title : @"Unknown Title";
    cell.detailTextLabel.text = artist ? artist : @"Unknown Artist";
    favoriteButton.tag = indexPath.row;
    NSString *star = [[TBFavoritesManager sharedManager] isFavoriteItem:item] ? @"★" : @"☆";
    [favoriteButton setTitle:star forState:UIControlStateNormal];
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
}

- (void)favoritesChanged:(NSNotification *)notification {
    [self reloadTrackItems];
    [self.tableView reloadData];
}

- (void)updatePlayPauseButton {
    self.playPauseButton.title =
      ([TBPlayerManager sharedManager].musicPlayer.playbackState == MPMusicPlaybackStatePlaying)
      ? @"Pause" : @"Play";
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
