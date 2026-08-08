#import "TBQueueViewController.h"
#import "TBPlayerManager.h"

@implementation TBQueueViewController

- (id)init {
    self = [super initWithStyle:UITableViewStylePlain];
    if (self) self.title = @"Queue";
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    _items = [[[TBPlayerManager sharedManager] queueItems] retain];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(nowPlayingChanged:)
        name:MPMusicPlayerControllerNowPlayingItemDidChangeNotification
        object:[TBPlayerManager sharedManager].musicPlayer];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return (NSInteger)[_items count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *identifier = @"QueueCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:identifier];
    if (!cell) cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle
        reuseIdentifier:identifier] autorelease];
    MPMediaItem *item = [_items objectAtIndex:(NSUInteger)indexPath.row];
    NSString *title = [item valueForProperty:MPMediaItemPropertyTitle];
    cell.textLabel.text = [NSString stringWithFormat:@"%u. %@", (unsigned)indexPath.row + 1,
        title ? title : @"Unknown Title"];
    cell.detailTextLabel.text = [item valueForProperty:MPMediaItemPropertyArtist];
    cell.accessoryType = (indexPath.row == [TBPlayerManager sharedManager].currentQueueIndex)
        ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    [[TBPlayerManager sharedManager] playQueueItemAtIndex:indexPath.row];
    [tableView reloadData];
}

- (void)nowPlayingChanged:(NSNotification *)notification { [self.tableView reloadData]; }

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [_items release];
    [super dealloc];
}

@end
