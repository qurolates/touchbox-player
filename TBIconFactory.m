#import "TBIconFactory.h"
#import "TBTheme.h"

@implementation TBIconFactory

+ (NSMutableDictionary *)cache {
    static NSMutableDictionary *cache = nil;
    if (!cache) cache = [[NSMutableDictionary alloc] init];
    return cache;
}

+ (void)triangleInContext:(CGContextRef)context rect:(CGRect)rect backwards:(BOOL)backwards {
    CGContextBeginPath(context);
    if (backwards) {
        CGContextMoveToPoint(context, CGRectGetMaxX(rect), CGRectGetMinY(rect));
        CGContextAddLineToPoint(context, CGRectGetMinX(rect), CGRectGetMidY(rect));
        CGContextAddLineToPoint(context, CGRectGetMaxX(rect), CGRectGetMaxY(rect));
    } else {
        CGContextMoveToPoint(context, CGRectGetMinX(rect), CGRectGetMinY(rect));
        CGContextAddLineToPoint(context, CGRectGetMaxX(rect), CGRectGetMidY(rect));
        CGContextAddLineToPoint(context, CGRectGetMinX(rect), CGRectGetMaxY(rect));
    }
    CGContextClosePath(context);
    CGContextFillPath(context);
}

+ (UIImage *)iconNamed:(NSString *)name active:(BOOL)active {
    NSString *key = [NSString stringWithFormat:@"%@-%d-theme%d", name, active, [TBTheme currentTheme]];
    UIImage *cached = [[self cache] objectForKey:key];
    if (cached) return cached;
    CGSize size = CGSizeMake(28, 28);
    UIGraphicsBeginImageContext(size);
    CGContextRef context = UIGraphicsGetCurrentContext();
    UIColor *color = active ? [TBTheme accentColor] : [TBTheme secondaryTextColor];
    CGContextSetFillColorWithColor(context, color.CGColor);
    CGContextSetStrokeColorWithColor(context, color.CGColor);
    CGContextSetLineWidth(context, 2.0f);
    CGContextSetLineCap(context, kCGLineCapRound);
    CGContextSetLineJoin(context, kCGLineJoinRound);
    if ([name isEqualToString:@"play"]) {
        [self triangleInContext:context rect:CGRectMake(8, 5, 15, 18) backwards:NO];
    } else if ([name isEqualToString:@"pause"]) {
        CGContextFillRect(context, CGRectMake(7, 5, 5, 18));
        CGContextFillRect(context, CGRectMake(17, 5, 5, 18));
    } else if ([name isEqualToString:@"previous"] || [name isEqualToString:@"next"]) {
        BOOL backwards = [name isEqualToString:@"previous"];
        [self triangleInContext:context rect:CGRectMake(6, 6, 10, 16) backwards:backwards];
        [self triangleInContext:context rect:CGRectMake(14, 6, 10, 16) backwards:backwards];
    } else if ([name isEqualToString:@"star"]) {
        CGContextBeginPath(context);
        NSUInteger i;
        for (i = 0; i < 10; i++) {
            CGFloat angle = -M_PI_2 + i * M_PI / 5.0f;
            CGFloat radius = (i % 2 == 0) ? 10.0f : 4.2f;
            CGPoint point = CGPointMake(14 + cos(angle) * radius, 14 + sin(angle) * radius);
            if (i == 0) CGContextMoveToPoint(context, point.x, point.y);
            else CGContextAddLineToPoint(context, point.x, point.y);
        }
        CGContextClosePath(context);
        if (active) CGContextFillPath(context); else CGContextStrokePath(context);
    } else if ([name isEqualToString:@"shuffle"]) {
        CGContextMoveToPoint(context, 4, 8); CGContextAddLineToPoint(context, 9, 8);
        CGContextAddCurveToPoint(context, 15, 8, 15, 20, 22, 20); CGContextStrokePath(context);
        CGContextMoveToPoint(context, 19, 17); CGContextAddLineToPoint(context, 23, 20);
        CGContextAddLineToPoint(context, 19, 23); CGContextStrokePath(context);
        CGContextMoveToPoint(context, 4, 20); CGContextAddLineToPoint(context, 9, 20);
        CGContextAddCurveToPoint(context, 15, 20, 15, 8, 22, 8); CGContextStrokePath(context);
        CGContextMoveToPoint(context, 19, 5); CGContextAddLineToPoint(context, 23, 8);
        CGContextAddLineToPoint(context, 19, 11); CGContextStrokePath(context);
    } else if ([name isEqualToString:@"repeat"]) {
        CGContextMoveToPoint(context, 6, 10); CGContextAddCurveToPoint(context, 8, 6, 19, 6, 22, 10);
        CGContextStrokePath(context);
        CGContextMoveToPoint(context, 19, 7); CGContextAddLineToPoint(context, 22, 10);
        CGContextAddLineToPoint(context, 19, 13); CGContextStrokePath(context);
        CGContextMoveToPoint(context, 22, 18); CGContextAddCurveToPoint(context, 19, 22, 8, 22, 6, 18);
        CGContextStrokePath(context);
        CGContextMoveToPoint(context, 9, 15); CGContextAddLineToPoint(context, 6, 18);
        CGContextAddLineToPoint(context, 9, 21); CGContextStrokePath(context);
    } else if ([name isEqualToString:@"queue"]) {
        NSUInteger y;
        for (y = 7; y <= 21; y += 7) {
            CGContextFillEllipseInRect(context, CGRectMake(4, y - 1, 3, 3));
            CGContextFillRect(context, CGRectMake(10, y, 14, 2));
        }
    }
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    if (image) [[self cache] setObject:image forKey:key];
    return image;
}

+ (UIImage *)artworkPlaceholderWithSize:(CGSize)size {
    NSString *key = [NSString stringWithFormat:@"placeholder-%u-%u-theme%d", (unsigned)size.width, (unsigned)size.height, [TBTheme currentTheme]];
    UIImage *cached = [[self cache] objectForKey:key];
    if (cached) return cached;
    UIGraphicsBeginImageContext(size);
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetFillColorWithColor(context, [TBTheme placeholderColor].CGColor);
    CGContextFillRect(context, CGRectMake(0, 0, size.width, size.height));
    CGContextSetStrokeColorWithColor(context, [TBTheme secondaryTextColor].CGColor);
    CGContextSetLineWidth(context, MAX(2.0f, size.width / 55.0f));
    CGFloat x = size.width * 0.48f, y = size.height * 0.32f;
    CGContextMoveToPoint(context, x, y); CGContextAddLineToPoint(context, x, size.height * 0.62f);
    CGContextAddLineToPoint(context, size.width * 0.68f, size.height * 0.56f);
    CGContextAddLineToPoint(context, size.width * 0.68f, size.height * 0.27f);
    CGContextAddLineToPoint(context, x, y); CGContextStrokePath(context);
    CGContextFillEllipseInRect(context, CGRectMake(size.width * 0.36f, size.height * 0.58f,
        size.width * 0.14f, size.width * 0.10f));
    CGContextFillEllipseInRect(context, CGRectMake(size.width * 0.57f, size.height * 0.52f,
        size.width * 0.14f, size.width * 0.10f));
    NSString *text = @"TOUCHBOX";
    [TBTheme.secondaryTextColor set];
    [text drawInRect:CGRectMake(0, size.height * 0.76f, size.width, 18)
        withFont:[UIFont boldSystemFontOfSize:MAX(9.0f, size.width / 15.0f)]
        lineBreakMode:UILineBreakModeClip alignment:UITextAlignmentCenter];
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    if (image) [[self cache] setObject:image forKey:key];
    return image;
}
@end
