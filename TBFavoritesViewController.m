#import "TBFavoritesViewController.h"
#import "TBFavoritesManager.h"
#import "TBLibraryManager.h"
#import "TBLoadingView.h"

@implementation TBFavoritesViewController

- (id)init {
    return [super initWithTitle:@"Favorites" items:[NSArray array]];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(songsReady:)
        name:TBLibrarySongsDidLoadNotification object:[TBLibraryManager sharedManager]];
    if (![[TBLibraryManager sharedManager] songsLoaded]) {
        self.tableView.backgroundView = TBCreateLoadingView(@"Loading Favorites…");
        [[TBLibraryManager sharedManager] beginLoadingLibrary];
    }
}

- (void)songsReady:(NSNotification *)notification {
    self.tableView.backgroundView = nil;
    [self reloadTrackItems];
    [self.tableView reloadData];
}

- (void)reloadTrackItems {
    if (![[TBLibraryManager sharedManager] songsLoaded]) return;
    self.items = [[TBFavoritesManager sharedManager]
        favoriteItemsFromSongs:[[TBLibraryManager sharedManager] songs]];
}

@end
