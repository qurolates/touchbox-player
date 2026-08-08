#import "TBTheme.h"

@implementation TBTheme
+ (UIColor *)backgroundColor { return [UIColor colorWithWhite:0.98f alpha:1.0f]; }
+ (UIColor *)primaryTextColor { return [UIColor colorWithWhite:0.08f alpha:1.0f]; }
+ (UIColor *)secondaryTextColor { return [UIColor colorWithWhite:0.42f alpha:1.0f]; }
+ (UIColor *)accentColor { return [UIColor colorWithRed:0.12f green:0.38f blue:0.55f alpha:1.0f]; }
+ (UIColor *)separatorColor { return [UIColor colorWithWhite:0.86f alpha:1.0f]; }
+ (UIColor *)placeholderColor { return [UIColor colorWithWhite:0.90f alpha:1.0f]; }
+ (UIFont *)largeTitleFont { return [UIFont boldSystemFontOfSize:23.0f]; }
+ (UIFont *)sectionTitleFont { return [UIFont boldSystemFontOfSize:17.0f]; }
+ (UIFont *)primaryFont { return [UIFont boldSystemFontOfSize:15.0f]; }
+ (UIFont *)secondaryFont { return [UIFont systemFontOfSize:12.0f]; }
+ (UIFont *)metadataFont { return [UIFont systemFontOfSize:11.0f]; }
+ (void)styleTableView:(UITableView *)tableView {
    tableView.backgroundColor = [self backgroundColor];
    tableView.separatorColor = [self separatorColor];
}
@end
