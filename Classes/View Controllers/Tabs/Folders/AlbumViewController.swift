import UIKit

final class AlbumViewController: UITableViewController, SUSLoaderDelegate {

    private var sectionInfo: [(String, Int)]? // for each "section", the first letter and the start index

    private let myId: String
    private let myArtist: Artist
    private let myAlbum: Album?

    private lazy var dataModel: SUSSubFolderDAO! = SUSSubFolderDAO(delegate: self, andId: self.myId, andArtist: self.myArtist)

    // for the two forms of this view controller, start with "folder" called Various Artists; that's the Artist alternative
    // then tap an album to see its tracks (songs); that's the Album alternative

    @objc init(withArtist artist: Artist?, orAlbum album: Album?) {

        if let artist {
            self.myId = artist.artistId ?? ""
            self.myArtist = artist
            self.myAlbum = nil
        } else if let album {
            self.myId = album.albumId ?? ""
            self.myArtist = Artist(name: album.artistName ?? "", andArtistId: album.artistId ?? "")
            self.myAlbum = album
        } else {
            fatalError("They can't both be nil")
        }

        super.init(nibName: nil, bundle: nil)

        if let artist {
            self.title = artist.name
        } else if let album {
            self.title = album.title
        }

        if self.dataModel.hasLoaded {
            self.tableView.reloadData()
            self.addHeaderAndIndex()
        } else {
            ViewObjects.shared().showAlbumLoadingScreen(self.view, sender: self)
            self.dataModel?.startLoad()
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        self.refreshControl = RefreshControl { [weak self] in
            guard let self else { return }
            ViewObjects.shared().showAlbumLoadingScreen(self.view, sender: self)
            self.dataModel.startLoad()
        }

        // this is my modification, so that the cells listing the tracks are multiline
        self.tableView.separatorStyle = .singleLine
        if self.myAlbum != nil {
            self.tableView.register(TrackTableViewCell.self, forCellReuseIdentifier: UniversalTableViewCell.reuseId)
            self.tableView.estimatedRowHeight = Defines.rowHeight
            self.tableView.rowHeight = UITableView.automaticDimension
            self.tableView.separatorColor = .label
            self.tableView.separatorInset = .zero
        } else {
            self.tableView.register(UniversalTableViewCell.self, forCellReuseIdentifier: UniversalTableViewCell.reuseId)
            self.tableView.rowHeight = Defines.rowHeight
            self.tableView.separatorColor = UIColor.clear
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        if Music.shared().showPlayerIcon {
            self.navigationItem.rightBarButtonItem = UIBarButtonItem(
                image: .init(systemName: Defines.musicNoteImageSystemName), style: .plain,
                target: self, action: #selector(nowPlayingAction)
            )
        } else {
            self.navigationItem.rightBarButtonItem = nil
        }

        self.tableView.reloadData()

        NotificationCenter.default.addObserver(self, selector: #selector(reloadData), name: .init(ISMSNotification_CurrentPlaylistIndexChanged), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(reloadData), name: .init(ISMSNotification_SongPlaybackStarted), object: nil)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        self.dataModel.cancelLoad()

        NotificationCenter.default.removeObserver(self, name: .init(ISMSNotification_CurrentPlaylistIndexChanged), object: nil)
        NotificationCenter.default.removeObserver(self, name: .init(ISMSNotification_SongPlaybackStarted), object: nil)
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
        self.dataModel.delegate = nil
    }

    @objc func reloadData() {
        self.tableView.reloadData()
    }

    private func cancelLoad() {
        self.dataModel.cancelLoad()
        self.refreshControl?.endRefreshing()
        ViewObjects.shared().hideLoadingScreen()
    }

    @objc private func nowPlayingAction() {
        let playerViewController = PlayerViewController()
        playerViewController.hidesBottomBarWhenPushed = true
        self.navigationController?.pushViewController(playerViewController, animated: true)
    }

    // Autolayout solution described here: https://medium.com/@aunnnn/table-header-view-with-autolayout-13de4cfc4343
    private func addHeaderAndIndex() {
        if self.dataModel.songsCount == 0 && self.dataModel.albumsCount == 0 {
            self.tableView.tableHeaderView = nil
        } else {
            // Create the container view and constrain it to the table
            let headerView = UIView()
            headerView.translatesAutoresizingMaskIntoConstraints = false
            self.tableView.tableHeaderView = headerView
            NSLayoutConstraint.activate([
                headerView.centerXAnchor.constraint(equalTo: self.tableView.centerXAnchor),
                headerView.widthAnchor.constraint(equalTo: self.tableView.widthAnchor),
                headerView.topAnchor.constraint(equalTo: self.tableView.topAnchor),
            ])

            // Create the play all and shuffle buttons and constrain to the container view
            let playAllAndShuffleHeader = PlayAllAndShuffleHeader { [weak self] in
                guard let self else { return }
                Database.shared().playAllSongs(self.myId, artist: self.myArtist)
            } shuffleHandler: {
                Database.shared().shuffleAllSongs(self.myId, artist: self.myArtist)
            }

            headerView.addSubview(playAllAndShuffleHeader)
            NSLayoutConstraint.activate([
                playAllAndShuffleHeader.leadingAnchor.constraint(equalTo: headerView.leadingAnchor),
                playAllAndShuffleHeader.trailingAnchor.constraint(equalTo: headerView.trailingAnchor),
                playAllAndShuffleHeader.bottomAnchor.constraint(equalTo: headerView.bottomAnchor),
            ])

            if self.dataModel.songsCount > 0, let album = myAlbum {
                // Create the album header view and constrain to the container view
                let albumHeader = AlbumTableViewHeader(album: album, tracks: Int(dataModel.songsCount), duration: Double(dataModel.folderLength))
                headerView.addSubview(albumHeader)
                NSLayoutConstraint.activate([
                    albumHeader.leadingAnchor.constraint(equalTo: headerView.leadingAnchor),
                    albumHeader.trailingAnchor.constraint(equalTo: headerView.trailingAnchor),
                    albumHeader.topAnchor.constraint(equalTo: headerView.topAnchor),
                ])

                // Constrain the buttons below the album header
                playAllAndShuffleHeader.topAnchor.constraint(equalTo: albumHeader.bottomAnchor).isActive = true
            } else {
                // Play All and Shuffle buttons only
                playAllAndShuffleHeader.topAnchor.constraint(equalTo: headerView.topAnchor).isActive = true
            }

            // Force re-layout using the constraints
            self.tableView.tableHeaderView?.layoutIfNeeded()
            self.tableView.tableHeaderView = self.tableView.tableHeaderView
        }

        self.sectionInfo = (self.dataModel.sectionInfo() as? [[Any]])?.map { ($0[0] as! String, $0[1] as! Int) }
        if self.sectionInfo != nil {
            self.tableView.reloadData()
        }
    }

    func loadingFailed(_ loader: SUSLoader!, withError error: Error!) {
        if Settings.shared().isPopupsEnabled {
            let message = "There was an error loading the album.\n\nError \(String(error._code)): \(error.localizedDescription)"
            let alert = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
            present(alert, animated: true)
        }

        ViewObjects.shared().hideLoadingScreen()

        self.refreshControl?.endRefreshing()
    }

    func loadingFinished(_ loader: SUSLoader!) {
        ViewObjects.shared().hideLoadingScreen()

        self.tableView.reloadData()
        self.addHeaderAndIndex()

        self.refreshControl?.endRefreshing()
    }

}

extension AlbumViewController /* UITableViewDataSource, UITableViewDelegate */ {
    override func sectionIndexTitles(for tableView: UITableView) -> [String]? {
        self.sectionInfo?.map { $0.0 }
    }

    // wow, check out this total perversion of what this method is supposed to do! yipes
    override func tableView(_ tableView: UITableView, sectionForSectionIndexTitle title: String, at index: Int) -> Int {
        guard let sectionInfo = self.sectionInfo else { return -1 }
        let row = sectionInfo[index].1
        let indexPath = IndexPath(row: row, section: 0)
        tableView.scrollToRow(at: indexPath, at: .top, animated: false)

        return -1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        Int(self.dataModel.totalCount)
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: UniversalTableViewCell.reuseId, for: indexPath) as? UniversalTableViewCell else {
            fatalError("no cell")
        }
        if indexPath.row < self.dataModel.albumsCount { // album
            cell.hideSecondaryLabel = true
            cell.hideNumberLabel = true
            cell.hideCoverArt = false
            cell.hideDurationLabel = true
            cell.update(model: self.dataModel.album(forTableViewRow: UInt(indexPath.row)))
        } else { // song
            cell.hideSecondaryLabel = false
            cell.hideCoverArt = true
            cell.hideDurationLabel = false
            if let song = self.dataModel.song(forTableViewRow: UInt(indexPath.row)) {
                cell.update(model: song)
                guard let track = song.track else {
                    cell.hideNumberLabel = true
                    return cell
                }
                if track.intValue == 0 {
                    cell.hideNumberLabel = true
                } else {
                    cell.hideNumberLabel = false
                    cell.number = track.intValue
                }
            }
        }
        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.row < self.dataModel.albumsCount { // created with artist, it's a list of albums
            let album = self.dataModel.album(forTableViewRow: UInt(indexPath.row))
            let albumViewController = AlbumViewController(withArtist: nil, orAlbum: album)
            pushCustom(albumViewController)
        } else { // created with album, it's a list of tracks (songs)
            // change the meaning of simple tap on a song in an album so that it enqueues that song
            // this is basically what was happening with the swipe action queue button before
            guard let song = self.dataModel.song(forTableViewRow: UInt(indexPath.row)) else { return }
            song.addToCurrentPlaylistDbQueue()
            // may as well provide the same feedback as before
            SlidingNotification.showOnMainWindow(message: "Added to play queue", duration: 1.0)
            UINotificationFeedbackGenerator().notificationOccurred(.success)
            // would be nice to deselect at this point
            // old code:
            /*
             ISMSSong *playedSong = [self.dataModel playSongAtTableViewRow:indexPath.row];
             if (!playedSong.isVideo) {
             [self showPlayer];
             }
             */
        }
    }

    override func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        if indexPath.row < self.dataModel.albumsCount {
            return SwipeAction.downloadAndQueueConfig(model: self.dataModel.album(forTableViewRow: UInt(indexPath.row)))
        } else {
            guard let song = self.dataModel.song(forTableViewRow: UInt(indexPath.row)) else { return nil }
            if !song.isVideo {
                return SwipeAction.downloadAndQueueConfig(model: song)
            }
        }
        return nil
    }

}
