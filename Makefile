ARCHS = armv7
TARGET = iphone:clang:4.1:4.1

include $(THEOS)/makefiles/common.mk

APPLICATION_NAME = Touchbox

Touchbox_FILES = main.m AppDelegate.m \
	TBLibraryManager.m TBPlayerManager.m TBFavoritesManager.m \
	TBUserPlaylistManager.m \
	TBRecentManager.m TBRecentViewController.m \
	TBClickWheelView.m TBClassicViewController.m \
	TBLoadingView.m \
	TBTheme.m TBThemeViewController.m TBIconFactory.m \
	TBAlphabeticIndex.m \
	TBAlphabetIndexView.m \
	TBArtworkCache.m TBAlbumGridCell.m \
	TBNowPlayingViewController.m TBQueueViewController.m \
	TBPlaylistNameViewController.m TBUserPlaylistViewController.m \
	TBAddToPlaylistViewController.m \
	TBTrackListViewController.m TBSongsViewController.m \
	TBAlbumsViewController.m TBArtistsViewController.m TBAlbumViewController.m \
	TBFavoritesViewController.m TBPlaylistsViewController.m
Touchbox_FRAMEWORKS = UIKit Foundation CoreGraphics MediaPlayer
TB_DEBUG_PERFORMANCE ?= 0
Touchbox_CFLAGS = -fno-objc-arc -DTB_DEBUG_PERFORMANCE=$(TB_DEBUG_PERFORMANCE)

include $(THEOS_MAKE_PATH)/application.mk
