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
#import "AppDelegate.h"

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
    TBClassicScreenAddToPlaylist
} TBClassicScreenType;

@implementation TBClassicViewController

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
    }
    return self;
}

- (void)loadView {
    UIView *root = [[UIView alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    root.backgroundColor = [UIColor colorWithWhite:0.88f alpha:1.0f]; self.view = root; [root release];
    UIView *display = [[[UIView alloc] initWithFrame:CGRectMake(0, 0, 320, 220)] autorelease];
    display.backgroundColor = [UIColor colorWithWhite:0.97f alpha:1.0f]; [self.view addSubview:display];
    _titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 320, 30)];
    _titleLabel.backgroundColor = [UIColor colorWithWhite:0.90f alpha:1.0f];
    _titleLabel.font = [UIFont boldSystemFontOfSize:14];
    _titleLabel.textColor = [UIColor colorWithWhite:0.15f alpha:1.0f]; [display addSubview:_titleLabel];
    _rowLabels = [[NSMutableArray alloc] initWithCapacity:TBClassicVisibleRows]; NSInteger i;
    for (i = 0; i < TBClassicVisibleRows; i++) {
        UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(8, 31 + i * 29, 304, 29)];
        label.font = [UIFont boldSystemFontOfSize:14]; label.lineBreakMode = UILineBreakModeTailTruncation;
        [display addSubview:label]; [_rowLabels addObject:label]; [label release];
    }
    _statusLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 205, 320, 15)];
    _statusLabel.backgroundColor = [UIColor colorWithWhite:0.92f alpha:1.0f];
    _statusLabel.font = [UIFont systemFontOfSize:10]; _statusLabel.textColor = [UIColor darkGrayColor];
    _statusLabel.textAlignment = UITextAlignmentCenter; [display addSubview:_statusLabel];
    _nowPlayingView = [[UIView alloc] initWithFrame:CGRectMake(0, 30, 320, 175)];
    _nowPlayingView.backgroundColor = [UIColor colorWithWhite:0.97f alpha:1.0f];
    _nowPlayingView.hidden = YES; [display addSubview:_nowPlayingView];
    _nowPlayingArtworkView = [[UIImageView alloc] initWithFrame:CGRectMake(10, 8, 100, 100)];
    _nowPlayingArtworkView.contentMode = UIViewContentModeScaleAspectFit;
    _nowPlayingArtworkView.image = [TBIconFactory artworkPlaceholderWithSize:CGSizeMake(100, 100)];
    [_nowPlayingView addSubview:_nowPlayingArtworkView];
    _nowPlayingTitleLabel = [[UILabel alloc] initWithFrame:CGRectMake(122, 12, 188, 40)];
    _nowPlayingTitleLabel.numberOfLines = 2; _nowPlayingTitleLabel.font = [UIFont boldSystemFontOfSize:15];
    _nowPlayingTitleLabel.backgroundColor = [UIColor clearColor]; _nowPlayingTitleLabel.lineBreakMode = UILineBreakModeTailTruncation;
    [_nowPlayingView addSubview:_nowPlayingTitleLabel];
    _nowPlayingArtistLabel = [[UILabel alloc] initWithFrame:CGRectMake(122, 57, 188, 20)];
    _nowPlayingArtistLabel.font = [UIFont systemFontOfSize:12]; _nowPlayingArtistLabel.textColor = [UIColor darkGrayColor];
    _nowPlayingArtistLabel.backgroundColor = [UIColor clearColor]; _nowPlayingArtistLabel.lineBreakMode = UILineBreakModeTailTruncation;
    [_nowPlayingView addSubview:_nowPlayingArtistLabel];
    _nowPlayingAlbumLabel = [[UILabel alloc] initWithFrame:CGRectMake(122, 79, 188, 20)];
    _nowPlayingAlbumLabel.font = [UIFont systemFontOfSize:11]; _nowPlayingAlbumLabel.textColor = [UIColor grayColor];
    _nowPlayingAlbumLabel.backgroundColor = [UIColor clearColor]; _nowPlayingAlbumLabel.lineBreakMode = UILineBreakModeTailTruncation;
    [_nowPlayingView addSubview:_nowPlayingAlbumLabel];
    UIView *progressTrack = [[[UIView alloc] initWithFrame:CGRectMake(50, 130, 220, 3)] autorelease];
    progressTrack.backgroundColor = [UIColor colorWithWhite:0.78f alpha:1.0f]; [_nowPlayingView addSubview:progressTrack];
    _progressFillView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 0, 3)];
    _progressFillView.backgroundColor = [UIColor colorWithRed:0.18f green:0.42f blue:0.72f alpha:1.0f]; [progressTrack addSubview:_progressFillView];
    _nowPlayingElapsedLabel = [[UILabel alloc] initWithFrame:CGRectMake(10, 140, 70, 18)];
    _nowPlayingRemainingLabel = [[UILabel alloc] initWithFrame:CGRectMake(240, 140, 70, 18)];
    NSArray *timeLabels = [NSArray arrayWithObjects:_nowPlayingElapsedLabel, _nowPlayingRemainingLabel, nil];
    NSUInteger timeIndex; for (timeIndex = 0; timeIndex < [timeLabels count]; timeIndex++) { UILabel *label = [timeLabels objectAtIndex:timeIndex]; label.font = [UIFont systemFontOfSize:10]; label.textColor = [UIColor darkGrayColor]; label.backgroundColor = [UIColor clearColor]; }
    _nowPlayingRemainingLabel.textAlignment = UITextAlignmentRight;
    [_nowPlayingView addSubview:_nowPlayingElapsedLabel]; [_nowPlayingView addSubview:_nowPlayingRemainingLabel];
    UIView *divider = [[[UIView alloc] initWithFrame:CGRectMake(0, 219, 320, 1)] autorelease];
    divider.backgroundColor = [UIColor colorWithWhite:0.55f alpha:1.0f]; [self.view addSubview:divider];
    _wheelView = [[TBClickWheelView alloc] initWithFrame:CGRectMake(0, 220, 320, 260)];
    _wheelView.delegate = self; [self.view addSubview:_wheelView]; [self updateDisplay];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    NSLog(@"Touchbox Classic: enter Phase 2 navigation, screen=%@", _screenTitle);
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
    _nowPlayingView.hidden = !nowPlaying; _statusLabel.hidden = nowPlaying;
    NSInteger hiddenRow; for (hiddenRow = 0; hiddenRow < TBClassicVisibleRows; hiddenRow++)
        ((UILabel *)[_rowLabels objectAtIndex:(NSUInteger)hiddenRow]).hidden = nowPlaying;
    if (nowPlaying) { [self updateNowPlaying]; [self startProgressTimer]; return; }
    [self stopProgressTimer];
    NSInteger count = (NSInteger)[_currentItems count];
    if (count == 0) _selectedIndex = 0; else if (_selectedIndex >= count) _selectedIndex = count - 1;
    NSInteger maximumStart = MAX(0, count - TBClassicVisibleRows);
    NSInteger start = _selectedIndex - 2; if (start < 0) start = 0; if (start > maximumStart) start = maximumStart;
    NSInteger row;
    for (row = 0; row < TBClassicVisibleRows; row++) {
        UILabel *label = [_rowLabels objectAtIndex:(NSUInteger)row]; NSInteger itemIndex = start + row;
        if (itemIndex < count) {
            BOOL selected = itemIndex == _selectedIndex; id item = [_currentItems objectAtIndex:(NSUInteger)itemIndex];
            NSString *title = [self titleForItem:item atIndex:itemIndex];
            label.hidden = NO; label.backgroundColor = selected ? [UIColor colorWithRed:0.18f green:0.42f blue:0.72f alpha:1.0f] : [UIColor clearColor];
            label.textColor = selected ? [UIColor whiteColor] : [UIColor colorWithWhite:0.12f alpha:1.0f];
            label.text = [NSString stringWithFormat:@"  %@%@", title, [self itemIsSubmenuAtIndex:itemIndex] ? @"  >" : @""];
        } else label.hidden = YES;
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
    NSLog(@"Touchbox Classic screen: %@", title); [self updateDisplay];
}

