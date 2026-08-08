ВАЖНО: сборочная среда уже проверена на реальном устройстве.

Подтверждено:
- macOS Sonoma
- Xcode 15.4
- современный Theos
- настоящий iPhoneOS4.1.sdk в $THEOS/sdks/
- ARCHS = armv7
- TARGET = iphone:clang:4.1:4.1
- минимальное приложение успешно компилируется
- .deb успешно устанавливается по SSH
- приложение успешно запускается на реальном iPod touch 3G (iPod3,1) с iOS 4.1
- предупреждение Theos/libroot о minimum iOS 7 не препятствует запуску текущего тестового приложения

Не меняй SDK, deployment target, архитектуру или toolchain без реальной необходимости.

Текущий рабочий проект TouchboxTest использовать как проверенную основу.

Ты помогаешь разработать полноценное стороннее музыкальное приложение для iPod touch 3rd generation под iOS 4.1.
Проект предназначен для jailbreak-устройства и не должен соответствовать ограничениям App Store, но на первом этапе нужно максимально использовать публичные API iOS 4.1 и избегать ненужных private API.
Рабочее название проекта:
Touchbox
Главная идея Touchbox — превратить iPod touch 3G в удобный отдельный музыкальный плеер/DAP, используя уже существующую iOS 4.1, её драйверы, CoreAudio, системную музыкальную библиотеку и MediaPlayer.framework.
Touchbox НЕ является:
* новой операционной системой;
* Rockbox-портом;
* tweak’ом SpringBoard;
* модификацией Music.app;
* заменой системных драйверов;
* модифицированной IPSW.
На первом этапе Touchbox — обычное нативное приложение, установленное через jailbreak.
==================================================
 
ЦЕЛЕВОЕ УСТРОЙСТВО
Device:
iPod touch 3rd generation
model identifier: iPod3,1
OS:
iOS 4.1
Architecture:
ARMv7
Hardware constraints:
примерно 256 MB RAM
старый ARMv7 CPU
экран 320×480
non-Retina
touch interface
физические кнопки громкости отсутствуют
Устройство используется преимущественно как музыкальный плеер.
Особенно важны:
* низкое потребление RAM;
* низкая нагрузка на CPU;
* отсутствие лишних фоновых процессов;
* быстрый запуск;
* плавная прокрутка больших библиотек;
* стабильность при библиотеке примерно 2000–5000 треков;
* минимальное количество действий для запуска музыки.
==================================================
 
СРЕДА РАЗРАБОТКИ
Использовать:
Objective-C
UIKit
Foundation
MediaPlayer.framework
CoreGraphics
Memory management:
MRC
Manual Retain/Release
НЕ использовать:
ARC
Swift
SwiftUI
Storyboards
Auto Layout
UICollectionView
Combine
современные Objective-C/Swift API
API, появившиеся после iOS 4.1
Проект собирается через:
Theos
SDK:
$THEOS/sdks/iPhoneOS4.1.sdk
Host environment:
Linux / WSL
Если какая-либо часть современного Theos несовместима с SDK 4.1, сначала исследуй причину и предложи минимально необходимое изменение toolchain.
Не переходи автоматически на новый SDK, если проблему можно решить с настоящим iPhoneOS4.1.sdk.
==================================================
 
ВАЖНОЕ ПРАВИЛО СОВМЕСТИМОСТИ
Этот проект ориентирован именно на настоящую iOS 4.1.
НЕ предполагай, что API существует только потому, что он присутствует в современной Apple Documentation.
Перед использованием значимого API проверяй его наличие непосредственно в:
$THEOS/sdks/iPhoneOS4.1.sdk
Особенно:
System/Library/Frameworks/MediaPlayer.framework/Headers/
Headers SDK 4.1 являются главным источником истины.
Если API отсутствует:
1. не выдумывай его;
2. не используй более современный аналог;
3. явно сообщи об ограничении;
4. предложи совместимый способ реализации.
Compilation success НЕ означает совместимость с устройством.
Не утверждай, что функция точно работает на iOS 4.1, пока она не была протестирована на реальном iPod.
==================================================
 
АРХИТЕКТУРНАЯ ИДЕЯ
Touchbox не хранит собственные копии музыкальных файлов.
Он должен работать с той же музыкальной библиотекой, которую использует стандартное приложение Music/iPod.
Основная архитектура:
System Music Library
         ↓
    MediaPlayer.framework
         ↓
    Touchbox Library Layer
         ↓
    Touchbox UI
         ↓
MPMusicPlayerController
         ↓
    System Audio Stack
