Personal fork from https://github.com/einsteinx2/iSubMusicStreamer.

* Initial fork.  Can build and run on device (not on simulator).
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