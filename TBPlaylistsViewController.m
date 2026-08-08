#import "TBPlaylistsViewController.h"
#import "TBLibraryManager.h"
#import "TBTrackListViewController.h"

@implementation TBPlaylistsViewController

- (id)init {
    self = [super initWithStyle:UITableViewStylePlain];
    if (self) self.title = @"Playlists";
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    _playlists = [[[TBLibraryManager sharedManager] playlists] retain];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.navigationController setToolbarHidden:YES animated:animated];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return (NSInteger)[_playlists count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *identifier = @"PlaylistCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:identifier];
    if (cell == nil) cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle
        reuseIdentifier:identifier] autorelease];
    MPMediaPlaylist *playlist = [_playlists objectAtIndex:(NSUInteger)indexPath.row];
    NSString *name = [playlist valueForProperty:MPMediaPlaylistPropertyName];
    cell.textLabel.text = name ? name : @"Unknown Playlist";
    cell.detailTextLabel.text = [NSString stringWithFormat:@"%lu tracks", (unsigned long)playlist.count];
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    MPMediaPlaylist *playlist = [_playlists objectAtIndex:(NSUInteger)indexPath.row];
    NSString *name = [playlist valueForProperty:MPMediaPlaylistPropertyName];
    TBTrackListViewController *controller = [[TBTrackListViewController alloc]
        initWithTitle:(name ? name : @"Playlist") items:playlist.items];
    [self.navigationController pushViewController:controller animated:YES];
    [controller release];
}

- (void)dealloc { [_playlists release]; [super dealloc]; }

@end
