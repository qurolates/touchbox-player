#import "TBCoverFlowView.h"
#import "TBLibraryManager.h"
#import "TBArtworkCache.h"
#import "TBIconFactory.h"
#import "TBTheme.h"
#import <QuartzCore/QuartzCore.h>
#import <math.h>

static const NSInteger TBCoverFlowSlotCount = 7;

@interface TBCoverFlowView ()
- (void)applyCoverFlowLayoutAnimated:(BOOL)animated;
- (void)artworkLoaded:(NSDictionary *)result;
- (void)updateLabels;
- (void)loadVisibleArtwork;
- (void)animationDidStop:(CAAnimation *)animation finished:(BOOL)finished;
@end

@implementation TBCoverFlowView

- (id)initWithFrame:(CGRect)frame {
    if ((self = [super initWithFrame:frame])) {
        self.backgroundColor = [TBTheme classicDisplayColor];
        self.clipsToBounds = YES;
        _selectedIndex = NSNotFound;
        _previousSelectedIndex = NSNotFound;
        _scrollView = [[UIScrollView alloc] initWithFrame:self.bounds];
        _scrollView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        _scrollView.scrollEnabled = NO; _scrollView.userInteractionEnabled = NO;
        _scrollView.clipsToBounds = YES; _scrollView.backgroundColor = [UIColor clearColor];
        [self addSubview:_scrollView];
        _coverViews = [[NSMutableArray alloc] initWithCapacity:TBCoverFlowSlotCount];
        NSInteger slot;
        for (slot = 0; slot < TBCoverFlowSlotCount; slot++) {
            UIImageView *cover = [[UIImageView alloc] initWithFrame:CGRectZero];
            cover.contentMode = UIViewContentModeScaleAspectFit;
            cover.backgroundColor = [TBTheme placeholderColor];
            cover.layer.borderWidth = 1.0f; cover.layer.borderColor = [TBTheme borderColor].CGColor;
            [_scrollView addSubview:cover]; [_coverViews addObject:cover]; [cover release];
        }
        _albumLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        _albumLabel.backgroundColor = [UIColor clearColor]; _albumLabel.textAlignment = UITextAlignmentCenter;
        _albumLabel.font = [UIFont boldSystemFontOfSize:13]; _albumLabel.lineBreakMode = UILineBreakModeTailTruncation;
        [self addSubview:_albumLabel];
        _artistLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        _artistLabel.backgroundColor = [UIColor clearColor]; _artistLabel.textAlignment = UITextAlignmentCenter;
        _artistLabel.font = [UIFont systemFontOfSize:11]; _artistLabel.lineBreakMode = UILineBreakModeTailTruncation;
        [self addSubview:_artistLabel];
        [self applyTheme];
    }
    return self;
}

- (MPMediaItem *)representativeItemForAlbum:(NSDictionary *)album {
    NSArray *items = [album objectForKey:TBAlbumItemsKey];
    return [items count] ? [items objectAtIndex:0] : nil;
}

- (NSString *)keyForAlbum:(NSDictionary *)album size:(CGFloat)size {
    MPMediaItem *item = [self representativeItemForAlbum:album];
    NSNumber *identifier = [item valueForProperty:MPMediaItemPropertyPersistentID];
    return identifier ? [NSString stringWithFormat:@"coverflow-%llu-%u",
        [identifier unsignedLongLongValue], (unsigned)size] : nil;
}

- (void)setAlbums:(NSArray *)albums selectedIndex:(NSInteger)index {
    if (_albums != albums) { [_albums release]; _albums = [albums retain]; }
    [self selectIndex:index animated:NO];
}

- (void)selectIndex:(NSInteger)index animated:(BOOL)animated {
    if (![_albums count]) index = NSNotFound;
    else index = MAX(0, MIN(index, (NSInteger)[_albums count] - 1));
    BOOL changed = index != _selectedIndex;
    _previousSelectedIndex = _selectedIndex;
    _selectedIndex = index;
    [self applyCoverFlowLayoutAnimated:(animated && changed)];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    _scrollView.frame = self.bounds;
    [self applyCoverFlowLayoutAnimated:NO];
}

