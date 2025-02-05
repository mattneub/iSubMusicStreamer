Personal fork from https://github.com/einsteinx2/iSubMusicStreamer.

* Initial fork. Can build and run on device (not on simulator).
* On initial server configuration screen, make URL field have `.URL` keyboard type for easier entry.
* Album titles are sorted without regard for diacritics (like the Finder).
* Nav bar above current playlist is no longer transparent.
* Album track tap changed to mean “enqueue”.
* Remove Flurry support.
* Remove Lumberjack.
* Modernize LibBASS. Can now run on simulator!!! Plug-ins to play formats such as flac, ape, etc. are currently disabled.
* Fix all compile-time warnings.
* Fix runtime warnings at launch.
* Album track list cell is now self-sizing, displays full title and artist info.
* Remove Reachability sample code.
* Fix call-super and related howlers.
* Make some tap targets bigger on player view controller.
* Rewrite auto scrolling label: better layout, correct use of content size, detect more situations where we need to stop
* Improve visibility of nav bar and tab bar.
* Playlist track list cell is also now self-sizing. Fixed bug in More view controller customization.
* Change album/song/genre default default to true.
* Started translating into Swift; this process is also exposing some likely bugs that I'm marking up as I go.
* More Swift translation.
* Fixed search query bug.
* Fixed Jukebox button bug.
* More Swift translation, heavily rejiggering the Playlists interface. Increased the minimum requirement to iOS 15.
* More translation (playlist songs).
* More translation (albums).
* Use standard search interface in Albums.
* Use standard search interface in Folders, remove folder selection dropdown.
* Layout tweaks to player interface.
* Added a new song property, "comment", displayed in player. **WARNING:** This is a breaking change! You must delete the app and start over.
* Rejigger the opening dance when we launch with no server URL; remove hidden dependency on iSub test server (<http://isubapp.com:9001>).