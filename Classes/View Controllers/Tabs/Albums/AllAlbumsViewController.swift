import UIKit

final class AllAlbumsViewController: UIViewController {
    private lazy var tableView = UITableView()

    private var dataModel: SUSAllAlbumsDAO?
    private var allSongsDataModel: SUSAllSongsDAO?

    private lazy var headerView: UIView = {
        let headerView = UIView(frame: CGRect(x: 0, y: 0, width: 320, height: 60))
        headerView.autoresizingMask = .flexibleWidth
        headerView.addSubview(countLabel)
        headerView.addSubview(reloadTimeLabel)
        return headerView
    }()

    private lazy var countLabel: UILabel = {
        let countLabel = UILabel(frame: CGRect(x: 0, y: 9, width: 320, height: 30))
        countLabel.autoresizingMask = .flexibleWidth
        countLabel.textColor = .label
        countLabel.textAlignment = .center
        countLabel.font = .boldSystemFont(ofSize: 32)
        return countLabel
    }()

    private lazy var reloadTimeLabel: UILabel = {
        let reloadTimeLabel = UILabel(frame: CGRect(x: 0, y: 40, width: 320, height: 12))
        reloadTimeLabel.autoresizingMask = .flexibleWidth
        reloadTimeLabel.textColor = .secondaryLabel
        reloadTimeLabel.textAlignment = .center
        reloadTimeLabel.font = .systemFont(ofSize: 11)
        return reloadTimeLabel
    }()

    private var searcher: UISearchController?

    private var loadingScreen: LoadingScreen?

    private var isSearching = false

    private var isProcessingArtists = false

