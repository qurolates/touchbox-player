#import "TBClassicViewController.h"
#import "TBPlayerManager.h"
#import "TBLibraryManager.h"
#import "TBArtworkCache.h"
#import "TBIconFactory.h"
#import "TBFavoritesManager.h"
#import "TBUserPlaylistManager.h"
#import "TBRecentManager.h"
#import "TBPlaylistNameViewController.h"
#import "TBTheme.h"
#import "TBThemeViewController.h"
#import "AppDelegate.h"
#import "TBPerformance.h"
#import "TBCoverFlowView.h"
#import <math.h>

static const NSInteger TBClassicVisibleRows = 6;
static NSString *const TBClassicStateTypeKey = @"type";
static NSString *const TBClassicStateTitleKey = @"title";
static NSString *const TBClassicStateItemsKey = @"items";
static NSString *const TBClassicStateSelectionKey = @"selection";
static NSString *const TBClassicRootSelectionDefaultsKey = @"TBClassicRootSelection";

static NSInteger TBClassicAlbumTitleGroup(NSString *title) {
    if (![title length] || [title caseInsensitiveCompare:@"Unknown Album"] == NSOrderedSame) return 2;
    NSString *folded = [title stringByFoldingWithOptions:(NSCaseInsensitiveSearch | NSDiacriticInsensitiveSearch)
        locale:[NSLocale currentLocale]];
    unichar first = [[folded uppercaseString] characterAtIndex:0];
    return (first >= 'A' && first <= 'Z') ? 0 : 1;
}

static NSInteger TBClassicAlbumTitleSort(id left, id right, void *context) {
    NSString *leftTitle = [left objectForKey:TBAlbumTitleKey];
    NSString *rightTitle = [right objectForKey:TBAlbumTitleKey];
    NSInteger leftGroup = TBClassicAlbumTitleGroup(leftTitle);
    NSInteger rightGroup = TBClassicAlbumTitleGroup(rightTitle);
    if (leftGroup < rightGroup) return NSOrderedAscending;
    if (leftGroup > rightGroup) return NSOrderedDescending;
    NSComparisonResult result = [(leftTitle ? leftTitle : @"") compare:(rightTitle ? rightTitle : @"")
        options:(NSCaseInsensitiveSearch | NSDiacriticInsensitiveSearch)];
    if (result != NSOrderedSame) return result;
    NSString *leftArtist = [left objectForKey:TBAlbumArtistKey];
    NSString *rightArtist = [right objectForKey:TBAlbumArtistKey];
    return [(leftArtist ? leftArtist : @"") compare:(rightArtist ? rightArtist : @"")
        options:(NSCaseInsensitiveSearch | NSDiacriticInsensitiveSearch)];
}

typedef enum {
    TBClassicScreenRoot = 0,
    TBClassicScreenMusic,
    TBClassicScreenArtists,
    TBClassicScreenArtistAlbums,
    TBClassicScreenAlbums,
    TBClassicScreenAlbumTracks,
    TBClassicScreenSongs,
    TBClassicScreenSettings,
    TBClassicScreenNowPlaying,
    TBClassicScreenFavorites,
    TBClassicScreenPlaylists,
    TBClassicScreenUserPlaylists,
    TBClassicScreenSystemPlaylists,
    TBClassicScreenPlaylistTracks,
    TBClassicScreenRecent,
    TBClassicScreenRecentTracks,
    TBClassicScreenQueue,
    TBClassicScreenTrackOptions,
    TBClassicScreenAddToPlaylist,
    TBClassicScreenCoverFlow
} TBClassicScreenType;

@implementation TBClassicViewController

- (void)layoutClassicForBounds {
    CGFloat width = self.view.bounds.size.width, height = self.view.bounds.size.height;
    CGFloat bodyWidth = MIN(360.0f, width);
    CGFloat extraHeight = MAX(0.0f, height - 480.0f);
    CGFloat displayHeight = MIN(300.0f, 220.0f + extraHeight * 0.43f);
    CGFloat wheelHeight = 260.0f;
    CGFloat originX = floorf((width - bodyWidth) * 0.5f);
    CGFloat originY = floorf(MAX(0.0f, (height - displayHeight - wheelHeight) * 0.5f));
    UIView *display = _titleLabel.superview;
    display.frame = CGRectMake(originX, originY, bodyWidth, displayHeight);
    _titleLabel.frame = CGRectMake(0, 0, bodyWidth, 30);
    _queuePositionLabel.frame = CGRectMake(bodyWidth - 60, 0, 52, 30);
    CGFloat rowHeight = floorf((displayHeight - 46.0f) / TBClassicVisibleRows);
    NSInteger row;
    for (row = 0; row < TBClassicVisibleRows; row++) {
        ((UILabel *)[_rowLabels objectAtIndex:(NSUInteger)row]).frame =
            CGRectMake(8, 31 + row * rowHeight, bodyWidth - 16, rowHeight);
        ((UILabel *)[_rowAccessoryLabels objectAtIndex:(NSUInteger)row]).frame =
            CGRectMake(bodyWidth - 26, 31 + row * rowHeight, 18, rowHeight);
    }
    _statusLabel.frame = CGRectMake(0, displayHeight - 15, bodyWidth, 15);
    CGFloat nowHeight = displayHeight - 45.0f;
    _nowPlayingView.frame = CGRectMake(0, 30, bodyWidth, nowHeight);
    _coverFlowView.frame = CGRectMake(0, 30, bodyWidth, nowHeight);
    CGFloat artworkSize = MIN(140.0f, 114.0f + MAX(0.0f, displayHeight - 220.0f) * 0.325f);
    _nowPlayingArtworkView.frame = CGRectMake(10, 7, artworkSize, artworkSize);
    CGFloat metadataX = artworkSize + 20.0f;
    CGFloat metadataWidth = MAX(100.0f, bodyWidth - metadataX - 10.0f);
    _nowPlayingTitleLabel.frame = CGRectMake(metadataX, 9, metadataWidth, 40);
    _nowPlayingArtistLabel.frame = CGRectMake(metadataX, 53, metadataWidth, 19);
    _nowPlayingAlbumLabel.frame = CGRectMake(metadataX, 74, metadataWidth, 18);
    CGFloat progressY = nowHeight - 26.0f;
    _progressFillView.superview.frame = CGRectMake(50, progressY, MAX(80.0f, bodyWidth - 100), 3);
    _nowPlayingElapsedLabel.frame = CGRectMake(5, progressY - 9, 42, 18);
    _nowPlayingRemainingLabel.frame = CGRectMake(bodyWidth - 47, progressY - 9, 42, 18);
    UIView *divider = [self.view viewWithTag:841];
    divider.frame = CGRectMake(originX, originY + displayHeight - 1, bodyWidth, 1);
    _wheelView.frame = CGRectMake(originX, originY + displayHeight, bodyWidth, wheelHeight);
}

