
import UIKit

final class PlaylistsViewController: UIViewController {

    /// The loose view that appears in the center of the screen to say there are no
    /// playlists. There doesn't seem to be much point in using an image view;
    /// we could do the same with a plain view
    /// with the right background color and rounded corners.
    private lazy var noPlaylistsScreen: UIImageView = {
        let noPlaylistsScreen = UIImageView()
        noPlaylistsScreen.autoresizingMask = [.flexibleLeftMargin, .flexibleTopMargin, .flexibleRightMargin, .flexibleBottomMargin]
        noPlaylistsScreen.frame = CGRect(x: 0, y: 0, width: 240, height: 180)
        noPlaylistsScreen.center = CGPoint(x: self.view.bounds.size.width / 2, y: self.view.bounds.size.height / 2)
        noPlaylistsScreen.image = UIImage(named: "loading-screen-image")
        noPlaylistsScreen.alpha = 0.80
        noPlaylistsScreen.isUserInteractionEnabled = true
        noPlaylistsScreen.addSubview(noPlaylistsScreenTitleLabel)
        noPlaylistsScreen.addSubview(noPlaylistsScreenSubtitleLabel)
        return noPlaylistsScreen
    }()

    /// First label in the no playlists screen.
    private lazy var noPlaylistsScreenTitleLabel: UILabel = {
        let textLabel = UILabel()
        textLabel.backgroundColor = .clear
        textLabel.textColor = .white
        textLabel.font = .boldSystemFont(ofSize: 30)
        textLabel.textAlignment = .center
        textLabel.numberOfLines = 0
        return textLabel
    }()

    private lazy var noPlaylistsScreenSubtitleLabel: UILabel = {
        let textLabel2 = UILabel()
        textLabel2.backgroundColor = .clear
        textLabel2.textColor = .white
        textLabel2.font = .boldSystemFont(ofSize: 14)
        textLabel2.textAlignment = .center
        textLabel2.numberOfLines = 0
        return textLabel2
    }()

    private var ephemeralSession: URLSession?

    private lazy var serverPlaylistsDataModel = SUSServerPlaylistsDAO(delegate: self)

    private var currentPlaylistCount = 0

    /// Background behind the segmented control. Seems pointless, since it has no background color;
    /// the same thing could have been done with constraints alone.
    private lazy var segmentedControlContainer: UIView = {
        let segmentedControlContainer = UIView()
        segmentedControlContainer.translatesAutoresizingMaskIntoConstraints = false
        segmentedControlContainer.addSubview(self.segmentedControl)
        NSLayoutConstraint.activate([
            self.segmentedControl.topAnchor.constraint(equalTo: segmentedControlContainer.topAnchor),
            self.segmentedControl.bottomAnchor
                .constraint(equalTo: segmentedControlContainer.bottomAnchor, constant: -8),
            self.segmentedControl.leadingAnchor.constraint(equalTo: segmentedControlContainer.leadingAnchor),
            self.segmentedControl.trailingAnchor.constraint(equalTo: segmentedControlContainer.trailingAnchor),
        ])
        return segmentedControlContainer
    }()

    private lazy var segmentedControl: UISegmentedControl = {
        let segmentedControl = UISegmentedControl(items: ["", "", ""]) // dummies just so we have segments
        // TODO: fix this so it's unavailable if offline
        let titles =  Settings.shared().isOfflineMode ? ["Current", "Local", "[Server]"] : ["Current", "Local", "Server"]
        segmentedControl.translatesAutoresizingMaskIntoConstraints = false
        segmentedControl.selectedSegmentIndex = 0
        // current
        segmentedControl.setAction(.init(title: titles[0]) { [weak self] _ in
            guard let self else { return }
            self.tableView.reloadData()
            self.removeHeader()
            self.removeNoPlaylistsScreen()
            self.currentPlaylistCount = Int(PlayQueue.shared().count)
            if self.currentPlaylistCount > 0 {
                self.addAndConfigureHeader()
            }
            selectCurrentRowOfCurrentPlaylist()
        }, forSegmentAt: 0)
        // local, or offline
        segmentedControl.setAction(.init(title: titles[1]) { [weak self] _ in
            guard let self else { return }
            self.tableView.reloadData()
            self.removeHeader()
            self.removeNoPlaylistsScreen()
            let localPlaylistsCount = Database.shared().localPlaylistsDbQueue?.int(
                forQuery: "SELECT COUNT(*) FROM localPlaylists"
            ) ?? 0
            if localPlaylistsCount > 0 {
                self.addAndConfigureHeader()
            } else if localPlaylistsCount == 0 {
                self.addNoPlaylistsScreen()
            }
        }, forSegmentAt: 1)
        segmentedControl.setAction(.init(title: titles[2]) { [weak self] _ in
            guard let self else { return }
            self.removeHeader()
            self.removeNoPlaylistsScreen()
            self.tableView.reloadData()
            ViewObjects.shared().showAlbumLoadingScreen(AppDelegate.shared().window, sender: self) // ?? really?
            self.serverPlaylistsDataModel?.startLoad()
        }, forSegmentAt: 2)
        return segmentedControl
    }()

    private lazy var saveEditContainer: UIView = {
        let saveEditContainer = UIView()
        saveEditContainer.translatesAutoresizingMaskIntoConstraints = false

        saveEditContainer.addSubview(self.leftButton)
        saveEditContainer.addSubview(self.rightButton)

        NSLayoutConstraint.activate([
            self.leftButton.widthAnchor.constraint(equalTo: saveEditContainer.widthAnchor, multiplier:0.75),
            self.leftButton.leadingAnchor.constraint(equalTo: saveEditContainer.leadingAnchor),
            self.leftButton.topAnchor.constraint(equalTo: saveEditContainer.topAnchor),
            self.leftButton.bottomAnchor.constraint(equalTo: saveEditContainer.bottomAnchor),

            self.rightButton.widthAnchor.constraint(equalTo: saveEditContainer.widthAnchor, multiplier:0.25),
            self.rightButton.trailingAnchor.constraint(equalTo: saveEditContainer.trailingAnchor),
            self.rightButton.topAnchor.constraint(equalTo: saveEditContainer.topAnchor),
            self.rightButton.bottomAnchor.constraint(equalTo: saveEditContainer.bottomAnchor),
        ])
        return saveEditContainer
    }()

