import UIKit

final class PlaylistSongsViewController: UITableViewController {
    private let md5: String
    private let serverPlaylist: ServerPlaylist?

    private var isLocalPlaylist: Bool { serverPlaylist == nil }

    private var dataTaskIdentifier: Int?
    private var playlistCount = 0

    init(md5: String, serverPlaylist: ServerPlaylist?) {
        self.md5 = md5
        self.serverPlaylist = serverPlaylist
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        if self.isLocalPlaylist {
            self.title = Database.shared().localPlaylistsDbQueue?.string(
                forQuery: "SELECT playlist FROM localPlaylists WHERE md5 = ?",
                arguments: [self.md5]
            )
            if !Settings.shared().isOfflineMode {
                let headerView = UIView(frame: CGRect(x: 0, y: 0, width: 320, height: 50))

                let sendButton = UIButton(configuration: .filled(), primaryAction: .init { [weak self] _ in
                    guard let self else { return }
                    var parameters: [String: Any] = ["name": self.title ?? ""]

                    let query = "SELECT COUNT(*) FROM playlist\(md5)"
                    let count: Int = Database.shared().localPlaylistsDbQueue?.int(forQuery: query) ?? 0
                    let songIds: [String?] = (1...count).map { [weak self] i in
                        guard let self else { return nil }
                        let query = "SELECT songId FROM playlist\(md5) WHERE ROWID = \(i)"
                        return Database.shared().localPlaylistsDbQueue?.string(forQuery: query)
                    }
                    parameters["songId"] = songIds.compactMap {$0}

                    let request = NSMutableURLRequest(susAction: "createPlaylist", parameters: parameters)
                    let dataTask = SUSLoader.sharedSession().dataTask(with: request! as URLRequest) { [weak self] data, response, error in
                        guard let self else { return }
                        if let error = error as? NSError {
                            if Settings.shared().isPopupsEnabled {
                                Task { @MainActor in
                                    let message = "There was an error saving the playlist to the server.\n\nError \(error.code): error.localizedDescription"
                                    let alert = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
                                    alert.addAction(.init(title: "OK", style: .cancel, handler: nil))
                                    self.present(alert, animated: true)
                                }
                            }
                        } else if let data {
                            let stringData = String(data: data, encoding: .utf8)
                            NSLog("[PlaylistSongsViewController] upload playlist response: \(stringData ?? "")")
                            guard let root = RXMLElement(fromXMLData: data) else { return }
                            if !root.isValid {
                                let error = NSError(ismsCode: Int(ISMSErrorCode_NotXML))
                                self.subsonicErrorCode("", message: error?.description ?? "")
                            } else {
                                if let error = root.child("error") , error.isValid {
                                        let code = error.attribute("code") ?? ""
                                        let message = error.attribute("message") ?? ""
                                        self.subsonicErrorCode(code, message: message)
                                } else {
                                    UINotificationFeedbackGenerator().notificationOccurred(.success)
                                    if Settings.shared().isPopupsEnabled {
                                        Task { @MainActor in
                                            let message = "The playlist was saved to the server."
                                            let alert = UIAlertController(title: "Playlist Saved", message: message, preferredStyle: .alert)
                                            alert.addAction(.init(title: "OK", style: .cancel, handler: nil))
                                            self.present(alert, animated: true)
                                        }
                                    }
                                }
                            }
                        }

                        Task { @MainActor in
                            self.tableView.isScrollEnabled = true
                            ViewObjects.shared().hideLoadingScreen()
                            self.refreshControl?.endRefreshing()
                        }
                    }
                    dataTask.resume()
                    self.dataTaskIdentifier = dataTask.taskIdentifier

                    self.tableView.isScrollEnabled = false
                    ViewObjects.shared().showAlbumLoadingScreen(self.view, sender: self)
                })
                sendButton.autoresizingMask = [.flexibleWidth, .flexibleRightMargin]
                sendButton.frame = CGRect(x: 0, y: 0, width: 320, height: 50)
                sendButton.configuration?.background.backgroundColor = .clear
                sendButton.configuration?.attributedTitle = .init("Save to Server", attributes: AttributeContainer
                    .font(UIFont.boldSystemFont(ofSize: 24))
                    .foregroundColor(UIColor.label)
                )
                headerView.addSubview(sendButton)

                self.tableView.tableHeaderView = headerView
            }
        } else {
            self.title = self.serverPlaylist?.playlistName
            self.playlistCount = Database.shared().localPlaylistsDbQueue?.int(forQuery: "SELECT COUNT(*) FROM splaylist\(md5)") ?? 0
            self.tableView.reloadData()

            self.refreshControl = RefreshControl() { [weak self] in
                self?.loadData()
            }
        }

        self.tableView.estimatedRowHeight = Defines.rowHeight
        self.tableView.rowHeight = UITableView.automaticDimension
        self.tableView.separatorColor = .label
        self.tableView.separatorInset = .zero
        self.tableView.separatorStyle = .singleLine
        self.tableView.register(TrackTableViewCell.self, forCellReuseIdentifier: UniversalTableViewCell.reuseId)
    }

