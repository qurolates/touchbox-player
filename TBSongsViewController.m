#import "TBSongsViewController.h"
#import "TBLibraryManager.h"
#import "TBLoadingView.h"

@implementation TBSongsViewController

- (id)init {
    return [super initWithTitle:@"Songs" items:[[TBLibraryManager sharedManager] songs]];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(songsReady:)
        name:TBLibrarySongsDidLoadNotification object:[TBLibraryManager sharedManager]];
    if (![[TBLibraryManager sharedManager] songsLoaded]) {
        self.tableView.backgroundView = TBCreateLoadingView(@"Loading Songs…");
        [[TBLibraryManager sharedManager] beginLoadingLibrary];
    }
}

- (void)songsReady:(NSNotification *)notification {
    self.items = [[TBLibraryManager sharedManager] songs];
    self.tableView.backgroundView = nil;
    [self.tableView reloadData];
}

@end