    private func leftButtonLeaveEditMode() {
        leftButton.configuration?.attributedTitle = AttributedString(
            "Save Playlist",
            attributes: AttributeContainer
                .font(UIFont.boldSystemFont(ofSize: 22))
                .foregroundColor(UIColor.label)
        )
        if self.segmentedControl.selectedSegmentIndex == 0 {
            leftButton.configuration?.attributedSubtitle = AttributedString(
                "1 song",
                attributes: AttributeContainer
                    .font(UIFont.boldSystemFont(ofSize: 12))
                    .foregroundColor(UIColor.label)
            )
            self.updateCurrentPlaylistCount()
        } else {
            leftButton.configuration?.attributedSubtitle = nil
        }
        leftButton.configuration?.baseBackgroundColor = UIColor.clear
        leftButton.configuration?.titleAlignment = .center
    }

    private func leftButtonEnterEditMode() {
        leftButton.configuration?.attributedTitle = AttributedString(
            "Select All",
            attributes: AttributeContainer
                .font(UIFont.boldSystemFont(ofSize: 22))
                .foregroundColor(.label)
        )
        leftButton.configuration?.attributedSubtitle = nil
        leftButton.configuration?.baseBackgroundColor = UIColor(red: 0.93, green: 0.43, blue: 0.43, alpha: 1)
    }

    /// Button that sits on the wider left side of the header.
    /// It can save, select all, or delete selected.
    private lazy var leftButton: UIButton = {
        let leftButton = UIButton(configuration: .filled())
        leftButton.configuration?.background.cornerRadius = 0 // pure rectangle
        leftButton.translatesAutoresizingMaskIntoConstraints = false
        leftButton.addAction(.init { [weak self] action in
            guard let self else { return }
            let selectedRowIndexes = (self.tableView.indexPathsForSelectedRows ?? []).map(\.row)
            let deleteAction: () -> () = { // this is what we will do if the button says Delete
                self.unregisterForNotifications()
                switch self.segmentedControl.selectedSegmentIndex {
                case 0: self.deleteCurrentPlaylistSongs(at: selectedRowIndexes)
                case 1: self.deleteLocalPlaylists(at: selectedRowIndexes)
                default: break
                }
                ViewObjects.shared().hideLoadingScreen()
                self.registerForNotifications()
            }
            switch self.segmentedControl.selectedSegmentIndex {
            case 0:
                if (action.sender as! UIButton).configuration?.title == "Save Playlist" { // show appropriate alert
                    if Settings.shared().isOfflineMode {
                        self.showSavePlaylistAlert(savePlaylistLocal: true)
                    } else {
                        let message = "Would you like to save this playlist to your device or to the server?"
                        let alert = UIAlertController(title: "Playlist Location", message: message, preferredStyle: .actionSheet)
                        alert.addAction(.init(title: "Local", style: .default) { [weak self] _ in
                            self?.showSavePlaylistAlert(savePlaylistLocal: true)
                        })
                        alert.addAction(.init(title: "Server", style: .default) { [weak self] _ in
                            self?.showSavePlaylistAlert(savePlaylistLocal: false)
                        })
                        alert.addAction(.init(title: "Cancel", style: .cancel, handler: nil))
                        self.present(alert, animated: true)
                        if let pop = alert.popoverPresentationController {
                            pop.sourceView = self.leftButton
                            pop.sourceRect = self.leftButton.bounds
                        }
                    }
                } else { // select or delete
                    if selectedRowIndexes.count == 0 && self.isEditing { // select
                        // Select all the rows
                        for i in 0..<self.currentPlaylistCount {
                            self.tableView.selectRow(at: .init(row: i, section: 0), animated: false, scrollPosition: .none)
                        }
                        self.leftSideUpdateForEditingMode()
                    } else { // delete
                        ViewObjects.shared().showLoadingScreenOnMainWindow(withMessage: "Deleting")
                        Task {
                            try await Task.sleep(nanoseconds: 50_000_000)
                            deleteAction()
                        }
                    }
                }
            case 1:
                guard (action.sender as! UIButton).configuration?.title != "Save Playlist" else { break }
                if selectedRowIndexes.count == 0 { // select all
                    let count = Database.shared().localPlaylistsDbQueue?.int(forQuery: "SELECT COUNT(*) FROM localPlaylists") ?? 0
                    for i in 0..<count {
                        self.tableView.selectRow(at: .init(row: i, section: 0), animated: false, scrollPosition: .none)
                    }
                    self.leftSideUpdateForEditingMode()
                } else { // delete
                    ViewObjects.shared().showLoadingScreenOnMainWindow(withMessage: "Deleting")
                    Task {
                        try await Task.sleep(nanoseconds: 50_000_000)
                        deleteAction()
                    }
                }
            case 2:
                guard (action.sender as! UIButton).configuration?.title != "Save Playlist" else { break }
                if (selectedRowIndexes.count == 0) { // select
                    if let count = self.serverPlaylistsDataModel?.serverPlaylists?.count {
                        for i in 0..<count {
                            self.tableView.selectRow(at: .init(row: i, section: 0), animated: false, scrollPosition: .none)
                        }
                        self.leftSideUpdateForEditingMode()
                    }
                } else { // delete
                    self.deleteServerPlaylists(at: selectedRowIndexes)
                }
            default: break
            }
        }, for: .touchUpInside)
        return leftButton
    }()

    /// Invisible button that sits on the narrower right side of the top area.
    /// It enters or leaves edit mode.
    private lazy var rightButton: UIButton = {
        let rightButton = UIButton(configuration: .filled())
        rightButton.configuration?.background.cornerRadius = 0 // pure rectangle
        rightButton.translatesAutoresizingMaskIntoConstraints = false
        rightButton.addAction(.init { [weak self] _ in
            guard let self else { return }
            switch self.segmentedControl.selectedSegmentIndex {
            case 0:
                if self.isEditing { // stop editing
                    self.changeEditMode(false, animated: true) {
                        // Afterwards, reload the table to correct the numbers
                        Task { @MainActor in
                            // need the delay in case there is no height change,
                            // so that we don't tromp on the animation
                            try await Task.sleep(nanoseconds: 300_000_000)
                            self.tableView.reloadData()
                            let currentIndex = PlayQueue.shared().currentIndex
                            if currentIndex >= 0 && currentIndex < self.currentPlaylistCount {
                                self.tableView.selectRow(at: .init(row: currentIndex, section: 0), animated: false, scrollPosition: .top)
                            }
                        }
                    }
                    rightButtonLeaveEditMode()
                    leftButtonLeaveEditMode()
                } else { // start editing; cannot switch "tabs" while editing
                    self.changeEditMode(true, animated: true, andThen: {})
                    leftButtonEnterEditMode()
                    self.leftSideUpdateForEditingMode()
                    rightButtonEnterEditMode()
                }
            case 1, 2:
                if self.isEditing { // stop editing
                    self.changeEditMode(false, animated: true) {
                        // Afterwards, reload the table to correct the numbers
                        Task { @MainActor in
                            // need the delay in case there is no height change,
                            // so that we don't tromp on the animation
                            try await Task.sleep(nanoseconds: 300_000_000)
                            self.tableView.reloadData()
                        }
                    }
                    rightButtonLeaveEditMode()
                    leftButtonLeaveEditMode()
                } else { // start editing; cannot switch "table
                    self.changeEditMode(true, animated: true, andThen: {})
                    leftButtonEnterEditMode()
                    self.leftSideUpdateForEditingMode()
                    rightButtonEnterEditMode()
                }
            default: break
            }
        }, for: .touchUpInside)
        return rightButton
    }()