- (void)popScreen {
    if (![_navigationStack count]) {
        NSLog(@"Touchbox Classic: Menu at root, returning to Standard");
        [(AppDelegate *)[UIApplication sharedApplication].delegate showStandardMode]; return;
    }
    NSDictionary *state = [[_navigationStack lastObject] retain]; [_navigationStack removeLastObject];
    _screenType = [[state objectForKey:TBClassicStateTypeKey] integerValue];
    [_screenTitle release]; _screenTitle = [[state objectForKey:TBClassicStateTitleKey] copy];
    [_currentItems release]; _currentItems = [[state objectForKey:TBClassicStateItemsKey] retain];
    _selectedIndex = [[state objectForKey:TBClassicStateSelectionKey] integerValue];
    if (_screenType == TBClassicScreenArtists) { [_currentItems release]; _currentItems = [[[TBLibraryManager sharedManager] artistGroups] retain]; }
    else if (_screenType == TBClassicScreenAlbums) { [_currentItems release]; _currentItems = [[self allAlbums] retain]; }
    [state release]; NSLog(@"Touchbox Classic: Menu back to %@", _screenTitle); [self updateDisplay];
}

- (void)selectCurrentItem {
    if (_screenType == TBClassicScreenNowPlaying) {
        [self pushScreen:TBClassicScreenTrackOptions title:@"Track Options"
            items:[self trackOptions]];
        return;
    }
    if (![_currentItems count]) return;
    id item = [_currentItems objectAtIndex:(NSUInteger)_selectedIndex];
    NSLog(@"Touchbox Classic: Center selected: %@", [self titleForItem:item atIndex:_selectedIndex]);
    if (_screenType == TBClassicScreenRoot) {
        [[NSUserDefaults standardUserDefaults] setInteger:_selectedIndex forKey:TBClassicRootSelectionDefaultsKey];
        if (_selectedIndex == 0) [self pushScreen:TBClassicScreenMusic title:@"Music"
            items:[NSArray arrayWithObjects:@"Artists", @"Albums", @"Songs", @"Playlists", @"Favorites", nil]];
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
            items:[NSArray arrayWithObject:@"Standard Mode"]];
    } else if (_screenType == TBClassicScreenMusic) {
        if (_selectedIndex == 0) [self pushScreen:TBClassicScreenArtists title:@"Artists"
            items:[[TBLibraryManager sharedManager] artistGroups]];
        else if (_selectedIndex == 1) [self pushScreen:TBClassicScreenAlbums title:@"Albums" items:[self allAlbums]];
        else if (_selectedIndex == 2) [self pushScreen:TBClassicScreenSongs title:@"Songs" items:[self shuffleListWithTracks:[[TBLibraryManager sharedManager] songs]]];
        else if (_selectedIndex == 3) [self pushScreen:TBClassicScreenPlaylists title:@"Playlists" items:[NSArray arrayWithObjects:@"Touchbox Playlists", @"System Playlists", nil]];
        else [self pushScreen:TBClassicScreenFavorites title:@"Favorites" items:[self shuffleListWithTracks:[self favoriteItems]]];
    } else if (_screenType == TBClassicScreenArtists) {
        [self pushScreen:TBClassicScreenArtistAlbums title:[item objectForKey:TBArtistNameKey]
            items:[self artistAlbumMenuItems:[item objectForKey:TBAlbumsKey]]];
    } else if (_screenType == TBClassicScreenArtistAlbums || _screenType == TBClassicScreenAlbums) {
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
        [(AppDelegate *)[UIApplication sharedApplication].delegate showStandardMode];
    }
}

