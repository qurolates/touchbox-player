#import "TBNowPlayingViewController.h"
#import "TBPlayerManager.h"
#import "TBQueueViewController.h"
#import "TBTheme.h"
#import "TBIconFactory.h"
#import "TBFavoritesManager.h"
#import "TBAddToPlaylistViewController.h"

@implementation TBNowPlayingViewController

- (id)init {
    self = [super init];
    if (self) {
        self.title = @"Now Playing";
        self.hidesBottomBarWhenPushed = YES;
    }
    return self;
}

- (UILabel *)labelWithFrame:(CGRect)frame font:(UIFont *)font color:(UIColor *)color {
    UILabel *label = [[[UILabel alloc] initWithFrame:frame] autorelease];
    label.font = font;
    label.textColor = color;
    label.backgroundColor = [UIColor clearColor];
    label.textAlignment = UITextAlignmentCenter;
    label.lineBreakMode = UILineBreakModeTailTruncation;
    [self.view addSubview:label];
    return label;
}

- (UIButton *)buttonWithFrame:(CGRect)frame title:(NSString *)title action:(SEL)action {
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    button.frame = frame;
    button.titleLabel.font = [TBTheme metadataFont];
    [button setTitle:title forState:UIControlStateNormal];
    [button setTitleColor:[TBTheme secondaryTextColor] forState:UIControlStateNormal];
    [button setTitleColor:[TBTheme accentColor] forState:UIControlStateHighlighted];
    [button addTarget:self action:action forControlEvents:UIControlEventTouchUpInside];
    [button addTarget:self action:@selector(controlPressed:) forControlEvents:UIControlEventTouchDown];
    [button addTarget:self action:@selector(controlReleased:)
        forControlEvents:UIControlEventTouchUpInside | UIControlEventTouchUpOutside |
                         UIControlEventTouchCancel];
    [self.view addSubview:button];
    return button;
}