    func rightButtonLeaveEditMode() {
        rightButton.configuration?.attributedTitle = AttributedString(
            "Edit",
            attributes: AttributeContainer
                .font(UIFont.boldSystemFont(ofSize: 22))
                .foregroundColor(.systemBlue)
        )
        rightButton.configuration?.baseBackgroundColor = .clear
    }

    func rightButtonEnterEditMode() {
        rightButton.configuration?.attributedTitle = AttributedString(
            "Done",
            attributes: AttributeContainer
                .font(UIFont.boldSystemFont(ofSize: 22))
                .foregroundColor(.label)
        )
        rightButton.configuration?.baseBackgroundColor = UIColor(red: 0.008, green: 0.46, blue: 0.933, alpha: 1)
    }

    private lazy var tableView: UITableView = {
        let tableView = UITableView()
        tableView.translatesAutoresizingMaskIntoConstraints = false
        return tableView
    }()

    private lazy var tableViewTopConstraint: NSLayoutConstraint = self.tableView.topAnchor
        .constraint(equalTo: self.segmentedControlContainer.bottomAnchor)

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        coordinator.animate { context in
            guard !UIDevice.isPad() else { return }

            if UIApplication.orientation().isPortrait {
                self.noPlaylistsScreen.transform = CGAffineTransformTranslate(self.noPlaylistsScreen.transform, 0.0, -23.0)
            } else {
                self.noPlaylistsScreen.transform = CGAffineTransformTranslate(self.noPlaylistsScreen.transform, 0.0, 110.0)
            }
        }
    }

    var observers = Set<NSObject>()

    private func registerForNotifications() {
        NotificationCenter.default.addObserver(self, selector: #selector(selectCurrentRowOfCurrentPlaylist), name: .init(ISMSNotification_BassInitialized), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(selectCurrentRowOfCurrentPlaylist), name: .init(ISMSNotification_BassFreed), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(selectCurrentRowOfCurrentPlaylist), name: .init(ISMSNotification_CurrentPlaylistIndexChanged), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(selectCurrentRowOfCurrentPlaylist), name: .init(ISMSNotification_CurrentPlaylistShuffleToggled), object: nil)
        // TODO: I don't see any evidence that this notification exists
        NotificationCenter.default.addObserver(self, selector: #selector(updateCurrentPlaylistCount), name: .init("updateCurrentPlaylistCount"), object: nil)
        var ob = NotificationCenter.default.addObserver(forName: .init(ISMSNotification_CurrentPlaylistSongsQueued), object: nil, queue: nil) { [weak self] _ in
            self?.updateCurrentPlaylistCount()
            self?.tableView.reloadData()
        }
        observers.insert(ob as! NSObject)
        ob = NotificationCenter.default.addObserver(forName: .init(ISMSNotification_JukeboxSongInfo), object: nil, queue: nil) { [weak self] _ in
            self?.updateCurrentPlaylistCount()
            self?.tableView.reloadData()
            self?.selectCurrentRowOfCurrentPlaylist()
        }
        observers.insert(ob as! NSObject)
    }

    private func unregisterForNotifications() {
        NotificationCenter.default.removeObserver(self, name: .init(ISMSNotification_BassInitialized), object: nil)
        NotificationCenter.default.removeObserver(self, name: .init(ISMSNotification_BassFreed), object: nil)
        NotificationCenter.default.removeObserver(self, name: .init(ISMSNotification_CurrentPlaylistIndexChanged), object: nil)
        NotificationCenter.default.removeObserver(self, name: .init(ISMSNotification_CurrentPlaylistShuffleToggled), object: nil)
        // TODO: I don't see any evidence that this notification exists
        NotificationCenter.default.removeObserver(self, name: .init("updateCurrentPlaylistCount"), object: nil)
        for observer in self.observers {
            NotificationCenter.default.removeObserver(observer)
        }
        self.observers.removeAll()
    }

    private func recreateEphemeralSession() {
        self.ephemeralSession?.invalidateAndCancel()
        let configuration = URLSessionConfiguration.ephemeral
        let ephemeralSessionDelegate = SelfSignedCertURLSessionDelegate()
        self.ephemeralSession = URLSession(configuration: configuration, delegate: ephemeralSessionDelegate, delegateQueue: nil)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        self.recreateEphemeralSession()

        self.view.backgroundColor = UIColor(named: "isubBackgroundColor")
        self.title = "Playlists"

        if Settings.shared().isOfflineMode {
            self.navigationItem.leftBarButtonItem = UIBarButtonItem(
                image: .init(systemName: "gearshape.fill"),
                primaryAction: .init { [weak self] _ in
                    let serverListViewController = ServerListViewController(nibName: "ServerListViewController", bundle: nil)
                    serverListViewController.hidesBottomBarWhenPushed = true
                    self?.navigationController?.pushViewController(serverListViewController, animated: true)
                }
            )
        }

        self.view.addSubview(self.segmentedControlContainer)
        self.view.addSubview(self.tableView)

        NSLayoutConstraint.activate([
            segmentedControlContainer.topAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.topAnchor, constant:8),
            segmentedControlContainer.leadingAnchor.constraint(equalTo: self.view.leadingAnchor, constant:6),
            segmentedControlContainer.trailingAnchor.constraint(equalTo: self.view.trailingAnchor, constant:-6),
            segmentedControlContainer.heightAnchor.constraint(equalToConstant: 36),
        ])

        NSLayoutConstraint.activate([
            self.tableViewTopConstraint,
            self.tableView.bottomAnchor.constraint(equalTo: self.view.bottomAnchor),
            self.tableView.leadingAnchor.constraint(equalTo: self.view.leadingAnchor),
            self.tableView.trailingAnchor.constraint(equalTo: self.view.trailingAnchor),
        ])

        self.tableView.allowsMultipleSelectionDuringEditing = true
        self.tableView.register(TrackTableViewCell.self, forCellReuseIdentifier: UniversalTableViewCell.reuseId)
        self.tableView.estimatedRowHeight = Defines.rowHeight
        self.tableView.rowHeight = UITableView.automaticDimension
        self.tableView.separatorColor = UIColor.label
        self.tableView.separatorInset = .zero
        self.tableView.delegate = self
        self.tableView.dataSource = self

        NotificationCenter.default.addObserver(
            self, selector: #selector(addURLRefBackButton), name: UIApplication.didBecomeActiveNotification, object: nil
        )
    }

    override func viewWillAppear(_ animated: Bool) { // TODO: I'm pretty sure we should register / unregister when backgrounding too
        super.viewWillAppear(animated)

        self.addURLRefBackButton()

        self.navigationItem.rightBarButtonItem = nil
        if Music.shared().showPlayerIcon {
            self.navigationItem.rightBarButtonItem = UIBarButtonItem(
                image: UIImage(systemName: Defines.musicNoteImageSystemName),
                primaryAction: .init { [weak self] _ in
                    let playerViewController = PlayerViewController()
                    playerViewController.hidesBottomBarWhenPushed = true
                    self?.navigationController?.pushViewController(playerViewController, animated: true)
                }
            )
        }

        // Reload the data, etc., in case things changed
        self.performCurrentSegmentedControlAction()

        self.registerForNotifications()

        if Settings.shared().isJukeboxEnabled {
            Jukebox.shared().getInfo()
        }
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)

        self.unregisterForNotifications()

        self.changeEditMode(false, animated: false, andThen: {})
    }

    @objc private func addURLRefBackButton() {
        if AppDelegate.shared().referringAppUrl != nil {
            if AppDelegate.shared().mainTabBarController.selectedIndex != 4 { // ?
                self.navigationItem.leftBarButtonItem = UIBarButtonItem(
                    title: "Back", style:.plain,
                    target: AppDelegate.shared(), action: #selector(AppDelegate.backToReferringApp)
                )
            }
        }
    }

    private func performCurrentSegmentedControlAction() {
        if let action = self.segmentedControl.actionForSegment(
            at: self.segmentedControl.selectedSegmentIndex
        ) {
            self.segmentedControl.sendAction(action)
        }
    }

    // MARK: Header

    /// Configures the left side of the header to match
    /// the current selection within editing mode.
    private func leftSideUpdateForEditingMode() {
        let selectedRowsCount = self.tableView.indexPathsForSelectedRows?.count ?? 0
        switch self.segmentedControl.selectedSegmentIndex {
        case 0:
            switch selectedRowsCount {
            case 0:
                leftButton.configuration?.attributedTitle?.characters = .init("Select All")
            default:
                leftButton.configuration?.attributedTitle?.characters = .init("Remove " + "Song".pluralized(count: selectedRowsCount))
            }
        case 1, 2:
            switch selectedRowsCount {
            case 0:
                leftButton.configuration?.attributedTitle?.characters = .init("Select All")
            default:
                leftButton.configuration?.attributedTitle?.characters = .init("Remove " + "Playlist".pluralized(count: selectedRowsCount))
            }
        default: break
        }
    }

    func changeEditMode(_ editing: Bool, animated: Bool, andThen: @escaping () -> ()) {
        self.setEditing(editing, animated: false)
        self.tableView.setEditing(editing, animated: true)
        self.segmentedControl.isEnabled = !editing // let's just make a simple rule about this
        // and now comes the Secret Sauce! these next lines cause cell height recalculation
        // plus we can do a completion handler after the animation
        self.tableView.performBatchUpdates {
            // none
        } completion: { _ in
            Task { @MainActor in
                andThen()
            }
        }
    }

    /// Left button Save action
    private func showSavePlaylistAlert(savePlaylistLocal: Bool) {
        let alert = UIAlertController(title: "Save Playlist", message: nil, preferredStyle: .alert)
        alert.addTextField {
            $0.placeholder =  "Playlist name"
        }
        alert.addAction(.init(title: "Save", style: .default) {
            [weak self] _ in
            guard let self else { return }
            let name = alert.textFields?.first?.text ?? ""
            if name.isEmpty {
                return
            }
            let md5 = name.md5() ?? ""
            if savePlaylistLocal || Settings.shared().isOfflineMode {
                // Check if the playlist exists, if not create the playlist table and add the entry
                // to localPlaylists table
                let test = Database.shared().localPlaylistsDbQueue?.string(
                    forQuery: "SELECT md5 FROM localPlaylists WHERE md5 = ?", arguments: [md5]
                )
                if test != nil {
                    // If it exists, ask to overwrite
                    self.showOverwritePlaylistAlert(name, savePlaylistLocal: true)
                } else {
                    let databaseName = (
                        Settings.shared().isOfflineMode
                        ? "offlineCurrentPlaylist.db"
                        : "\(Settings.shared().urlString?.md5() ?? "")currentPlaylist.db"
                    )
                    let currTable = (
                        Settings.shared().isJukeboxEnabled
                        ? "jukeboxCurrentPlaylist"
                        : "currentPlaylist"
                    )
                    let shufTable = (
                        Settings.shared().isJukeboxEnabled
                        ? "jukeboxShufflePlaylist"
                        : "shufflePlaylist"
                    )
                    let table = PlayQueue.shared().isShuffle ? shufTable : currTable
                    Database.shared().localPlaylistsDbQueue?.inDatabase { db in
                        db.executeUpdate(
                            "INSERT INTO localPlaylists (playlist, md5) VALUES (?, ?)", withArgumentsIn: [name, md5]
                        )
                        db.executeUpdate(
                            "CREATE TABLE playlist\(md5) (\(Song.standardSongColumnSchema()))"
                        )
                        let path = (Database.shared().databaseFolderPath as NSString).appendingPathComponent(databaseName)
                        db.executeUpdate(
                            "ATTACH DATABASE ? AS ?", withArgumentsIn: [path, "currentPlaylistDb"]
                        )
                        if db.hadError() {
                            NSLog("[PlaylistsViewController] Err attaching the currentPlaylistDb \(db.lastErrorCode()): \(db.lastErrorMessage())")
                        }
                        db.executeUpdate(
                            "INSERT INTO playlist\(md5) SELECT * FROM \(table)"
                        )
                        db.executeUpdate(
                            "DETACH DATABASE currentPlaylistDb"
                        )
                    }
                }
            } else { // save playlist to server
                let tableName = "splaylist\(md5)"
                Database.shared().localPlaylistsDbQueue?.inDatabase { db in
                    let exists = db.tableExists(tableName)
                    Task { @MainActor in
                        if exists {
                            // If it exists, ask to overwrite
                            self.showOverwritePlaylistAlert(name, savePlaylistLocal: false)
                        } else {
                            self.uploadPlaylist(name: name)
                        }
                    }
                }
            }
        })
        alert.addAction(.init(title: "Cancel", style: .cancel, handler: nil))
        self.present(alert, animated: true)
    }

    /// Continuation of the above, in the case where the user types an existing name for playlist
    private func showOverwritePlaylistAlert(_ name: String, savePlaylistLocal: Bool) {
        let md5 = name.md5() ?? ""
        let message = #"A playlist named "\#(name)" already exists. Would you like to overwrite it?"#
        let alert = UIAlertController(title: "Overwrite?", message: message, preferredStyle: .alert)
        alert.addAction(.init(title: "Overwrite", style: .destructive) { [weak self] _ in
            guard let self else { return }
            // If yes, overwrite the playlist
            if savePlaylistLocal || Settings.shared().isOfflineMode {
                let databaseName = (
                    Settings.shared().isOfflineMode
                    ? "offlineCurrentPlaylist.db"
                    : "\(Settings.shared().urlString?.md5() ?? "")currentPlaylist.db"
                )
                let currTable = Settings.shared().isJukeboxEnabled ? "jukeboxCurrentPlaylist" : "currentPlaylist"
                let shufTable = Settings.shared().isJukeboxEnabled ? "jukeboxShufflePlaylist" : "shufflePlaylist"
                let table = PlayQueue.shared().isShuffle ? shufTable : currTable

                Database.shared().localPlaylistsDbQueue?.inDatabase { db in
                    db.executeUpdate("DROP TABLE playlist\(md5)")
                    db.executeUpdate("CREATE TABLE playlist\(md5) (\(Song.standardSongColumnSchema()))")
                    let path = (Database.shared().databaseFolderPath as NSString).appendingPathComponent(databaseName)
                    db.executeUpdate("ATTACH DATABASE ? AS ?", withArgumentsIn: [path, "currentPlaylistDb"])
                    if db.hadError() {
                        NSLog("[PlaylistsViewController] Err attaching the currentPlaylistDb \(db.lastErrorCode()): \(db.lastErrorMessage())")
                    }
                    db.executeUpdate("INSERT INTO playlist\(md5) SELECT * FROM \(table)")
                    db.executeUpdate("DETACH DATABASE currentPlaylistDb")

                }
            } else {
                Database.shared().localPlaylistsDbQueue?.inDatabase { db in
                    db.executeUpdate("DROP TABLE splaylist\(md5)")
                }
                self.uploadPlaylist(name: name)
            }
        })
        alert.addAction(.init(title: "Cancel", style: .cancel, handler: nil))
        self.present(alert, animated: true)
    }

    /// Further continuation of both of the above.
    /// Actual work of the third "save" case: save playlist to _server_.
    /// In some ways this is the easiest case: we just prepare and perform a URL request,
    /// and then parse the result as XML
    private func uploadPlaylist(name: String) {
        var parameters: [String: Any] = ["name": name]
        var songIds = [String]()
        let currTable = Settings.shared().isJukeboxEnabled ? "jukeboxCurrentPlaylist" : "currentPlaylist"
        let shufTable = Settings.shared().isJukeboxEnabled ? "jukeboxShufflePlaylist" : "shufflePlaylist"
        let table = PlayQueue.shared().isShuffle ? shufTable : currTable

        Database.shared().currentPlaylistDbQueue?.inDatabase { db in
            for i in 0..<self.currentPlaylistCount {
                if let song = Song(fromDbRow: UInt(i), inTable: table, in: db), let id = song.songId {
                    songIds.append(id)
                }
            }
        }
        parameters["songId"] = songIds

        let request = NSMutableURLRequest(susAction: "createPlaylist", parameters: parameters) as URLRequest
        let dataTask = ephemeralSession?.dataTask(with: request) { data, response, error in // TODO: really should adopt async here
            if let error {
                if Settings.shared().isPopupsEnabled {
                    Task { @MainActor in
                        let code = (error as NSError).code
                        let message = """
                        There was an error saving the playlist to the server.
                        Error \(code): \(error.localizedDescription)
                        """
                        let alert = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
                        alert.addAction(.init(title: "OK", style: .cancel, handler: nil))
                        self.present(alert, animated: true)
                    }
                }
            } else if let data {
                if let root = RXMLElement(fromXMLData: data) {
                    if !root.isValid {
                        if let error = NSError(ismsCode: Int(ISMSErrorCode_NotXML)) {
                            self.subsonicErrorCode(nil, message: error.description)
                        }
                    } else {
                        if let error = root.child("error") {
                            if error.isValid {
                                let code = error.attribute("code")
                                let message = error.attribute("message")
                                self.subsonicErrorCode(code, message: message)
                            }
                        }
                    }
                }
            }
            Task { @MainActor in
                self.tableView.isScrollEnabled = true
                ViewObjects.shared().hideLoadingScreen()
            }
        }
        dataTask?.resume()
        self.tableView.isScrollEnabled = false
        ViewObjects.shared().showAlbumLoadingScreen(self.view, sender: self)
    }

    /// Utility of the previous, post an error if there is one
    private func subsonicErrorCode(_ code: String?, message: String?) {
        NSLog(#"[PlaylistsViewController] subsonic error \(code ?? "[no code]): \(message ?? [no message])"#)
        if Settings.shared().isPopupsEnabled {
            Task { @MainActor in
                let alert = UIAlertController(title: "Subsonic Error", message: message, preferredStyle: .alert)
                alert.addAction(.init(title: "OK", style: .cancel, handler: nil))
                self.present(alert, animated: true)
            }
        }
    }

    /// Coordinate first tab selection with currently playing song.
    /// Mostly triggered by notifications from the shared play queue. Also called directly when
    /// switching segmented control index.
    /// Does not just select the current row; it puts up the no playlists screen if there are
    /// no rows.
    @objc private func selectCurrentRowOfCurrentPlaylist() {
        if self.segmentedControl.selectedSegmentIndex == 0 {
            self.tableView.reloadData()
            self.updateCurrentPlaylistCount()
            let currentIndex = PlayQueue.shared().currentIndex
            if currentIndex >= 0 && currentIndex < self.currentPlaylistCount {
                Task { @MainActor in
                    try await Task.sleep(nanoseconds: 200_000_000) // needed esp. if launching
                    // how to select and scroll to row with minimum scrolling
                    self.tableView.selectRow(at: .init(row: currentIndex, section: 0), animated: false, scrollPosition: .none)
                    self.tableView.scrollToRow(at: .init(row: currentIndex, section: 0), at: .none, animated: false)
                }
            } else if self.currentPlaylistCount == 0 {
                self.addNoPlaylistsScreen()
            }
        }
    }

    /// Utility to be called any time we want to make sure we know (and are displaying) the number
    /// of songs in the current playlist (first tab).
    @objc private func updateCurrentPlaylistCount() {
        if self.segmentedControl.selectedSegmentIndex == 0 {
            self.currentPlaylistCount = Int(PlayQueue.shared().count)
            leftButton.configuration?.attributedSubtitle?.characters = .init("song".pluralized(count: self.currentPlaylistCount))
        }
    }

    /// If a "tab" is empty, remove the header area completely. I don't see any reason to
    /// disassemble and destroy the view as he was doing; it's sufficient to remove it
    /// and close up the constraint.
    private func removeHeader() {
        self.saveEditContainer.removeFromSuperview()
        self.tableViewTopConstraint.constant = 0
    }

    /// Create and insert the header area, and also make sure the "buttons" are correctly labeled.
    private func addAndConfigureHeader() { // TODO: Could be simplified heavily?
        if self.saveEditContainer.window == nil {
            self.view.addSubview(self.saveEditContainer)
            NSLayoutConstraint.activate([
                self.saveEditContainer.widthAnchor.constraint(equalTo: self.view.widthAnchor),
                self.saveEditContainer.heightAnchor.constraint(equalToConstant: 50),
                self.saveEditContainer.topAnchor.constraint(equalTo: self.segmentedControlContainer.bottomAnchor),
                // no bottom, the height is fixed
            ])
            self.tableViewTopConstraint.constant = 50
        }

        // left side
        leftButtonLeaveEditMode()
        switch self.segmentedControl.selectedSegmentIndex {
        case 0:
            leftButton.configuration?.attributedTitle?.characters = .init("Save Playlist")
            leftButton.configuration?.attributedSubtitle?.characters = .init("song".pluralized(count: self.currentPlaylistCount))
        case 1:
            var count: Int?
            if let queue = Database.shared().localPlaylistsDbQueue {
                count = queue.int(forQuery: "SELECT COUNT(*) FROM localPlaylists")
            }
            let localPlaylistsCount = count ?? 0
            leftButton.configuration?.attributedTitle?.characters = .init("playlist".pluralized(count: localPlaylistsCount))
        case 2:
            let serverPlaylistsCount = self.serverPlaylistsDataModel?.serverPlaylists?.count ?? 0
            leftButton.configuration?.attributedTitle?.characters = .init("playlist".pluralized(count: serverPlaylistsCount))
        default: break
        }

        // right side
        rightButtonLeaveEditMode()
    }

    /// Remove the no playlists overlay screen if it's showing
    private func removeNoPlaylistsScreen() {
        self.noPlaylistsScreen.removeFromSuperview()
    }

    /// Show and configure the no playlists overlay screen
    private func addNoPlaylistsScreen() {
        self.removeNoPlaylistsScreen()

        switch self.segmentedControl.selectedSegmentIndex {
        case 0:
            self.noPlaylistsScreenTitleLabel.text = "No Songs\nQueued"
            self.noPlaylistsScreenTitleLabel.frame = CGRect(x: 20, y: 0, width: 200, height: 100)
        case 1, 2:
            self.noPlaylistsScreenTitleLabel.text = "No Playlists\nFound"
            self.noPlaylistsScreenTitleLabel.frame = CGRectMake(20, 20, 200, 140)
        default: break
        }
        if self.segmentedControl.selectedSegmentIndex == 0 {
            self.noPlaylistsScreenSubtitleLabel.text = "Swipe left on any song, album, or artist to bring up the Queue button" // but actually I now tap
            self.noPlaylistsScreenSubtitleLabel.frame = CGRect(x: 20, y: 100, width: 200, height: 60)
            self.noPlaylistsScreenSubtitleLabel.isHidden = false
        } else {
            self.noPlaylistsScreenSubtitleLabel.isHidden = true
        }

        if !UIDevice.isPad() {
            if UIApplication.orientation().isLandscape {
                //noPlaylistsScreen.transform = CGAffineTransformScale(noPlaylistsScreen.transform, 0.75, 0.75);
                self.noPlaylistsScreen.transform = CGAffineTransformTranslate(self.noPlaylistsScreen.transform, 0.0, 23.0)
            }
        }

        self.view.addSubview(self.noPlaylistsScreen)
    }
}

