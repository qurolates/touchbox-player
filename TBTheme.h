#import <UIKit/UIKit.h>

typedef enum { TBThemeModeLight = 0, TBThemeModeDark = 1 } TBThemeMode;
extern NSString *const TBThemeDidChangeNotification;

@interface TBTheme : NSObject
+ (TBThemeMode)currentTheme;
+ (void)setCurrentTheme:(TBThemeMode)theme;
+ (BOOL)isDarkTheme;
+ (UIColor *)backgroundColor;
+ (UIColor *)secondaryBackgroundColor;
+ (UIColor *)elevatedBackgroundColor;
+ (UIColor *)primaryTextColor;
+ (UIColor *)secondaryTextColor;
+ (UIColor *)disabledTextColor;
+ (UIColor *)accentColor;
+ (UIColor *)selectionColor;
+ (UIColor *)separatorColor;
+ (UIColor *)borderColor;
+ (UIColor *)placeholderColor;
+ (UIColor *)navigationBarColor;
+ (UIColor *)navigationBarTextColor;
+ (UIColor *)tabBarColor;
+ (UIColor *)searchBackgroundColor;
+ (UIColor *)classicBodyColor;
+ (UIColor *)classicDisplayColor;
+ (UIColor *)classicHeaderColor;
+ (UIColor *)classicWheelColor;
+ (UIColor *)classicWheelBorderColor;
+ (UIColor *)classicCenterColor;
+ (UIColor *)classicPressedCenterColor;
+ (UIColor *)classicWheelTextColor;
+ (UIFont *)largeTitleFont;
+ (UIFont *)sectionTitleFont;
+ (UIFont *)primaryFont;
+ (UIFont *)secondaryFont;
+ (UIFont *)metadataFont;
+ (CGFloat)contentMargin;
+ (CGFloat)listRowHeight;
+ (CGFloat)compactRowHeight;
+ (CGFloat)searchBarHeight;
+ (CGFloat)sectionHeaderHeight;
+ (CGFloat)alphabetIndexWidth;
+ (void)styleTableView:(UITableView *)tableView;
@end
