#import "TBFavoritesViewController.h"
#import "TBFavoritesManager.h"
#import "TBLibraryManager.h"
#import "TBLoadingView.h"
#import "TBTheme.h"

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
    UIView *header = [[[UIView alloc] initWithFrame:CGRectMake(0, 0, 320, 30)] autorelease];
    UILabel *countLabel = [[[UILabel alloc] initWithFrame:CGRectMake(15, 4, 290, 22)] autorelease];
    countLabel.backgroundColor = [TBTheme backgroundColor];
    countLabel.textColor = [TBTheme secondaryTextColor];
    countLabel.font = [TBTheme secondaryFont];
    countLabel.text = [NSString stringWithFormat:@"%lu tracks", (unsigned long)[self.items count]];
    [header addSubview:countLabel];
    self.tableView.tableHeaderView = header;
}

@end
