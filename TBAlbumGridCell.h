#import <UIKit/UIKit.h>

@interface TBAlbumItemControl : UIControl {
    UIImageView *_artworkView;
    UILabel *_titleLabel;
    UILabel *_artistLabel;
    NSDictionary *_album;
    NSString *_artworkKey;
}

@property(nonatomic, retain) NSDictionary *album;
@property(nonatomic, copy) NSString *artworkKey;
- (void)configureWithAlbum:(NSDictionary *)album;
- (void)resetContent;

@end

@interface TBAlbumGridCell : UITableViewCell {
    TBAlbumItemControl *_leftItem;
    TBAlbumItemControl *_rightItem;
}

@property(nonatomic, readonly) TBAlbumItemControl *leftItem;
@property(nonatomic, readonly) TBAlbumItemControl *rightItem;

@end
