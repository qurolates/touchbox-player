#import "TBArtistsViewController.h"
#import "TBLibraryManager.h"
#import "TBAlbumViewController.h"

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
    if (_selectedArtist == nil) {
        _artistGroups = [[[TBLibraryManager sharedManager] artistGroups] retain];
    }
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
        cell.detailTextLabel.text = [NSString stringWithFormat:@"%lu tracks",
            (unsigned long)[[album objectForKey:TBAlbumItemsKey] count]];
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
    [_artistGroups release];
    [_selectedArtist release];
    [super dealloc];
}

@end