- (void)controlPressed:(UIButton *)button { button.alpha = 0.55f; }
- (void)controlReleased:(UIButton *)button { button.alpha = 1.0f; }

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [TBTheme backgroundColor];
    self.navigationItem.rightBarButtonItem = [[[UIBarButtonItem alloc]
        initWithTitle:@"Queue" style:UIBarButtonItemStyleBordered
        target:self action:@selector(queuePressed:)] autorelease];
    _artworkView = [[UIImageView alloc] initWithFrame:CGRectMake(50, 4, 220, 220)];
    _artworkView.backgroundColor = [TBTheme placeholderColor];
    _artworkView.image = [TBIconFactory artworkPlaceholderWithSize:CGSizeMake(220, 220)];
    _artworkView.contentMode = UIViewContentModeScaleAspectFit;
    [self.view addSubview:_artworkView];
    _titleLabel = [[self labelWithFrame:CGRectMake(15, 228, 258, 22)
        font:[TBTheme sectionTitleFont] color:[TBTheme primaryTextColor]] retain];
    _favoriteButton = [[UIButton buttonWithType:UIButtonTypeCustom] retain];
    _favoriteButton.frame = CGRectMake(274, 221, 42, 36);
    [_favoriteButton addTarget:self action:@selector(favoritePressed:)
              forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:_favoriteButton];
    _artistLabel = [[self labelWithFrame:CGRectMake(15, 250, 290, 18)
        font:[TBTheme secondaryFont] color:[TBTheme secondaryTextColor]] retain];
    _albumLabel = [[self labelWithFrame:CGRectMake(15, 268, 250, 17)
        font:[TBTheme metadataFont] color:[TBTheme secondaryTextColor]] retain];
    UIButton *addToPlaylist = [UIButton buttonWithType:UIButtonTypeCustom];
    addToPlaylist.tag = 203;
    addToPlaylist.frame = CGRectMake(268, 258, 48, 34);
    addToPlaylist.titleLabel.font = [TBTheme metadataFont];
    [addToPlaylist setTitle:@"+ List" forState:UIControlStateNormal];
    [addToPlaylist setTitleColor:[TBTheme accentColor] forState:UIControlStateNormal];
    [addToPlaylist addTarget:self action:@selector(addToPlaylistPressed:)
             forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:addToPlaylist];
    _elapsedLabel = [[self labelWithFrame:CGRectMake(4, 294, 46, 18)
        font:[TBTheme metadataFont] color:[TBTheme secondaryTextColor]] retain];
    _remainingLabel = [[self labelWithFrame:CGRectMake(270, 294, 46, 18)
        font:[TBTheme metadataFont] color:[TBTheme secondaryTextColor]] retain];
    _progressSlider = [[UISlider alloc] initWithFrame:CGRectMake(46, 290, 228, 24)];
    [_progressSlider addTarget:self action:@selector(seekStarted:)
        forControlEvents:UIControlEventTouchDown];
    [_progressSlider addTarget:self action:@selector(seekFinished:)
        forControlEvents:UIControlEventTouchUpInside | UIControlEventTouchUpOutside |
                         UIControlEventTouchCancel];
    [self.view addSubview:_progressSlider];
    UIButton *previous = [self buttonWithFrame:CGRectMake(31, 318, 64, 44)
        title:nil action:@selector(previousPressed:)];
    previous.tag = 201;
    [previous setImage:[TBIconFactory iconNamed:@"previous" active:NO] forState:UIControlStateNormal];
    _playPauseButton = [[self buttonWithFrame:CGRectMake(128, 318, 64, 44)
        title:nil action:@selector(playPausePressed:)] retain];
    UIButton *next = [self buttonWithFrame:CGRectMake(225, 318, 64, 44)
        title:nil action:@selector(nextPressed:)];
    next.tag = 202;
    [next setImage:[TBIconFactory iconNamed:@"next" active:NO] forState:UIControlStateNormal];
    _shuffleButton = [[self buttonWithFrame:CGRectMake(50, 370, 100, 36)
        title:@"Shuffle" action:@selector(shufflePressed:)] retain];
    _shuffleButton.imageEdgeInsets = UIEdgeInsetsMake(4, 0, 4, 8);
    _repeatButton = [[self buttonWithFrame:CGRectMake(170, 370, 100, 36)
        title:@"Repeat" action:@selector(repeatPressed:)] retain];
    _repeatButton.imageEdgeInsets = UIEdgeInsetsMake(4, 0, 4, 8);

    NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
    MPMusicPlayerController *player = [TBPlayerManager sharedManager].musicPlayer;
    [center addObserver:self selector:@selector(playerItemChanged:)
        name:MPMusicPlayerControllerNowPlayingItemDidChangeNotification object:player];
    [center addObserver:self selector:@selector(playerStateChanged:)
        name:MPMusicPlayerControllerPlaybackStateDidChangeNotification object:player];
    [center addObserver:self selector:@selector(favoritesChanged:)
        name:TBFavoritesDidChangeNotification object:nil];
    [center addObserver:self selector:@selector(themeChanged:)
        name:TBThemeDidChangeNotification object:nil];
    [self updateAll];
    [self applyTheme];
}

- (void)themeChanged:(NSNotification *)notification { [self applyTheme]; }
- (void)applyTheme {
    self.view.backgroundColor = [TBTheme backgroundColor]; _artworkView.backgroundColor = [TBTheme placeholderColor];
    MPMediaItem *themeItem = [TBPlayerManager sharedManager].musicPlayer.nowPlayingItem;
    if (![themeItem valueForProperty:MPMediaItemPropertyArtwork])
        _artworkView.image = [TBIconFactory artworkPlaceholderWithSize:CGSizeMake(220, 220)];
    _titleLabel.textColor = [TBTheme primaryTextColor]; _artistLabel.textColor = [TBTheme secondaryTextColor];
    _albumLabel.textColor = [TBTheme secondaryTextColor]; _elapsedLabel.textColor = [TBTheme secondaryTextColor];
    _remainingLabel.textColor = [TBTheme secondaryTextColor];
    NSUInteger index; for (index = 0; index < [[self.view subviews] count]; index++) { UIView *view = [[self.view subviews] objectAtIndex:index];
        if ([view isKindOfClass:[UIButton class]]) { UIButton *button = (UIButton *)view; [button setTitleColor:[TBTheme secondaryTextColor] forState:UIControlStateNormal]; [button setTitleColor:[TBTheme accentColor] forState:UIControlStateHighlighted]; }
    }
    [self updateButtons]; [self updateFavoriteButton];
    [(UIButton *)[self.view viewWithTag:201] setImage:[TBIconFactory iconNamed:@"previous" active:NO] forState:UIControlStateNormal];
    [(UIButton *)[self.view viewWithTag:202] setImage:[TBIconFactory iconNamed:@"next" active:NO] forState:UIControlStateNormal];
    [(UIButton *)[self.view viewWithTag:203] setTitleColor:[TBTheme accentColor] forState:UIControlStateNormal];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.navigationController setToolbarHidden:YES animated:animated];
    [self updateAll];
    if (!_progressTimer) _progressTimer = [[NSTimer scheduledTimerWithTimeInterval:1.0
        target:self selector:@selector(progressTimerFired:) userInfo:nil repeats:YES] retain];
}

