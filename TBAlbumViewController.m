#import "TBAlbumViewController.h"
#import "TBLibraryManager.h"

@implementation TBAlbumViewController

- (id)initWithAlbum:(NSDictionary *)album {
    self = [super initWithTitle:[album objectForKey:TBAlbumTitleKey]
                         items:[album objectForKey:TBAlbumItemsKey]];
    if (self) _album = [album retain];
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    UIView *header = [[[UIView alloc] initWithFrame:CGRectMake(0, 0, 320, 116)] autorelease];
    UIImageView *artworkView = [[[UIImageView alloc] initWithFrame:CGRectMake(10, 10, 96, 96)] autorelease];
    artworkView.contentMode = UIViewContentModeScaleAspectFit;
    NSArray *items = [_album objectForKey:TBAlbumItemsKey];
    if ([items count] > 0) {
        NSTimeInterval artworkStart = [NSDate timeIntervalSinceReferenceDate];
        MPMediaItemArtwork *artwork = [[items objectAtIndex:0] valueForProperty:MPMediaItemPropertyArtwork];
        artworkView.image = [artwork imageWithSize:CGSizeMake(96, 96)];
        NSLog(@"Touchbox timing: opened album artwork %.3f sec available=%@",
              [NSDate timeIntervalSinceReferenceDate] - artworkStart,
              artworkView.image ? @"YES" : @"NO");
    }
    [header addSubview:artworkView];

    UILabel *title = [[[UILabel alloc] initWithFrame:CGRectMake(116, 20, 194, 44)] autorelease];
    title.font = [UIFont boldSystemFontOfSize:17.0f];
    title.numberOfLines = 2;
    title.text = [_album objectForKey:TBAlbumTitleKey];
    [header addSubview:title];
    UILabel *artist = [[[UILabel alloc] initWithFrame:CGRectMake(116, 68, 194, 25)] autorelease];
    artist.font = [UIFont systemFontOfSize:14.0f];
    artist.textColor = [UIColor darkGrayColor];
    artist.text = [_album objectForKey:TBAlbumArtistKey];
    [header addSubview:artist];
    self.tableView.tableHeaderView = header;
}

- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [super tableView:tableView cellForRowAtIndexPath:indexPath];
    MPMediaItem *item = [self.items objectAtIndex:(NSUInteger)indexPath.row];
    NSNumber *track = [item valueForProperty:MPMediaItemPropertyAlbumTrackNumber];
    if ([track unsignedIntegerValue] > 0) {
        cell.textLabel.text = [NSString stringWithFormat:@"%u. %@",
            [track unsignedIntValue], cell.textLabel.text];
    }
    return cell;
}

- (void)didReceiveMemoryWarning {
    self.tableView.tableHeaderView = nil;
    [super didReceiveMemoryWarning];
}

- (void)dealloc {
    [_album release];
    [super dealloc];
}

@end
