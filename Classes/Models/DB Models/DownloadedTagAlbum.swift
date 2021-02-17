//
//  DownloadedTagAlbum.swift
//  iSub
//
//  Created by Benjamin Baron on 1/15/21.
//  Copyright © 2021 Ben Baron. All rights reserved.
//

import Foundation
import Resolver

struct DownloadedTagAlbum: Codable, Equatable {
    let serverId: Int
    let id: Int
    let name: String
    let coverArtId: String?
    let tagArtistId: Int?
    let tagArtistName: String?
    let songCount: Int
    let duration: Int
    let playCount: Int
    let year: Int
    let genre: String?
    
    static func ==(lhs: DownloadedTagAlbum, rhs: DownloadedTagAlbum) -> Bool {
        return lhs.serverId == rhs.serverId && lhs.id == rhs.id
    }
}

extension DownloadedTagAlbum: TableCellModel {
    private var store: Store { Resolver.resolve() }
    
    var primaryLabelText: String? { name }
    var secondaryLabelText: String? {
        if let songCount = store.downloadedSongsCount(downloadedTagAlbum: self) {
            return "\(songCount) \("Song".pluralize(amount: songCount))"
        }
        return nil
    }
    var durationLabelText: String? { nil }
    var isDownloaded: Bool { true }
    var isDownloadable: Bool { false }
    
    var tagAlbumId: Int? { id }
    var parentFolderId: Int? { nil }
    
    func download() {
        // TODO: implement this
        fatalError("implement this")
    }
    func queue() {
        // TODO: implement this
        fatalError("implement this")
    }
    func queueNext() {
        // TODO: implement this
        fatalError("implement this")
    }
}
