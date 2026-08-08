#import "TBTrackListViewController.h"

@interface TBAlbumViewController : TBTrackListViewController {
    NSDictionary *_album;
    UIImageView *_albumArtworkView;
    NSString *_albumArtworkKey;
}

- (id)initWithAlbum:(NSDictionary *)album;

@end