- (id)init {
    if ((self = [super init])) {
        _navigationStack = [[NSMutableArray alloc] init];
        _screenType = TBClassicScreenRoot;
        _screenTitle = [@"Touchbox" copy];
        _currentItems = [[NSArray arrayWithObjects:@"Music", @"Favorites", @"Recent", @"Queue", @"Now Playing", @"Settings", nil] retain];
        _selectedIndex = [[NSUserDefaults standardUserDefaults] integerForKey:TBClassicRootSelectionDefaultsKey];
        if (_selectedIndex < 0 || _selectedIndex >= (NSInteger)[_currentItems count]) _selectedIndex = 0;
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(libraryIndexReady:)
            name:TBLibraryIndexDidLoadNotification object:[TBLibraryManager sharedManager]];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(librarySongsReady:)
            name:TBLibrarySongsDidLoadNotification object:[TBLibraryManager sharedManager]];
        MPMusicPlayerController *player = [TBPlayerManager sharedManager].musicPlayer;
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playerItemChanged:)
            name:MPMusicPlayerControllerNowPlayingItemDidChangeNotification object:player];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playerStateChanged:)
            name:MPMusicPlayerControllerPlaybackStateDidChangeNotification object:player];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(sharedDataChanged:)
            name:TBFavoritesDidChangeNotification object:[TBFavoritesManager sharedManager]];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(sharedDataChanged:)
            name:TBUserPlaylistsDidChangeNotification object:[TBUserPlaylistManager sharedManager]];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(sharedDataChanged:)
            name:TBRecentDidChangeNotification object:[TBRecentManager sharedManager]];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(sharedDataChanged:)
            name:TBPlayerQueueDidChangeNotification object:[TBPlayerManager sharedManager]];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(sharedDataChanged:)
            name:TBLibraryPlaylistsDidLoadNotification object:[TBLibraryManager sharedManager]];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(themeChanged:)
            name:TBThemeDidChangeNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationDidEnterBackground:)
            name:UIApplicationDidEnterBackgroundNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationDidBecomeActive:)
            name:UIApplicationDidBecomeActiveNotification object:nil];
    }
    return self;
}

- (void)loadView {
    UIView *root = [[UIView alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    root.backgroundColor = [TBTheme classicBodyColor]; self.view = root; [root release];
    UIView *display = [[[UIView alloc] initWithFrame:CGRectMake(0, 0, 320, 220)] autorelease];
    display.backgroundColor = [TBTheme classicDisplayColor]; [self.view addSubview:display];
    _titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 320, 30)];
    _titleLabel.backgroundColor = [TBTheme classicHeaderColor];
    _titleLabel.font = [UIFont boldSystemFontOfSize:14];
    _titleLabel.textColor = [TBTheme primaryTextColor]; [display addSubview:_titleLabel];
    _queuePositionLabel = [[UILabel alloc] initWithFrame:CGRectMake(260, 0, 52, 30)];
    _queuePositionLabel.backgroundColor = [UIColor clearColor];
    _queuePositionLabel.font = [UIFont boldSystemFontOfSize:12];
    _queuePositionLabel.textAlignment = UITextAlignmentRight;
    _queuePositionLabel.textColor = [TBTheme secondaryTextColor];
    _queuePositionLabel.hidden = YES; [display addSubview:_queuePositionLabel];
    _rowLabels = [[NSMutableArray alloc] initWithCapacity:TBClassicVisibleRows];
    _rowAccessoryLabels = [[NSMutableArray alloc] initWithCapacity:TBClassicVisibleRows]; NSInteger i;
    for (i = 0; i < TBClassicVisibleRows; i++) {
        UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(8, 31 + i * 29, 304, 29)];
        label.font = [UIFont boldSystemFontOfSize:14]; label.lineBreakMode = UILineBreakModeTailTruncation;
        [display addSubview:label]; [_rowLabels addObject:label]; [label release];
        UILabel *accessory = [[UILabel alloc] initWithFrame:CGRectMake(294, 31 + i * 29, 18, 29)];
        accessory.backgroundColor = [UIColor clearColor]; accessory.font = [UIFont boldSystemFontOfSize:14];
        accessory.textAlignment = UITextAlignmentCenter; accessory.text = @">";
        [display addSubview:accessory]; [_rowAccessoryLabels addObject:accessory]; [accessory release];
    }
    _statusLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 205, 320, 15)];
    _statusLabel.backgroundColor = [TBTheme classicHeaderColor];
    _statusLabel.font = [UIFont systemFontOfSize:10]; _statusLabel.textColor = [TBTheme secondaryTextColor];
    _statusLabel.textAlignment = UITextAlignmentCenter; [display addSubview:_statusLabel];
    _nowPlayingView = [[UIView alloc] initWithFrame:CGRectMake(0, 30, 320, 175)];
    _nowPlayingView.backgroundColor = [TBTheme classicDisplayColor];
    _nowPlayingView.hidden = YES; [display addSubview:_nowPlayingView];
    _nowPlayingArtworkView = [[UIImageView alloc] initWithFrame:CGRectMake(8, 6, 120, 120)];
    _nowPlayingArtworkView.contentMode = UIViewContentModeScaleAspectFit;
    _nowPlayingArtworkView.image = [TBIconFactory artworkPlaceholderWithSize:CGSizeMake(120, 120)];
    [_nowPlayingView addSubview:_nowPlayingArtworkView];
    _nowPlayingTitleLabel = [[UILabel alloc] initWithFrame:CGRectMake(138, 10, 172, 42)];
    _nowPlayingTitleLabel.numberOfLines = 2; _nowPlayingTitleLabel.font = [UIFont boldSystemFontOfSize:15];
    _nowPlayingTitleLabel.textColor = [TBTheme primaryTextColor];
    _nowPlayingTitleLabel.backgroundColor = [UIColor clearColor]; _nowPlayingTitleLabel.lineBreakMode = UILineBreakModeTailTruncation;
    [_nowPlayingView addSubview:_nowPlayingTitleLabel];
    _nowPlayingArtistLabel = [[UILabel alloc] initWithFrame:CGRectMake(138, 58, 172, 20)];
    _nowPlayingArtistLabel.font = [UIFont systemFontOfSize:12]; _nowPlayingArtistLabel.textColor = [TBTheme secondaryTextColor];
    _nowPlayingArtistLabel.backgroundColor = [UIColor clearColor]; _nowPlayingArtistLabel.lineBreakMode = UILineBreakModeTailTruncation;
    [_nowPlayingView addSubview:_nowPlayingArtistLabel];
    _nowPlayingAlbumLabel = [[UILabel alloc] initWithFrame:CGRectMake(138, 80, 172, 20)];
    _nowPlayingAlbumLabel.font = [UIFont systemFontOfSize:11]; _nowPlayingAlbumLabel.textColor = [TBTheme secondaryTextColor];
    _nowPlayingAlbumLabel.backgroundColor = [UIColor clearColor]; _nowPlayingAlbumLabel.lineBreakMode = UILineBreakModeTailTruncation;
    [_nowPlayingView addSubview:_nowPlayingAlbumLabel];
    UIView *progressTrack = [[[UIView alloc] initWithFrame:CGRectMake(50, 149, 220, 3)] autorelease];
    progressTrack.backgroundColor = [TBTheme borderColor]; [_nowPlayingView addSubview:progressTrack];
    _progressFillView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 0, 3)];
    _progressFillView.backgroundColor = [TBTheme accentColor]; [progressTrack addSubview:_progressFillView];
    _nowPlayingElapsedLabel = [[UILabel alloc] initWithFrame:CGRectMake(5, 140, 42, 18)];
    _nowPlayingRemainingLabel = [[UILabel alloc] initWithFrame:CGRectMake(273, 140, 42, 18)];
    NSArray *timeLabels = [NSArray arrayWithObjects:_nowPlayingElapsedLabel, _nowPlayingRemainingLabel, nil];
    NSUInteger timeIndex; for (timeIndex = 0; timeIndex < [timeLabels count]; timeIndex++) { UILabel *label = [timeLabels objectAtIndex:timeIndex]; label.font = [UIFont systemFontOfSize:10]; label.textColor = [TBTheme secondaryTextColor]; label.backgroundColor = [UIColor clearColor]; }
    _nowPlayingRemainingLabel.textAlignment = UITextAlignmentRight;
    [_nowPlayingView addSubview:_nowPlayingElapsedLabel]; [_nowPlayingView addSubview:_nowPlayingRemainingLabel];
    _coverFlowView = [[TBCoverFlowView alloc] initWithFrame:CGRectMake(0, 30, 320, 175)];
    _coverFlowView.hidden = YES; [display addSubview:_coverFlowView];
    UIView *divider = [[[UIView alloc] initWithFrame:CGRectMake(0, 219, 320, 1)] autorelease];
    divider.backgroundColor = [TBTheme borderColor]; divider.tag = 841; [self.view addSubview:divider];
    _wheelView = [[TBClickWheelView alloc] initWithFrame:CGRectMake(0, 220, 320, 260)];
    _wheelView.delegate = self; [self.view addSubview:_wheelView]; [self updateDisplay];
    [self layoutClassicForBounds];
}

