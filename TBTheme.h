#import <UIKit/UIKit.h>

@interface TBTheme : NSObject
+ (UIColor *)backgroundColor;
+ (UIColor *)primaryTextColor;
+ (UIColor *)secondaryTextColor;
+ (UIColor *)accentColor;
+ (UIColor *)separatorColor;
+ (UIColor *)placeholderColor;
+ (UIFont *)largeTitleFont;
+ (UIFont *)sectionTitleFont;
+ (UIFont *)primaryFont;
+ (UIFont *)secondaryFont;
+ (UIFont *)metadataFont;
+ (void)styleTableView:(UITableView *)tableView;
@end