- (NSString *)timeString:(NSTimeInterval)time negative:(BOOL)negative {
    if (time < 0) time = 0; NSUInteger seconds = (NSUInteger)time;
    return [NSString stringWithFormat:negative ? @"-%u:%02u" : @"%u:%02u",
        (unsigned)(seconds / 60), (unsigned)(seconds % 60)];
}
- (void)startProgressTimer {
    if (_progressTimer) return;
    _progressTimer = [[NSTimer scheduledTimerWithTimeInterval:1.0 target:self
        selector:@selector(progressTimerFired:) userInfo:nil repeats:YES] retain];
}
- (void)stopProgressTimer { [_progressTimer invalidate]; [_progressTimer release]; _progressTimer = nil; }
- (void)progressTimerFired:(NSTimer *)timer { [self updateProgress]; }
- (void)updateProgress {
    MPMusicPlayerController *player = [TBPlayerManager sharedManager].musicPlayer;
    NSTimeInterval duration = [[player.nowPlayingItem valueForProperty:MPMediaItemPropertyPlaybackDuration] doubleValue];
    NSTimeInterval elapsed = player.currentPlaybackTime; if (elapsed < 0) elapsed = 0;
    CGFloat fraction = duration > 0 ? MIN(1.0f, (CGFloat)(elapsed / duration)) : 0;
    _progressFillView.frame = CGRectMake(0, 0, 220.0f * fraction, 3);
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
    _titleLabel.text = queueIndex == NSNotFound ? @"  Now Playing" : [NSString stringWithFormat:@"  Now Playing                         %ld/%ld", (long)queueIndex + 1, (long)queueCount];
    _nowPlayingArtworkView.image = [TBIconFactory artworkPlaceholderWithSize:CGSizeMake(100, 100)];
    NSNumber *number = [item valueForProperty:MPMediaItemPropertyPersistentID];
    [_nowPlayingArtworkKey release]; _nowPlayingArtworkKey = number ? [[NSString stringWithFormat:@"%llu", [number unsignedLongLongValue]] copy] : nil;
    UIImage *image = [[TBArtworkCache sharedCache] cachedImageForKey:_nowPlayingArtworkKey];
    if (image) _nowPlayingArtworkView.image = image;
    else if (item) [[TBArtworkCache sharedCache] requestImageForItem:item size:CGSizeMake(100, 100)
        key:_nowPlayingArtworkKey target:self selector:@selector(nowPlayingArtworkLoaded:)];
    [self updateProgress];
}
- (void)nowPlayingArtworkLoaded:(NSDictionary *)result {
    if (![_nowPlayingArtworkKey isEqualToString:[result objectForKey:@"key"]]) return;
    id image = [result objectForKey:@"image"];
    if (image != [NSNull null]) _nowPlayingArtworkView.image = image;
}
- (void)playerItemChanged:(NSNotification *)notification { if (_screenType == TBClassicScreenNowPlaying) [self updateNowPlaying]; }
- (void)playerStateChanged:(NSNotification *)notification { if (_screenType == TBClassicScreenNowPlaying) [self updateProgress]; }

