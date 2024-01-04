import UIKit

final class SearchSongsViewController: UITableViewController {
    enum SearchSongsSearchType: Int {
        case artists
        case albums
        case songs
    }

    var listOfAlbums = [Album]()
    var listOfArtists = [Artist]()
    var listOfSongs = [Song]()
    var query: String?
    var searchType = SearchSongsSearchType.songs

    private var connection: URLSession?
    private var offset = 0
    private var isMoreResults = true
    private var isLoading = false

    override func viewDidLoad() {
        super.viewDidLoad()
        if Music.shared().showPlayerIcon {
            let image = UIImage(systemName: Defines.musicNoteImageSystemName)
            navigationItem.rightBarButtonItem = UIBarButtonItem(image: image, style: .plain, target: self, action: #selector(nowPlayingAction))
        } else {
            navigationItem.rightBarButtonItem = nil
        }
        self.tableView.rowHeight = Defines.rowHeight
        self.tableView.register(UniversalTableViewCell.self, forCellReuseIdentifier: UniversalTableViewCell.reuseId)
    }

    @objc func nowPlayingAction() {
        let playerViewController = PlayerViewController()
        playerViewController.hidesBottomBarWhenPushed = true
        self.navigationController?.pushViewController(playerViewController, animated: true)
    }

    /*
     The way he's done this is quite confusing: the search is not self-contained here!
     Instead, the initial search has _already_ been done in HomeViewController.
     The code here _repeats_ that code, and
     is needed only just in case we need to paginate beyond the initial 20.
     */
    private func loadMoreResults() {
        guard !self.isLoading else { return }
        self.isLoading = true

        self.offset += 20
        var parameters: [String: String?] = ["query": self.query, "artistCount": "0", "albumCount": "0", "songCount": "0"]

        var action: String? = nil

        // TODO: I think we can stop supporting the original first API
        // TODO: There is now a third API? Should check this out, http://www.subsonic.org/pages/api.jsp#search3
        if Settings.shared().isNewSearchAPI {
            action = "search2"
            // This looks like a bug; we are already adding "*" if needed, in HomeViewController
            // And I am not persuaded that it is needed; it certainly works the same without it in Navidrome
            // let queryString: String? = self.query.flatMap { $0 + "*" }
            // let queryString: String? = self.query
            switch searchType {
            case .artists:
                parameters["artistCount"] = "20"
                parameters["artistOffset"] = String(self.offset)
            case .albums:
                parameters["albumCount"] = "20"
                parameters["albumOffset"] = String(self.offset)
            case .songs:
                parameters["songCount"] = "20"
                parameters["songOffset"] = String(self.offset)
            }
        } else {
            action = "search"
            parameters = ["count": "20", "any": self.query, "offset": String(self.offset)]
        }

        let request = NSMutableURLRequest(susAction: action, parameters: parameters as [AnyHashable : Any]) as URLRequest
        // TODO: redefine these on Swift URLRequest
        let dataTask = SUSLoader.sharedSession().dataTask(with: request) { [weak self] data, response, error in
            if let error {
                Task { @MainActor in
                    if Settings.shared().isPopupsEnabled {
                        let message = "There was an error performing the search.\n\nError: \(error.localizedDescription)"
                        let alert = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
                        alert.addAction(.init(title: "OK", style: .cancel))
                        self?.present(alert, animated: true)
                    }
                    self?.isLoading = false
                }
            } else if let data, let self {
                let parserDelegate = SearchXMLParser()
                let xmlParser = XMLParser(data: data)
                xmlParser.delegate = parserDelegate
                xmlParser.parse()
                switch searchType {
                case .artists:
                    if parserDelegate.listOfArtists.count == 0 {
                        self.isMoreResults = false
                    } else {
                        self.listOfArtists.append(contentsOf: parserDelegate.listOfArtists)
                    }
                case .albums:
                    if parserDelegate.listOfAlbums.count == 0 {
                        self.isMoreResults = false
                    } else {
                        self.listOfAlbums.append(contentsOf: parserDelegate.listOfAlbums)
                    }
                case .songs:
                    if parserDelegate.listOfSongs.count == 0 {
                        self.isMoreResults = false
                    } else {
                        self.listOfSongs.append(contentsOf: parserDelegate.listOfSongs)
                    }
                }
                Task { @MainActor in
                    self.tableView.reloadData()
                    self.isLoading = false
                }
            }
        }
        dataTask.resume()
    }
}

extension SearchSongsViewController /* UITableViewDataSource, UITableViewDelegate */ {
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch searchType {
        case .artists: listOfArtists.count + 1
        case .albums: listOfAlbums.count + 1
        case .songs: listOfSongs.count + 1
        }
    }

