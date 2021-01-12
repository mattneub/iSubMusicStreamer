//
//  SubFolderLoader.swift
//  iSub
//
//  Created by Benjamin Baron on 12/27/20.
//  Copyright © 2020 Ben Baron. All rights reserved.
//

import Foundation
import CocoaLumberjackSwift
import Resolver

typealias FolderAlbumHandler = (_ folderAlbum: FolderAlbum) -> ()
typealias SongHandler = (_ song: Song) -> ()

final class SubfolderLoader: APILoader {
    @Injected private var store: Store
    
    override var type: APILoaderType { .subFolders }
    
    var serverId = Settings.shared().currentServerId
    let parentFolderId: Int
    private(set) var folderMetadata: FolderMetadata?
    private(set) var folderAlbumIds = [Int]()
    private(set) var songIds = [Int]()
    
    var onProcessFolderAlbum: FolderAlbumHandler?
    var onProcessSong: SongHandler?
    
    init(parentFolderId: Int, callback: LoaderCallback? = nil, folderAlbumHandler: FolderAlbumHandler? = nil, songHandler: SongHandler? = nil) {
        self.parentFolderId = parentFolderId
        self.onProcessFolderAlbum = folderAlbumHandler
        self.onProcessSong = songHandler
        super.init(callback: callback)
    }
    
    override func createRequest() -> URLRequest? {
        return NSMutableURLRequest(susAction: "getMusicDirectory", parameters: ["id": parentFolderId]) as URLRequest
    }
    
    override func processResponse(data: Data) {
        let root = RXMLElement(fromXMLData: data)
        if !root.isValid {
            informDelegateLoadingFailed(error: NSError(ismsCode: Int(ISMSErrorCode_NotXML)))
        } else {
            if let error = root.child("error"), error.isValid {
                informDelegateLoadingFailed(error: NSError(subsonicXMLResponse: error))
            } else {
                if store.resetFolderAlbumCache(serverId: serverId, parentFolderId: parentFolderId) {
                    var songCount = 0
                    var duration = 0
                    
                    var folderAlbums = [FolderAlbum]()
                    folderAlbumIds.removeAll()
                    songIds.removeAll()
                    root.iterate("directory.child") { element in
                        if element.attribute("isDir") == "true" {
                            let folderAlbum = FolderAlbum(serverId: self.serverId, element: element)
                            if folderAlbum.name != ".AppleDouble" {
                                folderAlbums.append(folderAlbum)
                                
                                // Optionally the client can do something with the folder album object
                                self.onProcessFolderAlbum?(folderAlbum)
                            }
                        } else {
                            let song = Song(serverId: self.serverId, element: element)
                            if song.path != "" && (Settings.shared().currentServer.isVideoSupported || !song.isVideo) {
                                // Fix for pdfs showing in directory listing
                                // TODO: See if this is still necessary
                                if song.suffix.lowercased() != "pdf" {
                                    if self.store.add(folderSong: song) {
                                        self.songIds.append(song.id)
                                        songCount += 1
                                        duration += song.duration
                                        
                                        // Optionally the client can do something with the song object
                                        self.onProcessSong?(song)
                                    } else {
                                        self.informDelegateLoadingFailed(error: NSError(ismsCode: Int(ISMSErrorCode_Database)))
                                        return
                                    }
                                }
                            }
                        }
                    }
                    
                    // Hack for Subsonic 4.7 breaking alphabetical order
                    folderAlbums.sort { $0.name.caseInsensitiveCompare($1.name) != .orderedDescending }
                    var folderCount = 0
                    for folderAlbum in folderAlbums {
                        if store.add(folderAlbum: folderAlbum) {
                            self.folderAlbumIds.append(folderAlbum.id)
                            folderCount += 1
                        } else {
                            informDelegateLoadingFailed(error: NSError(ismsCode: Int(ISMSErrorCode_Database)))
                            return
                        }
                    }
                    
                    let metadata = FolderMetadata(serverId: serverId, parentFolderId: parentFolderId, folderCount: folderCount, songCount: songCount, duration: duration)
                    if !store.add(folderMetadata: metadata) {
                        informDelegateLoadingFailed(error: NSError(ismsCode: Int(ISMSErrorCode_Database)))
                        return
                    }
                    
                    folderMetadata = metadata
                    informDelegateLoadingFinished()
                } else {
                    informDelegateLoadingFailed(error: NSError(ismsCode: Int(ISMSErrorCode_Database)))
                }
            }
        }
    }
}
