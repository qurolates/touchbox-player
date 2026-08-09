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
        _artworkView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 138, 138)];
        _artworkView.backgroundColor = [TBTheme placeholderColor];
        _artworkView.image = [TBIconFactory artworkPlaceholderWithSize:CGSizeMake(133, 133)];
        _artworkView.contentMode = UIViewContentModeScaleAspectFit;
        [self addSubview:_artworkView];
        _titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 142, 138, 18)];
        _titleLabel.font = [TBTheme primaryFont];
        _titleLabel.textColor = [TBTheme primaryTextColor];
        _titleLabel.backgroundColor = [TBTheme backgroundColor];
        _titleLabel.lineBreakMode = UILineBreakModeTailTruncation;
        [self addSubview:_titleLabel];
        _artistLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 161, 138, 15)];
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

- (void)layoutSubviews {
    [super layoutSubviews];
    CGFloat artworkSize = MAX(1.0f, floorf(self.bounds.size.width));
    _artworkView.frame = CGRectMake(0, 0, artworkSize, artworkSize);
    _titleLabel.frame = CGRectMake(0, artworkSize + 4, artworkSize, 18);
    _artistLabel.frame = CGRectMake(0, artworkSize + 23, artworkSize, 15);
}

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
    CGFloat artworkSize = MAX(1.0f, floorf(self.bounds.size.width));
    self.artworkKey = [NSString stringWithFormat:@"album-%llu-%u",
        [persistentID unsignedLongLongValue], (unsigned)artworkSize];
    UIImage *cached = [[TBArtworkCache sharedCache] cachedImageForKey:_artworkKey];
    if (cached) {
        _artworkView.image = cached;
    } else {
        [[TBArtworkCache sharedCache] requestImageForItem:item size:CGSizeMake(artworkSize, artworkSize)
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
    CGFloat artworkSize = MAX(1.0f, floorf(self.bounds.size.width));
    _artworkView.image = [TBIconFactory artworkPlaceholderWithSize:CGSizeMake(artworkSize, artworkSize)];
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
        _leftItem = [[TBAlbumItemControl alloc] initWithFrame:CGRectMake(8, 4, 138, 176)];
        _rightItem = [[TBAlbumItemControl alloc] initWithFrame:CGRectMake(154, 4, 138, 176)];
        [self.contentView addSubview:_leftItem];
        [self.contentView addSubview:_rightItem];
    }
    return self;
}

- (void)layoutForWidth:(CGFloat)width {
    CGFloat margin = 8.0f, gap = 8.0f;
    CGFloat cardWidth = floorf((width - margin * 2.0f - gap) * 0.5f);
    _leftItem.frame = CGRectMake(margin, 4, cardWidth, cardWidth + 38);
    _rightItem.frame = CGRectMake(margin + cardWidth + gap, 4, cardWidth, cardWidth + 38);
    [_leftItem setNeedsLayout]; [_leftItem layoutIfNeeded];
    [_rightItem setNeedsLayout]; [_rightItem layoutIfNeeded];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    [self layoutForWidth:self.contentView.bounds.size.width];
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
