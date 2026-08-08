#import "TBAlphabetIndexView.h"
#import "TBTheme.h"

@implementation TBAlphabetIndexView
- (id)initWithFrame:(CGRect)frame titles:(NSArray *)titles target:(id)target action:(SEL)action {
    self = [super initWithFrame:frame];
    if (self) {
        _titles = [titles copy];
        _target = target;
        _action = action;
        _selectedIndex = -1;
        self.backgroundColor = [TBTheme backgroundColor];
        self.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleLeftMargin;
    }
    return self;
}
- (void)drawRect:(CGRect)rect {
    CGFloat itemHeight = self.bounds.size.height / MAX((CGFloat)[_titles count], 1.0f);
    UIFont *font = [UIFont boldSystemFontOfSize:8.0f];
    NSUInteger index;
    for (index = 0; index < [_titles count]; index++) {
        UIColor *color = ((NSInteger)index == _selectedIndex)
            ? [TBTheme accentColor] : [TBTheme secondaryTextColor];
        [color set];
        [[_titles objectAtIndex:index] drawInRect:CGRectMake(0, floorf(index * itemHeight),
            self.bounds.size.width, ceilf(itemHeight)) withFont:font
            lineBreakMode:UILineBreakModeClip alignment:UITextAlignmentCenter];
    }
}
- (void)selectForTouch:(UITouch *)touch {
    if (![_titles count]) return;
    CGFloat y = [touch locationInView:self].y;
    NSInteger index = (NSInteger)floorf((y / MAX(self.bounds.size.height, 1.0f)) * [_titles count]);
    index = MAX(0, MIN(index, (NSInteger)[_titles count] - 1));
    if (index == _selectedIndex) return;
    _selectedIndex = index;
    [self setNeedsDisplay];
    if ([_target respondsToSelector:_action])
        [_target performSelector:_action withObject:[NSNumber numberWithInteger:index]];
}
- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    [self selectForTouch:[touches anyObject]];
}
- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
    [self selectForTouch:[touches anyObject]];
}
- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
    _selectedIndex = -1;
    [self setNeedsDisplay];
}
- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event {
    _selectedIndex = -1;
    [self setNeedsDisplay];
}
- (void)dealloc { [_titles release]; [super dealloc]; }
@end
