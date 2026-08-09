#import "TBAlbumViewController.h"
#import "TBLibraryManager.h"
#import "TBPlayerManager.h"
#import "TBArtworkCache.h"
#import "TBIconFactory.h"
#import "TBTheme.h"

@interface TBAlbumTrackCell : UITableViewCell {
    UILabel *_numberLabel;
    UILabel *_trackTitleLabel;
    UILabel *_durationLabel;
    UIImageView *_playingMarker;
}
- (void)setNumber:(NSString *)number title:(NSString *)title duration:(NSString *)duration
          playing:(BOOL)playing;
@end

@implementation TBAlbumTrackCell
- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)identifier {
    self = [super initWithStyle:style reuseIdentifier:identifier];
    if (self) {
        self.backgroundColor = [TBTheme backgroundColor];
        _numberLabel = [[UILabel alloc] initWithFrame:CGRectMake(10, 0, 28, 48)];
        _numberLabel.backgroundColor = [UIColor clearColor];
        _numberLabel.textColor = [TBTheme secondaryTextColor];
        _numberLabel.font = [TBTheme metadataFont];
        _numberLabel.textAlignment = UITextAlignmentRight;
        [self.contentView addSubview:_numberLabel];
        _playingMarker = [[UIImageView alloc] initWithFrame:CGRectMake(40, 10, 28, 28)];
        [self.contentView addSubview:_playingMarker];
        _trackTitleLabel = [[UILabel alloc] initWithFrame:CGRectMake(46, 0, 210, 48)];
        _trackTitleLabel.backgroundColor = [UIColor clearColor];
        _trackTitleLabel.textColor = [TBTheme primaryTextColor];
        _trackTitleLabel.font = [TBTheme primaryFont];
        _trackTitleLabel.lineBreakMode = UILineBreakModeTailTruncation;
        [self.contentView addSubview:_trackTitleLabel];
        _durationLabel = [[UILabel alloc] initWithFrame:CGRectMake(260, 0, 48, 48)];
        _durationLabel.backgroundColor = [UIColor clearColor];
        _durationLabel.textColor = [TBTheme secondaryTextColor];
        _durationLabel.font = [TBTheme metadataFont];
        _durationLabel.textAlignment = UITextAlignmentRight;
        [self.contentView addSubview:_durationLabel];
    }
    return self;
}
- (void)setNumber:(NSString *)number title:(NSString *)title duration:(NSString *)duration
          playing:(BOOL)playing {
    self.backgroundColor = [TBTheme backgroundColor];
    _numberLabel.textColor = [TBTheme secondaryTextColor]; _trackTitleLabel.textColor = [TBTheme primaryTextColor];
    _durationLabel.textColor = [TBTheme secondaryTextColor];
    _numberLabel.text = number;
    _playingMarker.image = playing ? [TBIconFactory iconNamed:@"play" active:YES] : nil;
    _trackTitleLabel.frame = CGRectMake(playing ? 68 : 46, 0, playing ? 190 : 212, 48);
    _trackTitleLabel.text = title;
    _durationLabel.text = duration;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    CGFloat width = self.contentView.bounds.size.width;
    CGFloat rowHeight = self.contentView.bounds.size.height;
    _numberLabel.frame = CGRectMake(10, 0, 28, rowHeight);
    _playingMarker.frame = CGRectMake(40, floorf((rowHeight - 28.0f) * 0.5f), 28, 28);
    _durationLabel.frame = CGRectMake(MAX(252.0f, width - 58.0f), 0, 46, rowHeight);
    CGFloat titleX = _playingMarker.image ? 68.0f : 46.0f;
    _trackTitleLabel.frame = CGRectMake(titleX, 0,
        MAX(40.0f, CGRectGetMinX(_durationLabel.frame) - titleX - 6.0f), rowHeight);
}

- (void)dealloc {
    [_numberLabel release]; [_trackTitleLabel release]; [_durationLabel release]; [_playingMarker release];
    [super dealloc];
}
@end

@implementation TBAlbumViewController

- (void)applyTheme {
    [super applyTheme]; UIView *header = self.tableView.tableHeaderView; header.backgroundColor = [TBTheme backgroundColor];
    if ([self.items count] && ![[self.items objectAtIndex:0] valueForProperty:MPMediaItemPropertyArtwork])
        _albumArtworkView.image = [TBIconFactory artworkPlaceholderWithSize:CGSizeMake(128, 128)];
    BOOL primaryAssigned = NO; NSUInteger index;
    for (index = 0; index < [[header subviews] count]; index++) { UIView *view = [[header subviews] objectAtIndex:index];
        if ([view isKindOfClass:[UILabel class]]) { UILabel *label = (UILabel *)view; label.backgroundColor = [UIColor clearColor]; label.textColor = primaryAssigned ? [TBTheme secondaryTextColor] : [TBTheme primaryTextColor]; primaryAssigned = YES; }
        else if ([view isKindOfClass:[UIButton class]]) { [(UIButton *)view setTitleColor:[TBTheme accentColor] forState:UIControlStateNormal]; [(UIButton *)view setTitleColor:[TBTheme secondaryTextColor] forState:UIControlStateHighlighted]; }
    }
}