    override func viewDidLoad() {
        super.viewDidLoad()
        self.tableView.translatesAutoresizingMaskIntoConstraints = false
        self.view.addSubview(tableView)
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
        ])
        tableView.delegate = self
        tableView.dataSource = self

        createDataModel()

        NotificationCenter.default.addObserver(self, selector: #selector(createDataModel), name: .init(ISMSNotification_ServerSwitched), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(loadingFinishedNotification), name: .init(ISMSNotification_AllSongsLoadingFinished), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(addURLRefBackButton), name: .init(UIApplication.didBecomeActiveNotification), object: nil)

        tableView.refreshControl = UIRefreshControl(frame: .zero, primaryAction: .init { [weak self] _ in
            self?.reloadAction()
        })

        tableView.rowHeight = Defines.rowHeight
        tableView.register(BlurredSectionHeader.self, forHeaderFooterViewReuseIdentifier: BlurredSectionHeader.reuseId)
        tableView.register(UniversalTableViewCell.self, forCellReuseIdentifier: UniversalTableViewCell.reuseId)

        let searcher = UISearchController(searchResultsController: nil)
        self.searcher = searcher
        searcher.hidesNavigationBarDuringPresentation = false
        searcher.obscuresBackgroundDuringPresentation = false
        searcher.searchResultsUpdater = self
        searcher.delegate = self
        navigationItem.searchController = searcher
        searcher.searchBar.searchTextField.backgroundColor = .systemBackground
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        defer {
            tableView.reloadData()
        }

        guard !SUSAllSongsLoader.isLoading() else {
            self.showLoadingScreen()
            return
        }

        addURLRefBackButton()

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

        if let dataModel, dataModel.isDataLoaded {
            addCount()
            return
        }

        self.tableView.tableHeaderView = nil

        // TODO: he really is using a string here, but that surely won't stand eventually
        if let urlString = Settings.shared().urlString,
           let loading = UserDefaults.standard.string(forKey: "\(urlString)isAllSongsLoading"),
           loading == "YES" {
            let message = """
                If you've reloaded the albums tab since this load started, you should choose 'Restart Load'.

                IMPORTANT: Make sure to plug in your device to keep the app active if you have a large collection.
                """
            let alert = UIAlertController(title: "Resume Load?", message: message, preferredStyle: .alert)
            alert.addAction(.init(title: "Restart Load", style: .destructive) { [weak self] _ in
                guard let self else { return }
                self.showLoadingScreen()
                self.allSongsDataModel?.restartLoad()
                self.tableView.tableHeaderView = nil
                self.tableView.reloadData()
                self.tableView.refreshControl?.endRefreshing()
            })

            alert.addAction(.init(title: "Resume Load", style: .destructive) { [weak self] _ in
                guard let self else { return }
                self.showLoadingScreen()
                self.allSongsDataModel?.startLoad()
                self.tableView.tableHeaderView = nil
                self.tableView.reloadData()
                self.tableView.refreshControl?.endRefreshing()
            })
            alert.addAction(.init(title: "Cancel", style: .cancel, handler: nil))
            Task { @MainActor in
                try await Task.sleep(nanoseconds: 200_000_000)
                self.present(alert, animated: true)
            }
        } else {
            let message = """
            This could take a while if you have a big collection.

            IMPORTANT: Make sure to plug in your device to keep the app active if you have a large collection.

            Note: If you've added new artists, you should reload the Folders first.
            """
            let alert = UIAlertController(title: "Load?", message: message, preferredStyle: .alert)
            alert.addAction(.init(title: "OK", style: .destructive) { [weak self] _ in
                guard let self else { return }
                self.showLoadingScreen()
                self.allSongsDataModel?.restartLoad()
                self.tableView.tableHeaderView = nil
                self.tableView.reloadData()
                self.tableView.refreshControl?.endRefreshing()
            })
            alert.addAction(.init(title: "Cancel", style: .cancel, handler: nil))
            Task { @MainActor in
                try await Task.sleep(nanoseconds: 200_000_000)
                self.present(alert, animated: true)
            }
        }
    }
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        hideLoadingScreen()
    }

    @objc private func createDataModel() {
        self.dataModel = SUSAllAlbumsDAO()
        self.allSongsDataModel?.delegate = nil
        self.allSongsDataModel = SUSAllSongsDAO(delegate: self)
    }

    private func addCount() {
        if let dataModel {
            countLabel.text = "\(dataModel.count) Albums"
        }
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        if let urlString = Settings.shared().urlString {
            if let when = UserDefaults.standard.string(forKey: "\(urlString)songsReloadTime") {
                self.reloadTimeLabel.text = "last reload: \(when)"
            } else {
                self.reloadTimeLabel.text = "last reload: ---"
            }
        }
        tableView.tableHeaderView = headerView
        tableView.reloadData()
    }

    @objc private func addURLRefBackButton() {
        if AppDelegate.shared().referringAppUrl != nil {
            if AppDelegate.shared().mainTabBarController.selectedIndex != 4 {
                self.navigationItem.leftBarButtonItem = UIBarButtonItem(
                    title: "Back", style: .plain,
                    target: AppDelegate.shared(),
                    action: #selector(AppDelegate.shared().backToReferringApp)
                )
            }
        }
    }

    private func reloadAction() {
        if !SUSAllSongsLoader.isLoading() {
            let message = """
            This could take a while if you have a big collection.

            IMPORTANT: Make sure to plug in your device to keep the app active if you have a large collection.

            Note: If you've added new artists, you should reload the Folders tab first.
            """
            let alert = UIAlertController(title: "Reload?", message: message, preferredStyle: .alert)
            alert.addAction(.init(title: "OK", style: .destructive) { [weak self] _ in
                guard let self else { return }
                self.showLoadingScreen()

                self.allSongsDataModel?.restartLoad() // this is the weird part;
                // he doesn't ask for the albums! he may be unaware that you can now ask for
                // http://your-server/rest/getAlbumList with type "alphabeticalByName"
                // Take a look at SUSQuickAlbumsLoader to see how to ask for `getAlbumList`
                // Eventually I want to work out how to load this way
                self.tableView.tableHeaderView = nil
                self.tableView.reloadData()

                self.tableView.refreshControl?.endRefreshing()
            })
            alert.addAction(.init(title: "Cancel", style: .cancel) { [weak self] _ in
                self?.tableView.refreshControl?.endRefreshing()
            })
            self.present(alert, animated: true)
        } else {
            if Settings.shared().isPopupsEnabled {
                let message = "You cannot reload the Albums tab while the Folders or Songs tabs are loading."
                let alert = UIAlertController(title: "Please Wait", message: message, preferredStyle: .alert)
                alert.addAction(.init(title: "OK", style: .cancel, handler: nil))
                self.present(alert, animated: true)
            }
            self.tableView.refreshControl?.endRefreshing()
        }
    }

    private func registerForLoadingNotifications() {
        NotificationCenter.default.addObserver(self, selector: #selector(updateLoadingScreen), name: .init(ISMSNotification_AllSongsLoadingArtists), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(updateLoadingScreen), name: .init(ISMSNotification_AllSongsLoadingAlbums), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(updateLoadingScreen), name: .init(ISMSNotification_AllSongsArtistName), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(updateLoadingScreen), name: .init(ISMSNotification_AllSongsAlbumName), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(updateLoadingScreen), name: .init(ISMSNotification_AllSongsSongName), object: nil)
    }

    private func unregisterForLoadingNotifications() {
        NotificationCenter.default.removeObserver(self, name: .init(ISMSNotification_AllSongsLoadingArtists), object: nil)
        NotificationCenter.default.removeObserver(self, name: .init(ISMSNotification_AllSongsLoadingAlbums), object: nil)
        NotificationCenter.default.removeObserver(self, name: .init(ISMSNotification_AllSongsArtistName), object: nil)
        NotificationCenter.default.removeObserver(self, name: .init(ISMSNotification_AllSongsAlbumName), object: nil)
        NotificationCenter.default.removeObserver(self, name: .init(ISMSNotification_AllSongsSongName), object: nil)
    }

    private func showLoadingScreen() {
        let message = ["Processing Artist:", "", "Processing Album:", ""]
        self.loadingScreen = LoadingScreen(on: self.view, withMessage: message, blockInput: true, mainWindow: false)
        self.tableView.isScrollEnabled = false
        self.tableView.allowsSelection = false
        self.navigationItem.leftBarButtonItem = nil
        self.navigationItem.rightBarButtonItem = nil

        self.registerForLoadingNotifications()
    }

    private func hideLoadingScreen() {
        self.unregisterForLoadingNotifications()

        self.tableView.isScrollEnabled = true
        self.tableView.allowsSelection = true

        // Hide the loading screen
        self.loadingScreen?.hide()
        self.loadingScreen = nil
    }

    @objc private func updateLoadingScreen(_ notification: Notification) {
        let name = notification.object as? String ?? ""

        switch notification.name.rawValue {
        case ISMSNotification_AllSongsLoadingArtists:
            self.isProcessingArtists = true
            self.loadingScreen?.loadingTitle1.text = "Processing Artist:"
            self.loadingScreen?.loadingTitle2.text = "Processing Album:"
        case ISMSNotification_AllSongsLoadingAlbums:
            self.isProcessingArtists = false
            self.loadingScreen?.loadingTitle1.text = "Processing Album:"
            self.loadingScreen?.loadingTitle2.text = "Processing Song:"
        case ISMSNotification_AllSongsSorting:
            self.loadingScreen?.loadingTitle1.text = "Sorting"
            self.loadingScreen?.loadingTitle2.text = ""
            self.loadingScreen?.loadingMessage1.text = name
            self.loadingScreen?.loadingMessage2.text = ""
        case ISMSNotification_AllSongsArtistName:
            self.isProcessingArtists = true
            self.loadingScreen?.loadingTitle1.text = "Processing Artist:"
            self.loadingScreen?.loadingTitle2.text = "Processing Album:"
            self.loadingScreen?.loadingMessage1.text = name
        case ISMSNotification_AllSongsAlbumName:
            if self.isProcessingArtists {
                self.loadingScreen?.loadingMessage2.text = name
            } else {
                self.loadingScreen?.loadingMessage1.text = name
            }
        case ISMSNotification_AllSongsSongName:
            self.isProcessingArtists = false
            self.loadingScreen?.loadingTitle1.text = "Processing Album:"
            self.loadingScreen?.loadingTitle2.text = "Processing Song:"
            self.loadingScreen?.loadingMessage2.text = name
        default: break
        }
    }

    @objc private func loadingFinishedNotification() {
        self.tableView.reloadData()
        self.createDataModel()
        self.addCount()
        self.hideLoadingScreen()
    }
}

