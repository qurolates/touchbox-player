#import "TBAlbumGridCell.h"
#import "TBLibraryManager.h"
#import "TBArtworkCache.h"

@implementation TBAlbumItemControl

@synthesize album = _album;
@synthesize artworkKey = _artworkKey;

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        _artworkView = [[UIImageView alloc] initWithFrame:CGRectMake(5, 0, 138, 138)];
        _artworkView.backgroundColor = [UIColor colorWithWhite:0.88f alpha:1.0f];
        _artworkView.contentMode = UIViewContentModeScaleAspectFit;
        [self addSubview:_artworkView];
        _titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(5, 140, 138, 18)];
        _titleLabel.font = [UIFont boldSystemFontOfSize:13.0f];
        _titleLabel.lineBreakMode = UILineBreakModeTailTruncation;
        [self addSubview:_titleLabel];
        _artistLabel = [[UILabel alloc] initWithFrame:CGRectMake(5, 158, 138, 16)];
        _artistLabel.font = [UIFont systemFontOfSize:11.0f];
        _artistLabel.textColor = [UIColor grayColor];
        _artistLabel.lineBreakMode = UILineBreakModeTailTruncation;
        [self addSubview:_artistLabel];
    }
    return self;
}

- (void)configureWithAlbum:(NSDictionary *)album {
    [self resetContent];
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
        [[TBArtworkCache sharedCache] requestImageForItem:item size:CGSizeMake(138, 138)
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
    _artworkView.image = nil;
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
        _leftItem = [[TBAlbumItemControl alloc] initWithFrame:CGRectMake(8, 3, 148, 176)];
        _rightItem = [[TBAlbumItemControl alloc] initWithFrame:CGRectMake(164, 3, 148, 176)];
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
