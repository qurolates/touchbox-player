#import "TBTheme.h"

NSString *const TBThemeDidChangeNotification = @"TBThemeDidChangeNotification";
static NSString *const TBThemeModeDefaultsKey = @"TBThemeMode";

@implementation TBTheme
+ (TBThemeMode)currentTheme { NSInteger value = [[NSUserDefaults standardUserDefaults] integerForKey:TBThemeModeDefaultsKey]; return value == TBThemeModeDark ? TBThemeModeDark : TBThemeModeLight; }
+ (BOOL)isDarkTheme { return [self currentTheme] == TBThemeModeDark; }
+ (void)setCurrentTheme:(TBThemeMode)theme {
    if (theme != TBThemeModeDark) theme = TBThemeModeLight;
    if ([self currentTheme] == theme) return;
    [[NSUserDefaults standardUserDefaults] setInteger:theme forKey:TBThemeModeDefaultsKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
    [[NSNotificationCenter defaultCenter] postNotificationName:TBThemeDidChangeNotification object:self];
}
+ (UIColor *)backgroundColor { return [self isDarkTheme] ? [UIColor colorWithRed:0.067f green:0.071f blue:0.078f alpha:1] : [UIColor colorWithWhite:0.98f alpha:1]; }
+ (UIColor *)secondaryBackgroundColor { return [self isDarkTheme] ? [UIColor colorWithRed:0.102f green:0.110f blue:0.122f alpha:1] : [UIColor whiteColor]; }
+ (UIColor *)elevatedBackgroundColor { return [self isDarkTheme] ? [UIColor colorWithRed:0.133f green:0.141f blue:0.157f alpha:1] : [UIColor colorWithWhite:0.95f alpha:1]; }
+ (UIColor *)primaryTextColor { return [self isDarkTheme] ? [UIColor colorWithWhite:0.95f alpha:1] : [UIColor colorWithWhite:0.08f alpha:1]; }
+ (UIColor *)secondaryTextColor { return [self isDarkTheme] ? [UIColor colorWithWhite:0.66f alpha:1] : [UIColor colorWithWhite:0.42f alpha:1]; }
+ (UIColor *)disabledTextColor { return [UIColor colorWithWhite:[self isDarkTheme] ? 0.40f : 0.62f alpha:1]; }
+ (UIColor *)accentColor { return [self isDarkTheme] ? [UIColor colorWithRed:0.29f green:0.62f blue:0.86f alpha:1] : [UIColor colorWithRed:0.12f green:0.38f blue:0.55f alpha:1]; }
+ (UIColor *)selectionColor { return [self isDarkTheme] ? [UIColor colorWithRed:0.14f green:0.31f blue:0.46f alpha:1] : [UIColor colorWithRed:0.18f green:0.42f blue:0.72f alpha:1]; }
+ (UIColor *)separatorColor { return [self isDarkTheme] ? [UIColor colorWithRed:0.20f green:0.21f blue:0.23f alpha:1] : [UIColor colorWithWhite:0.86f alpha:1]; }
+ (UIColor *)borderColor { return [self isDarkTheme] ? [UIColor colorWithRed:0.25f green:0.27f blue:0.29f alpha:1] : [UIColor colorWithWhite:0.72f alpha:1]; }
+ (UIColor *)placeholderColor { return [self isDarkTheme] ? [UIColor colorWithRed:0.14f green:0.15f blue:0.17f alpha:1] : [UIColor colorWithWhite:0.90f alpha:1]; }
+ (UIColor *)navigationBarColor { return [self isDarkTheme] ? [self elevatedBackgroundColor] : [self accentColor]; }
+ (UIColor *)navigationBarTextColor { return [self primaryTextColor]; }
+ (UIColor *)tabBarColor { return [self isDarkTheme] ? [self elevatedBackgroundColor] : [UIColor colorWithWhite:0.92f alpha:1]; }
+ (UIColor *)searchBackgroundColor { return [self isDarkTheme] ? [self elevatedBackgroundColor] : [UIColor colorWithWhite:0.90f alpha:1]; }
+ (UIColor *)classicBodyColor { return [self isDarkTheme] ? [UIColor colorWithRed:0.063f green:0.067f blue:0.075f alpha:1] : [UIColor colorWithRed:0.88f green:0.88f blue:0.86f alpha:1]; }
+ (UIColor *)classicDisplayColor { return [self isDarkTheme] ? [self secondaryBackgroundColor] : [UIColor colorWithWhite:0.97f alpha:1]; }
+ (UIColor *)classicHeaderColor { return [self isDarkTheme] ? [self elevatedBackgroundColor] : [UIColor colorWithWhite:0.90f alpha:1]; }
+ (UIColor *)classicWheelColor { return [self isDarkTheme] ? [UIColor colorWithRed:0.16f green:0.17f blue:0.18f alpha:1] : [UIColor colorWithRed:0.78f green:0.79f blue:0.79f alpha:1]; }
+ (UIColor *)classicWheelBorderColor { return [self isDarkTheme] ? [UIColor colorWithRed:0.29f green:0.30f blue:0.32f alpha:1] : [UIColor colorWithWhite:0.58f alpha:1]; }
+ (UIColor *)classicCenterColor { return [self isDarkTheme] ? [UIColor colorWithRed:0.11f green:0.12f blue:0.13f alpha:1] : [UIColor colorWithWhite:0.86f alpha:1]; }
+ (UIColor *)classicPressedCenterColor { return [self isDarkTheme] ? [UIColor colorWithRed:0.23f green:0.25f blue:0.27f alpha:1] : [UIColor colorWithWhite:0.66f alpha:1]; }
+ (UIColor *)classicWheelTextColor { return [self isDarkTheme] ? [UIColor colorWithWhite:0.82f alpha:1] : [UIColor colorWithWhite:0.27f alpha:1]; }
+ (UIFont *)largeTitleFont { return [UIFont boldSystemFontOfSize:23]; }
+ (UIFont *)sectionTitleFont { return [UIFont boldSystemFontOfSize:17]; }
+ (UIFont *)primaryFont { return [UIFont boldSystemFontOfSize:15]; }
+ (UIFont *)secondaryFont { return [UIFont systemFontOfSize:12]; }
+ (UIFont *)metadataFont { return [UIFont systemFontOfSize:11]; }
+ (CGFloat)contentMargin { return 12.0f; }
+ (CGFloat)listRowHeight { return 50.0f; }
+ (CGFloat)compactRowHeight { return 46.0f; }
+ (CGFloat)searchBarHeight { return 44.0f; }
+ (CGFloat)sectionHeaderHeight { return 24.0f; }
+ (CGFloat)alphabetIndexWidth { return 20.0f; }
+ (void)styleTableView:(UITableView *)tableView {
    tableView.backgroundColor = [self backgroundColor]; tableView.separatorColor = [self separatorColor];
    tableView.rowHeight = [self listRowHeight];
    UIView *background = tableView.backgroundView; background.backgroundColor = [self backgroundColor]; NSUInteger index;
    for (index = 0; index < [[background subviews] count]; index++) { UIView *view = [[background subviews] objectAtIndex:index];
        if ([view isKindOfClass:[UILabel class]]) ((UILabel *)view).textColor = [self secondaryTextColor];
        else if ([view isKindOfClass:[UIActivityIndicatorView class]])
            ((UIActivityIndicatorView *)view).activityIndicatorViewStyle = [self isDarkTheme] ? UIActivityIndicatorViewStyleWhite : UIActivityIndicatorViewStyleGray;
    }
}
@end
