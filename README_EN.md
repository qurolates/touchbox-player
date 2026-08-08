# Touchbox

[Русская версия](README.md)

Touchbox is a full-featured offline music player for the local iPod touch library. It combines the capabilities of a modern local player with a separate Classic Mode inspired by the iPod Classic and controlled through a virtual Click Wheel.

The application is designed primarily for the iPod touch 3G running iOS 4.1. It may also run on iOS 5 and iOS 6, but iPod3,1 / iOS 4.1 remains the main target and device-test configuration.

## Core Features

- Full playback of the local iPod/iOS media library.
- Browse music by album, artist, and song.
- Album artwork and dedicated release pages.
- Album track lists with track number, title, and duration.
- Correct disc and track-number ordering.
- Automatic transition to Now Playing after selecting a song.
- A mini-player in Standard Mode.
- Search, Favorites, custom playlists, Recent lists, and a controllable queue.
- Two independent interfaces: Standard Mode and Classic Mode.
- Global Light and Dark themes.

## Now Playing

The complete Now Playing screen includes:

- album artwork;
- track title;
- artist and album;
- playback progress;
- elapsed and remaining time;
- Play/Pause, Previous, and Next;
- Shuffle and Repeat;
- Favorite;
- Queue;
- Add to Playlist.

The playback position can be changed with the slider, including while paused. Metadata, artwork, progress, and Favorite state update automatically when the track changes.

## Navigation and Search

Large libraries are easier to navigate with:

- A–Z/# navigation in Artists;
- a dedicated alphabetical bar in Albums that does not cover artwork;
- search across Songs, Albums, Artists, Favorites, and Playlists;
- matching by song title, artist, and album;
- queues built from the active search results when a result is played.

Search operates on the existing library index and does not rescan the system media library after every typed character.

## Favorites

Touchbox has its own Favorites system, independent of system playlists. You can:

- add or remove the current song with the star button;
- see Favorite state in lists and Now Playing;
- open a dedicated Favorites list;
- play it as a separate queue;
- shuffle all Favorites;
- change Favorite state from a contextual menu.

Favorites persist between application launches.

## Touchbox Playlists

Touchbox creates editable local playlists independently of the limitations of the old MediaPlayer API:

- create and name a playlist;
- open, play, or shuffle it;
- add and remove songs;
- create a playlist while listening;
- add the current song from Now Playing;
- add a song through a long press;
- prevent accidental duplicates.

System iPod/iTunes playlists can also be browsed and played. Touchbox Playlists are stored separately and never attempt to edit system playlists.

## Full Playback Queue

Touchbox maintains its own playback queue model with support for:

- viewing the current queue;
- selecting any queued song;
- Play Next;
- Add to Queue;
- Shuffle;
- saving and restoring the queue after relaunch.

The queue follows the playback context. Starting a song from an album creates an album queue; starting from a playlist, Favorites, Recent, or search results uses that corresponding list.

## Contextual Track Actions

Long-pressing a song opens the relevant actions:

```text
Play Next
Add to Queue
Add to Playlist
Add/Remove Favorite
Go to Album
Go to Artist
```

The menu works across different sections and targets the correct track even in filtered search results. A normal tap plays the song and opens Now Playing.

## Shuffle Everywhere

The shared playback system can shuffle:

- the entire song library;
- an album;
- every song by an artist;
- Favorites;
- a Touchbox Playlist;
- Recently Played;
- Recently Added.

The original library, album, or playlist order is not modified. Only the playback queue is shuffled.

## Recent

Recent contains two lists:

- **Recently Played** records recently played unique tracks;
- **Recently Added** shows music recently discovered by the Touchbox index.

When the old public iOS API does not provide a reliable date-added value, Touchbox records when it first discovers each track. Both lists can be played as queues or shuffled.

## Playback State Restoration

Touchbox remembers:

- the current song;
- the position within the song;
- the queue and current index;
- Shuffle and Repeat;
- the last UI mode;
- the selected theme.

After relaunch, the previous session can be resumed from almost the same point. The restored player remains paused for a predictable startup. Tracks removed from the device are safely omitted instead of causing a crash.

