#import "TBTrackListViewController.h"

@interface TBAlbumViewController : TBTrackListViewController {
    NSDictionary *_album;
}

- (id)initWithAlbum:(NSDictionary *)album;

@end
