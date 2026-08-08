#import "TBArtworkCache.h"

static const NSUInteger TBArtworkCacheLimit = 16;

@implementation TBArtworkCache

+ (TBArtworkCache *)sharedCache {
    static TBArtworkCache *cache = nil;
    if (cache == nil) cache = [[TBArtworkCache alloc] init];
    return cache;
}

- (id)init {
    self = [super init];
    if (self) {
        _images = [[NSMutableDictionary alloc] init];
        _recentKeys = [[NSMutableArray alloc] init];
        _pendingKeys = [[NSMutableSet alloc] init];
    }
    return self;
}

- (UIImage *)cachedImageForKey:(NSString *)key {
    id image = [_images objectForKey:key];
    if (image) {
        [_recentKeys removeObject:key];
        [_recentKeys addObject:key];
    }
    return image == [NSNull null] ? nil : image;
}

- (void)requestImageForItem:(MPMediaItem *)item size:(CGSize)size key:(NSString *)key
                     target:(id)target selector:(SEL)selector {
    if (!item || !key || [_images objectForKey:key] || [_pendingKeys containsObject:key]) return;
    [_pendingKeys addObject:key];
    NSDictionary *request = [NSDictionary dictionaryWithObjectsAndKeys:
        item, @"item", key, @"key", target, @"target",
        NSStringFromSelector(selector), @"selector",
        [NSValue valueWithCGSize:size], @"size", nil];
    [self performSelectorInBackground:@selector(loadImage:) withObject:request];
}

- (void)loadImage:(NSDictionary *)request {
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    MPMediaItemArtwork *artwork = [[request objectForKey:@"item"]
        valueForProperty:MPMediaItemPropertyArtwork];
    UIImage *image = [artwork imageWithSize:[[request objectForKey:@"size"] CGSizeValue]];
    NSDictionary *result = [[NSDictionary alloc] initWithObjectsAndKeys:
        [request objectForKey:@"key"], @"key", [request objectForKey:@"target"], @"target",
        [request objectForKey:@"selector"], @"selector",
        (image ? image : [NSNull null]), @"image", nil];
    [self performSelectorOnMainThread:@selector(finishImage:) withObject:result waitUntilDone:YES];
    [result release];
    [pool drain];
}

- (void)finishImage:(NSDictionary *)result {
    NSString *key = [result objectForKey:@"key"];
    UIImage *image = [result objectForKey:@"image"];
    [_pendingKeys removeObject:key];
    [_images setObject:image forKey:key];
    [_recentKeys removeObject:key];
    [_recentKeys addObject:key];
    while ([_recentKeys count] > TBArtworkCacheLimit) {
        NSString *oldest = [_recentKeys objectAtIndex:0];
        [_images removeObjectForKey:oldest];
        [_recentKeys removeObjectAtIndex:0];
    }
    id target = [result objectForKey:@"target"];
    SEL selector = NSSelectorFromString([result objectForKey:@"selector"]);
    if ([target respondsToSelector:selector]) [target performSelector:selector withObject:result];
}

- (void)removeAllImages {
    [_images removeAllObjects];
    [_recentKeys removeAllObjects];
}

- (void)dealloc {
    [_images release]; [_recentKeys release]; [_pendingKeys release];
    [super dealloc];
}

@end
