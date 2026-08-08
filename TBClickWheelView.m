#import "TBClickWheelView.h"
#import <math.h>
#import "TBTheme.h"

static const CGFloat TBWheelRadius = 105.0f;
static const CGFloat TBCenterRadius = 42.0f;
/* Phase 1 device feedback: 15% slower than the original 0.22 threshold. */
static const CGFloat TBStepThreshold = 0.26f;

@implementation TBClickWheelView
@synthesize delegate = _delegate;

- (id)initWithFrame:(CGRect)frame {
    if ((self = [super initWithFrame:frame])) {
        self.backgroundColor = [TBTheme classicBodyColor];
        self.multipleTouchEnabled = NO;
        self.exclusiveTouch = YES;
    }
    return self;
}

- (CGPoint)wheelCenter { return CGPointMake(self.bounds.size.width * 0.5f, self.bounds.size.height * 0.5f); }
- (CGFloat)distanceForPoint:(CGPoint)point {
    CGPoint center = [self wheelCenter]; CGFloat dx = point.x - center.x; CGFloat dy = point.y - center.y;
    return sqrtf(dx * dx + dy * dy);
}
- (CGFloat)angleForPoint:(CGPoint)point {
    CGPoint center = [self wheelCenter]; return atan2f(point.y - center.y, point.x - center.x);
}
- (CGFloat)normalizedDelta:(CGFloat)delta {
    while (delta > (CGFloat)M_PI) delta -= (CGFloat)(2.0 * M_PI);
    while (delta < (CGFloat)-M_PI) delta += (CGFloat)(2.0 * M_PI);
    return delta;
}
- (TBClickWheelRegion)buttonRegionForAngle:(CGFloat)angle {
    CGFloat tolerance = 0.43f;
    if (fabsf([self normalizedDelta:angle - (CGFloat)-M_PI_2]) < tolerance) return TBClickWheelRegionMenu;
    if (fabsf([self normalizedDelta:angle - (CGFloat)M_PI]) < tolerance) return TBClickWheelRegionPrevious;
    if (fabsf([self normalizedDelta:angle]) < tolerance) return TBClickWheelRegionNext;
    if (fabsf([self normalizedDelta:angle - (CGFloat)M_PI_2]) < tolerance) return TBClickWheelRegionPlayPause;
    return TBClickWheelRegionRing;
}

- (void)drawRect:(CGRect)rect {
    CGContextRef context = UIGraphicsGetCurrentContext(); CGPoint center = [self wheelCenter];
    CGRect wheelRect = CGRectMake(center.x - TBWheelRadius, center.y - TBWheelRadius, TBWheelRadius * 2.0f, TBWheelRadius * 2.0f);
    self.backgroundColor = [TBTheme classicBodyColor];
    CGContextSetFillColorWithColor(context, [TBTheme classicWheelColor].CGColor);
    CGContextFillEllipseInRect(context, wheelRect);
    CGContextSetStrokeColorWithColor(context, [TBTheme classicWheelBorderColor].CGColor);
    CGContextSetLineWidth(context, 1.0f); CGContextStrokeEllipseInRect(context, wheelRect);
    CGRect centerRect = CGRectMake(center.x - TBCenterRadius, center.y - TBCenterRadius, TBCenterRadius * 2.0f, TBCenterRadius * 2.0f);
    UIColor *centerColor = (_pressedRegion == TBClickWheelRegionCenter)
        ? [TBTheme classicPressedCenterColor] : [TBTheme classicCenterColor];
    CGContextSetFillColorWithColor(context, centerColor.CGColor); CGContextFillEllipseInRect(context, centerRect);
    CGContextSetStrokeColorWithColor(context, [TBTheme classicWheelBorderColor].CGColor); CGContextStrokeEllipseInRect(context, centerRect);

    NSDictionary *labels = [NSDictionary dictionaryWithObjectsAndKeys:@"MENU", [NSNumber numberWithInt:TBClickWheelRegionMenu],
        @"|◀", [NSNumber numberWithInt:TBClickWheelRegionPrevious], @"▶|", [NSNumber numberWithInt:TBClickWheelRegionNext],
        @"▶ Ⅱ", [NSNumber numberWithInt:TBClickWheelRegionPlayPause], nil];
    UIFont *font = [UIFont boldSystemFontOfSize:12.0f]; UIColor *normal = [TBTheme classicWheelTextColor]; UIColor *pressed = [TBTheme accentColor];
    NSArray *regions = [NSArray arrayWithObjects:[NSNumber numberWithInt:TBClickWheelRegionMenu], [NSNumber numberWithInt:TBClickWheelRegionPrevious], [NSNumber numberWithInt:TBClickWheelRegionNext], [NSNumber numberWithInt:TBClickWheelRegionPlayPause], nil];
    NSUInteger i; for (i = 0; i < [regions count]; i++) { TBClickWheelRegion region = [[regions objectAtIndex:i] intValue]; NSString *text = [labels objectForKey:[regions objectAtIndex:i]]; CGSize size = [text sizeWithFont:font]; CGPoint p;
        if (region == TBClickWheelRegionMenu) p = CGPointMake(center.x - size.width/2, center.y - 91);
        else if (region == TBClickWheelRegionPrevious) p = CGPointMake(center.x - 91 - size.width/2, center.y - size.height/2);
        else if (region == TBClickWheelRegionNext) p = CGPointMake(center.x + 91 - size.width/2, center.y - size.height/2);
        else p = CGPointMake(center.x - size.width/2, center.y + 75);
        [(region == _pressedRegion ? pressed : normal) set]; [text drawAtPoint:p withFont:font];
    }
}