extension AllAlbumsViewController: SUSLoaderDelegate {
    func loadingFailed(_ loader: SUSLoader!, withError error: Error!) {
        self.tableView.reloadData()
        self.createDataModel()
        self.hideLoadingScreen()
    }

    func loadingFinished(_ loader: SUSLoader!) {
        // Don't do anything, handled by the notification
    }
}

extension AllAlbumsViewController: UITableViewDataSource, UITableViewDelegate {

    // Purely for these methods, to decide which version of the table to display.
    private var showingSearch: Bool {
        self.isSearching && (searcher?.searchBar.text?.count ?? 0) > 0
    }

    func numberOfSections(in tableView: UITableView) -> Int {
        if showingSearch {
            return 1
        } else {
            return Int(self.dataModel?.index()?.count ?? 0)
        }
    }

    private func album(at indexPath: IndexPath) -> Album? {
        if showingSearch {
            return self.dataModel?.albumForPosition(inSearch: UInt(indexPath.row + 1))
        } else {
            if let index = self.dataModel?.index() as? [Index] {
                let position = index[indexPath.section].position
                let sectionStartIndex = Int(position)
                return self.dataModel?.album(forPosition: UInt(sectionStartIndex + indexPath.row + 1))
            } else {
                return nil
            }
        }
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if showingSearch {
            return 0
        }
        if self.dataModel?.index()?.count == 0 {
            return 0
        }
        return Defines.rowHeight - 5
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if showingSearch {
            return Int(self.dataModel?.searchCount ?? 0)
        } else {
            return Int((self.dataModel?.index() as? [Index])?[section].count ?? 0)
        }
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        if showingSearch {
            return nil
        }
        if self.dataModel?.index()?.count == 0 {
            return nil
        }

        let sectionHeader = tableView.dequeueReusableHeaderFooterView(withIdentifier: BlurredSectionHeader.reuseId) as? BlurredSectionHeader
        let index = self.dataModel?.index() as? [Index]
        sectionHeader?.text = index?[section].name
        return sectionHeader
    }

