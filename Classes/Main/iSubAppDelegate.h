//
//  iSubAppDelegate.h
//  iSub
//
//  Created by Ben Baron on 2/27/10.
//  Copyright Ben Baron 2010. All rights reserved.
//

#ifndef iSub_iSubAppDelegate_h
#define iSub_iSubAppDelegate_h

#import "SUSLoaderDelegate.h"
#import <AVKit/AVKit.h>

#define appDelegateS [iSubAppDelegate sharedInstance]

@class BBSplitViewController, PadRootViewController, InitialDetailViewController, LoadingScreen, FMDatabase, SettingsViewController, FoldersViewController, AudioStreamer, SUSStatusLoader, MPMoviePlayerController, AVPlayerViewController, HLSReverseProxyServer, ServerListViewController, Reachability;

NS_ASSUME_NONNULL_BEGIN

NS_SWIFT_NAME(AppDelegate)
@interface iSubAppDelegate : NSObject <UIApplicationDelegate, SUSLoaderDelegate, AVPlayerViewControllerDelegate>

//@property (nullable, strong) HTTPServer *hlsProxyServer;

@property (nullable,  strong) SUSStatusLoader *statusLoader;

@property (strong, nonatomic) IBOutlet UIWindow *window;

@property (strong) SettingsViewController *settingsViewController;
@property (strong) IBOutlet UIImageView *background;
@property (strong) UITabBarController *currentTabBarController;
@property (strong) IBOutlet UITabBarController *mainTabBarController;
@property (strong) IBOutlet UITabBarController *offlineTabBarController;
@property (strong) IBOutlet UINavigationController *homeNavigationController;
@property (strong) IBOutlet UINavigationController *playerNavigationController;
@property (strong) IBOutlet UINavigationController *artistsNavigationController;
@property (strong) IBOutlet FoldersViewController *rootViewController;
@property (strong) IBOutlet UINavigationController *allAlbumsNavigationController;
@property (strong) IBOutlet UINavigationController *allSongsNavigationController;
@property (strong) IBOutlet UINavigationController *playlistsNavigationController;
@property (strong) IBOutlet UINavigationController *bookmarksNavigationController;
@property (strong) IBOutlet UINavigationController *playingNavigationController;
@property (strong) IBOutlet UINavigationController *genresNavigationController;
@property (strong) IBOutlet UINavigationController *cacheNavigationController;
@property (strong) IBOutlet UINavigationController *chatNavigationController;
@property (strong) UINavigationController *supportNavigationController;

@property (strong) ServerListViewController *serverListViewController;

@property (strong) PadRootViewController *padRootViewController;

// Network connectivity objects and variables
//
@property (strong) Reachability *wifiReach;
@property (readonly) BOOL isWifi;

// Multitasking stuff
@property UIBackgroundTaskIdentifier backgroundTask;
@property BOOL isInBackground;

@property BOOL showIntro;

@property (nullable, strong) NSURL *referringAppUrl;

@property (nullable, strong) AVPlayerViewController *videoPlayerController;
@property (nullable, strong) HLSReverseProxyServer *hlsProxyServer;

- (void)backToReferringApp;

+ (instancetype)sharedInstance NS_SWIFT_NAME(shared());

- (void)enterOnlineModeForce;
- (void)enterOfflineModeForce;

- (void)reachabilityChanged:(nullable NSNotification *)note;

- (void)showSettings;

- (void)batteryStateChanged:(nullable NSNotification *)notification;

- (void)checkServer;

- (NSString *)zipAllLogFiles;


@end

NS_ASSUME_NONNULL_END

#endif