    private func loadData() {
        let parameters: [String: Any] = ["id": self.serverPlaylist?.playlistId ?? ""]
        guard let request = NSMutableURLRequest(susAction: "getPlaylist", parameters: parameters) else { return }
        let dataTask = SUSLoader.sharedSession().dataTask(with: request as URLRequest) { [weak self] data, response, error in
            guard let self else { return }
            if let error = error as? NSError {
                if Settings.shared().isPopupsEnabled {
                    Task { @MainActor in
                        let message = "There was an error loading the playlist.\n\nError \(error.code): error.localizedDescription"
                        let alert = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
                        alert.addAction(.init(title: "OK", style: .cancel, handler: nil))
                        self.present(alert, animated: true)
                    }
                }
                self.tableView.isScrollEnabled = true
                ViewObjects.shared().hideLoadingScreen()
                self.refreshControl?.endRefreshing()
            } else if let data {
                let stringData = String(data: data, encoding: .utf8)
                NSLog("[PlaylistSongsViewController] upload playlist response: \(stringData ?? "")")
                guard let root = RXMLElement(fromXMLData: data) else { return }
                if !root.isValid {
                    let error = NSError(ismsCode: Int(ISMSErrorCode_NotXML))
                    self.subsonicErrorCode("", message: error?.description ?? "")
                } else {
                    if let error = root.child("error") , error.isValid {
                        let code = error.attribute("code") ?? ""
                        let message = error.attribute("message") ?? ""
                        self.subsonicErrorCode(code, message: message)
                    } else {
                        if root.child("playlist").isValid {
                            Database.shared().removeServerPlaylistTable(self.md5)
                            Database.shared().createServerPlaylistTable(self.md5)
                            root.iterate("playlist.entry") { element in
                                if let element {
                                    let song = Song(rxmlElement: element)
                                    song.insertIntoServerPlaylist(withPlaylistId: self.md5)
                                }
                            }
                        }
                    }
                }
                let query = "SELECT COUNT(*) FROM splaylist\(self.md5)"
                self.playlistCount = Database.shared().localPlaylistsDbQueue?.int(forQuery: query) ?? 0
                Task { @MainActor in
                    self.tableView.reloadData()
                    self.refreshControl?.endRefreshing()
                    ViewObjects.shared().hideLoadingScreen()
                    self.tableView.isScrollEnabled = true
                }
            }
        }
        dataTask.resume()
        self.dataTaskIdentifier = dataTask.taskIdentifier

        self.tableView.isScrollEnabled = true
        ViewObjects.shared().showAlbumLoadingScreen(self.view, sender: self)
    }