- (void)themeChanged:(NSNotification *)notification { if (_visible && [UIApplication sharedApplication].applicationState == UIApplicationStateActive) [self applyTheme]; }
- (void)applyTheme {
    self.view.backgroundColor = [TBTheme classicBodyColor];
    _titleLabel.superview.backgroundColor = [TBTheme classicDisplayColor];
    _titleLabel.backgroundColor = [TBTheme classicHeaderColor]; _titleLabel.textColor = [TBTheme primaryTextColor];
    _queuePositionLabel.textColor = [TBTheme secondaryTextColor];
    _statusLabel.backgroundColor = [TBTheme classicHeaderColor]; _statusLabel.textColor = [TBTheme secondaryTextColor];
    _nowPlayingView.backgroundColor = [TBTheme classicDisplayColor];
    _nowPlayingTitleLabel.textColor = [TBTheme primaryTextColor];
    MPMediaItem *themeItem = [TBPlayerManager sharedManager].musicPlayer.nowPlayingItem;
    if (![themeItem valueForProperty:MPMediaItemPropertyArtwork])
        _nowPlayingArtworkView.image = [TBIconFactory artworkPlaceholderWithSize:_nowPlayingArtworkView.bounds.size];
    _nowPlayingArtistLabel.textColor = [TBTheme secondaryTextColor]; _nowPlayingAlbumLabel.textColor = [TBTheme secondaryTextColor];
    _nowPlayingElapsedLabel.textColor = [TBTheme secondaryTextColor]; _nowPlayingRemainingLabel.textColor = [TBTheme secondaryTextColor];
    _progressFillView.backgroundColor = [TBTheme accentColor]; _progressFillView.superview.backgroundColor = [TBTheme borderColor];
    [_coverFlowView applyTheme];
    [[self.view viewWithTag:841] setBackgroundColor:[TBTheme borderColor]];
    _wheelView.backgroundColor = [TBTheme classicBodyColor]; [_wheelView setNeedsDisplay];
    [self updateDisplay];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    _visible = YES;
    [self layoutClassicForBounds];
    [self applyTheme];
}
- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    TBPerformanceLog(@"Touchbox Classic: visible screen=%@", _screenTitle);
}
- (void)viewWillDisappear:(BOOL)animated {
    if (_classicSeekChanged) {
        [[TBPlayerManager sharedManager] endInteractiveSeek];
        _classicSeekChanged = NO;
        _classicSeekPosition = 0;
    }
    _visible = NO;
    [self stopProgressTimer];
    [super viewWillDisappear:animated];
}
- (void)applicationDidEnterBackground:(NSNotification *)notification { [self stopProgressTimer]; }
- (void)applicationDidBecomeActive:(NSNotification *)notification {
    if (_visible && _screenType == TBClassicScreenNowPlaying) {
        [self updateNowPlaying];
        [self startProgressTimer];
    }
}

- (NSArray *)allAlbums {
    NSArray *groups = [[TBLibraryManager sharedManager] artistGroups];
    NSMutableArray *albums = [NSMutableArray array]; NSUInteger index;
    for (index = 0; index < [groups count]; index++)
        [albums addObjectsFromArray:[[groups objectAtIndex:index] objectForKey:TBAlbumsKey]];
    [albums sortUsingFunction:TBClassicAlbumTitleSort context:NULL];
    return albums;
}