// MARK: - Deletion of row(s) by swipe or Delete button

// There is some repetition as to what we do after the deletion is over, but I prefer to see that
// repetition spelled out here at the call site so that the strategy is explicit. We have to deal
// with the fact that the user may have swiped in normal mode or tapped the delete button in edit
// mode, and either way we must end up in normal mode in good order.
extension PlaylistsViewController {
    /// tab 1
    private func deleteCurrentPlaylistSongs(at rowIndexes: [Int]) {
        PlayQueue.shared().deleteSongs(rowIndexes)
        self.updateCurrentPlaylistCount()

        // [self.tableView deleteRowsAtIndexPaths:self.tableView.indexPathsForSelectedRows withRowAnimation:UITableViewRowAnimationRight];
        self.tableView.reloadData()

        if self.isEditing {
            self.changeEditMode(false, animated: true) { [unowned self] in
                self.performCurrentSegmentedControlAction()
            }
        } else {
            self.performCurrentSegmentedControlAction()
        }
    }

    /// tab 2
    private func deleteLocalPlaylists(at rowIndexes: [Int]) {
        // Sort the row indexes to make sure they're ascending; in a moment we'll reverse this order
        let sortedRowIndexes = rowIndexes.sorted()
        Database.shared().localPlaylistsDbQueue?.inDatabase { db in
            db.executeUpdate("DROP TABLE localPlaylistsTemp") // not sure about this
            db.executeUpdate("CREATE TABLE localPlaylistsTemp(playlist TEXT, md5 TEXT)")
            for index in sortedRowIndexes.reversed() {
                let rowId = index + 1
                if let md5 = db.string(forQuery: "SELECT md5 FROM localPlaylists WHERE ROWID = \(rowId)") {
                    db.executeUpdate("DROP TABLE playlist\(md5)")
                    db.executeUpdate("DELETE FROM localPlaylists WHERE md5 = ?", withArgumentsIn: [md5])
                }
            }
            db.executeUpdate("INSERT INTO localPlaylistsTemp SELECT * FROM localPlaylists")
            db.executeUpdate("DROP TABLE localPlaylists")
            db.executeUpdate("ALTER TABLE localPlaylistsTemp RENAME TO localPlaylists")
        }

        self.tableView.reloadData()

        if self.isEditing {
            self.changeEditMode(false, animated: true) { [unowned self] in
                self.performCurrentSegmentedControlAction()
            }
        } else {
            self.performCurrentSegmentedControlAction()
        }
    }

