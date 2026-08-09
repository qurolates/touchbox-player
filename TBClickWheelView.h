#import <UIKit/UIKit.h>

@class TBClickWheelView;

@protocol TBClickWheelViewDelegate <NSObject>
- (void)clickWheel:(TBClickWheelView *)wheel didRotateBySteps:(NSInteger)steps;
- (void)clickWheelDidEndRotation:(TBClickWheelView *)wheel;
- (void)clickWheelDidSelect:(TBClickWheelView *)wheel;
- (void)clickWheelDidPressMenu:(TBClickWheelView *)wheel;
- (void)clickWheelDidPressPrevious:(TBClickWheelView *)wheel;
- (void)clickWheelDidPressNext:(TBClickWheelView *)wheel;
- (void)clickWheelDidPressPlayPause:(TBClickWheelView *)wheel;
@end

typedef enum {
    TBClickWheelRegionNone = 0,
    TBClickWheelRegionRing,
    TBClickWheelRegionCenter,
    TBClickWheelRegionMenu,
    TBClickWheelRegionPrevious,
    TBClickWheelRegionNext,
    TBClickWheelRegionPlayPause
} TBClickWheelRegion;

@interface TBClickWheelView : UIView {
    id<TBClickWheelViewDelegate> _delegate;
    UITouch *_activeTouch;
    CGFloat _previousAngle;
    CGFloat _accumulatedAngle;
    CGFloat _totalAngularMovement;
    TBClickWheelRegion _pressedRegion;
    BOOL _rotating;
}
@property(nonatomic, assign) id<TBClickWheelViewDelegate> delegate;
@end