Не читать внутреннюю iTunes database напрямую, пока это не станет абсолютно необходимо.
Не изменять системную музыкальную базу вручную.
Не копировать AAC/MP3/ALAC файлы в sandbox приложения.
==================================================
 
ЭТАП 0 — ИССЛЕДОВАНИЕ SDK
Перед написанием основного кода исследуй headers iPhoneOS4.1.sdk.
Проверь наличие и реальные signatures следующих классов:
MPMediaQuery
MPMediaItem
MPMediaItemCollection
MPMediaItemArtwork
MPMusicPlayerController
MPMediaPropertyPredicate
Проверь availability следующих возможностей:
LIBRARY:
songsQuery
albumsQuery
artistsQuery
playlistsQuery
METADATA:
title
artist
album artist
album title
genre
duration
persistent ID
album persistent ID
artwork
Особенно проверить constants вида:
MPMediaItemPropertyTitle
MPMediaItemPropertyArtist
MPMediaItemPropertyAlbumArtist
MPMediaItemPropertyAlbumTitle
MPMediaItemPropertyGenre
MPMediaItemPropertyPlaybackDuration
MPMediaItemPropertyPersistentID
MPMediaItemPropertyAlbumPersistentID
MPMediaItemPropertyArtwork
PLAYBACK:
+iPodMusicPlayer

-setQueueWithItemCollection:
-setQueueWithQuery:

-play
-pause
-stop

-skipToNextItem
-skipToPreviousItem
-skipToBeginning

playbackState
nowPlayingItem
currentPlaybackTime
Проверить возможность изменения:
currentPlaybackTime
Проверить notifications:
playback state changed
now playing item changed
volume changed
Проверить:
beginGeneratingPlaybackNotifications
endGeneratingPlaybackNotifications
Сначала сформировать небольшой compatibility report:
available
unavailable
uncertain / requires device test
До завершения этого этапа не писать большой проект.
==================================================
 
ЭТАП 1 — MINIMAL PLAYBACK PROOF OF CONCEPT
Сначала создать максимально маленькое рабочее приложение.
Цель:
Library → select song → playback
Приложение должно:
1. запускаться на iOS 4.1;
2. получить список всех доступных песен;
3. показать UITableView;
4. для каждой строки показывать:
5. при выборе строки запускать соответствующий трек;
6. иметь три простые кнопки:
7. выводить через NSLog:
количество найденных треков;
выбранный persistent ID;
title;
artist;
playback state;
nowPlayingItem;
необычные состояния.
На этом этапе НЕ реализовывать:
artwork;
albums UI;
artists UI;
playlists UI;
favorites;
красивый Now Playing;
поиск;
собственные темы;
grid UI;
анимации;
private API;
filesystem database access;
SpringBoard integration.
Главная задача этого этапа:
доказать на настоящем iPod3,1 / iOS 4.1, что системной библиотекой можно управлять из стороннего приложения.
Если это не работает — остановиться и исследовать проблему.
Не строить остальной Touchbox поверх неподтверждённой гипотезы.
==================================================
 
ЭТАП 2 — LIBRARY MODEL
После успешного PoC создать простой LibraryManager.
Он должен централизовать работу с MediaPlayer.framework.
Например:
TBLibraryManager
Его задачи:
getSongs
getAlbums
getArtists
getPlaylists
Не размазывать MPMediaQuery по всем ViewController.
UI должен работать через LibraryManager.
Не создавать тяжёлую вторую музыкальную database.
Можно хранить небольшие массивы ссылок/metadata, если это действительно необходимо.
По возможности использовать persistent IDs как идентификаторы.
==================================================
 
ОСНОВНАЯ НАВИГАЦИЯ
Конечный Touchbox должен иметь разделы:
Songs
Albums
Artists
Favorites
Playlists
UI должен быть ориентирован не на копирование старого Music.app, а на максимально удобное использование устройства как отдельного DAP.
Главные требования:
быстро;
просто;
мало taps;
крупные элементы управления;
хорошая читаемость;
минимум декоративной нагрузки.
==================================================
 
SONGS
Songs показывает все треки.
Минимальная строка:
Track Title
Artist
Дополнительно, если не влияет заметно на производительность:
Album
Использовать UITableView reuse.
Не создавать UILabel/UIImageView заново для каждого отображения без необходимости.
==================================================
 
ALBUMS
Это один из важных элементов проекта.
Не использовать старую логику стандартного Music.app, где альбомы могут отображаться просто глобальным списком по названию.
Главный режим должен быть похож на современные версии Apple Music:
Artist
    Album
    Album
    Album
