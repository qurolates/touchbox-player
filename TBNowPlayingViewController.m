#import "TBNowPlayingViewController.h"
#import "TBPlayerManager.h"
#import "TBQueueViewController.h"

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
    UIButton *button = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    button.frame = frame;
    [button setTitle:title forState:UIControlStateNormal];
    [button addTarget:self action:action forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:button];
    return button;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    _artworkView = [[UIImageView alloc] initWithFrame:CGRectMake(65, 8, 190, 190)];
    _artworkView.backgroundColor = [UIColor colorWithWhite:0.88f alpha:1.0f];
    _artworkView.contentMode = UIViewContentModeScaleAspectFit;
    [self.view addSubview:_artworkView];
    _titleLabel = [[self labelWithFrame:CGRectMake(15, 202, 290, 23)
        font:[UIFont boldSystemFontOfSize:17.0f] color:[UIColor blackColor]] retain];
    _artistLabel = [[self labelWithFrame:CGRectMake(15, 225, 290, 19)
        font:[UIFont systemFontOfSize:14.0f] color:[UIColor darkGrayColor]] retain];
    _albumLabel = [[self labelWithFrame:CGRectMake(15, 244, 290, 18)
        font:[UIFont systemFontOfSize:13.0f] color:[UIColor grayColor]] retain];
    _elapsedLabel = [[self labelWithFrame:CGRectMake(5, 270, 47, 20)
        font:[UIFont systemFontOfSize:11.0f] color:[UIColor darkGrayColor]] retain];
    _remainingLabel = [[self labelWithFrame:CGRectMake(268, 270, 47, 20)
        font:[UIFont systemFontOfSize:11.0f] color:[UIColor darkGrayColor]] retain];
    _progressSlider = [[UISlider alloc] initWithFrame:CGRectMake(48, 267, 224, 24)];
    [_progressSlider addTarget:self action:@selector(seekStarted:)
        forControlEvents:UIControlEventTouchDown];
    [_progressSlider addTarget:self action:@selector(seekFinished:)
        forControlEvents:UIControlEventTouchUpInside | UIControlEventTouchUpOutside |
                         UIControlEventTouchCancel];
    [self.view addSubview:_progressSlider];
    [self buttonWithFrame:CGRectMake(25, 300, 75, 42) title:@"Previous" action:@selector(previousPressed:)];
    _playPauseButton = [[self buttonWithFrame:CGRectMake(122, 300, 76, 42)
        title:@"Play" action:@selector(playPausePressed:)] retain];
    [self buttonWithFrame:CGRectMake(220, 300, 75, 42) title:@"Next" action:@selector(nextPressed:)];
    _shuffleButton = [[self buttonWithFrame:CGRectMake(8, 352, 94, 38)
        title:@"Shuffle Off" action:@selector(shufflePressed:)] retain];
    [self buttonWithFrame:CGRectMake(113, 352, 94, 38) title:@"Queue" action:@selector(queuePressed:)];
    _repeatButton = [[self buttonWithFrame:CGRectMake(218, 352, 94, 38)
        title:@"Repeat Off" action:@selector(repeatPressed:)] retain];

    NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
    MPMusicPlayerController *player = [TBPlayerManager sharedManager].musicPlayer;
    [center addObserver:self selector:@selector(playerItemChanged:)
        name:MPMusicPlayerControllerNowPlayingItemDidChangeNotification object:player];
    [center addObserver:self selector:@selector(playerStateChanged:)
        name:MPMusicPlayerControllerPlaybackStateDidChangeNotification object:player];
    [self updateAll];
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
    [self updateProgress];
    [self requestArtworkForItem:item];
}

- (void)requestArtworkForItem:(MPMediaItem *)item {
    [_artworkKey release];
    _artworkKey = nil;
    _artworkView.image = nil;
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
    UIImage *image = [artwork imageWithSize:CGSizeMake(190, 190)];
    NSDictionary *result = [[NSDictionary alloc] initWithObjectsAndKeys:
        [request objectForKey:@"key"], @"key", (image ? image : [NSNull null]), @"image", nil];
    [self performSelectorOnMainThread:@selector(showArtwork:) withObject:result waitUntilDone:YES];
    [result release];
    [pool drain];
}

- (void)showArtwork:(NSDictionary *)result {
    if (![_artworkKey isEqualToString:[result objectForKey:@"key"]]) return;
    id image = [result objectForKey:@"image"];
    _artworkView.image = image == [NSNull null] ? nil : image;
}

- (void)updateButtons {
    TBPlayerManager *manager = [TBPlayerManager sharedManager];
    BOOL playing = manager.musicPlayer.playbackState == MPMusicPlaybackStatePlaying;
    [_playPauseButton setTitle:(playing ? @"Pause" : @"Play") forState:UIControlStateNormal];
    [_shuffleButton setTitle:(manager.shuffleEnabled ? @"Shuffle On" : @"Shuffle Off")
                    forState:UIControlStateNormal];
    [_repeatButton setTitle:(manager.repeatOneEnabled ? @"Repeat One" : @"Repeat Off")
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
- (void)playerItemChanged:(NSNotification *)notification { [self updateAll]; }
- (void)playerStateChanged:(NSNotification *)notification { [self updateButtons]; [self updateProgress]; }

- (void)didReceiveMemoryWarning {
    _artworkView.image = nil;
    [super didReceiveMemoryWarning];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [_progressTimer invalidate]; [_progressTimer release];
    [_artworkView release]; [_titleLabel release]; [_artistLabel release]; [_albumLabel release];
    [_elapsedLabel release]; [_remainingLabel release]; [_progressSlider release];
    [_playPauseButton release]; [_shuffleButton release]; [_repeatButton release];
    [_artworkKey release];
    [super dealloc];
}

@end