    /// tab 3
    private func deleteServerPlaylists(at rowIndexes: [Int]) {
        self.tableView.isScrollEnabled = false
        ViewObjects.shared().showAlbumLoadingScreen(self.view, sender: self)

        for index in rowIndexes {
            if let serverPlaylists = self.serverPlaylistsDataModel?.serverPlaylists as? [ServerPlaylist] {
                let playlistId = serverPlaylists[index].playlistId
                let request = NSMutableURLRequest(susAction: "deletePlaylist", parameters: ["id": playlistId]) as URLRequest
                let dataTask = self.ephemeralSession?.dataTask(with: request) { data, response, error in
                    if let error {
                        print(error)
                    }
                    Task { @MainActor in
                        ViewObjects.shared().hideLoadingScreen()
                        if self.isEditing {
                            self.changeEditMode(false, animated: true) { [unowned self] in
                                self.performCurrentSegmentedControlAction()
                            }
                        } else {
                            self.performCurrentSegmentedControlAction()
                        }
                    }
                }
                dataTask?.resume()
            }
        }
    }
}

// MARK: - Loader Delegate

/// We are the loading delegate only for the third "tab", which talks to the server to refresh
/// the list.
extension PlaylistsViewController: SUSLoaderDelegate {
    func loadingFailed(_ loader: SUSLoader!, withError error: Error!) {
        ViewObjects.shared().hideLoadingScreen()
    }