- (void)applyCanonicalStateToCover:(UIImageView *)cover relativeIndex:(NSInteger)relativeIndex
        centerX:(CGFloat)centerX centerY:(CGFloat)centerY centralSize:(CGFloat)centralSize
        spacing:(CGFloat)spacing {
    NSInteger distance = abs((int)relativeIndex);
    CGFloat size = relativeIndex == 0 ? centralSize : centralSize * (distance == 1 ? 0.72f : 0.60f);
    cover.bounds = CGRectMake(0, 0, size, size);
    cover.center = CGPointMake(floorf(centerX + relativeIndex * spacing), centerY);
    CATransform3D transform = CATransform3DIdentity; transform.m34 = -1.0f / 500.0f;
    if (relativeIndex < 0) transform = CATransform3DRotate(transform, 0.52f, 0, 1, 0);
    else if (relativeIndex > 0) transform = CATransform3DRotate(transform, -0.52f, 0, 1, 0);
    cover.layer.transform = transform;
    cover.layer.zPosition = 100.0f - distance * 10.0f;
    cover.alpha = distance > 2 ? 0.0f : 1.0f;
}

- (void)freezeCoverAtPresentationState:(UIImageView *)cover {
    CALayer *presentation = (CALayer *)[cover.layer presentationLayer];
    CGPoint position = presentation ? presentation.position : cover.layer.position;
    CGRect bounds = presentation ? presentation.bounds : cover.layer.bounds;
    CATransform3D transform = presentation ? presentation.transform : cover.layer.transform;
    float opacity = presentation ? presentation.opacity : cover.layer.opacity;
    [cover.layer removeAllAnimations];
    [CATransaction begin]; [CATransaction setDisableActions:YES];
    cover.layer.position = position; cover.layer.bounds = bounds;
    cover.layer.transform = transform; cover.layer.opacity = opacity;
    [CATransaction commit];
}

- (void)animateCover:(UIImageView *)cover relativeIndex:(NSInteger)relativeIndex
        centerX:(CGFloat)centerX centerY:(CGFloat)centerY centralSize:(CGFloat)centralSize
        spacing:(CGFloat)spacing generation:(NSUInteger)generation {
    CGPoint oldPosition = cover.layer.position; CGRect oldBounds = cover.layer.bounds;
    CATransform3D oldTransform = cover.layer.transform; float oldOpacity = cover.layer.opacity;
    [CATransaction begin]; [CATransaction setDisableActions:YES];
    [self applyCanonicalStateToCover:cover relativeIndex:relativeIndex centerX:centerX centerY:centerY
        centralSize:centralSize spacing:spacing];
    CGPoint newPosition = cover.layer.position; CGRect newBounds = cover.layer.bounds;
    CATransform3D newTransform = cover.layer.transform; float newOpacity = cover.layer.opacity;
    [CATransaction commit];
    CAMediaTimingFunction *timing = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
    CABasicAnimation *position = [CABasicAnimation animationWithKeyPath:@"position"];
    position.fromValue = [NSValue valueWithCGPoint:oldPosition]; position.toValue = [NSValue valueWithCGPoint:newPosition];
    position.duration = 0.22; position.timingFunction = timing;
    if (relativeIndex == 0) { position.delegate = self; [position setValue:[NSNumber numberWithUnsignedInteger:generation] forKey:@"generation"]; }
    [cover.layer addAnimation:position forKey:@"tbCoverPosition"];
    CABasicAnimation *bounds = [CABasicAnimation animationWithKeyPath:@"bounds"];
    bounds.fromValue = [NSValue valueWithCGRect:oldBounds]; bounds.toValue = [NSValue valueWithCGRect:newBounds];
    bounds.duration = 0.22; bounds.timingFunction = timing; [cover.layer addAnimation:bounds forKey:@"tbCoverBounds"];
    CABasicAnimation *transform = [CABasicAnimation animationWithKeyPath:@"transform"];
    transform.fromValue = [NSValue valueWithCATransform3D:oldTransform]; transform.toValue = [NSValue valueWithCATransform3D:newTransform];
    transform.duration = 0.22; transform.timingFunction = timing; [cover.layer addAnimation:transform forKey:@"tbCoverTransform"];
    CABasicAnimation *opacity = [CABasicAnimation animationWithKeyPath:@"opacity"];
    opacity.fromValue = [NSNumber numberWithFloat:oldOpacity]; opacity.toValue = [NSNumber numberWithFloat:newOpacity];
    opacity.duration = 0.22; opacity.timingFunction = timing; [cover.layer addAnimation:opacity forKey:@"tbCoverOpacity"];
}