    func sectionIndexTitles(for tableView: UITableView) -> [String]? {
        if showingSearch {
            return nil
        } else {
            guard let names = (self.dataModel?.index() as? [Index])?.map({ $0.name ?? "" }) else { return nil }
            return ["{search}"] + names
        }
    }

    func tableView(_ tableView: UITableView, sectionForSectionIndexTitle title: String, at index: Int) -> Int {
        if showingSearch { return -1 }

        if index == 0 { // oh, yeah, this again, yecch
            tableView.scrollRectToVisible(CGRect(x: 0, y: 50, width: 320, height: 40), animated: true)
            return -1
        }

        return index - 1
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: UniversalTableViewCell.reuseId) as? UniversalTableViewCell else {
            fatalError("no cell")
        }
        cell.hideNumberLabel = true
        cell.hideDurationLabel = true
        cell.update(withModel: self.album(at: indexPath))
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.pushCustom(AlbumViewController(withArtist: nil, orAlbum: album(at: indexPath)))
    }

    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        if let album = album(at: indexPath) {
            return SwipeAction.downloadAndQueueConfig(model: album)
        } else {
            return nil
        }
    }

}

extension AllAlbumsViewController: UISearchResultsUpdating, UISearchControllerDelegate {
    func updateSearchResults(for searchController: UISearchController) {
        if let update = searchController.searchBar.text, !update.isEmpty {
            self.dataModel?.search(forAlbumName: update)
        } else {
            Database.shared().allAlbumsDbQueue?.inDatabase { db in
                db.executeUpdate("DROP TABLE allAlbumsSearch")
            }
        }
        self.tableView.reloadData()
    }

    func willPresentSearchController(_ searchController: UISearchController) {
        self.isSearching = true
        self.tableView.reloadData()
    }

    func willDismissSearchController(_ searchController: UISearchController) {
        self.isSearching = false
        self.tableView.reloadData()
    }

    func didDismissSearchController(_ searchController: UISearchController) {
        self.tableView.setContentOffset(.zero, animated: true)
    }
}