- (NSString *)titleForItem:(id)item atIndex:(NSInteger)index {
    if (_screenType == TBClassicScreenArtists)
        return [item objectForKey:TBArtistNameKey];
    if (_screenType == TBClassicScreenArtistAlbums || _screenType == TBClassicScreenAlbums)
        return [item isKindOfClass:[NSString class]] ? item : [item objectForKey:TBAlbumTitleKey];
    if (_screenType == TBClassicScreenAlbumTracks || _screenType == TBClassicScreenSongs) {
        if ([item isKindOfClass:[NSString class]]) return item;
        NSString *title = [item valueForProperty:MPMediaItemPropertyTitle];
        if (!title) title = @"Unknown Title";
        if (_screenType == TBClassicScreenAlbumTracks) {
            NSNumber *number = [item valueForProperty:MPMediaItemPropertyAlbumTrackNumber];
            if ([number integerValue] > 0) return [NSString stringWithFormat:@"%@  %@", number, title];
        }
        return title;
    }
    if (_screenType == TBClassicScreenFavorites || _screenType == TBClassicScreenRecentTracks ||
        _screenType == TBClassicScreenPlaylistTracks || _screenType == TBClassicScreenQueue) {
        if ([item isKindOfClass:[NSString class]]) return item;
        NSString *title = [item valueForProperty:MPMediaItemPropertyTitle]; if (!title) title = @"Unknown Title";
        if (_screenType == TBClassicScreenQueue && index == [TBPlayerManager sharedManager].currentQueueIndex)
            return [NSString stringWithFormat:@"|> %@", title];
        return title;
    }
    if (_screenType == TBClassicScreenUserPlaylists || _screenType == TBClassicScreenAddToPlaylist)
        return [item isKindOfClass:[NSString class]] ? item : [item objectForKey:TBUserPlaylistNameKey];
    if (_screenType == TBClassicScreenSystemPlaylists) {
        NSString *name = [item valueForProperty:MPMediaPlaylistPropertyName]; return name ? name : @"Unknown Playlist";
    }
    return item;
}

- (NSArray *)shuffleListWithTracks:(NSArray *)tracks {
    NSMutableArray *items = [NSMutableArray arrayWithObject:@"Shuffle"];
    [items addObjectsFromArray:(tracks ? tracks : [NSArray array])]; return items;
}
- (NSArray *)tracksFromShuffleList:(NSArray *)items {
    return [items count] > 1 ? [items subarrayWithRange:NSMakeRange(1, [items count] - 1)] : [NSArray array];
}
- (NSArray *)favoriteItems {
    return [[TBFavoritesManager sharedManager] favoriteItemsFromSongs:[[TBLibraryManager sharedManager] songs]];
}
- (NSArray *)userPlaylistMenuItems {
    NSMutableArray *items = [NSMutableArray arrayWithArray:[[TBUserPlaylistManager sharedManager] playlists]];
    [items addObject:@"+ New Playlist"]; return items;
}
- (NSArray *)artistAlbumMenuItems:(NSArray *)albums {
    NSMutableArray *items = [NSMutableArray arrayWithObject:@"Shuffle Artist"];
    [items addObjectsFromArray:(albums ? albums : [NSArray array])]; return items;
}
- (NSArray *)trackOptions {
    TBPlayerManager *player = [TBPlayerManager sharedManager];
    BOOL favorite = [[TBFavoritesManager sharedManager] isFavoriteItem:player.musicPlayer.nowPlayingItem];
    return [NSArray arrayWithObjects:(favorite ? @"Remove Favorite" : @"Add Favorite"),
        @"Add to Playlist", @"Play Next", @"Queue",
        (player.shuffleEnabled ? @"Shuffle Off" : @"Shuffle On"),
        (player.repeatOneEnabled ? @"Repeat Off" : @"Repeat One"), nil];
}
- (void)presentPlaylistNameForCurrentItem:(BOOL)addCurrentItem {
    _creatingPlaylistForCurrentItem = addCurrentItem;
    TBPlaylistNameViewController *controller = [[TBPlaylistNameViewController alloc]
        initWithTarget:self action:@selector(createdPlaylistNamed:)];
    UINavigationController *navigation = [[UINavigationController alloc] initWithRootViewController:controller];
    navigation.navigationBar.tintColor = [TBTheme accentColor]; [controller release];
    [self presentModalViewController:navigation animated:YES]; [navigation release];
}
- (void)createdPlaylistNamed:(NSString *)name {
    NSDictionary *playlist = [[TBUserPlaylistManager sharedManager] createPlaylistWithName:name];
    if (playlist && _creatingPlaylistForCurrentItem) [[TBUserPlaylistManager sharedManager]
        addItem:[TBPlayerManager sharedManager].musicPlayer.nowPlayingItem
        toPlaylistID:[playlist objectForKey:TBUserPlaylistIDKey]];
    _statusLabel.text = playlist ? @"Playlist created" : @"Playlist not created";
}
- (void)loadClassicSystemPlaylist:(MPMediaPlaylist *)playlist {
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    NSString *name = [playlist valueForProperty:MPMediaPlaylistPropertyName]; NSArray *tracks = [playlist items];
    NSDictionary *result = [[NSDictionary alloc] initWithObjectsAndKeys:(name ? name : @"Playlist"), @"name",
        (tracks ? tracks : [NSArray array]), @"tracks", nil];
    [self performSelectorOnMainThread:@selector(showClassicSystemPlaylist:) withObject:result waitUntilDone:YES];
    [result release]; [pool drain];
}
- (void)showClassicSystemPlaylist:(NSDictionary *)result {
    _loadingClassicPlaylist = NO;
    if (_screenType != TBClassicScreenSystemPlaylists) return;
    [self pushScreen:TBClassicScreenPlaylistTracks title:[result objectForKey:@"name"]
        items:[self shuffleListWithTracks:[result objectForKey:@"tracks"]]];
}

- (BOOL)itemIsSubmenuAtIndex:(NSInteger)index {
    if (_screenType == TBClassicScreenRoot) return YES;
    return _screenType == TBClassicScreenMusic || _screenType == TBClassicScreenArtists ||
        _screenType == TBClassicScreenArtistAlbums || _screenType == TBClassicScreenAlbums ||
        _screenType == TBClassicScreenPlaylists || _screenType == TBClassicScreenUserPlaylists ||
        _screenType == TBClassicScreenSystemPlaylists || _screenType == TBClassicScreenRecent;
}

