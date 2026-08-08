#import <UIKit/UIKit.h>

@interface TBPlaylistsViewController : UITableViewController <UISearchBarDelegate> {
    NSArray *_playlists;
    NSArray *_userPlaylists;
    NSArray *_allPlaylists;
    NSArray *_allUserPlaylists;
    UISearchBar *_searchBar;
    BOOL _loadingPlaylistItems;
}
@end
