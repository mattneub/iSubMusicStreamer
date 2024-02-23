//
//  Common-Bridging-Header.h
//  iSub
//
//  Created by Benjamin Baron on 11/11/20.
//  Copyright © 2020 Ben Baron. All rights reserved.
//

/*
 * Import Objective-C headers here to be exposed to Swift in all build targets
 */

#ifndef Common_Bridging_Header_h
#define Common_Bridging_Header_h

#import "Defines.h"
#import "ObjcExceptionCatcher.h"

/*
 * User Interface Components
 */

// View Controllers
#import "CustomUINavigationController.h"
#import "ChatViewController.h"
// #import "AlbumViewController.h"
#import "CurrentPlaylistViewController.h"
#import "EqualizerViewController.h"
#import "ServerListViewController.h"
#import "CacheViewController.h"
#import "GenresViewController.h"
// #import "PlaylistsViewController.h"
#import "BookmarksViewController.h"
#import "PlayingViewController.h"
// #import "AllAlbumsViewController.h"
#import "AllSongsViewController.h"
#import "CacheOfflineFoldersViewController.h"
//#import "FolderDropdownDelegate.h"
//#import "FolderDropdownControl.h"
#import "SUSAllSongsLoader.h"
#import "CustomUITabBarController.h"
#import "SUSDropdownFolderLoader.h"
#import "SUSSubFolderDAO.h"
#import "SUSServerPlaylistsDAO.h"
#import "SUSAllSongsDAO.h"
#import "SUSAllAlbumsDAO.h"
#import "SUSServerPlaylistsDAO.h"

// Views
// #import "CellCachedIndicatorView.h"

/*
 * Data Models
 */

// Loaders
#import "ISMSErrorDomain.h"
#import "SUSServerShuffleLoader.h"
#import "SUSQuickAlbumsLoader.h"
#import "SUSStatusLoader.h"
#import "SUSLoaderDelegate.h"

// DAOs
#import "SUSRootFoldersDAO.h"
#import "ISMSSong+DAO.h"
#import "ISMSBookmarkDAO.h"
#import "SUSLyricsDAO.h"
#import "SUSCoverArtDAO.h"

// Parsers
#import "SearchXMLParser.h"

// Models
#import "ISMSArtist.h"
#import "ISMSAlbum.h"
#import "ISMSServer.h"

// Utils
#import "EX2Dispatch.h"

/*
 * Extensions
 */

#import "UIViewController+PushViewControllerCustom.h"
#import "NSString+time.h"
#import "NSMutableURLRequest+SUS.h"
#import "UIApplication+Helper.h"
#import "UIDevice+Info.h"
#import "NSNotificationCenter+MainThread.h"
#import "NSString+FileSize.h"
#import "NSString+MD5.h"

/*
 * Singletons
 */

#import "iSubAppDelegate.h"
#import "ViewObjectsSingleton.h"
#import "MusicSingleton.h"
#import "JukeboxSingleton.h"
#import "SavedSettings.h"
#import "AudioEngine.h"
#import "ISMSStreamManager.h"
#import "DatabaseSingleton.h"
#import "CacheSingleton.h"

/*
 * Frameworks
 */

#import "OBSlider.h"
#import "FMDB.h"
//#import "FMDatabaseQueue.h"
//#import "FMDatabaseQueueAdditions.h"
//#import "FMDatabaseAdditions.h"
#import "GCDWebServer.h"
#import "GCDWebServerDataResponse.h"
#import "GCDWebServerErrorResponse.h"

#import "RXMLElement.h"
#import "NSError+ISMSError.h"

#import "SUSServerPlaylist.h"
#import "ISMSLocalPlaylist.h"
#import "ISMSIndex.h"
#import "LoadingScreen.h"

#endif /* Common_Bridging_Header_h */
