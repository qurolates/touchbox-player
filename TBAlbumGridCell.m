#import "TBAlbumGridCell.h"
#import "TBLibraryManager.h"
#import "TBArtworkCache.h"
#import "TBTheme.h"
#import "TBIconFactory.h"

@implementation TBAlbumItemControl

@synthesize album = _album;
@synthesize artworkKey = _artworkKey;

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        _artworkView = [[UIImageView alloc] initWithFrame:CGRectMake(4, 0, 133, 133)];
        _artworkView.backgroundColor = [TBTheme placeholderColor];
        _artworkView.image = [TBIconFactory artworkPlaceholderWithSize:CGSizeMake(133, 133)];
        _artworkView.contentMode = UIViewContentModeScaleAspectFit;
        [self addSubview:_artworkView];
        _titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(4, 135, 133, 18)];
        _titleLabel.font = [TBTheme primaryFont];
        _titleLabel.textColor = [TBTheme primaryTextColor];
        _titleLabel.backgroundColor = [TBTheme backgroundColor];
        _titleLabel.lineBreakMode = UILineBreakModeTailTruncation;
        [self addSubview:_titleLabel];
        _artistLabel = [[UILabel alloc] initWithFrame:CGRectMake(4, 153, 133, 16)];
        _artistLabel.font = [TBTheme secondaryFont];
        _artistLabel.textColor = [TBTheme secondaryTextColor];
        _artistLabel.backgroundColor = [TBTheme backgroundColor];
        _artistLabel.lineBreakMode = UILineBreakModeTailTruncation;
        [self addSubview:_artistLabel];
        [self addTarget:self action:@selector(showPressedState:)
            forControlEvents:UIControlEventTouchDown];
        [self addTarget:self action:@selector(clearPressedState:)
            forControlEvents:UIControlEventTouchUpInside | UIControlEventTouchUpOutside |
                             UIControlEventTouchCancel];
    }
    return self;
}

- (void)showPressedState:(id)sender { self.alpha = 0.58f; }
- (void)clearPressedState:(id)sender { self.alpha = 1.0f; }

- (void)configureWithAlbum:(NSDictionary *)album {
    [self resetContent];
    self.backgroundColor = [TBTheme backgroundColor];
    _titleLabel.backgroundColor = [TBTheme backgroundColor]; _titleLabel.textColor = [TBTheme primaryTextColor];
    _artistLabel.backgroundColor = [TBTheme backgroundColor]; _artistLabel.textColor = [TBTheme secondaryTextColor];
    _artworkView.backgroundColor = [TBTheme placeholderColor];
    self.hidden = NO;
    self.album = album;
    _titleLabel.text = [album objectForKey:TBAlbumTitleKey];
    _artistLabel.text = [album objectForKey:TBAlbumArtistKey];
    NSArray *items = [album objectForKey:TBAlbumItemsKey];
    if ([items count] == 0) return;
    MPMediaItem *item = [items objectAtIndex:0];
    NSNumber *persistentID = [item valueForProperty:MPMediaItemPropertyPersistentID];
    self.artworkKey = [NSString stringWithFormat:@"%llu", [persistentID unsignedLongLongValue]];
    UIImage *cached = [[TBArtworkCache sharedCache] cachedImageForKey:_artworkKey];
    if (cached) {
        _artworkView.image = cached;
    } else {
        [[TBArtworkCache sharedCache] requestImageForItem:item size:CGSizeMake(133, 133)
            key:_artworkKey target:self selector:@selector(artworkLoaded:)];
    }
}

- (void)artworkLoaded:(NSDictionary *)result {
    if (![_artworkKey isEqualToString:[result objectForKey:@"key"]]) return;
    id image = [result objectForKey:@"image"];
    _artworkView.image = (image == [NSNull null]) ? nil : image;
}

- (void)resetContent {
    self.album = nil;
    self.artworkKey = nil;
    _artworkView.image = [TBIconFactory artworkPlaceholderWithSize:CGSizeMake(133, 133)];
    _titleLabel.text = nil;
    _artistLabel.text = nil;
}

- (void)dealloc {
    [_artworkView release]; [_titleLabel release]; [_artistLabel release];
    [_album release]; [_artworkKey release];
    [super dealloc];
}

@end

@implementation TBAlbumGridCell

@synthesize leftItem = _leftItem;
@synthesize rightItem = _rightItem;

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)identifier {
    self = [super initWithStyle:style reuseIdentifier:identifier];
    if (self) {
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        self.backgroundColor = [TBTheme backgroundColor];
        self.contentView.backgroundColor = [TBTheme backgroundColor];
        _leftItem = [[TBAlbumItemControl alloc] initWithFrame:CGRectMake(6, 3, 141, 171)];
        _rightItem = [[TBAlbumItemControl alloc] initWithFrame:CGRectMake(153, 3, 141, 171)];
        [self.contentView addSubview:_leftItem];
        [self.contentView addSubview:_rightItem];
    }
    return self;
}

- (void)prepareForReuse {
    [super prepareForReuse];
    [_leftItem resetContent]; [_rightItem resetContent];
    _leftItem.hidden = NO; _rightItem.hidden = NO;
}

- (void)dealloc {
    [_leftItem release]; [_rightItem release];
    [super dealloc];
}

@end
