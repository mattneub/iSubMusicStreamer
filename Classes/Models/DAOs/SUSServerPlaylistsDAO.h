//
//  SUSServerPlaylistsDAO.h
//  iSub
//
//  Created by Benjamin Baron on 11/1/11.
//  Copyright (c) 2011 Ben Baron. All rights reserved.
//

#import "SUSLoaderManager.h"

@class SUSServerPlaylistsLoader, SUSServerPlaylist, FMDatabase;
@interface SUSServerPlaylistsDAO : NSObject <SUSLoaderDelegate, SUSLoaderManager>

@property (weak) NSObject <SUSLoaderDelegate> *delegate;
@property (strong) SUSServerPlaylistsLoader *loader;

#pragma mark - Public DAO Methods

@property (strong) NSArray<SUSServerPlaylist*> *serverPlaylists;

@end