- (void)updateDisplay {
    _titleLabel.text = [NSString stringWithFormat:@"  %@", _screenTitle];
    BOOL nowPlaying = _screenType == TBClassicScreenNowPlaying;
    BOOL coverFlow = _screenType == TBClassicScreenCoverFlow;
    _nowPlayingView.hidden = !nowPlaying; _statusLabel.hidden = nowPlaying;
    _coverFlowView.hidden = !coverFlow;
    _queuePositionLabel.hidden = !nowPlaying;
    NSInteger hiddenRow; for (hiddenRow = 0; hiddenRow < TBClassicVisibleRows; hiddenRow++)
        { ((UILabel *)[_rowLabels objectAtIndex:(NSUInteger)hiddenRow]).hidden = nowPlaying || coverFlow;
          ((UILabel *)[_rowAccessoryLabels objectAtIndex:(NSUInteger)hiddenRow]).hidden = nowPlaying || coverFlow; }
    if (nowPlaying) { [self updateNowPlaying]; if (_visible) [self startProgressTimer]; return; }
    [self stopProgressTimer];
    NSInteger count = (NSInteger)[_currentItems count];
    if (count == 0) _selectedIndex = 0; else if (_selectedIndex >= count) _selectedIndex = count - 1;
    if (coverFlow) {
        _statusLabel.hidden = YES;
        [_coverFlowView setAlbums:_currentItems selectedIndex:(count ? _selectedIndex : NSNotFound)];
        return;
    }
    _statusLabel.hidden = NO;
    NSInteger maximumStart = MAX(0, count - TBClassicVisibleRows);
    NSInteger start = _selectedIndex - 2; if (start < 0) start = 0; if (start > maximumStart) start = maximumStart;
    NSInteger row;
    for (row = 0; row < TBClassicVisibleRows; row++) {
        UILabel *label = [_rowLabels objectAtIndex:(NSUInteger)row]; NSInteger itemIndex = start + row;
        UILabel *accessory = [_rowAccessoryLabels objectAtIndex:(NSUInteger)row];
        if (itemIndex < count) {
            BOOL selected = itemIndex == _selectedIndex; id item = [_currentItems objectAtIndex:(NSUInteger)itemIndex];
            NSString *title = [self titleForItem:item atIndex:itemIndex];
            BOOL submenu = [self itemIsSubmenuAtIndex:itemIndex];
            label.hidden = NO; label.backgroundColor = selected ? [TBTheme selectionColor] : [UIColor clearColor];
            label.textColor = selected ? [UIColor whiteColor] : [TBTheme primaryTextColor];
            label.font = selected ? [UIFont boldSystemFontOfSize:14] : [UIFont systemFontOfSize:14];
            label.text = [NSString stringWithFormat:@"  %@", title];
            accessory.hidden = !submenu; accessory.backgroundColor = [UIColor clearColor];
            accessory.textColor = label.textColor;
        } else { label.hidden = YES; accessory.hidden = YES; }
    }
    _statusLabel.text = count ? [NSString stringWithFormat:@"%ld of %ld", (long)_selectedIndex + 1, (long)count]
        : ([[TBLibraryManager sharedManager] mediaItemsReady] ? @"No Items" : @"Loading Library…");
}

- (void)pushScreen:(TBClassicScreenType)type title:(NSString *)title items:(NSArray *)items {
    NSDictionary *state = [NSDictionary dictionaryWithObjectsAndKeys:
        [NSNumber numberWithInteger:_screenType], TBClassicStateTypeKey,
        (_screenTitle ? _screenTitle : @""), TBClassicStateTitleKey,
        (_currentItems ? _currentItems : [NSArray array]), TBClassicStateItemsKey,
        [NSNumber numberWithInteger:_selectedIndex], TBClassicStateSelectionKey, nil];
    [_navigationStack addObject:state];
    [_screenTitle release]; _screenTitle = [title copy];
    [_currentItems release]; _currentItems = [(items ? items : [NSArray array]) retain];
    _screenType = type; _selectedIndex = 0;
    TBPerformanceLog(@"Touchbox Classic screen: %@", title); [self updateDisplay];
}

- (void)popScreen {
    if (![_navigationStack count]) {
        TBPerformanceLog(@"Touchbox Classic: Menu at root, returning to Standard");
        [(AppDelegate *)[UIApplication sharedApplication].delegate showStandardMode]; return;
    }
    NSDictionary *state = [[_navigationStack lastObject] retain]; [_navigationStack removeLastObject];
    _screenType = [[state objectForKey:TBClassicStateTypeKey] integerValue];
    [_screenTitle release]; _screenTitle = [[state objectForKey:TBClassicStateTitleKey] copy];
    [_currentItems release]; _currentItems = [[state objectForKey:TBClassicStateItemsKey] retain];
    _selectedIndex = [[state objectForKey:TBClassicStateSelectionKey] integerValue];
    if (_screenType == TBClassicScreenArtists) { [_currentItems release]; _currentItems = [[[TBLibraryManager sharedManager] artistGroups] retain]; }
    else if (_screenType == TBClassicScreenAlbums || _screenType == TBClassicScreenCoverFlow) { [_currentItems release]; _currentItems = [[self allAlbums] retain]; }
    [state release]; TBPerformanceLog(@"Touchbox Classic: Menu back to %@", _screenTitle); [self updateDisplay];
}