- (void)viewWillDisappear:(BOOL)animated {
    [_progressTimer invalidate];
    [_progressTimer release];
    _progressTimer = nil;
    [super viewWillDisappear:animated];
}

- (NSString *)timeString:(NSTimeInterval)time negative:(BOOL)negative {
    if (time < 0) time = 0;
    NSUInteger seconds = (NSUInteger)time;
    return [NSString stringWithFormat:negative ? @"-%u:%02u" : @"%u:%02u",
        (unsigned)(seconds / 60), (unsigned)(seconds % 60)];
}

- (void)updateAll {
    MPMediaItem *item = [TBPlayerManager sharedManager].musicPlayer.nowPlayingItem;
    _titleLabel.text = item ? ([item valueForProperty:MPMediaItemPropertyTitle] ?: @"Unknown Title") : @"Not Playing";
    _artistLabel.text = item ? ([item valueForProperty:MPMediaItemPropertyArtist] ?: @"Unknown Artist") : @"";
    _albumLabel.text = item ? ([item valueForProperty:MPMediaItemPropertyAlbumTitle] ?: @"Unknown Album") : @"";
    [self updateButtons];
    [self updateFavoriteButton];
    [self updateProgress];
    [self requestArtworkForItem:item];
}

- (void)updateFavoriteButton {
    MPMediaItem *item = [TBPlayerManager sharedManager].musicPlayer.nowPlayingItem;
    BOOL favorite = item && [[TBFavoritesManager sharedManager] isFavoriteItem:item];
    [_favoriteButton setImage:[TBIconFactory iconNamed:@"star" active:favorite]
                     forState:UIControlStateNormal];
    _favoriteButton.enabled = item != nil;
    _favoriteButton.alpha = item ? 1.0f : 0.35f;
}

- (void)favoritePressed:(id)sender {
    MPMediaItem *item = [TBPlayerManager sharedManager].musicPlayer.nowPlayingItem;
    if (!item) return;
    [[TBFavoritesManager sharedManager] toggleFavoriteItem:item];
    [self updateFavoriteButton];
}

- (void)requestArtworkForItem:(MPMediaItem *)item {
    [_artworkKey release];
    _artworkKey = nil;
    _artworkView.image = [TBIconFactory artworkPlaceholderWithSize:CGSizeMake(220, 220)];
    if (!item) return;
    NSNumber *number = [item valueForProperty:MPMediaItemPropertyPersistentID];
    _artworkKey = [[NSString stringWithFormat:@"%llu", [number unsignedLongLongValue]] copy];
    NSDictionary *request = [NSDictionary dictionaryWithObjectsAndKeys:
        item, @"item", _artworkKey, @"key", nil];
    [self performSelectorInBackground:@selector(loadArtwork:) withObject:request];
}

- (void)loadArtwork:(NSDictionary *)request {
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    MPMediaItemArtwork *artwork = [[request objectForKey:@"item"] valueForProperty:MPMediaItemPropertyArtwork];
    UIImage *image = [artwork imageWithSize:CGSizeMake(220, 220)];
    NSDictionary *result = [[NSDictionary alloc] initWithObjectsAndKeys:
        [request objectForKey:@"key"], @"key", (image ? image : [NSNull null]), @"image", nil];
    [self performSelectorOnMainThread:@selector(showArtwork:) withObject:result waitUntilDone:YES];
    [result release];
    [pool drain];
}

- (void)showArtwork:(NSDictionary *)result {
    if (![_artworkKey isEqualToString:[result objectForKey:@"key"]]) return;
    id image = [result objectForKey:@"image"];
    if (image != [NSNull null]) _artworkView.image = image;
}

