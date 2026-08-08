# MediaPlayer compatibility report — iPhoneOS 4.1 SDK

Source of truth: `/Users/qura/theos/sdks/iPhoneOS4.1.sdk/System/Library/Frameworks/MediaPlayer.framework/Headers`.

## Available in headers

- `MPMediaQuery`, including `songsQuery`, `albumsQuery`, `artistsQuery`, and `playlistsQuery`
- `MPMediaItem`, `MPMediaItemCollection`, `MPMediaItemArtwork`, and `MPMediaPropertyPredicate`
- Metadata constants: title, artist, album artist, album title, genre, playback duration, persistent ID, and artwork
- `MPMediaItemArtwork -imageWithSize:`
- `MPMusicPlayerController +iPodMusicPlayer`
- Queue methods `setQueueWithItemCollection:` and `setQueueWithQuery:`
- `play`, `pause`, `stop`, previous, next, and beginning controls
- `playbackState`, writable `nowPlayingItem`, and writable `currentPlaybackTime`
- Playback-state, now-playing-item, and volume notifications
- `beginGeneratingPlaybackNotifications` and `endGeneratingPlaybackNotifications`

## Unavailable in headers

- `MPMediaItemPropertyAlbumPersistentID`

## Requires a real-device runtime test

- Third-party access to the device's populated system music library
- Correct queue start at the item assigned to `nowPlayingItem`
- Playback and transport controls through `iPodMusicPlayer`
- Delivery and timing of playback notifications
- Behavior for DRM-protected or otherwise unplayable items