- (void)selectCurrentItem {
    if (_screenType == TBClassicScreenNowPlaying) {
        [self pushScreen:TBClassicScreenTrackOptions title:@"Track Options"
            items:[self trackOptions]];
        return;
    }
    if (![_currentItems count]) return;
    id item = [_currentItems objectAtIndex:(NSUInteger)_selectedIndex];
    TBPerformanceLog(@"Touchbox Classic: Center selected: %@", [self titleForItem:item atIndex:_selectedIndex]);
    if (_screenType == TBClassicScreenRoot) {
        [[NSUserDefaults standardUserDefaults] setInteger:_selectedIndex forKey:TBClassicRootSelectionDefaultsKey];
        if (_selectedIndex == 0) [self pushScreen:TBClassicScreenMusic title:@"Music"
            items:[NSArray arrayWithObjects:@"Artists", @"Albums", @"Cover Flow", @"Songs", @"Playlists", @"Favorites", nil]];
        else if (_selectedIndex == 1) [self pushScreen:TBClassicScreenFavorites title:@"Favorites"
            items:[self shuffleListWithTracks:[self favoriteItems]]];
        else if (_selectedIndex == 2) [self pushScreen:TBClassicScreenRecent title:@"Recent"
            items:[NSArray arrayWithObjects:@"Recently Played", @"Recently Added", nil]];
        else if (_selectedIndex == 3) [self pushScreen:TBClassicScreenQueue title:@"Queue"
            items:[TBPlayerManager sharedManager].queueItems];
        else if (_selectedIndex == 4) {
            if ([TBPlayerManager sharedManager].musicPlayer.nowPlayingItem)
                [self pushScreen:TBClassicScreenNowPlaying title:@"Now Playing" items:[NSArray array]];
            else _statusLabel.text = @"Nothing is playing";
        }
        else [self pushScreen:TBClassicScreenSettings title:@"Settings"
            items:[NSArray arrayWithObjects:@"Theme", @"Standard Mode", nil]];
    } else if (_screenType == TBClassicScreenMusic) {
        if (_selectedIndex == 0) [self pushScreen:TBClassicScreenArtists title:@"Artists"
            items:[[TBLibraryManager sharedManager] artistGroups]];
        else if (_selectedIndex == 1) [self pushScreen:TBClassicScreenAlbums title:@"Albums" items:[self allAlbums]];
        else if (_selectedIndex == 2) [self pushScreen:TBClassicScreenCoverFlow title:@"Cover Flow" items:[self allAlbums]];
        else if (_selectedIndex == 3) [self pushScreen:TBClassicScreenSongs title:@"Songs" items:[self shuffleListWithTracks:[[TBLibraryManager sharedManager] songs]]];
        else if (_selectedIndex == 4) [self pushScreen:TBClassicScreenPlaylists title:@"Playlists" items:[NSArray arrayWithObjects:@"Touchbox Playlists", @"System Playlists", nil]];
        else [self pushScreen:TBClassicScreenFavorites title:@"Favorites" items:[self shuffleListWithTracks:[self favoriteItems]]];
    } else if (_screenType == TBClassicScreenArtists) {
        [self pushScreen:TBClassicScreenArtistAlbums title:[item objectForKey:TBArtistNameKey]
            items:[self artistAlbumMenuItems:[item objectForKey:TBAlbumsKey]]];
    } else if (_screenType == TBClassicScreenArtistAlbums || _screenType == TBClassicScreenAlbums || _screenType == TBClassicScreenCoverFlow) {
        if (![[TBLibraryManager sharedManager] mediaItemsReady]) { _statusLabel.text = @"Tracks are still loading…"; return; }
        if (_screenType == TBClassicScreenArtistAlbums && _selectedIndex == 0) {
            NSMutableArray *tracks = [NSMutableArray array]; NSUInteger albumIndex;
            for (albumIndex = 1; albumIndex < [_currentItems count]; albumIndex++)
                [tracks addObjectsFromArray:[[_currentItems objectAtIndex:albumIndex] objectForKey:TBAlbumItemsKey]];
            if ([tracks count]) { [[TBPlayerManager sharedManager] playItemsShuffled:tracks]; [self pushScreen:TBClassicScreenNowPlaying title:@"Now Playing" items:[NSArray array]]; }
            return;
        }
        [self pushScreen:TBClassicScreenAlbumTracks title:[item objectForKey:TBAlbumTitleKey]
            items:[self shuffleListWithTracks:[item objectForKey:TBAlbumItemsKey]]];
    } else if (_screenType == TBClassicScreenAlbumTracks || _screenType == TBClassicScreenSongs) {
        NSArray *tracks = [self tracksFromShuffleList:_currentItems];
        if (_selectedIndex == 0) [[TBPlayerManager sharedManager] playItemsShuffled:tracks];
        else [[TBPlayerManager sharedManager] playItems:tracks startingAtItem:item];
        if ([tracks count]) [self pushScreen:TBClassicScreenNowPlaying title:@"Now Playing" items:[NSArray array]];
    } else if (_screenType == TBClassicScreenFavorites || _screenType == TBClassicScreenRecentTracks || _screenType == TBClassicScreenPlaylistTracks) {
        NSArray *tracks = [self tracksFromShuffleList:_currentItems];
        if (_selectedIndex == 0) { if ([tracks count]) { [[TBPlayerManager sharedManager] playItemsShuffled:tracks]; [self pushScreen:TBClassicScreenNowPlaying title:@"Now Playing" items:[NSArray array]]; } }
        else { [[TBPlayerManager sharedManager] playItems:tracks startingAtItem:item]; [self pushScreen:TBClassicScreenNowPlaying title:@"Now Playing" items:[NSArray array]]; }
    } else if (_screenType == TBClassicScreenPlaylists) {
        if (_selectedIndex == 0) [self pushScreen:TBClassicScreenUserPlaylists title:@"Touchbox Playlists" items:[self userPlaylistMenuItems]];
        else [self pushScreen:TBClassicScreenSystemPlaylists title:@"System Playlists" items:[[TBLibraryManager sharedManager] playlists]];
    } else if (_screenType == TBClassicScreenUserPlaylists) {
        if ([item isKindOfClass:[NSString class]]) [self presentPlaylistNameForCurrentItem:NO];
        else { NSArray *tracks = [[TBLibraryManager sharedManager] itemsForPersistentIDs:[item objectForKey:TBUserPlaylistTrackIDsKey]];
            [self pushScreen:TBClassicScreenPlaylistTracks title:[item objectForKey:TBUserPlaylistNameKey] items:[self shuffleListWithTracks:tracks]]; }
    } else if (_screenType == TBClassicScreenSystemPlaylists) {
        if (_loadingClassicPlaylist) return; _loadingClassicPlaylist = YES; _statusLabel.text = @"Loading Tracks…";
        [self performSelectorInBackground:@selector(loadClassicSystemPlaylist:) withObject:item];
    } else if (_screenType == TBClassicScreenRecent) {
        NSArray *tracks = _selectedIndex == 0 ? [[TBRecentManager sharedManager] recentlyPlayedItems] : [[TBRecentManager sharedManager] recentlyAddedItems];
        [self pushScreen:TBClassicScreenRecentTracks title:item items:[self shuffleListWithTracks:tracks]];
    } else if (_screenType == TBClassicScreenQueue) {
        [[TBPlayerManager sharedManager] playQueueItemAtIndex:_selectedIndex];
        [self pushScreen:TBClassicScreenNowPlaying title:@"Now Playing" items:[NSArray array]];
    } else if (_screenType == TBClassicScreenTrackOptions) {
        MPMediaItem *current = [TBPlayerManager sharedManager].musicPlayer.nowPlayingItem;
        if (_selectedIndex == 0) { [[TBFavoritesManager sharedManager] toggleFavoriteItem:current]; _statusLabel.text = @"Favorite updated"; }
        else if (_selectedIndex == 1) [self pushScreen:TBClassicScreenAddToPlaylist title:@"Add to Playlist" items:[self userPlaylistMenuItems]];
        else if (_selectedIndex == 2) { [[TBPlayerManager sharedManager] playNextItem:current]; _statusLabel.text = @"Added next"; }
        else if (_selectedIndex == 3) [self pushScreen:TBClassicScreenQueue title:@"Queue" items:[TBPlayerManager sharedManager].queueItems];
        else if (_selectedIndex == 4) { [[TBPlayerManager sharedManager] toggleShuffle]; _statusLabel.text = [TBPlayerManager sharedManager].shuffleEnabled ? @"Shuffle On" : @"Shuffle Off"; }
        else { [[TBPlayerManager sharedManager] toggleRepeatOne]; _statusLabel.text = [TBPlayerManager sharedManager].repeatOneEnabled ? @"Repeat One" : @"Repeat Off"; }
        if (_screenType == TBClassicScreenTrackOptions) { [_currentItems release]; _currentItems = [[self trackOptions] retain]; [self updateDisplay]; }
    } else if (_screenType == TBClassicScreenAddToPlaylist) {
        if ([item isKindOfClass:[NSString class]]) [self presentPlaylistNameForCurrentItem:YES];
        else { BOOL added = [[TBUserPlaylistManager sharedManager] addItem:[TBPlayerManager sharedManager].musicPlayer.nowPlayingItem toPlaylistID:[item objectForKey:TBUserPlaylistIDKey]]; _statusLabel.text = added ? @"Added to playlist" : @"Already in playlist"; }
    } else if (_screenType == TBClassicScreenSettings) {
        if (_selectedIndex == 0) {
            TBThemeViewController *theme = [[TBThemeViewController alloc] initWithDismissButton:YES];
            UINavigationController *navigation = [[UINavigationController alloc] initWithRootViewController:theme];
            navigation.navigationBar.tintColor = [TBTheme navigationBarColor]; [theme release];
            [self presentModalViewController:navigation animated:YES]; [navigation release];
        } else [(AppDelegate *)[UIApplication sharedApplication].delegate showStandardMode];
    }
}

