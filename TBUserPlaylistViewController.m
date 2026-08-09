#import "TBUserPlaylistViewController.h"
#import "TBUserPlaylistManager.h"
#import "TBLibraryManager.h"
#import "TBPlayerManager.h"
#import "TBTheme.h"

@implementation TBUserPlaylistViewController
- (id)initWithPlaylist:(NSDictionary *)playlist {
    self = [super initWithTitle:[playlist objectForKey:TBUserPlaylistNameKey] items:[NSArray array]];
    if (self) _playlistID = [[playlist objectForKey:TBUserPlaylistIDKey] copy];
    return self;
}
- (void)viewDidLoad {
    [super viewDidLoad];
    self.navigationItem.leftBarButtonItem = self.editButtonItem;
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playlistChanged:)
        name:TBUserPlaylistsDidChangeNotification object:[TBUserPlaylistManager sharedManager]];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(libraryReady:)
        name:TBLibraryIndexDidLoadNotification object:[TBLibraryManager sharedManager]];
    [self reloadTrackItems];
}
- (void)reloadTrackItems {
    NSDictionary *playlist = [[TBUserPlaylistManager sharedManager] playlistWithID:_playlistID];
    NSArray *trackIDs = [playlist objectForKey:TBUserPlaylistTrackIDsKey];
    self.items = [[TBLibraryManager sharedManager] itemsForPersistentIDs:trackIDs];
    UIView *header = [[[UIView alloc] initWithFrame:CGRectMake(0, 0, self.tableView.bounds.size.width, 38)] autorelease];
    UILabel *count = [[[UILabel alloc] initWithFrame:CGRectMake([TBTheme contentMargin], 7, 150, 24)] autorelease];
    count.backgroundColor = [TBTheme backgroundColor]; count.font = [TBTheme secondaryFont];
    count.textColor = [TBTheme secondaryTextColor];
    count.text = [NSString stringWithFormat:@"%lu tracks", (unsigned long)[self.items count]];
    [header addSubview:count];
    UIButton *shuffle = [UIButton buttonWithType:UIButtonTypeCustom];
    shuffle.titleLabel.font = [TBTheme secondaryFont];
    shuffle.frame = CGRectMake(MAX([TBTheme contentMargin], header.bounds.size.width - 87.0f), 2, 75, 34);
    shuffle.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin;
    [shuffle setTitle:@"Shuffle" forState:UIControlStateNormal];
    [shuffle setTitleColor:[TBTheme accentColor] forState:UIControlStateNormal];
    shuffle.enabled = [self.items count] > 0;
    [shuffle addTarget:self action:@selector(shufflePlaylist:) forControlEvents:UIControlEventTouchUpInside];
    [header addSubview:shuffle];
    self.tableView.tableHeaderView = header;
}
- (void)applyTheme { [super applyTheme]; UIView *header = self.tableView.tableHeaderView; header.backgroundColor = [TBTheme backgroundColor]; NSUInteger i; for (i = 0; i < [[header subviews] count]; i++) { UIView *view = [[header subviews] objectAtIndex:i]; if ([view isKindOfClass:[UILabel class]]) { view.backgroundColor = [TBTheme backgroundColor]; ((UILabel *)view).textColor = [TBTheme secondaryTextColor]; } else if ([view isKindOfClass:[UIButton class]]) [(UIButton *)view setTitleColor:[TBTheme accentColor] forState:UIControlStateNormal]; } }
- (void)shufflePlaylist:(id)sender {
    if (![self.items count]) return;
    [[TBPlayerManager sharedManager] playItemsShuffled:self.items];
    [self showNowPlaying:nil];
}
- (void)playlistChanged:(NSNotification *)notification { [self reloadTrackItems]; [self.tableView reloadData]; }
- (void)libraryReady:(NSNotification *)notification { [self reloadTrackItems]; [self.tableView reloadData]; }
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)style
 forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (style != UITableViewCellEditingStyleDelete || indexPath.row >= (NSInteger)[self.items count]) return;
    MPMediaItem *item = [self.items objectAtIndex:(NSUInteger)indexPath.row];
    NSNumber *number = [item valueForProperty:MPMediaItemPropertyPersistentID];
    NSString *trackID = [NSString stringWithFormat:@"%llu", [number unsignedLongLongValue]];
    NSMutableDictionary *playlist = (NSMutableDictionary *)[[TBUserPlaylistManager sharedManager]
        playlistWithID:_playlistID];
    NSMutableArray *trackIDs = [playlist objectForKey:TBUserPlaylistTrackIDsKey];
    NSUInteger storedIndex = [trackIDs indexOfObject:trackID];
    if (storedIndex != NSNotFound) [[TBUserPlaylistManager sharedManager]
        removeTrackAtIndex:storedIndex fromPlaylistID:_playlistID];
}
- (void)dealloc { [[NSNotificationCenter defaultCenter] removeObserver:self]; [_playlistID release]; [super dealloc]; }
@end