- (void)applyCoverFlowLayoutAnimated:(BOOL)animated {
    CGFloat width = self.bounds.size.width, height = self.bounds.size.height;
    CGFloat centralSize = MIN(140.0f, MAX(92.0f, height - 50.0f));
    CGFloat centerY = floorf((height - 34.0f) * 0.5f);
    CGFloat centerX = width * 0.5f;
    CGFloat spacing = MIN(62.0f, centralSize * 0.48f);
    UIImage *placeholder = [TBIconFactory artworkPlaceholderWithSize:CGSizeMake(centralSize, centralSize)];
    _animationGeneration++;
    NSUInteger generation = _animationGeneration;
    NSUInteger coverIndex;
    for (coverIndex = 0; coverIndex < [_coverViews count]; coverIndex++)
        [self freezeCoverAtPresentationState:[_coverViews objectAtIndex:coverIndex]];
    NSMutableArray *assigned = [NSMutableArray arrayWithCapacity:TBCoverFlowSlotCount];
    NSInteger first = _selectedIndex == NSNotFound ? 0 : MAX(0, _selectedIndex - TBCoverFlowSlotCount / 2);
    NSInteger last = _selectedIndex == NSNotFound ? -1 : MIN((NSInteger)[_albums count] - 1, _selectedIndex + TBCoverFlowSlotCount / 2);
    NSInteger albumIndex;
    for (albumIndex = first; albumIndex <= last; albumIndex++) {
        UIImageView *cover = nil;
        for (coverIndex = 0; coverIndex < [_coverViews count]; coverIndex++) {
            UIImageView *candidate = [_coverViews objectAtIndex:coverIndex];
            if (![assigned containsObject:candidate] && candidate.tag == albumIndex + 1) { cover = candidate; break; }
        }
        BOOL reused = cover == nil;
        if (reused) {
            for (coverIndex = 0; coverIndex < [_coverViews count]; coverIndex++) {
                UIImageView *candidate = [_coverViews objectAtIndex:coverIndex];
                NSInteger candidateIndex = candidate.tag - 1;
                if (![assigned containsObject:candidate] && (candidateIndex < first || candidateIndex > last)) { cover = candidate; break; }
            }
        }
        if (!cover) continue;
        [assigned addObject:cover]; cover.hidden = NO;
        NSInteger relativeIndex = albumIndex - _selectedIndex;
        if (reused) {
            cover.tag = albumIndex + 1;
            NSDictionary *album = [_albums objectAtIndex:(NSUInteger)albumIndex];
            NSString *key = [self keyForAlbum:album size:centralSize];
            UIImage *image = [[TBArtworkCache sharedCache] cachedImageForKey:key];
            cover.image = image ? image : placeholder;
            NSInteger entryIndex = relativeIndex < 0 ? -4 : 4;
            if (relativeIndex == 0)
                entryIndex = (_previousSelectedIndex != NSNotFound && _selectedIndex < _previousSelectedIndex) ? -4 : 4;
            [CATransaction begin]; [CATransaction setDisableActions:YES];
            [self applyCanonicalStateToCover:cover relativeIndex:entryIndex centerX:centerX centerY:centerY
                centralSize:centralSize spacing:spacing];
            if (entryIndex != 0) cover.layer.opacity = 0.0f;
            [CATransaction commit];
        }
        if (animated) [self animateCover:cover relativeIndex:relativeIndex centerX:centerX centerY:centerY
            centralSize:centralSize spacing:spacing generation:generation];
        else {
            [CATransaction begin]; [CATransaction setDisableActions:YES];
            [self applyCanonicalStateToCover:cover relativeIndex:relativeIndex centerX:centerX centerY:centerY
                centralSize:centralSize spacing:spacing]; [CATransaction commit];
        }
    }
    for (coverIndex = 0; coverIndex < [_coverViews count]; coverIndex++) {
        UIImageView *cover = [_coverViews objectAtIndex:coverIndex];
        if (![assigned containsObject:cover]) { [cover.layer removeAllAnimations]; cover.hidden = YES; cover.tag = 0; }
    }
    _albumLabel.frame = CGRectMake(10, MAX(0.0f, height - 34), width - 20, 18);
    _artistLabel.frame = CGRectMake(10, MAX(0.0f, height - 17), width - 20, 15);
    _animationInProgress = animated;
    if (!animated || _selectedIndex == NSNotFound) { _animationInProgress = NO; [self updateLabels]; [self loadVisibleArtwork]; }
}

