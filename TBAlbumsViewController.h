#import <UIKit/UIKit.h>

@class TBAlphabetIndexView;

@interface TBAlbumsViewController : UIViewController <UITableViewDataSource, UITableViewDelegate, UISearchBarDelegate> {
    NSArray *_artistGroups;
    NSArray *_allArtistGroups;
    NSArray *_sectionIndexMap;
    UITableView *_tableView;
    TBAlphabetIndexView *_alphabetIndexView;
    UISearchBar *_searchBar;
}
@property(nonatomic, retain) UITableView *tableView;
@end