- (void)libraryIndexReady:(NSNotification *)notification {
    if (_screenType == TBClassicScreenArtists) { [_currentItems release]; _currentItems = [[[TBLibraryManager sharedManager] artistGroups] retain]; }
    else if (_screenType == TBClassicScreenAlbums) { [_currentItems release]; _currentItems = [[self allAlbums] retain]; }
    else if (_screenType == TBClassicScreenArtistAlbums) {
        NSArray *groups = [[TBLibraryManager sharedManager] artistGroups]; NSUInteger index;
        for (index = 0; index < [groups count]; index++) {
            NSDictionary *group = [groups objectAtIndex:index];
            if ([[group objectForKey:TBArtistNameKey] isEqualToString:_screenTitle]) {
                [_currentItems release]; _currentItems = [[self artistAlbumMenuItems:[group objectForKey:TBAlbumsKey]] retain]; break;
            }
        }
    }
    [self updateDisplay];
}
- (void)librarySongsReady:(NSNotification *)notification {
    if (_screenType == TBClassicScreenSongs) { [_currentItems release]; _currentItems = [[self shuffleListWithTracks:[[TBLibraryManager sharedManager] songs]] retain]; [self updateDisplay]; }
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
    if (items) { [_currentItems release]; _currentItems = [items retain]; [self updateDisplay]; }
}

- (void)clickWheel:(TBClickWheelView *)wheel didRotateBySteps:(NSInteger)steps {
    if (_screenType == TBClassicScreenNowPlaying) return;
    NSInteger count = (NSInteger)[_currentItems count]; if (!count) return;
    NSInteger next = _selectedIndex + steps; if (next < 0) next = 0; if (next >= count) next = count - 1;
    if (next != _selectedIndex) { _selectedIndex = next;
        if (_screenType == TBClassicScreenRoot) [[NSUserDefaults standardUserDefaults]
            setInteger:_selectedIndex forKey:TBClassicRootSelectionDefaultsKey];
        [self updateDisplay]; }
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
    [_wheelView release]; [_navigationStack release]; [_currentItems release]; [_screenTitle release];
    [_rowLabels release]; [_titleLabel release]; [_statusLabel release];
    [_nowPlayingView release]; [_nowPlayingArtworkView release]; [_nowPlayingTitleLabel release];
    [_nowPlayingArtistLabel release]; [_nowPlayingAlbumLabel release];
    [_nowPlayingElapsedLabel release]; [_nowPlayingRemainingLabel release];
    [_progressFillView release]; [_nowPlayingArtworkKey release]; [super dealloc];
}
@end