    private func createLoadingCell(row: Int) -> UITableViewCell {
        let cell = UITableViewCell(style: .default, reuseIdentifier: "NoReuse")
        cell.backgroundColor = UIColor(named: "isubBackgroundColor")
        if self.isMoreResults {
            cell.textLabel?.text = "Loading more results..."
            let indicator = UIActivityIndicatorView(style: .medium)
            var y = self.tableView(self.tableView, heightForRowAt: IndexPath(row: row, section: 0))
            y /= 2
            indicator.center = CGPoint(x: 300, y: y)
            indicator.autoresizingMask = .flexibleLeftMargin
            cell.contentView.addSubview(indicator)
            indicator.startAnimating()

            self.loadMoreResults()
        } else {
            if self.listOfArtists.count > 0 || self.listOfAlbums.count > 0 || self.listOfSongs.count > 0 {
                cell.textLabel?.text = "No more search results"
            } else {
                cell.textLabel?.text = "No results"
            }
        }
        return cell
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch self.searchType {
        case .artists:
            if indexPath.row < self.listOfArtists.count {
                if let cell = tableView.dequeueReusableCell(
                    withIdentifier: UniversalTableViewCell.reuseId, for: indexPath
                ) as? UniversalTableViewCell {
                    cell.hideNumberLabel = true
                    cell.hideCoverArt = true
                    cell.hideSecondaryLabel = true
                    cell.hideDurationLabel = true
                    cell.update(model: self.listOfArtists[indexPath.row])
                    return cell
                }
            } else if indexPath.row == self.listOfArtists.count {
                return self.createLoadingCell(row: indexPath.row)
            }
        case .albums:
            if indexPath.row < self.listOfAlbums.count {
                if let cell = tableView.dequeueReusableCell(
                    withIdentifier: UniversalTableViewCell.reuseId, for: indexPath
                ) as? UniversalTableViewCell {
                    cell.hideNumberLabel = true
                    cell.hideCoverArt = false
                    cell.hideSecondaryLabel = false
                    cell.hideDurationLabel = true
                    cell.update(model: self.listOfAlbums[indexPath.row])
                    return cell
                }
            } else if indexPath.row == self.listOfAlbums.count {
                return self.createLoadingCell(row: indexPath.row)
            }
        case .songs:
            if indexPath.row < self.listOfSongs.count {
                if let cell = tableView.dequeueReusableCell(
                    withIdentifier: UniversalTableViewCell.reuseId, for: indexPath
                ) as? UniversalTableViewCell {
                    cell.hideNumberLabel = true
                    cell.hideCoverArt = false
                    cell.hideSecondaryLabel = false
                    cell.hideDurationLabel = false
                    cell.update(model: self.listOfSongs[indexPath.row])
                    return cell
                }
            } else if indexPath.row == self.listOfSongs.count {
                return self.createLoadingCell(row: indexPath.row)
            }
        }
        fatalError("no cell")
    }

    // cannot select last row, it's the loading row
    override func tableView(_ tableView: UITableView, shouldHighlightRowAt indexPath: IndexPath) -> Bool {
        switch self.searchType {
        case .artists: indexPath.row < listOfArtists.count
        case .albums: indexPath.row < listOfAlbums.count
        case .songs: indexPath.row < listOfSongs.count
        }
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch self.searchType {
        case .artists:
            if indexPath.row != self.listOfArtists.count {
                let artist = self.listOfArtists[indexPath.row]
                let albumView = AlbumViewController(artist: artist, orAlbum: nil)
                pushCustom(albumView)
            }
        case .albums:
            if indexPath.row != self.listOfAlbums.count {
                let album = self.listOfAlbums[indexPath.row]
                let albumView = AlbumViewController(artist: nil, orAlbum: album)
                pushCustom(albumView)
            }
        case .songs:
            if indexPath.row != self.listOfSongs.count {
                // Clear the current playlist
                if Settings.shared().isJukeboxEnabled {
                    Database.shared().resetJukeboxPlaylist()
                    Jukebox.shared().clearRemotePlaylist()
                } else {
                    Database.shared().resetCurrentPlaylistDb()
                }
                // Add the songs to the playlist
                var songIds = [String]()
                for song in self.listOfSongs {
                    song.addToCurrentPlaylistDbQueue()

                    // In jukebox mode, collect the song ids to send to the server
                    if Settings.shared().isJukeboxEnabled, let songId = song.songId {
                        songIds.append(songId)
                    }
                }

                // If jukebox mode, send song ids to server
                if Settings.shared().isJukeboxEnabled {
                    Jukebox.shared().stop()
                    Jukebox.shared().clearPlaylist()
                    Jukebox.shared().addSongs(songIds)
                }

                // Set player defaults
                PlayQueue.shared().isShuffle = false

                NotificationCenter.default.post(name: .init(ISMSNotification_CurrentPlaylistSongsQueued), object: nil)

                // Start the song
                let playedSong = Music.shared().playSong(atPosition: indexPath.row)
                if let playedSong, !playedSong.isVideo {
                    self.showPlayer()
                }
            }
        }
    }

    override func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        switch searchType {
        case .artists:
            if indexPath.row != self.listOfArtists.count {
                return SwipeAction.downloadAndQueueConfig(model: self.listOfArtists[indexPath.row])
            }
        case .albums:
            if indexPath.row != self.listOfAlbums.count {
                return SwipeAction.downloadAndQueueConfig(model: self.listOfAlbums[indexPath.row])
            }
        case .songs:
            if indexPath.row != self.listOfSongs.count {
                return SwipeAction.downloadAndQueueConfig(model: self.listOfSongs[indexPath.row])
            }
        }
        return nil
    }
}