- (NSString *)durationString:(NSTimeInterval)duration {
    if (duration < 0) duration = 0;
    NSUInteger seconds = (NSUInteger)duration;
    NSUInteger hours = seconds / 3600;
    NSUInteger minutes = (seconds % 3600) / 60;
    NSUInteger remainder = seconds % 60;
    if (hours > 0) return [NSString stringWithFormat:@"%u:%02u:%02u",
        (unsigned)hours, (unsigned)minutes, (unsigned)remainder];
    return [NSString stringWithFormat:@"%u:%02u", (unsigned)(seconds / 60), (unsigned)remainder];
}

- (id)initWithAlbum:(NSDictionary *)album {
    self = [super initWithTitle:[album objectForKey:TBAlbumTitleKey]
                         items:[album objectForKey:TBAlbumItemsKey]];
    if (self) {
        _album = [album retain];
        self.hidesBottomBarWhenPushed = YES;
        NSString *albumTitle = [album objectForKey:TBAlbumTitleKey];
        if ([albumTitle length] > 20) self.title = @"Album";
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    /* The generic track list installs Shuffle on the left. Album Detail needs
       that slot for UINavigationController's automatic Back button. */
    self.navigationItem.leftBarButtonItem = nil;
    [TBTheme styleTableView:self.tableView];
    UIView *header = [[[UIView alloc] initWithFrame:CGRectMake(0, 0, self.tableView.bounds.size.width, 252)] autorelease];
    header.backgroundColor = [TBTheme backgroundColor];
    _albumArtworkView = [[UIImageView alloc] initWithFrame:CGRectMake(96, 10, 128, 128)];
    _albumArtworkView.center = CGPointMake(header.bounds.size.width * 0.5f, _albumArtworkView.center.y);
    _albumArtworkView.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
    _albumArtworkView.contentMode = UIViewContentModeScaleAspectFit;
    _albumArtworkView.image = [TBIconFactory artworkPlaceholderWithSize:CGSizeMake(128, 128)];
    [header addSubview:_albumArtworkView];

    UILabel *title = [[[UILabel alloc] initWithFrame:CGRectMake(15, 146, 290, 23)] autorelease];
    title.backgroundColor = [UIColor clearColor];
    title.font = [TBTheme sectionTitleFont];
    title.textColor = [TBTheme primaryTextColor];
    title.textAlignment = UITextAlignmentCenter;
    title.lineBreakMode = UILineBreakModeTailTruncation;
    title.text = [_album objectForKey:TBAlbumTitleKey];
    title.frame = CGRectMake([TBTheme contentMargin], 146, MAX(0.0f, header.bounds.size.width - [TBTheme contentMargin] * 2.0f), 23);
    title.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    [header addSubview:title];
    UILabel *artist = [[[UILabel alloc] initWithFrame:CGRectMake(15, 170, 290, 18)] autorelease];
    artist.backgroundColor = [UIColor clearColor];
    artist.font = [TBTheme secondaryFont];
    artist.textColor = [TBTheme secondaryTextColor];
    artist.textAlignment = UITextAlignmentCenter;
    artist.lineBreakMode = UILineBreakModeTailTruncation;
    artist.text = [_album objectForKey:TBAlbumArtistKey];
    artist.frame = CGRectMake([TBTheme contentMargin], 170, MAX(0.0f, header.bounds.size.width - [TBTheme contentMargin] * 2.0f), 18);
    artist.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    [header addSubview:artist];
    UILabel *metadata = [[[UILabel alloc] initWithFrame:CGRectMake(15, 190, 290, 16)] autorelease];
    metadata.backgroundColor = [UIColor clearColor];
    metadata.font = [TBTheme metadataFont];
    metadata.textColor = [TBTheme secondaryTextColor];
    metadata.textAlignment = UITextAlignmentCenter;
    metadata.frame = CGRectMake([TBTheme contentMargin], 190, MAX(0.0f, header.bounds.size.width - [TBTheme contentMargin] * 2.0f), 16);
    metadata.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    NSString *year = nil;
    NSTimeInterval totalDuration = 0;
    if ([self.items count]) {
        NSDate *releaseDate = nil;
        NSUInteger itemIndex;
        for (itemIndex = 0; itemIndex < [self.items count]; itemIndex++) {
            MPMediaItem *albumItem = [self.items objectAtIndex:itemIndex];
            totalDuration += [[albumItem valueForProperty:MPMediaItemPropertyPlaybackDuration] doubleValue];
            if (!releaseDate)
                releaseDate = [albumItem valueForProperty:MPMediaItemPropertyReleaseDate];
        }
        if (releaseDate) {
            NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
            [formatter setDateFormat:@"yyyy"];
            year = [formatter stringFromDate:releaseDate];
            [formatter release];
        }
    }
    NSString *albumDuration = [self durationString:totalDuration];
    metadata.text = [year length]
        ? [NSString stringWithFormat:@"%@ • %lu tracks • %@", year,
            (unsigned long)[self.items count], albumDuration]
        : [NSString stringWithFormat:@"%lu tracks • %@",
            (unsigned long)[self.items count], albumDuration];
    [header addSubview:metadata];
    UIButton *play = [UIButton buttonWithType:UIButtonTypeCustom];
    play.frame = CGRectMake(129, 213, 62, 32);
    play.center = CGPointMake(header.bounds.size.width * 0.5f, play.center.y);
    play.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
    play.titleLabel.font = [TBTheme secondaryFont];
    [play setTitle:@"Play" forState:UIControlStateNormal];
    [play setTitleColor:[TBTheme accentColor] forState:UIControlStateNormal];
    [play setTitleColor:[TBTheme secondaryTextColor] forState:UIControlStateHighlighted];
    [play addTarget:self action:@selector(playAlbum:) forControlEvents:UIControlEventTouchUpInside];
    [header addSubview:play];
    self.tableView.tableHeaderView = header;
    [self requestAlbumArtwork];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.navigationController setToolbarHidden:YES animated:animated];
}

