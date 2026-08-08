#import "TBSongsViewController.h"
#import "TBLibraryManager.h"

@implementation TBSongsViewController

- (id)init {
    return [super initWithTitle:@"Songs" items:[[TBLibraryManager sharedManager] songs]];
}

@end
