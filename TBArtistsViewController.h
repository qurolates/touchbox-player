#import <UIKit/UIKit.h>

@interface TBArtistsViewController : UITableViewController {
    NSArray *_artistGroups;
    NSDictionary *_selectedArtist;
}

- (id)initWithArtist:(NSDictionary *)artist;

@end