То есть первичная сортировка:
Album Artist
     ↓
Artist
     ↓
Unknown Artist
После этого:
Album
Пример:
Boris
    Amplifier Worship
    Akuma no Uta
    Feedbacker
    Pink

Have a Nice Life
    Deathconsciousness
    The Unnatural World

King Crimson
    Discipline
    In the Court of the Crimson King
    Red
Если MPMediaItemPropertyAlbumArtist доступен — использовать его.
Если albumArtist == nil:
fallback → artist
Если artist тоже nil:
"Unknown Artist"
Внутри исполнителя альбомы по умолчанию сортировать по album title.
Позже предусмотреть сортировки:
Artist
Album Title
Year/Recently Added добавлять только если соответствующие свойства действительно доступны и надёжны в SDK 4.1.
==================================================
 
ALBUM SCREEN
При открытии альбома показывать:
artwork
album title
artist
список треков
Для каждого трека:
track number
title
duration
если соответствующие metadata доступны.
Кнопка:
Play
должна запускать альбом с первого трека.
Также желательно:
Shuffle
но только после базовой реализации.
==================================================
 
ARTISTS
Artists:
Artist
    Albums
После открытия исполнителя:
artist name

Albums
    Album
    Album
При желании ниже:
All Songs
Не загружать artwork для всех альбомов исполнителя одновременно.
==================================================
 
PLAYLISTS
Показывать системные playlists, доступные через MediaPlayer.framework.
Touchbox не обязан первоначально уметь редактировать системные playlists.
Первая версия:
просмотр playlist
запуск playlist
запуск выбранного трека
Редактирование playlists — отдельная будущая функция.
==================================================
 
FAVORITES
Это важная функция Touchbox.
В iOS 4.1 нет необходимости пытаться реализовать современный Apple Music Love/Favorite.
Touchbox должен иметь собственную систему Favorites.
Favorites не должны изменять системную музыкальную database.
Хранить идентификаторы любимых треков.
Предпочтительно:
MPMediaEntityPersistentID
или соответствующий persistent ID API, реально присутствующий в SDK 4.1.
Для первой реализации использовать:
NSUserDefaults
или простой plist.
Не использовать SQLite без необходимости.
Хранить:
persistent IDs
а не:
title
artist
artwork
сам музыкальный файл
Это позволяет не создавать дубликаты данных.
Функции:
Add Favorite
Remove Favorite
Is Favorite
Get Favorites
UI:
На Now Playing должна быть кнопка:
☆
После добавления:
★
Повторное нажатие:
удалить из Favorites
Favorites является полноценным пунктом основной навигации:
Songs
Albums
Artists
Favorites
Playlists
Favorites должен показывать список сохранённых треков.
При загрузке Favorites:
persistentID → resolve MPMediaItem
Если элемента больше нет в библиотеке:
не падать;
игнорировать orphaned ID;
желательно удалить его из сохранённого списка.
==================================================
 
NOW PLAYING
Экран Now Playing должен быть одним из главных экранов приложения.
Показывать:
artwork
title
artist
album

elapsed time
duration

progress slider

Previous
Play/Pause
Next

Favorite ★/☆
При изменении nowPlayingItem UI должен обновляться.
Не poll’ить состояние слишком часто, если можно использовать notifications.
Прогресс можно обновлять NSTimer с разумной частотой, например около 1 раза в секунду.
Не делать 60 FPS обновление прогресс-бара.
==================================================
 
MINI PLAYER
После того как базовый UI стабилен, добавить компактную панель Now Playing в нижней части основных экранов.
Пример:
[small artwork] Track Title
                Artist        ▶
Нажатие на неё:
открыть Now Playing
Mini Player должен быть лёгким.
Не создавать копию большого artwork.
Использовать уменьшенную версию либо запрашивать подходящий размер через MPMediaItemArtwork, если API это позволяет.
==================================================
 
UI DESIGN
Не пытаться имитировать интерфейс iOS 15 pixel-perfect.
Цель — взять удобные идеи современных музыкальных приложений и адаптировать их к:
320×480
non-Retina
iOS 4.1
слабому устройству
Основные принципы:
крупная типографика;
простой layout;
минимум прозрачностей;
минимум shadow;
минимум gradients;
почти никаких сложных animations;
быстрый UITableView;
крупные touch targets.
Не использовать тяжёлые custom drawing effects, если UIKit-компонентов достаточно.
==================================================
 