- (NSString *)timeString:(NSTimeInterval)time negative:(BOOL)negative {
    if (time < 0) time = 0; NSUInteger seconds = (NSUInteger)time;
    return [NSString stringWithFormat:negative ? @"-%u:%02u" : @"%u:%02u",
        (unsigned)(seconds / 60), (unsigned)(seconds % 60)];
}
- (void)startProgressTimer {
    if (_progressTimer || !_visible ||
        [UIApplication sharedApplication].applicationState != UIApplicationStateActive) return;
    _progressTimer = [[NSTimer scheduledTimerWithTimeInterval:1.0 target:self
        selector:@selector(progressTimerFired:) userInfo:nil repeats:YES] retain];
}
- (void)stopProgressTimer { [_progressTimer invalidate]; [_progressTimer release]; _progressTimer = nil; }
- (void)progressTimerFired:(NSTimer *)timer {
    if (!_visible || !self.view.window || _screenType != TBClassicScreenNowPlaying ||
        [UIApplication sharedApplication].applicationState != UIApplicationStateActive) { [self stopProgressTimer]; return; }
    [self updateProgress];
}
- (void)updateProgress {
    if (!_visible || !self.view.window || _screenType != TBClassicScreenNowPlaying) return;
    if (_classicSeekChanged) return;
    MPMusicPlayerController *player = [TBPlayerManager sharedManager].musicPlayer;
    NSTimeInterval duration = [[player.nowPlayingItem valueForProperty:MPMediaItemPropertyPlaybackDuration] doubleValue];
    NSTimeInterval elapsed = player.currentPlaybackTime; if (elapsed < 0) elapsed = 0;
    CGFloat fraction = duration > 0 ? MIN(1.0f, (CGFloat)(elapsed / duration)) : 0;
    _progressFillView.frame = CGRectMake(0, 0,
        _progressFillView.superview.bounds.size.width * fraction, 3);
    _nowPlayingElapsedLabel.text = [self timeString:elapsed negative:NO];
    _nowPlayingRemainingLabel.text = [self timeString:MAX(duration - elapsed, 0) negative:YES];
}

- (void)updateProgressForElapsed:(NSTimeInterval)elapsed duration:(NSTimeInterval)duration {
    CGFloat fraction = duration > 0 ? MIN(1.0f, MAX(0.0f, (CGFloat)(elapsed / duration))) : 0;
    _progressFillView.frame = CGRectMake(0, 0,
        _progressFillView.superview.bounds.size.width * fraction, 3);
    _nowPlayingElapsedLabel.text = [self timeString:elapsed negative:NO];
    _nowPlayingRemainingLabel.text = [self timeString:MAX(duration - elapsed, 0) negative:YES];
}
- (void)updateNowPlaying {
    TBPlayerManager *manager = [TBPlayerManager sharedManager]; MPMediaItem *item = manager.musicPlayer.nowPlayingItem;
    NSString *title = [item valueForProperty:MPMediaItemPropertyTitle]; NSString *artist = [item valueForProperty:MPMediaItemPropertyArtist]; NSString *album = [item valueForProperty:MPMediaItemPropertyAlbumTitle];
    _nowPlayingTitleLabel.text = title ? title : @"Unknown Title";
    _nowPlayingArtistLabel.text = artist ? artist : @"Unknown Artist";
    _nowPlayingAlbumLabel.text = album ? album : @"Unknown Album";
    NSInteger queueIndex = manager.currentQueueIndex; NSInteger queueCount = (NSInteger)[manager.queueItems count];
    _titleLabel.text = @"  Now Playing";
    _queuePositionLabel.text = queueIndex == NSNotFound ? @"" :
        [NSString stringWithFormat:@"%ld/%ld", (long)queueIndex + 1, (long)queueCount];
    CGSize artworkSize = _nowPlayingArtworkView.bounds.size;
    _nowPlayingArtworkView.image = [TBIconFactory artworkPlaceholderWithSize:artworkSize];
    NSNumber *number = [item valueForProperty:MPMediaItemPropertyPersistentID];
    [_nowPlayingArtworkKey release]; _nowPlayingArtworkKey = number ? [[NSString stringWithFormat:@"classic-%llu-%u", [number unsignedLongLongValue], (unsigned)artworkSize.width] copy] : nil;
    UIImage *image = [[TBArtworkCache sharedCache] cachedImageForKey:_nowPlayingArtworkKey];
    if (image) _nowPlayingArtworkView.image = image;
    else if (item) [[TBArtworkCache sharedCache] requestImageForItem:item size:artworkSize
        key:_nowPlayingArtworkKey target:self selector:@selector(nowPlayingArtworkLoaded:)];
    [self updateProgress];
}
- (void)nowPlayingArtworkLoaded:(NSDictionary *)result {
    if (!_visible || !self.view.window || _screenType != TBClassicScreenNowPlaying) return;
    if (![_nowPlayingArtworkKey isEqualToString:[result objectForKey:@"key"]]) return;
    id image = [result objectForKey:@"image"];
    if (image != [NSNull null]) _nowPlayingArtworkView.image = image;
}
- (void)playerItemChanged:(NSNotification *)notification { if (_visible && self.view.window && [UIApplication sharedApplication].applicationState == UIApplicationStateActive && _screenType == TBClassicScreenNowPlaying) [self updateNowPlaying]; }
- (void)playerStateChanged:(NSNotification *)notification { if (_visible && self.view.window && [UIApplication sharedApplication].applicationState == UIApplicationStateActive && _screenType == TBClassicScreenNowPlaying) [self updateProgress]; }

