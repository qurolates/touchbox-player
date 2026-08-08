#import <UIKit/UIKit.h>

@interface TBIconFactory : NSObject
+ (UIImage *)iconNamed:(NSString *)name active:(BOOL)active;
+ (UIImage *)artworkPlaceholderWithSize:(CGSize)size;
@end