- (void)resetTouchState { _activeTouch = nil; _pressedRegion = TBClickWheelRegionNone; _rotating = NO; _accumulatedAngle = 0; _totalAngularMovement = 0; [self setNeedsDisplay]; }
- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    if (_activeTouch || [touches count] != 1) return; UITouch *touch = [touches anyObject]; CGPoint point = [touch locationInView:self]; CGFloat distance = [self distanceForPoint:point];
    if (distance > TBWheelRadius) return; _activeTouch = touch; _previousAngle = [self angleForPoint:point]; _accumulatedAngle = 0; _totalAngularMovement = 0; _rotating = NO;
    _pressedRegion = distance < TBCenterRadius ? TBClickWheelRegionCenter : [self buttonRegionForAngle:_previousAngle]; [self setNeedsDisplay];
}
- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
    if (!_activeTouch || ![touches containsObject:_activeTouch]) return; CGPoint point = [_activeTouch locationInView:self]; CGFloat distance = [self distanceForPoint:point];
    if (distance < TBCenterRadius) { if (_pressedRegion != TBClickWheelRegionCenter) _pressedRegion = TBClickWheelRegionNone; [self setNeedsDisplay]; return; }
    if (distance > TBWheelRadius) { _pressedRegion = TBClickWheelRegionNone; _previousAngle = [self angleForPoint:point]; [self setNeedsDisplay]; return; }
    CGFloat angle = [self angleForPoint:point]; CGFloat delta = [self normalizedDelta:angle - _previousAngle]; _previousAngle = angle; _totalAngularMovement += fabsf(delta);
    if (_totalAngularMovement > 0.10f) { _rotating = YES; _pressedRegion = TBClickWheelRegionNone; }
    _accumulatedAngle += delta; NSInteger steps = 0;
    while (_accumulatedAngle >= TBStepThreshold) { steps++; _accumulatedAngle -= TBStepThreshold; }
    while (_accumulatedAngle <= -TBStepThreshold) { steps--; _accumulatedAngle += TBStepThreshold; }
    if (steps) { NSLog(@"Touchbox Classic: Wheel %@%ld", steps > 0 ? @"+" : @"", (long)steps); [_delegate clickWheel:self didRotateBySteps:steps]; }
    [self setNeedsDisplay];
}
- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
    if (!_activeTouch || ![touches containsObject:_activeTouch]) return; TBClickWheelRegion region = _pressedRegion; BOOL activate = !_rotating;
    if (activate) { if (region == TBClickWheelRegionCenter) [_delegate clickWheelDidSelect:self]; else if (region == TBClickWheelRegionMenu) [_delegate clickWheelDidPressMenu:self]; else if (region == TBClickWheelRegionPrevious) [_delegate clickWheelDidPressPrevious:self]; else if (region == TBClickWheelRegionNext) [_delegate clickWheelDidPressNext:self]; else if (region == TBClickWheelRegionPlayPause) [_delegate clickWheelDidPressPlayPause:self]; }
    [self resetTouchState];
}
- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event { if (_activeTouch && [touches containsObject:_activeTouch]) [self resetTouchState]; }
@end
