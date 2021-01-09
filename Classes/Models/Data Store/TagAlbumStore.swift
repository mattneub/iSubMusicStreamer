//
//  TagAlbumStore.swift
//  iSub
//
//  Created by Benjamin Baron on 1/7/21.
//  Copyright © 2021 Ben Baron. All rights reserved.
//

import Foundation
import GRDB
import CocoaLumberjackSwift

extension TagAlbum: FetchableRecord, PersistableRecord {
    struct Table {
        static let tagSongList = "tagSongList"
    }
    enum Column: String, ColumnExpression {
        case serverId, id, name, coverArtId, tagArtistId, tagArtistName, songCount, duration, playCount, year, genre
    }
    enum RelatedColumn: String, ColumnExpression {
        case tagAlbumId, songId
    }
    
    static func createInitialSchema(_ db: Database) throws {
        // Shared table of unique album records
        try db.create(table: TagAlbum.databaseTableName) { t in
            t.column(Column.serverId, .integer).notNull()
            t.column(Column.id, .integer).notNull()
            t.column(Column.name, .text).notNull()
            t.column(Column.coverArtId, .text)
            t.column(Column.tagArtistId, .integer).indexed()
            t.column(Column.tagArtistName, .text)
            t.column(Column.songCount, .integer).notNull()
            t.column(Column.duration, .integer).notNull()
            t.column(Column.playCount, .integer)
            t.column(Column.year, .integer)
            t.column(Column.genre, .text)
            t.primaryKey([Column.serverId, Column.id])
        }
        
        // Cache of song IDs for each tag album for display
        try db.create(table: TagAlbum.Table.tagSongList) { t in
            t.autoIncrementedPrimaryKey(GRDB.Column.rowID).notNull()
            t.column(Column.serverId, .integer).notNull()
            t.column(RelatedColumn.tagAlbumId, .integer).notNull()
            t.column(RelatedColumn.songId, .integer).notNull()
        }
        try db.create(indexOn: TagAlbum.Table.tagSongList, columns: [Column.serverId, RelatedColumn.tagAlbumId])
    }
}

extension Store {
    @objc func deleteTagAlbums(serverId: Int) -> Bool {
        do {
            return try pool.write { db in
                try db.execute(literal: "DELETE FROM \(TagAlbum.self) WHERE serverId = \(serverId)")
                return true
            }
        } catch {
            DDLogError("Failed to delete tag albums for server \(serverId): \(error)")
            return false
        }
    }
    
    func deleteTagAlbums(serverId: Int, tagArtistId: Int) -> Bool {
        do {
            return try pool.write { db in
                try db.execute(literal: "DELETE FROM \(TagAlbum.self) WHERE serverId = \(serverId) AND tagArtistId = \(tagArtistId)")
                return true
            }
        } catch {
            DDLogError("Failed to delete tag albums for server \(serverId) and tag artist \(tagArtistId): \(error)")
            return false
        }
    }
    
    // TODO: Complete this query when needed for UI
//    func tagAlbumIds(mediaFolderId: Int, orderBy: TagAlbum.Column = .name) -> [String] {
//        do {
//            return try serverDb.read { db in
//                let sql: SQLLiteral = """
//                    SELECT id
//                    FROM \(TagAlbum.self)
//                    JOIN
//                    WHERE mediaFolderId = \(mediaFolderId)
//                    ORDER BY \(orderBy) ASC
//                    """
//                return try SQLRequest<String>(literal: sql).fetchAll(db)
//            }
//        } catch {
//            DDLogError("Failed to select tag album IDs for media folder \(mediaFolderId) ordered by \(orderBy): \(error)")
//            return []
//        }
//    }
    
    func tagAlbumIds(serverId: Int, tagArtistId: Int, orderBy: TagAlbum.Column = .name) -> [Int] {
        do {
            return try pool.read { db in
                let sql: SQLLiteral = """
                    SELECT id
                    FROM \(TagAlbum.self)
                    WHERE serverId = \(serverId) AND tagArtistId = \(tagArtistId)
                    ORDER BY \(orderBy) ASC
                    """
                return try SQLRequest<Int>(literal: sql).fetchAll(db)
            }
        } catch {
            DDLogError("Failed to select tag album IDs for server \(serverId) and tag artist \(tagArtistId) ordered by \(orderBy): \(error)")
            return []
        }
    }
    
    func tagAlbum(serverId: Int, id: Int) -> TagAlbum? {
        do {
            return try pool.read { db in
                try TagAlbum.filter(literal: "serverId = \(serverId) AND id = \(id)").fetchOne(db)
            }
        } catch {
            DDLogError("Failed to select server \(serverId) and tag album \(id): \(error)")
            return nil
        }
    }
    
    func add(tagAlbum: TagAlbum) -> Bool {
        do {
            return try pool.write { db in
                // Insert or update shared album record
                try tagAlbum.save(db)
                return true
            }
        } catch {
            DDLogError("Failed to insert tag album \(tagAlbum): \(error)")
            return false
        }
    }
    
    func songIds(serverId: Int, tagAlbumId: Int) -> [Int] {
        do {
            return try pool.read { db in
                let sql: SQLLiteral = """
                    SELECT songId
                    FROM tagSongList
                    WHERE serverId = \(serverId) AND tagAlbumId = \(tagAlbumId)
                    ORDER BY \(Column.rowID) ASC
                    """
                return try SQLRequest<Int>(literal: sql).fetchAll(db)
            }
        } catch {
            DDLogError("Failed to select song IDs for server \(serverId) and tag album \(tagAlbumId): \(error)")
            return []
        }
    }
    
    func deleteTagSongs(serverId: Int, tagAlbumId: Int) -> Bool {
        do {
            return try pool.write { db in
                try db.execute(literal: "DELETE FROM tagSongList WHERE serverId = \(serverId) AND tagAlbumId = \(tagAlbumId)")
                return true
            }
        } catch {
            DDLogError("Failed to reset tag album song cache server \(serverId) and tag album \(tagAlbumId): \(error)")
            return false
        }
    }
    
    func add(tagSong song: Song) -> Bool {
        do {
            return try pool.write { db in
                // Insert or update shared song record
                try song.save(db)
                
                // Insert song id into list cache
                let sql: SQLLiteral = """
                    INSERT INTO tagSongList
                    (serverId, tagAlbumId, songId)
                    VALUES (\(song.serverId), \(song.tagAlbumId), \(song.id))
                    """
                try db.execute(literal: sql)
                return true
            }
        } catch {
            DDLogError("Failed to insert tag song \(song) in tag album \(song.tagAlbumId): \(error)")
            return false
        }
    }
}
