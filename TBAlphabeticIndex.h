#import <Foundation/Foundation.h>

@interface TBAlphabeticIndex : NSObject
+ (NSArray *)titles;
+ (NSArray *)titlesForArtistGroups:(NSArray *)groups;
+ (NSArray *)sectionMapForArtistGroups:(NSArray *)groups;
@end
