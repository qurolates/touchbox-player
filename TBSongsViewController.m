#import "TBSongsViewController.h"
#import "TBLibraryManager.h"
#import "TBLoadingView.h"

@implementation TBSongsViewController

- (id)init {
    return [super initWithTitle:@"Songs" items:[[TBLibraryManager sharedManager] songs]];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    NSLog(@"Touchbox: Songs viewDidLoad");
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(songsReady:)
        name:TBLibrarySongsDidLoadNotification object:[TBLibraryManager sharedManager]];
    if (![[TBLibraryManager sharedManager] songsLoaded]) {
        self.tableView.backgroundView = TBCreateLoadingView(@"Loading Songs…");
        [[TBLibraryManager sharedManager] beginLoadingLibrary];
    } else {
        self.items = [[TBLibraryManager sharedManager] songs];
        self.tableView.backgroundView = nil;
        NSLog(@"Touchbox: songs count=%lu table rows=%lu (already loaded)",
              (unsigned long)[self.items count], (unsigned long)[self.items count]);
        [self.tableView reloadData];
    }
}

- (void)songsReady:(NSNotification *)notification {
    self.items = [[TBLibraryManager sharedManager] songs];
    NSLog(@"Touchbox: songs count=%lu table rows=%lu (notification)",
          (unsigned long)[self.items count], (unsigned long)[self.items count]);
    self.tableView.backgroundView = nil;
    [self.tableView reloadData];
}

@end
