//
//  SUSSubFolderLoader.m
//  iSub
//
//  Created by Benjamin Baron on 6/12/12.
//  Copyright (c) 2012 Ben Baron. All rights reserved.
//

#import "SUSSubFolderLoader.h"
#import "NSMutableURLRequest+SUS.h"
#import "RXMLElement.h"
#import "FMDatabaseQueueAdditions.h"
#import "SavedSettings.h"
#import "DatabaseSingleton.h"
#import "NSError+ISMSError.h"
#import "ISMSSong+DAO.h"
#import "EX2Kit.h"
#import "Swift.h"

LOG_LEVEL_ISUB_DEFAULT

@implementation SUSSubFolderLoader

#pragma mark Loader Methods

- (SUSLoaderType)type {
    return SUSLoaderType_SubFolders;
}

- (NSURLRequest *)createRequest {
    return [NSMutableURLRequest requestWithSUSAction:@"getMusicDirectory" parameters:@{@"id": n2N(self.folderId)}];
}

- (void)processResponse {    
    RXMLElement *root = [[RXMLElement alloc] initFromXMLData:self.receivedData];
    if (!root.isValid) {
        NSError *error = [NSError errorWithISMSCode:ISMSErrorCode_NotXML];
        [self informDelegateLoadingFailed:error];
    } else {
        RXMLElement *error = [root child:@"error"];
        if (error.isValid) {
            NSInteger code = [[error attribute:@"code"] integerValue];
            NSString *message = [error attribute:@"message"];
            [self informDelegateLoadingFailed:[NSError errorWithISMSCode:code message:message]];
        } else {
            [self resetDb];
            self.subfolderCount = 0;
            self.songCount = 0;
            self.duration = 0;
            
            NSMutableArray *subfolders = [[NSMutableArray alloc] initWithCapacity:0];
            [root iterate:@"directory.child" usingBlock: ^(RXMLElement *e) {
                if ([[e attribute:@"isDir"] boolValue]) {
                    ISMSFolderAlbum *folderAlbum = [[ISMSFolderAlbum alloc] initWithElement:e folderArtist:self.folderArtist];
                    if (![folderAlbum.title isEqualToString:@".AppleDouble"]) {
                        [subfolders addObject:folderAlbum];
                    }
                } else {
                    ISMSSong *aSong = [[ISMSSong alloc] initWithRXMLElement:e];
                    if (aSong.path && (settingsS.isVideoSupported || !aSong.isVideo)) {
                        // Fix for pdfs showing in directory listing
                        if (![aSong.suffix.lowercaseString isEqualToString:@"pdf"]) {
                            [self insertSongIntoFolderCache:aSong];
                            self.songCount++;
                            self.duration += aSong.duration.intValue;
                        }
                    }
                }
            }];
            
            // Hack for Subsonic 4.7 breaking alphabetical order
            [subfolders sortUsingComparator:^NSComparisonResult(ISMSFolderAlbum *obj1, ISMSFolderAlbum *obj2) {
                return [obj1.title caseInsensitiveCompareWithoutIndefiniteArticles:obj2.title];
            }];
            for (ISMSFolderAlbum *folderAlbum in subfolders) {
                [self insertFolderAlbumIntoFolderCache:folderAlbum];
            }
            self.subfolderCount = subfolders.count;
            //
            
            [self insertFolderMetadata];
            
            // Notify the delegate that the loading is finished
            [self informDelegateLoadingFinished];
        }
    }
}

#pragma mark Private DB Methods

- (FMDatabaseQueue *)dbQueue {
    return databaseS.albumListCacheDbQueue;
}

- (BOOL)resetDb {
    __block BOOL hadError;
    [self.dbQueue inDatabase:^(FMDatabase *db) {
        //Initialize the arrays.
        [db beginTransaction];
        [db executeUpdate:@"DELETE FROM folderAlbum WHERE folderId = ?", self.folderId];
        [db executeUpdate:@"DELETE FROM folderSong WHERE folderId = ?", self.folderId];
        [db executeUpdate:@"DELETE FROM folderMetadata WHERE folderId = ?", self.folderId];
        [db commit];
        
        hadError = db.hadError;
        if (hadError) {
            DDLogError(@"[SUSSubFolderLoader] Error resetting subfolder cache tables %d: %@", db.lastErrorCode, db.lastErrorMessage);
        }
    }];
    return !hadError;
}

- (BOOL)insertFolderAlbumIntoFolderCache:(ISMSFolderAlbum *)folderAlbum {
    __block BOOL hadError;
    [self.dbQueue inDatabase:^(FMDatabase *db) {
        [db executeUpdate:@"INSERT INTO folderAlbum (folderId, title, subfolderId, coverArtId, folderArtistId, folderArtistName) VALUES (?, ?, ?, ?, ?, ?)", self.folderId, folderAlbum.title, folderAlbum.folderId, folderAlbum.coverArtId, folderAlbum.folderArtistId, folderAlbum.folderArtistName];
        
        hadError = db.hadError;
        if (hadError) {
            DDLogError(@"[SUSSubFolderLoader] Error inserting folder %d: %@", db.lastErrorCode, db.lastErrorMessage);
        }
    }];
    return !hadError;
}

- (BOOL)insertSongIntoFolderCache:(ISMSSong *)aSong {
    __block BOOL hadError;
    [self.dbQueue inDatabase:^(FMDatabase *db) {
        [db executeUpdate:[NSString stringWithFormat:@"INSERT INTO folderSong (folderId, %@) VALUES (?, %@)", [ISMSSong standardSongColumnNames], [ISMSSong standardSongColumnQMarks]], self.folderId, aSong.title, aSong.songId, aSong.artist, aSong.album, aSong.genre, aSong.coverArtId, aSong.path, aSong.suffix, aSong.transcodedSuffix, aSong.duration, aSong.bitRate, aSong.track, aSong.year, aSong.size, aSong.parentId, NSStringFromBOOL(aSong.isVideo), aSong.discNumber];
        
        hadError = db.hadError;
        if (hadError) {
            DDLogError(@"[SUSSubFolderLoader] Error inserting song %d: %@", db.lastErrorCode, db.lastErrorMessage);
        }
    }];
    return !hadError;
}

- (BOOL)insertFolderMetadata {
    __block BOOL hadError;
    [self.dbQueue inDatabase:^(FMDatabase *db) {
        [db executeUpdate:@"INSERT INTO folderMetadata (folderId, subfolderCount, songCount, duration) VALUES (?, ?, ?, ?)", self.folderId, @(self.subfolderCount), @(self.songCount), @(self.duration)];
        
        hadError = db.hadError;
        if (hadError) {
            DDLogError(@"[SUSSubFolderLoader] Error inserting folder metadata %d: %@", db.lastErrorCode, db.lastErrorMessage);
        }
    }];
    return !hadError;
}

@end