TAB / NAVIGATION DESIGN
Из-за маленького экрана не пытаться одновременно показать слишком много элементов.
Возможные основные sections:
Songs
Albums
Artists
Favorites
Playlists
Можно использовать UITabBarController, если он доступен и удобен на iOS 4.1.
Либо создать собственную простую нижнюю навигацию, если стандартный Tab Bar слишком ограничивает дизайн.
Не писать кастомный navigation framework без необходимости.
==================================================
 
SEARCH
Search не нужен для первого релиза.
После основных функций можно добавить поиск по:
song title
artist
album
Только если UISearchBar/UISearchDisplayController API доступны и нормально работают в SDK 4.1.
==================================================
 
MEMORY MANAGEMENT
Это критически важно.
Используется MRC.
Правила:
retain
release
autorelease
dealloc
Properties:
@property(nonatomic, retain)
@property(nonatomic, copy)
@property(nonatomic, assign)
НЕ использовать:
strong
weak
__weak
Каждый owned object должен освобождаться.
Notification observers обязательно удалять.
NSTimer invalidated перед освобождением controller.
Не держать большие массивы artwork.
Не держать UIImage для всей библиотеки.
==================================================
 
ARTWORK PERFORMANCE
Artwork — потенциально главный источник проблем с RAM.
Правила:
1. не загружать artwork всей библиотеки заранее;
2. artwork загружать только для:
3. при cell reuse заменять старый artwork;
4. при memory warning очищать image cache;
5. если используется cache:
очень маленький;
ограниченный;
легко очищаемый.
Предпочтительно использовать MPMediaItemArtwork API для запроса изображения нужного размера, если такая возможность присутствует на iOS 4.1.
Не масштабировать сотни огромных картинок вручную одновременно.
==================================================
 
LARGE LIBRARY PERFORMANCE
Приложение должно быть рассчитано примерно на:
2000–5000 songs
200–500 albums
Не выполнять тяжёлые сортировки при каждом:
cellForRowAtIndexPath
Выполнять подготовку данных один раз и кешировать только лёгкую структуру.
Не делать repeated MPMediaQuery для каждой отображаемой строки.
UITableView обязательно использует cell reuse.
==================================================
 
SORTING
Не полагаться полностью на порядок MediaPlayer.
Реализовать свой sorting layer.
Нужны:
Songs: Title
Albums: Artist → Album
Artists: Artist
Favorites: порядок добавления либо Artist → Title
Playlists: системный порядок
Сортировку сделать отдельной логикой, а не внутри UITableView.
==================================================
 
PLAYBACK QUEUE
Touchbox должен понимать контекст запуска.
Если пользователь нажал трек внутри:
Songs: очередь = Songs
Album: очередь = этот Album
Artist: очередь = выбранный набор songs/album
Favorites: очередь = Favorites
Playlist: очередь = Playlist
После запуска выбранный трек должен стать текущим элементом очереди.
Проверь, какие механизмы для этого доступны в MPMusicPlayerController на iOS 4.1.
Если API не позволяет идеально выбрать начальный элемент после setQueueWithItemCollection:, исследуй доступные публичные методы.
Не использовать private API без отдельного решения.
==================================================
 
DRM / UNPLAYABLE ITEMS
Не реализовывать обход DRM.
Если системный MPMusicPlayerController не может проиграть элемент:
приложение не должно падать.
Зафиксировать ситуацию в NSLog.
При необходимости:
skip to next playable item
но только если это можно сделать надёжно.
==================================================
 
LOGGING / DEBUGGING
Создать простое диагностическое логирование.
Логировать:
app launch
library count
query duration
selected persistent ID
queue creation
playback state
now playing item
favorites add/remove
memory warnings
Не засорять production log каждой отрисованной UITableViewCell.
==================================================
 
THEOS PROJECT
Проект должен быть обычным Theos application project.
Предполагаемая структура:
Touchbox/
    Makefile
    control
    Resources/
        Info.plist
        icon.png
    Classes/
        TBAppDelegate.h
        TBAppDelegate.m

        TBRootViewController.h
        TBRootViewController.m

        TBLibraryManager.h
        TBLibraryManager.m

        TBPlayerManager.h
        TBPlayerManager.m

        TBFavoritesManager.h
        TBFavoritesManager.m

        TBSongsViewController.h
        TBSongsViewController.m

        TBAlbumsViewController.h
        TBAlbumsViewController.m

        TBArtistsViewController.h
        TBArtistsViewController.m

        TBFavoritesViewController.h
        TBFavoritesViewController.m

        TBPlaylistsViewController.h
        TBPlaylistsViewController.m

        TBAlbumViewController.h
        TBAlbumViewController.m

        TBArtistViewController.h
        TBArtistViewController.m

        TBNowPlayingViewController.h
        TBNowPlayingViewController.m
