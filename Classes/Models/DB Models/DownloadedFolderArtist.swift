//
//  DownloadedFolderArtist.swift
//  iSub
//
//  Created by Benjamin Baron on 1/11/21.
//  Copyright © 2021 Ben Baron. All rights reserved.
//

import Foundation
import Resolver

@objc final class DownloadedFolderArtist: NSObject, NSCopying, Codable {
    @objc let serverId: Int
    @objc let name: String
    
    @objc init(serverId: Int, name: String) {
        self.serverId = serverId
        self.name = name
        super.init()
    }
    
    func copy(with zone: NSZone? = nil) -> Any {
        return DownloadedFolderArtist(serverId: serverId, name: name)
    }
    
    override var description: String {
        "\(super.description): serverId: \(serverId), name: \(name)"
    }
}

extension DownloadedFolderArtist: TableCellModel {
    var primaryLabelText: String? { name }
    var secondaryLabelText: String? { nil }
    var durationLabelText: String? { nil }
    var coverArtId: String? { nil }
    var isCached: Bool { true }
    func download() {
        let store: Store = Resolver.main.resolve()
        let songs = store.songsRecursive(serverId: serverId, level: 0, parentPathComponent: name)
        for song in songs {
            song.download()
        }
    }
    func queue() {
        let store: Store = Resolver.main.resolve()
        let songs = store.songsRecursive(serverId: serverId, level: 0, parentPathComponent: name)
        for song in songs {
            song.queue()
        }
    }
}
