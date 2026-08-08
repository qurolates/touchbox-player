#import "TBFavoritesViewController.h"
#import "TBFavoritesManager.h"
#import "TBLibraryManager.h"

@implementation TBFavoritesViewController

- (id)init {
    return [super initWithTitle:@"Favorites" items:[NSArray array]];
}

- (void)reloadTrackItems {
    self.items = [[TBFavoritesManager sharedManager]
        favoriteItemsFromSongs:[[TBLibraryManager sharedManager] songs]];
}

@end
