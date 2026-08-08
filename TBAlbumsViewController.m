#import "TBAlbumsViewController.h"
#import "TBLibraryManager.h"
#import "TBAlbumViewController.h"

@implementation TBAlbumsViewController

- (id)init {
    self = [super initWithStyle:UITableViewStylePlain];
    if (self) self.title = @"Albums";
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    _artistGroups = [[[TBLibraryManager sharedManager] artistGroups] retain];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.navigationController setToolbarHidden:YES animated:animated];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return (NSInteger)[_artistGroups count];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return (NSInteger)[[[_artistGroups objectAtIndex:(NSUInteger)section]
        objectForKey:TBAlbumsKey] count];
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    return [[_artistGroups objectAtIndex:(NSUInteger)section] objectForKey:TBArtistNameKey];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *identifier = @"AlbumCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:identifier];
    if (cell == nil) cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault
        reuseIdentifier:identifier] autorelease];
    NSArray *albums = [[_artistGroups objectAtIndex:(NSUInteger)indexPath.section]
        objectForKey:TBAlbumsKey];
    cell.textLabel.text = [[albums objectAtIndex:(NSUInteger)indexPath.row]
        objectForKey:TBAlbumTitleKey];
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    NSArray *albums = [[_artistGroups objectAtIndex:(NSUInteger)indexPath.section]
        objectForKey:TBAlbumsKey];
    TBAlbumViewController *controller = [[TBAlbumViewController alloc]
        initWithAlbum:[albums objectAtIndex:(NSUInteger)indexPath.row]];
    [self.navigationController pushViewController:controller animated:YES];
    [controller release];
}

- (void)dealloc { [_artistGroups release]; [super dealloc]; }

@end
