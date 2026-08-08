#import "TBAddToPlaylistViewController.h"
#import "TBUserPlaylistManager.h"
#import "TBPlaylistNameViewController.h"
#import "TBTheme.h"

@implementation TBAddToPlaylistViewController
- (id)initWithItem:(MPMediaItem *)item {
    self = [super initWithStyle:UITableViewStylePlain];
    if (self) { _item = [item retain]; self.title = @"Add to Playlist"; }
    return self;
}
- (void)viewDidLoad {
    [super viewDidLoad];
    [TBTheme styleTableView:self.tableView];
    _playlists = [[[TBUserPlaylistManager sharedManager] playlists] retain];
}
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return (NSInteger)[_playlists count] + 1;
}
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *identifier = @"AddPlaylistCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:identifier];
    if (!cell) cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault
        reuseIdentifier:identifier] autorelease];
    cell.backgroundColor = [TBTheme backgroundColor];
    cell.textLabel.font = [TBTheme primaryFont];
    if (indexPath.row == (NSInteger)[_playlists count]) {
        cell.textLabel.text = @"+ New Playlist";
        cell.textLabel.textColor = [TBTheme accentColor];
    } else {
        cell.textLabel.text = [[_playlists objectAtIndex:(NSUInteger)indexPath.row]
            objectForKey:TBUserPlaylistNameKey];
        cell.textLabel.textColor = [TBTheme primaryTextColor];
    }
    return cell;
}
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    if (indexPath.row == (NSInteger)[_playlists count]) {
        TBPlaylistNameViewController *nameController = [[TBPlaylistNameViewController alloc]
            initWithTarget:self action:@selector(createdPlaylistNamed:)];
        UINavigationController *navigation = [[UINavigationController alloc]
            initWithRootViewController:nameController];
        navigation.navigationBar.tintColor = [TBTheme accentColor];
        [nameController release];
        [self presentModalViewController:navigation animated:YES];
        [navigation release];
        return;
    }
    NSDictionary *playlist = [_playlists objectAtIndex:(NSUInteger)indexPath.row];
    BOOL added = [[TBUserPlaylistManager sharedManager] addItem:_item
        toPlaylistID:[playlist objectForKey:TBUserPlaylistIDKey]];
    [self showResultAdded:added];
}
- (void)createdPlaylistNamed:(NSString *)name {
    NSDictionary *playlist = [[TBUserPlaylistManager sharedManager] createPlaylistWithName:name];
    if (playlist) [[TBUserPlaylistManager sharedManager] addItem:_item
        toPlaylistID:[playlist objectForKey:TBUserPlaylistIDKey]];
    [self.navigationController popViewControllerAnimated:YES];
}
- (void)showResultAdded:(BOOL)added {
    [self.navigationController popViewControllerAnimated:YES];
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:(added ? @"Added" : @"Already Added")
        message:(added ? @"Track added to playlist." : @"This track is already in that playlist.")
        delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
    [alert show];
    [alert release];
}
- (void)dealloc { [_item release]; [_playlists release]; [super dealloc]; }
@end
