#import <UIKit/UIKit.h>

@class TBAlphabetIndexView;

@interface TBArtistsViewController : UIViewController <UITableViewDataSource, UITableViewDelegate, UISearchBarDelegate> {
    NSArray *_artistGroups;
    NSArray *_allArtistGroups;
    NSDictionary *_selectedArtist;
    NSArray *_sectionIndexMap;
    UISearchBar *_searchBar;
    UITableView *_tableView;
    TBAlphabetIndexView *_alphabetIndexView;
}

@property(nonatomic, retain) UITableView *tableView;

- (id)initWithArtist:(NSDictionary *)artist;

@end