## Standard Mode

Standard Mode is the conventional touch interface with a tab bar, search, lists, mini-player, and complete Now Playing screen.

Albums use a two-column artwork grid. Standard Mode organizes albums primarily by artist: Artist → Albums. Album pages show artwork, metadata, Play, and the ordered track list.

Its main sections are:

- Albums;
- Artists;
- Songs;
- Favorites;
- Playlists.

## Classic Mode and the Virtual Click Wheel

Classic Mode is not merely a visual skin. It has an independent navigation interface with true circular finger control:

```text
             MENU

       Previous     Next

            SELECT

           Play/Pause
```

The Click Wheel supports clockwise and counter-clockwise rotation, Center/Select, MENU/Back, Previous, Next, and Play/Pause. It provides access to:

- Music;
- Artists;
- Albums;
- Songs;
- Favorites;
- Playlists;
- Recent;
- Queue;
- Now Playing;
- Settings.

Classic Albums is adapted specifically for wheel navigation: it is a flat A–Z list sorted by album title instead of Standard Mode's artist grouping.

Classic Now Playing displays artwork, title, artist, album, progress, time, and queue position. Pressing Center provides Favorite, Add to Playlist, Play Next, Queue, Shuffle, and Repeat actions.

Standard and Classic share one media library, one queue, and one playback engine. You can switch between them during playback without resetting the music, position, or queue.

## Light and Dark Themes

The global theme applies to both interfaces, producing four combinations:

```text
Standard Light
Standard Dark
Classic Light
Classic Dark
```

Themes change live without restarting the application or interrupting playback. Dark Mode uses a dedicated graphite palette for Standard UI, the Classic display, and the Click Wheel rather than simply inverting colors. The selection persists across launches.

## Optimized for Old Hardware

Touchbox is designed around the iPod touch 3G and approximately 256 MB of RAM:

- the library is indexed in one pass;
- a lightweight persistent cache accelerates later Albums and Artists launches;
- artwork loads lazily for visible items only;
- the in-memory artwork cache is limited;
- images are never stored in the library index;
- tables use reusable cells;
- Favorites, Playlists, Recent, and Queue store persistent IDs;
- search does not start a new `MPMediaQuery` for each character;
- Click Wheel steps never query the media library;
- Classic Mode uses mostly lightweight text lists;
- unnecessary animations and heavy visual effects are avoided.

The goal is not merely to launch on iOS 4.1, but to remain responsive and practical on its real hardware.

## How It Differs from Music on iOS 4

On top of the local system library, Touchbox adds:

**two interfaces → a virtual Click Wheel → Dark Mode → custom Favorites → editable Touchbox Playlists → Add to Playlist from Now Playing → Play Next → Add to Queue → a controllable queue → search → Recent → playback-state restoration → extended Shuffle → contextual actions → an optimized library index.**

Touchbox remains a native offline player for music already stored on the device: no streaming, accounts, recommendations, advertising, or internet dependency.

## Compatibility and Installation

- primary platform: iPod touch 3G / iPod3,1;
- verified target version: iOS 4.1;
- may also run on iOS 5 and iOS 6;
- 320×480 non-Retina display;
- ARMv7;
- jailbreak and `.deb` installation;
- public `MediaPlayer.framework` APIs.

After installation, respring the device. If SpringBoard shows an old or missing icon, refresh the icon cache with `uicache` and respring again.

> iOS 5 and iOS 6 are listed as possible compatibility targets. The primary development and device-test configuration is an iPod3,1 running iOS 4.1.

## Brief Implementation Notes

Touchbox is written in Objective-C with Manual Reference Counting and built with Theos against `iPhoneOS4.1.sdk`:

```sh
make clean package THEOS=/path/to/theos
```

`TBLibraryManager` handles the media index, `TBPlayerManager` provides shared playback and queue management, and lightweight managers store Favorites, Playlists, and Recent data. `TBTheme` supplies the shared palette. Standard and Classic are two presentation layers over the same playback engine and user data.