- (void)updateButtons {
    TBPlayerManager *manager = [TBPlayerManager sharedManager];
    BOOL playing = manager.musicPlayer.playbackState == MPMusicPlaybackStatePlaying;
    [_playPauseButton setImage:[TBIconFactory iconNamed:(playing ? @"pause" : @"play") active:NO]
                       forState:UIControlStateNormal];
    [_shuffleButton setImage:[TBIconFactory iconNamed:@"shuffle" active:manager.shuffleEnabled]
                     forState:UIControlStateNormal];
    [_shuffleButton setTitleColor:(manager.shuffleEnabled ? [TBTheme accentColor] : [TBTheme secondaryTextColor])
                         forState:UIControlStateNormal];
    [_repeatButton setImage:[TBIconFactory iconNamed:@"repeat" active:manager.repeatOneEnabled]
                    forState:UIControlStateNormal];
    [_repeatButton setTitle:(manager.repeatOneEnabled ? @"Repeat 1" : @"Repeat")
                   forState:UIControlStateNormal];
    [_repeatButton setTitleColor:(manager.repeatOneEnabled ? [TBTheme accentColor] : [TBTheme secondaryTextColor])
                        forState:UIControlStateNormal];
}

- (void)updateProgress {
    if (_seeking) return;
    MPMusicPlayerController *player = [TBPlayerManager sharedManager].musicPlayer;
    MPMediaItem *item = player.nowPlayingItem;
    NSTimeInterval duration = [[item valueForProperty:MPMediaItemPropertyPlaybackDuration] doubleValue];
    NSTimeInterval elapsed = player.currentPlaybackTime;
    if (elapsed < 0) elapsed = 0;
    _progressSlider.minimumValue = 0.0f;
    _progressSlider.maximumValue = duration > 0 ? (float)duration : 1.0f;
    _progressSlider.value = duration > 0 ? (float)MIN(elapsed, duration) : 0.0f;
    _progressSlider.enabled = duration > 0;
    _elapsedLabel.text = [self timeString:elapsed negative:NO];
    _remainingLabel.text = [self timeString:MAX(duration - elapsed, 0) negative:YES];
}

- (void)progressTimerFired:(NSTimer *)timer { [self updateProgress]; }
- (void)seekStarted:(UISlider *)slider { _seeking = YES; }
- (void)seekFinished:(UISlider *)slider {
    [[TBPlayerManager sharedManager] seekToTime:slider.value];
    _seeking = NO;
    [self updateProgress];
}
- (void)previousPressed:(id)sender { [[TBPlayerManager sharedManager] previous]; }
- (void)playPausePressed:(id)sender { [[TBPlayerManager sharedManager] togglePlayPause]; }
- (void)nextPressed:(id)sender { [[TBPlayerManager sharedManager] next]; }
- (void)shufflePressed:(id)sender { [[TBPlayerManager sharedManager] toggleShuffle]; [self updateButtons]; }
- (void)repeatPressed:(id)sender { [[TBPlayerManager sharedManager] toggleRepeatOne]; [self updateButtons]; }
- (void)queuePressed:(id)sender {
    TBQueueViewController *controller = [[TBQueueViewController alloc] init];
    [self.navigationController pushViewController:controller animated:YES];
    [controller release];
}
- (void)addToPlaylistPressed:(id)sender {
    MPMediaItem *item = [TBPlayerManager sharedManager].musicPlayer.nowPlayingItem;
    if (!item) return;
    TBAddToPlaylistViewController *controller = [[TBAddToPlaylistViewController alloc]
        initWithItem:item];
    [self.navigationController pushViewController:controller animated:YES];
    [controller release];
}
- (void)playerItemChanged:(NSNotification *)notification { [self updateAll]; }
- (void)playerStateChanged:(NSNotification *)notification { [self updateButtons]; [self updateProgress]; }
- (void)favoritesChanged:(NSNotification *)notification { [self updateFavoriteButton]; }

- (void)didReceiveMemoryWarning {
    _artworkView.image = [TBIconFactory artworkPlaceholderWithSize:CGSizeMake(220, 220)];
    [super didReceiveMemoryWarning];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [_progressTimer invalidate]; [_progressTimer release];
    [_artworkView release]; [_titleLabel release]; [_artistLabel release]; [_albumLabel release];
    [_elapsedLabel release]; [_remainingLabel release]; [_progressSlider release];
    [_playPauseButton release]; [_shuffleButton release]; [_repeatButton release];
    [_favoriteButton release];
    [_artworkKey release];
    [super dealloc];
}

@end