- (void)requestAlbumArtwork {
    if ([self.items count] == 0) return;
    MPMediaItem *item = [self.items objectAtIndex:0];
    NSNumber *number = [item valueForProperty:MPMediaItemPropertyPersistentID];
    [_albumArtworkKey release];
    _albumArtworkKey = [[NSString stringWithFormat:@"%llu", [number unsignedLongLongValue]] copy];
    UIImage *image = [[TBArtworkCache sharedCache] cachedImageForKey:_albumArtworkKey];
    if (image) _albumArtworkView.image = image;
    else [[TBArtworkCache sharedCache] requestImageForItem:item size:CGSizeMake(128, 128)
        key:_albumArtworkKey target:self selector:@selector(albumArtworkLoaded:)];
}

- (void)albumArtworkLoaded:(NSDictionary *)result {
    if (![_albumArtworkKey isEqualToString:[result objectForKey:@"key"]]) return;
    id image = [result objectForKey:@"image"];
    if (image != [NSNull null]) _albumArtworkView.image = image;
}

- (void)playAlbum:(id)sender {
    if ([self.items count]) { [[TBPlayerManager sharedManager]
        playItems:self.items startingAtItem:[self.items objectAtIndex:0]]; [self showNowPlaying:nil]; }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *identifier = @"AlbumTrackCell";
    TBAlbumTrackCell *cell = (TBAlbumTrackCell *)[tableView dequeueReusableCellWithIdentifier:identifier];
    if (!cell) cell = [[[TBAlbumTrackCell alloc] initWithStyle:UITableViewCellStyleDefault
        reuseIdentifier:identifier] autorelease];
    MPMediaItem *item = [self.items objectAtIndex:(NSUInteger)indexPath.row];
    NSNumber *track = [item valueForProperty:MPMediaItemPropertyAlbumTrackNumber];
    NSNumber *itemID = [item valueForProperty:MPMediaItemPropertyPersistentID];
    NSNumber *playingID = [[TBPlayerManager sharedManager].musicPlayer.nowPlayingItem
        valueForProperty:MPMediaItemPropertyPersistentID];
    NSString *trackTitle = [item valueForProperty:MPMediaItemPropertyTitle];
    NSTimeInterval duration = [[item valueForProperty:MPMediaItemPropertyPlaybackDuration] doubleValue];
    [cell setNumber:[track unsignedIntegerValue] ? [track stringValue] : @""
              title:(trackTitle ? trackTitle : @"Unknown Title")
           duration:[self durationString:duration]
            playing:(playingID && [itemID isEqualToNumber:playingID])];
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 48.0f;
}

- (void)didReceiveMemoryWarning {
    _albumArtworkView.image = [TBIconFactory artworkPlaceholderWithSize:CGSizeMake(128, 128)];
    [super didReceiveMemoryWarning];
}

- (void)dealloc {
    [_album release]; [_albumArtworkView release]; [_albumArtworkKey release];
    [super dealloc];
}

@end