- (void)updateLabels {
    if (_selectedIndex != NSNotFound) {
        NSDictionary *album = [_albums objectAtIndex:(NSUInteger)_selectedIndex];
        _albumLabel.text = [album objectForKey:TBAlbumTitleKey];
        _artistLabel.text = [album objectForKey:TBAlbumArtistKey];
    } else { _albumLabel.text = @"No Albums"; _artistLabel.text = @""; }
}

- (void)loadVisibleArtwork {
    CGFloat size = MIN(140.0f, MAX(92.0f, self.bounds.size.height - 50.0f));
    NSUInteger slot;
    for (slot = 0; slot < [_coverViews count]; slot++) {
        UIImageView *cover = [_coverViews objectAtIndex:slot]; NSInteger albumIndex = cover.tag - 1;
        if (albumIndex < 0 || albumIndex >= (NSInteger)[_albums count]) continue;
        NSDictionary *album = [_albums objectAtIndex:(NSUInteger)albumIndex];
        NSString *key = [self keyForAlbum:album size:size];
        UIImage *image = [[TBArtworkCache sharedCache] cachedImageForKey:key];
        if (image) cover.image = image;
        else {
            MPMediaItem *item = [self representativeItemForAlbum:album];
            if (item && key) [[TBArtworkCache sharedCache] requestImageForItem:item size:CGSizeMake(size, size)
                key:key target:self selector:@selector(artworkLoaded:)];
        }
    }
}

- (void)animationDidStop:(CAAnimation *)animation finished:(BOOL)finished {
    NSNumber *generation = [animation valueForKey:@"generation"];
    if (!finished || [generation unsignedIntegerValue] != _animationGeneration) return;
    _animationInProgress = NO;
    [self updateLabels]; [self loadVisibleArtwork];
}

- (void)artworkLoaded:(NSDictionary *)result {
    if (!self.window || self.hidden || _animationInProgress) return;
    NSString *key = [result objectForKey:@"key"]; id image = [result objectForKey:@"image"];
    if (image == [NSNull null]) return;
    NSUInteger slot;
    for (slot = 0; slot < [_coverViews count]; slot++) {
        UIImageView *cover = [_coverViews objectAtIndex:slot];
        NSInteger albumIndex = cover.tag - 1;
        if (albumIndex >= 0 && albumIndex < (NSInteger)[_albums count] &&
            [[self keyForAlbum:[_albums objectAtIndex:(NSUInteger)albumIndex]
                size:MIN(140.0f, MAX(92.0f, self.bounds.size.height - 50.0f))] isEqualToString:key])
            cover.image = image;
    }
}

- (void)applyTheme {
    self.backgroundColor = [TBTheme classicDisplayColor];
    _albumLabel.textColor = [TBTheme primaryTextColor]; _artistLabel.textColor = [TBTheme secondaryTextColor];
    NSUInteger slot; for (slot = 0; slot < [_coverViews count]; slot++) {
        UIImageView *cover = [_coverViews objectAtIndex:slot]; cover.backgroundColor = [TBTheme placeholderColor];
        cover.layer.borderColor = [TBTheme borderColor].CGColor;
    }
    [self setNeedsLayout];
}

- (void)dealloc {
    [_scrollView release]; [_coverViews release]; [_albumLabel release]; [_artistLabel release]; [_albums release];
    [super dealloc];
}
@end
