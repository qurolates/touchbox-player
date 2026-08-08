#import "TBArtistsViewController.h"
#import "TBLibraryManager.h"
#import "TBAlbumViewController.h"
#import "TBLoadingView.h"
#import "TBNowPlayingViewController.h"

@implementation TBArtistsViewController

- (id)init {
    self = [super initWithStyle:UITableViewStylePlain];
    if (self) self.title = @"Artists";
    return self;
}

- (id)initWithArtist:(NSDictionary *)artist {
    self = [super initWithStyle:UITableViewStylePlain];
    if (self) {
        _selectedArtist = [artist retain];
        self.title = [artist objectForKey:TBArtistNameKey];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.navigationItem.rightBarButtonItem = [[[UIBarButtonItem alloc]
        initWithTitle:@"Player" style:UIBarButtonItemStyleBordered
        target:self action:@selector(showNowPlaying:)] autorelease];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(indexReady:)
        name:TBLibraryIndexDidLoadNotification object:[TBLibraryManager sharedManager]];
    if (_selectedArtist == nil) {
        _artistGroups = [[[TBLibraryManager sharedManager] artistGroups] retain];
        if (![[TBLibraryManager sharedManager] indexLoaded]) {
            self.tableView.backgroundView = TBCreateLoadingView(@"Preparing Artists…");
            [[TBLibraryManager sharedManager] beginLoadingLibrary];
        }
    }
}

- (void)showNowPlaying:(id)sender {
    TBNowPlayingViewController *controller = [[TBNowPlayingViewController alloc] init];
    [self.navigationController pushViewController:controller animated:YES];
    [controller release];
}

- (void)indexReady:(NSNotification *)notification {
    if (_selectedArtist) {
        NSString *name = [_selectedArtist objectForKey:TBArtistNameKey];
        NSArray *groups = [[TBLibraryManager sharedManager] artistGroups];
        NSUInteger index;
        for (index = 0; index < [groups count]; index++) {
            NSDictionary *group = [groups objectAtIndex:index];
            if ([[group objectForKey:TBArtistNameKey] isEqualToString:name]) {
                [_selectedArtist release];
                _selectedArtist = [group retain];
                break;
            }
        }
    } else {
        [_artistGroups release];
        _artistGroups = [[[TBLibraryManager sharedManager] artistGroups] retain];
    }
    self.tableView.backgroundView = nil;
    [self.tableView reloadData];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.navigationController setToolbarHidden:YES animated:animated];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (_selectedArtist) return (NSInteger)[[self selectedAlbums] count];
    return (NSInteger)[_artistGroups count];
}

- (NSArray *)selectedAlbums { return [_selectedArtist objectForKey:TBAlbumsKey]; }

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *identifier = @"ArtistCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:identifier];
    if (cell == nil) cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle
        reuseIdentifier:identifier] autorelease];
    if (_selectedArtist) {
        NSDictionary *album = [[self selectedAlbums] objectAtIndex:(NSUInteger)indexPath.row];
        cell.textLabel.text = [album objectForKey:TBAlbumTitleKey];
        NSArray *tracks = [album objectForKey:TBAlbumItemsKey];
        if (tracks == nil) tracks = [album objectForKey:TBAlbumTrackRecordsKey];
        cell.detailTextLabel.text = [NSString stringWithFormat:@"%lu tracks",
            (unsigned long)[tracks count]];
    } else {
        NSDictionary *artist = [_artistGroups objectAtIndex:(NSUInteger)indexPath.row];
        cell.textLabel.text = [artist objectForKey:TBArtistNameKey];
        cell.detailTextLabel.text = [NSString stringWithFormat:@"%lu albums",
            (unsigned long)[[artist objectForKey:TBAlbumsKey] count]];
    }
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    UIViewController *controller;
    if (_selectedArtist) {
        if (![[TBLibraryManager sharedManager] mediaItemsReady]) {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Library Loading"
                message:@"Tracks will be available in a moment." delegate:nil
                cancelButtonTitle:@"OK" otherButtonTitles:nil];
            [alert show];
            [alert release];
            return;
        }
        controller = [[TBAlbumViewController alloc]
            initWithAlbum:[[self selectedAlbums] objectAtIndex:(NSUInteger)indexPath.row]];
    } else {
        controller = [[TBArtistsViewController alloc]
            initWithArtist:[_artistGroups objectAtIndex:(NSUInteger)indexPath.row]];
    }
    [self.navigationController pushViewController:controller animated:YES];
    [controller release];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [_artistGroups release];
    [_selectedArtist release];
    [super dealloc];
}

@end