- (void)libraryIndexReady:(NSNotification *)notification {
    if (_screenType == TBClassicScreenArtists) { [_currentItems release]; _currentItems = [[[TBLibraryManager sharedManager] artistGroups] retain]; }
    else if (_screenType == TBClassicScreenAlbums || _screenType == TBClassicScreenCoverFlow) { [_currentItems release]; _currentItems = [[self allAlbums] retain]; }
    else if (_screenType == TBClassicScreenArtistAlbums) {
        NSArray *groups = [[TBLibraryManager sharedManager] artistGroups]; NSUInteger index;
        for (index = 0; index < [groups count]; index++) {
            NSDictionary *group = [groups objectAtIndex:index];
            if ([[group objectForKey:TBArtistNameKey] isEqualToString:_screenTitle]) {
                [_currentItems release]; _currentItems = [[self artistAlbumMenuItems:[group objectForKey:TBAlbumsKey]] retain]; break;
            }
        }
    }
    if (_visible && [UIApplication sharedApplication].applicationState == UIApplicationStateActive) [self updateDisplay];
}
- (void)librarySongsReady:(NSNotification *)notification {
    if (_screenType == TBClassicScreenSongs) { [_currentItems release]; _currentItems = [[self shuffleListWithTracks:[[TBLibraryManager sharedManager] songs]] retain]; if (_visible && [UIApplication sharedApplication].applicationState == UIApplicationStateActive) [self updateDisplay]; }
}
- (void)sharedDataChanged:(NSNotification *)notification {
    NSArray *items = nil;
    if (_screenType == TBClassicScreenFavorites) items = [self shuffleListWithTracks:[self favoriteItems]];
    else if (_screenType == TBClassicScreenUserPlaylists || _screenType == TBClassicScreenAddToPlaylist) items = [self userPlaylistMenuItems];
    else if (_screenType == TBClassicScreenSystemPlaylists) items = [[TBLibraryManager sharedManager] playlists];
    else if (_screenType == TBClassicScreenQueue) items = [TBPlayerManager sharedManager].queueItems;
    else if (_screenType == TBClassicScreenRecentTracks) {
        items = [self shuffleListWithTracks:[_screenTitle isEqualToString:@"Recently Played"]
            ? [[TBRecentManager sharedManager] recentlyPlayedItems] : [[TBRecentManager sharedManager] recentlyAddedItems]];
    }
    if (items) { [_currentItems release]; _currentItems = [items retain]; if (_visible && [UIApplication sharedApplication].applicationState == UIApplicationStateActive) [self updateDisplay]; }
}

- (void)clickWheel:(TBClickWheelView *)wheel didRotateBySteps:(NSInteger)steps {
    if (_screenType == TBClassicScreenNowPlaying) {
        if (!steps) return;
        TBPlayerManager *manager = [TBPlayerManager sharedManager];
        MPMediaItem *item = manager.musicPlayer.nowPlayingItem;
        NSTimeInterval duration = [[item valueForProperty:MPMediaItemPropertyPlaybackDuration] doubleValue];
        if (!item || duration <= 0) return;
        NSTimeInterval current = _classicSeekChanged ? _classicSeekPosition : manager.musicPlayer.currentPlaybackTime;
        NSTimeInterval target = current + (NSTimeInterval)steps * 5.0;
        target = MAX(0.0, MIN(duration, target));
        if (fabs(target - current) < 0.5) return;
        if (!_classicSeekChanged) [manager beginInteractiveSeek];
        _classicSeekPosition = target;
        [manager seekToTimeWithoutSaving:target];
        _classicSeekChanged = YES;
        [self updateProgressForElapsed:target duration:duration];
        return;
    }
    NSInteger count = (NSInteger)[_currentItems count]; if (!count) return;
    NSInteger next = _selectedIndex + steps; if (next < 0) next = 0; if (next >= count) next = count - 1;
    if (next != _selectedIndex) { _selectedIndex = next;
        if (_screenType == TBClassicScreenRoot) [[NSUserDefaults standardUserDefaults]
            setInteger:_selectedIndex forKey:TBClassicRootSelectionDefaultsKey];
        if (_screenType == TBClassicScreenCoverFlow) [_coverFlowView selectIndex:_selectedIndex animated:YES];
        else [self updateDisplay]; }
}
- (void)clickWheelDidEndRotation:(TBClickWheelView *)wheel {
    if (_classicSeekChanged) {
        [[TBPlayerManager sharedManager] endInteractiveSeek];
        _classicSeekChanged = NO;
        _classicSeekPosition = 0;
    }
}
- (void)clickWheelDidSelect:(TBClickWheelView *)wheel { [self selectCurrentItem]; }
- (void)clickWheelDidPressMenu:(TBClickWheelView *)wheel { [self popScreen]; }
- (void)clickWheelDidPressPrevious:(TBClickWheelView *)wheel { [[TBPlayerManager sharedManager] previous]; }
- (void)clickWheelDidPressNext:(TBClickWheelView *)wheel { [[TBPlayerManager sharedManager] next]; }
- (void)clickWheelDidPressPlayPause:(TBClickWheelView *)wheel { [[TBPlayerManager sharedManager] togglePlayPause]; }
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)orientation { return orientation == UIInterfaceOrientationPortrait; }
- (void)didReceiveMemoryWarning {
    if (_screenType != TBClassicScreenNowPlaying) [[TBArtworkCache sharedCache] removeAllImages];
    [super didReceiveMemoryWarning];
}
- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self]; _wheelView.delegate = nil;
    [self stopProgressTimer];
    [_wheelView release]; [_coverFlowView release]; [_navigationStack release]; [_currentItems release]; [_screenTitle release];
    [_rowLabels release]; [_rowAccessoryLabels release]; [_titleLabel release]; [_queuePositionLabel release]; [_statusLabel release];
    [_nowPlayingView release]; [_nowPlayingArtworkView release]; [_nowPlayingTitleLabel release];
    [_nowPlayingArtistLabel release]; [_nowPlayingAlbumLabel release];
    [_nowPlayingElapsedLabel release]; [_nowPlayingRemainingLabel release];
    [_progressFillView release]; [_nowPlayingArtworkKey release]; [super dealloc];
}
@end
