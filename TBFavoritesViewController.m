#import "TBFavoritesViewController.h"
#import "TBFavoritesManager.h"
#import "TBLibraryManager.h"
#import "TBLoadingView.h"
#import "TBTheme.h"
#import "TBPlayerManager.h"

@implementation TBFavoritesViewController

- (id)init {
    return [super initWithTitle:@"Favorites" items:[NSArray array]];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.navigationItem.leftBarButtonItem = [[[UIBarButtonItem alloc]
        initWithTitle:@"Shuffle" style:UIBarButtonItemStyleBordered
        target:self action:@selector(shuffleFavorites:)] autorelease];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(songsReady:)
        name:TBLibrarySongsDidLoadNotification object:[TBLibraryManager sharedManager]];
    if (![[TBLibraryManager sharedManager] songsLoaded]) {
        self.tableView.backgroundView = TBCreateLoadingView(@"Loading Favorites…");
        [[TBLibraryManager sharedManager] beginLoadingLibrary];
    }
}

- (void)shuffleFavorites:(id)sender {
    if ([self.items count] == 0) return;
    [[TBPlayerManager sharedManager] playItemsShuffled:self.items];
    [self showNowPlaying:nil];
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
    self.navigationItem.prompt = [NSString stringWithFormat:@"%lu tracks", (unsigned long)[self.items count]];
    self.navigationItem.leftBarButtonItem.enabled = [self.items count] > 0;
}

@end
