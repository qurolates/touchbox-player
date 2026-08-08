#import "TBQueueViewController.h"
#import "TBPlayerManager.h"
#import "TBTheme.h"
#import "TBIconFactory.h"

@implementation TBQueueViewController

- (id)init {
    self = [super initWithStyle:UITableViewStylePlain];
    if (self) self.title = @"Queue";
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [TBTheme styleTableView:self.tableView];
    UILabel *header = [[[UILabel alloc] initWithFrame:CGRectMake(0, 0, 320, 34)] autorelease];
    header.text = @"  UP NEXT";
    header.font = [TBTheme metadataFont];
    header.textColor = [TBTheme secondaryTextColor];
    header.backgroundColor = [TBTheme backgroundColor];
    self.tableView.tableHeaderView = header;
    _items = [[[TBPlayerManager sharedManager] queueItems] retain];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(nowPlayingChanged:)
        name:MPMusicPlayerControllerNowPlayingItemDidChangeNotification
        object:[TBPlayerManager sharedManager].musicPlayer];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(queueChanged:)
        name:TBPlayerQueueDidChangeNotification object:[TBPlayerManager sharedManager]];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(themeChanged:)
        name:TBThemeDidChangeNotification object:nil];
}
- (void)themeChanged:(NSNotification *)notification { [TBTheme styleTableView:self.tableView]; UILabel *header = (UILabel *)self.tableView.tableHeaderView; header.backgroundColor = [TBTheme backgroundColor]; header.textColor = [TBTheme secondaryTextColor]; [self.tableView reloadData]; }

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return (NSInteger)[_items count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *identifier = @"QueueCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:identifier];
    if (!cell) cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle
        reuseIdentifier:identifier] autorelease];
    cell.backgroundColor = [TBTheme backgroundColor];
    cell.textLabel.font = [TBTheme primaryFont];
    cell.textLabel.textColor = [TBTheme primaryTextColor];
    cell.detailTextLabel.font = [TBTheme secondaryFont];
    cell.detailTextLabel.textColor = [TBTheme secondaryTextColor];
    MPMediaItem *item = [_items objectAtIndex:(NSUInteger)indexPath.row];
    NSString *title = [item valueForProperty:MPMediaItemPropertyTitle];
    cell.textLabel.text = [NSString stringWithFormat:@"%02u  %@", (unsigned)indexPath.row + 1,
        title ? title : @"Unknown Title"];
    NSString *artist = [item valueForProperty:MPMediaItemPropertyArtist];
    cell.detailTextLabel.text = artist ? artist : @"Unknown Artist";
    BOOL playing = indexPath.row == [TBPlayerManager sharedManager].currentQueueIndex;
    cell.imageView.image = playing ? [TBIconFactory iconNamed:@"play" active:YES] : nil;
    cell.accessoryType = UITableViewCellAccessoryNone;
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    [[TBPlayerManager sharedManager] playQueueItemAtIndex:indexPath.row];
    [tableView reloadData];
}

- (void)nowPlayingChanged:(NSNotification *)notification { [self.tableView reloadData]; }
- (void)queueChanged:(NSNotification *)notification { [_items release]; _items = [[[TBPlayerManager sharedManager] queueItems] retain]; [self.tableView reloadData]; }

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [_items release];
    [super dealloc];
}

@end