    func loadingFinished(_ loader: SUSLoader!) {
        self.tableView.reloadData()

        // If the list is empty, display the no playlists overlay screen
        if (self.serverPlaylistsDataModel?.serverPlaylists?.count ?? -1) == 0 && self.noPlaylistsScreen.window == nil {
            self.addNoPlaylistsScreen()
        } else {
            // Modify the header view to include the save and edit buttons
            self.addAndConfigureHeader()
        }

        // Hide the loading screen
        ViewObjects.shared().hideLoadingScreen()
    }
}

// MARK: - Table view

extension PlaylistsViewController: UITableViewDelegate, UITableViewDataSource {

    /// Utility for fetching info about a local playlist to use as a cell model in "tab" 1.
    fileprivate func localPlaylist(forIndex index: Int) -> ISMSLocalPlaylist? {
        guard let queue = Database.shared().localPlaylistsDbQueue else { return nil }
        if self.segmentedControl.selectedSegmentIndex == 1 {
            guard let name = queue.string(
                    forQuery: "SELECT playlist FROM localPlaylists WHERE ROWID = ?", arguments: [index + 1]
                  ),
                  let md5 = queue.string(
                    forQuery: "SELECT md5 FROM localPlaylists WHERE ROWID = ?", arguments: [index + 1]
                  ),
                  let count = queue.int(
                    forQuery: "SELECT COUNT(*) FROM playlist\(md5)"
                  ) else {
                return nil
            }
            return ISMSLocalPlaylist(name: name, md5: md5, count: UInt(count))
        }
        return nil
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch self.segmentedControl.selectedSegmentIndex {
        case 0:
            return self.currentPlaylistCount
        case 1:
            return Database.shared().localPlaylistsDbQueue?.int(forQuery: "SELECT COUNT(*) FROM localPlaylists") ?? 0
        case 2:
            return self.serverPlaylistsDataModel?.serverPlaylists?.count ?? 0
        default:
            return 0
        }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(
            withIdentifier: UniversalTableViewCell.reuseId, for: indexPath
        ) as? UniversalTableViewCell else {
            fatalError("no cell")
        }
        switch self.segmentedControl.selectedSegmentIndex {
        case 0:
            // Song
            cell.hideNumberLabel = false
            cell.hideCoverArt = true
            cell.hideDurationLabel = false
            cell.hideSecondaryLabel = false
            cell.number = indexPath.row + 1
            cell.update(model: PlayQueue.shared().song(for: UInt(indexPath.row)))
        case 1: // Local playlist
            cell.hideNumberLabel = true
            cell.hideCoverArt = false
            cell.hideDurationLabel = true
            cell.hideSecondaryLabel = false
            cell.update(model: self.localPlaylist(forIndex: indexPath.row))
        case 2: // Server playlist
            cell.hideNumberLabel = true
            cell.hideCoverArt = false
            cell.hideDurationLabel = true
            cell.hideSecondaryLabel = true
            cell.update(model: self.serverPlaylistsDataModel?.serverPlaylists?[indexPath.row])
        default: fatalError("There are no other segments")
        }
        return cell
    }