Это ориентир, а не требование создать все файлы сразу.
Не создавать пустую архитектуру ради архитектуры.
Добавлять классы только по мере необходимости.
==================================================
 
MAKEFILE
Architecture:
ARCHS = armv7
Target:
TARGET = iphone:clang:4.1:4.1
Перед использованием проверить, что эта форма TARGET соответствует установленной версии Theos.
Frameworks:
UIKit
Foundation
CoreGraphics
MediaPlayer
Использовать Theos application.mk.
Не добавлять ненужные frameworks.
==================================================
 
PACKAGING
Bundle identifier:
com.touchbox.player
Name:
Touchbox
Создать корректный Debian control для установки через Theos.
Установка:
make package install
по SSH через:
THEOS_DEVICE_IP
Touchbox должен появляться на SpringBoard как обычное приложение.
AppSync не является обязательной частью архитектуры проекта.
==================================================
 
ПОЭТАПНАЯ РАЗРАБОТКА
Очень важно:
НЕ писать сразу весь Touchbox.
Работать маленькими проверяемыми этапами.
ORDER:
PHASE 0 SDK compatibility investigation
PHASE 1 application launches
PHASE 2 Songs query works
PHASE 3 UITableView displays library
PHASE 4 selecting one song starts playback
PHASE 5 Previous / Play-Pause / Next
STOP
Проверить всё на реальном iPod.
После подтверждения:
PHASE 6 PlayerManager
PHASE 7 Albums
PHASE 8 Artists
PHASE 9 Favorites
PHASE 10 Now Playing
PHASE 11 Playlists
PHASE 12 Mini Player
PHASE 13 UI polish
PHASE 14 performance / memory optimization
==================================================
 
ПРАВИЛО ДЛЯ CODEX
Если у тебя есть доступ к файловой системе проекта и терминалу:
создавай реальные файлы;
запускай make;
анализируй compiler errors;
исправляй их;
снова запускай make.
Не просто печатай гипотетический код, если можешь проверить сборку.
Но:
успешная локальная сборка не подтверждает runtime compatibility.
Когда потребуется проверка на iPod:
1. дай точную команду установки;
2. укажи способ получить логи;
3. перечисли, что именно пользователь должен проверить;
4. не продолжай строить зависимые функции, пока результат проверки не будет известен.
==================================================
 
ЧЕГО НЕ ДЕЛАТЬ
На текущем этапе НЕ:
менять IPSW;
писать собственную ОС;
удалять системные daemon'ы;
заменять SpringBoard;
менять launchd;
внедряться в Music.app;
использовать MobileSubstrate;
писать tweak;
читать iTunesDB напрямую;
использовать private frameworks;
пытаться изменить системный Favorite/Love state;
писать собственный аудиодекодер.
Все эти направления могут рассматриваться отдельно после появления полностью рабочего Touchbox.
==================================================
 
КОНЕЧНАЯ ЦЕЛЬ
В итоге пользователь должен иметь возможность включить iPod и использовать Touchbox как основной музыкальный интерфейс.
Типичный сценарий:
Touchbox
    ↓
Albums
    ↓
Boris
    ↓
Feedbacker
    ↓
Track
    ↓
Now Playing
При этом:
музыка хранится в стандартной библиотеке;
Touchbox не создаёт её копию;
избранное хранится отдельно;
альбомы удобно сгруппированы по исполнителю;
интерфейс значительно удобнее стандартного Music.app iOS 4;
приложение остаётся быстрым на iPod touch 3G.
Touchbox должен ощущаться как интерфейс отдельного музыкального плеера, а не как экспериментальный jailbreak tweak.
==================================================
 
ПЕРВАЯ ТЕКУЩАЯ ЗАДАЧА
Сейчас НЕ реализовывай весь описанный проект.
Начни только с:
1. анализа MediaPlayer.framework headers в iPhoneOS4.1.sdk;
2. compatibility report;
3. создания минимального Theos application;
4. Songs через MPMediaQuery;
5. UITableView;
6. выбор трека;
7. воспроизведение через MPMusicPlayerController;
8. Previous / Play-Pause / Next;
9. сборки проекта;
10. подготовки к тестированию на реальном iPod.
После этого остановись.
В конце дай:
* что удалось собрать;
* какие API подтверждены headers;
* какие моменты требуют runtime-проверки;
* точную команду установки;
* точные шаги проверки на iPod;
* способ получить NSLog / crash information.
Не переходи к Albums, Favorites и полноценному UI, пока базовое воспроизведение не подтверждено на реальном устройстве