    @objc func cancelLoad() { // called by the ViewObjects cancel button
        Task { @MainActor in
            let tasks = await SUSLoader.sharedSession().allTasks
            if let task = tasks.first(where: { $0.taskIdentifier == self.dataTaskIdentifier }) {
                task.cancel()
            }
            self.tableView.isScrollEnabled = true
            ViewObjects.shared().hideLoadingScreen()
            
            self.refreshControl?.endRefreshing()
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        if Music.shared().showPlayerIcon {
            self.navigationItem.rightBarButtonItem = .init(
                image: .init(systemName: Defines.musicNoteImageSystemName),
                primaryAction: .init { _ in
                    let playerViewController = PlayerViewController()
                    playerViewController.hidesBottomBarWhenPushed = true
                    self.navigationController?.pushViewController(playerViewController, animated: true)
                }
            )
        } else {
            self.navigationItem.rightBarButtonItem = nil
        }

        if self.isLocalPlaylist {
            let query = "SELECT COUNT(*) FROM playlist\(md5)"
            self.playlistCount = Database.shared().localPlaylistsDbQueue?.int(forQuery: query) ?? 0
            self.tableView.reloadData()
        } else {
            if self.playlistCount == 0 {
                self.loadData()
            }
        }
    }

    private func subsonicErrorCode(_ errorCode: String, message: String) {
        NSLog("[PlayistSongsViewController] subsonic error \(errorCode): \(message)")
        if Settings.shared().isPopupsEnabled {
            Task { @MainActor in
                let alert = UIAlertController(title: "Subsonic Error",  message: message, preferredStyle: .alert)
                alert.addAction(.init(title: "OK", style: .cancel))
                self.present(alert, animated: true)
            }
        }
    }

    private func song(at indexPath: IndexPath) -> Song? {
        if self.isLocalPlaylist {
            guard let queue = Database.shared().localPlaylistsDbQueue else { return nil }
            return Song(fromDbRow: UInt(indexPath.row), inTable:"playlist\(md5)", in: queue)
        } else {
            return Song(fromServerPlaylistId: md5, row: UInt(indexPath.row))
        }
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return playlistCount
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: UniversalTableViewCell.reuseId) as? UniversalTableViewCell else {
            fatalError("no cell")
        }
        guard let model = self.song(at: indexPath) else {
            fatalError("no song")
        }
        cell.hideNumberLabel = false
        cell.hideCoverArt = true
        cell.hideDurationLabel = false
        cell.hideSecondaryLabel = false
        cell.number = indexPath.row + 1
        cell.update(withModel: model)
        cell.secondaryLabel.text = model.album
        return cell
    }

    private func didSelectRowInternal(indexPath: IndexPath) {
        // Clear the current playlist
        if Settings.shared().isJukeboxEnabled {
            Database.shared().resetJukeboxPlaylist()
            Jukebox.shared().clearRemotePlaylist()
        } else {
            Database.shared().resetCurrentPlaylistDb()
        }

        PlayQueue.shared().isShuffle = false

        guard let md5 = Settings.shared().urlString?.md5() else { return }
        let databaseName = (Settings.shared().isOfflineMode
                            ? "offlineCurrentPlaylist.db"
                            : "\(md5)currentPlaylist.db"
                            )
        let currTableName = (Settings.shared().isJukeboxEnabled
                             ? "jukeboxCurrentPlaylist"
                             : "currentPlaylist"
                             )
        let playTableName = isLocalPlaylist ? "playlist\(self.md5)" : "splaylist\(self.md5)"
        Database.shared().localPlaylistsDbQueue?.inDatabase { db in
            let dbName: String = (Database.shared().databaseFolderPath as NSString).appendingPathComponent(databaseName)
            db.executeUpdate("ATTACH DATABASE ? AS ?", withArgumentsIn: [dbName, "currentPlaylistDb"])
            if db.hadError() {
                NSLog("[PlaylistSongsViewController] Err attaching the currentPlaylistDb \(db.lastErrorCode()): \(db.lastErrorMessage())")
            }

            db.executeUpdate("INSERT INTO \(currTableName) SELECT * FROM \(playTableName)")
            db.executeUpdate("DETACH DATABASE currentPlaylistDb")
        }

        if Settings.shared().isJukeboxEnabled {
            Jukebox.shared().replacePlaylistWithLocal()
        }

        ViewObjects.shared().hideLoadingScreen()

        if let playedSong = Music.shared().playSong(atPosition: indexPath.row) {
            if !playedSong.isVideo {
                self.showPlayer()
            }
        }
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        ViewObjects.shared().showLoadingScreenOnMainWindow(withMessage: nil)
        Task { @MainActor in
            try await Task.sleep(nanoseconds: 100_000_000)
            self.didSelectRowInternal(indexPath: indexPath)
        }
    }

    override func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        if let song = self.song(at: indexPath) {
            if !song.isVideo {
                return SwipeAction.downloadAndQueueConfig(model: song)
            }
        }
        return nil
    }
}