    // Interesting misuse of the idea of section indexes, as there are in fact no sections
    var numberOfSectionIndexes: Int {
        if self.segmentedControl.selectedSegmentIndex == 0 {
            if self.currentPlaylistCount > 200 {
                return 20
            } else if self.currentPlaylistCount > 20 {
                return self.currentPlaylistCount / 10
            }
        }
        return 0
    }

    func sectionIndexTitles(for tableView: UITableView) -> [String]? {
        if self.segmentedControl.selectedSegmentIndex == 0 && self.currentPlaylistCount >= 20 {
            if !self.isEditing {
                return Array(repeating: "●", count: self.numberOfSectionIndexes)
            }
        }
        return nil
    }

    func tableView(_ tableView: UITableView, sectionForSectionIndexTitle title: String, at index: Int) -> Int {
        if self.segmentedControl.selectedSegmentIndex == 0 {
            if index == 0 {
                tableView.scrollRectToVisible(CGRect(x: 0, y: 0, width: 320, height: 40), animated: false)
            } else if index == self.numberOfSectionIndexes - 1 {
                let row = self.currentPlaylistCount - 1
                tableView.scrollToRow(at: .init(row: row, section: 0), at: .top, animated: false)
            } else {
                let row = self.currentPlaylistCount / self.numberOfSectionIndexes * index
                tableView.scrollToRow(at: .init(row: row, section: 0), at: .top, animated: false)
                return -1
            }
        }
        return index - 1
    }

    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }

    func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        return .delete
    }

    func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to toIndexPath: IndexPath) {
        if self.segmentedControl.selectedSegmentIndex == 0 { // and otherwise we shouldn't even be here
            let fromRow = fromIndexPath.row + 1
            let toRow = toIndexPath.row + 1

            Database.shared().currentPlaylistDbQueue?.inDatabase { db in
                let currTable = Settings.shared().isJukeboxEnabled ? "jukeboxCurrentPlaylist" : "currentPlaylist"
                let shufTable = Settings.shared().isJukeboxEnabled ? "jukeboxShufflePlaylist" : "shufflePlaylist"
                let table = PlayQueue.shared().isShuffle ? shufTable : currTable

                db.executeUpdate("DROP TABLE moveTemp")
                let query = "CREATE TABLE moveTemp (\(Song.standardSongColumnSchema()))"
                db.executeUpdate(query)

                if fromRow < toRow {
                    db.executeUpdate(
                        "INSERT INTO moveTemp SELECT * FROM \(table) WHERE ROWID < ?", withArgumentsIn: [fromRow]
                    )
                    db.executeUpdate(
                        "INSERT INTO moveTemp SELECT * FROM \(table) WHERE ROWID > ? AND ROWID <= ?", withArgumentsIn: [fromRow, toRow]
                    )
                    db.executeUpdate(
                        "INSERT INTO moveTemp SELECT * FROM \(table) WHERE ROWID = ?", withArgumentsIn: [fromRow]
                    )
                    db.executeUpdate(
                        "INSERT INTO moveTemp SELECT * FROM \(table) WHERE ROWID > ?", withArgumentsIn: [toRow]
                    )

                    db.executeUpdate("DROP TABLE \(table)")
                    db.executeUpdate("ALTER TABLE moveTemp RENAME TO \(table)")
                } else {
                    db.executeUpdate(
                        "INSERT INTO moveTemp SELECT * FROM \(table) WHERE ROWID < ?", withArgumentsIn: [toRow]
                    )
                    db.executeUpdate(
                        "INSERT INTO moveTemp SELECT * FROM \(table) WHERE ROWID = ?", withArgumentsIn: [fromRow]
                    )
                    db.executeUpdate(
                        "INSERT INTO moveTemp SELECT * FROM \(table) WHERE ROWID >= ? AND ROWID < ?", withArgumentsIn: [toRow, fromRow]
                    )
                    db.executeUpdate(
                        "INSERT INTO moveTemp SELECT * FROM \(table) WHERE ROWID > ?", withArgumentsIn: [fromRow]
                    )

                    db.executeUpdate("DROP TABLE \(table)")
                    db.executeUpdate("ALTER TABLE moveTemp RENAME TO \(table)")
                }
            }
            if Settings.shared().isJukeboxEnabled {
                Jukebox.shared().replacePlaylistWithLocal()
            }

            // Correct the value of currentPlaylistPosition
            // Wow, this is a tricky situation!
            let currentIndex = PlayQueue.shared().currentIndex
            if fromIndexPath.row == currentIndex {
                PlayQueue.shared().currentIndex = toIndexPath.row
            } else {
                if fromIndexPath.row < currentIndex && toIndexPath.row >= currentIndex {
                    PlayQueue.shared().currentIndex = currentIndex - 1
                } else if fromIndexPath.row > currentIndex && toIndexPath.row <= currentIndex {
                    PlayQueue.shared().currentIndex = currentIndex + 1
                }
            }

            // Highlight the current playing song
            if PlayQueue.shared().currentIndex >= 0 && PlayQueue.shared().currentIndex < self.currentPlaylistCount {
                self.tableView.selectRow(at: .init(row: PlayQueue.shared().currentIndex, section: 0), animated: false, scrollPosition: .top)
            }

            if !Settings.shared().isJukeboxEnabled {
                NotificationCenter.default.post(name: .init(ISMSNotification_CurrentPlaylistOrderChanged), object: nil)
            }
        }
    }

    func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        switch self.segmentedControl.selectedSegmentIndex {
        case 0:
            return true
        case 1:
            return false // he would have liked to make this one YES some day
        default:
            return false
        }
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if self.isEditing {
            self.leftSideUpdateForEditingMode()
            return
        }

        switch self.segmentedControl.selectedSegmentIndex {
        case 0:
            if let playedSong = Music.shared().playSong(atPosition: indexPath.row) {
                if !playedSong.isVideo {
                    self.showPlayer()
                }
            }
        case 1:
            let playlistSongsViewController = PlaylistSongsViewController(
                nibName: "PlaylistSongsViewController", bundle: nil
            )
            playlistSongsViewController.md5 = Database.shared().localPlaylistsDbQueue?.string(
                forQuery: "SELECT md5 FROM localPlaylists WHERE ROWID = ?",
                arguments: [indexPath.row + 1]
            )
            self.pushCustom(playlistSongsViewController)
        case 2:
            let playlistSongsViewController = PlaylistSongsViewController(
                nibName: "PlaylistSongsViewController", bundle: nil
            )
            if let playlist = self.serverPlaylistsDataModel?.serverPlaylists?[indexPath.row] {
                playlistSongsViewController.md5 = playlist.playlistName.md5()
                playlistSongsViewController.serverPlaylist = playlist
                self.pushCustom(playlistSongsViewController)
            }
        default: break
        }
    }

    func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        if self.isEditing {
            self.leftSideUpdateForEditingMode()
        }
    }

    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        switch self.segmentedControl.selectedSegmentIndex {
        case 0: // Current Playlist
            if let song = PlayQueue.shared().song(for: UInt(indexPath.row)) {
                if !song.isVideo {
                    return SwipeAction.downloadAndDeleteConfig(model: song) { [weak self] in
                        self?.deleteCurrentPlaylistSongs(at: [indexPath.row])
                    }
                }
            }
        case 1: // Local Playlists
            if let model = self.localPlaylist(forIndex: indexPath.row) {
                return SwipeAction.downloadAndDeleteConfig(model: model) { [weak self] in
                    self?.deleteLocalPlaylists(at: [indexPath.row])
                }
            }
        case 2: // Server Playlists
            if let model = self.serverPlaylistsDataModel?.serverPlaylists?[indexPath.row] {
                return SwipeAction.downloadAndDeleteConfig(model: model) { [weak self] in
                    self?.deleteServerPlaylists(at: [indexPath.row])
                }
            }
        default: return nil
        }
        return nil
    }
}
