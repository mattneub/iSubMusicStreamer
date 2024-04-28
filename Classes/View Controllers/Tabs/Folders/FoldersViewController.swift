import UIKit

final class FoldersViewController: UITableViewController {

    private var isSearching = false
    private var searcher: UISearchController?
    private var isCountShowing = false
    private var headerView = UIView()
    private var countLabel = UILabel()
    private var reloadTimeLabel = UILabel()
    private var folders = [Int: String]()

    private lazy var dataModel: SUSRootFoldersDAO = createModel()

    private func createModel() -> SUSRootFoldersDAO {
        let model = SUSRootFoldersDAO(delegate: self)!
        model.selectedFolderId = Settings.shared().rootFoldersSelectedFolderId
        return model
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.backgroundColor = UIColor(named: "isubBackgroundColor")

        self.title = "Folders"
        self.view.backgroundColor = UIColor(named: "isubBackgroundColor")

        NotificationCenter.default.addObserver(self, selector: #selector(serverSwitched), name: .init(ISMSNotification_ServerSwitched), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(updateFolders), name: .init(ISMSNotification_ServerCheckPassed), object: nil)

        tableView.refreshControl = UIRefreshControl(frame: .zero, primaryAction: .init { [weak self] _ in
            if let self, let id = Settings.shared().rootFoldersSelectedFolderId as? Int {
                self.loadData(id)
            } else {
                // well we need to load _something_! so I'm opting for the _last_ folder in the list
                // but my experience is that navidrome has just one music folder anyway
                guard let self else { return }
                if self.folders.count > 0 { // have we already fetched the music directory id?
                    let keys = self.folders.keys.sorted()
                    if let lastKey = keys.last {
                        loadData(lastKey)
                    }
                } else { // no we haven't; so do the whole thing now
                    // this is basically the same as `updateFolders` with an extra loadData
                    let loader = SUSMusicFoldersLoader { [weak self] success, error, loader in
                        guard let loader = loader as? SUSMusicFoldersLoader else { return }
                        guard let self else { return }
                        if success, let folders = loader.updatedfolders as? [Int: String] {
                            self.folders = folders
                            let keys = self.folders.keys.sorted()
                            if let lastKey = keys.last {
                                loadData(lastKey)
                            }
                        } else {
                            NSLog("[FoldersViewController] failed to update folders: %@", error?.localizedDescription ?? "")
                        }
                    }
                    loader.startLoad()
                }
            }
        })
        tableView.refreshControl?.tintColor = .systemBackground


        tableView.register(BlurredSectionHeader.self, forHeaderFooterViewReuseIdentifier: BlurredSectionHeader.reuseId)
        tableView.register(TrackTableViewCell.self, forCellReuseIdentifier: UniversalTableViewCell.reuseId)
        self.tableView.estimatedRowHeight = Defines.rowHeight
        self.tableView.rowHeight = UITableView.automaticDimension
        self.tableView.separatorColor = .label
        self.tableView.separatorInset = .zero
        self.tableView.sectionHeaderTopPadding = 0

        if let rootFolderId = Settings.shared().rootFoldersSelectedFolderId as? Int {
            self.dataModel.selectedFolderId = rootFolderId as NSNumber
        }
        if self.dataModel.isRootFolderIdCached {
            self.addCount()
            self.tableView.contentOffset.y = -self.tableView.adjustedContentInset.top
        }

        NotificationCenter.default.addObserver(self, selector: #selector(addURLRefBackButton), name: .init(UIApplication.didBecomeActiveNotification), object: nil)

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
        addURLRefBackButton()
        navigationItem.rightBarButtonItem = nil
        if Music.shared().showPlayerIcon {
            navigationItem.rightBarButtonItem = UIBarButtonItem(
                image: UIImage(systemName: Defines.musicNoteImageSystemName), style: .plain,
                target: self, action: #selector(nowPlayingAction)
            )
        }

        if !SUSAllSongsLoader.isLoading() && !ViewObjects.shared().isArtistsLoading {
            if !dataModel.isRootFolderIdCached, let id = Settings.shared().rootFoldersSelectedFolderId as? Int {
                loadData(id)
            } else {
                self.tableView.reloadData()
                self.updateCount()
            }
        }
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
        self.dataModel.delegate = nil
    }

    private func loadData(_ folderId: Int) {
        ViewObjects.shared().isArtistsLoading = true
        ViewObjects.shared().showAlbumLoadingScreen(AppDelegate.shared().window, sender: self)
        Settings.shared().rootFoldersSelectedFolderId = folderId as NSNumber
        self.dataModel.selectedFolderId = folderId as NSNumber
        self.dataModel.startLoad()
    }

    @objc private func serverSwitched() {
        self.dataModel = createModel()
        if !self.dataModel.isRootFolderIdCached {
            self.tableView.reloadData()
            self.removeCount()
        }
    }

    @objc private func updateFolders() {
        // this is nice, the "new" syntax lets you do the whole thing as a completion handler;
        // I could make it even nicer by using async/await
        let loader = SUSMusicFoldersLoader { success, error, loader in
            guard let loader = loader as? SUSMusicFoldersLoader else { return }
            if success, let folders = loader.updatedfolders as? [Int: String] {
                self.folders = folders
            } else {
                NSLog("[FoldersViewController] failed to update folders: %@", error?.localizedDescription ?? "")
            }
        }
        loader.startLoad()
    }

    @objc private func nowPlayingAction() {
        let player = PlayerViewController()
        player.hidesBottomBarWhenPushed = true
        navigationController?.pushViewController(player, animated: true)
    }

    @objc private func addURLRefBackButton() {
        let appDelegate = AppDelegate.shared()
        if appDelegate.referringAppUrl != nil && appDelegate.mainTabBarController.selectedIndex != 4 {
            self.navigationItem.leftBarButtonItem = UIBarButtonItem(
                title: "Back", style: .plain, target: appDelegate,
                action: #selector(AppDelegate.backToReferringApp)
            )
        }
    }
    @objc private func reloadAction() {
        if !SUSAllSongsLoader.isLoading(), let id = Settings.shared().rootFoldersSelectedFolderId as? Int {
            self.loadData(id)
        } else if Settings.shared().isPopupsEnabled {
            let message = "You cannot reload the Artists tab while the Albums or Songs tabs are loading"
            let alert = UIAlertController(title: "Please Wait", message: message, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .cancel))
            self.present(alert, animated: true)
        }
    }

    private func updateCount() {
        let folder = " Folder" + (dataModel.count > 1 ? "s" : "")
        countLabel.text = String(dataModel.count) + folder

        if let date = Settings.shared().rootFoldersReloadTime {
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            formatter.timeStyle = .short
            reloadTimeLabel.text = "last reload: \(formatter.string(from: date))"
        }
    }

    private func removeCount() {
        tableView.tableHeaderView = nil
        isCountShowing = false
    }

    private func addCount() {
        self.isCountShowing = true

        self.headerView = UIView(frame: CGRect(x: 0, y: 0, width: 320, height: 64))
        self.headerView.autoresizingMask = .flexibleWidth
        self.headerView.backgroundColor = self.view.backgroundColor

        self.countLabel = UILabel(frame: CGRect(x: 0, y: 10, width: 320, height: 30))
        self.countLabel.autoresizingMask = .flexibleWidth;
        self.countLabel.textColor = .label
        self.countLabel.textAlignment = .center
        self.countLabel.font = .boldSystemFont(ofSize: 32)
        self.headerView.addSubview(self.countLabel)

        self.reloadTimeLabel = UILabel(frame: CGRect(x: 0, y: 40, width: 320, height: 14))
        self.reloadTimeLabel.autoresizingMask = .flexibleWidth
        self.reloadTimeLabel.textColor = .label
        self.reloadTimeLabel.textAlignment = .center
        self.reloadTimeLabel.font = .systemFont(ofSize: 11)
        self.headerView.addSubview(self.reloadTimeLabel)

        self.updateCount()

        // Special handling for voice over users
        if UIAccessibility.isVoiceOverRunning {
            // Add a refresh button
            let voiceOverRefresh = UIButton(type: .custom)
            voiceOverRefresh.frame = CGRect(x: 0, y: 0, width: 50, height: 50)
            voiceOverRefresh.addTarget(self, action: #selector(reloadAction), for: .touchUpInside)
            voiceOverRefresh.accessibilityLabel = "Reload Folders"
            self.headerView.addSubview(voiceOverRefresh)

            // Resize the two labels at the top so the refresh button can be pressed
            self.countLabel.frame = CGRect(x: 50, y: 5, width: 220, height: 30)
            self.reloadTimeLabel.frame = CGRect(x: 50, y: 36, width: 220, height: 12)
        }

        self.tableView.tableHeaderView = self.headerView
    }

    @objc func cancelLoad() { // called by the ViewObjects cancel button
        dataModel.cancelLoad()
        ViewObjects.shared().hideLoadingScreen()
        tableView.refreshControl?.endRefreshing()
    }

}

extension FoldersViewController: SUSLoaderDelegate {
    func loadingFailed(_ loader: SUSLoader!, withError error: Error!) {
        ViewObjects.shared().isArtistsLoading = false

        // Hide the loading screen
        ViewObjects.shared().hideLoadingScreen()

        self.tableView.refreshControl?.endRefreshing()

        // Inform the user that the connection failed.
        // NOTE: Must call after a delay or the refresh control won't hide
        Task { @MainActor in
            try await Task.sleep(nanoseconds: 300_000_000)
            let alert = UIAlertController(title: "Subsonic Error", message: error.localizedDescription, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
            self.present(alert, animated: true)
        }
    }
    
    func loadingFinished(_ loader: SUSLoader!) {
        if self.isCountShowing {
            self.updateCount()
        } else {
            self.addCount()
        }
        self.tableView.reloadData()
        ViewObjects.shared().isArtistsLoading = false
        // Hide the loading screen
        ViewObjects.shared().hideLoadingScreen()
        // stop refreshing
        self.tableView.refreshControl?.endRefreshing()
        // nice position
        let top = -self.tableView.adjustedContentInset.top
        self.tableView.setContentOffset(CGPoint(x: 0, y: top), animated: true)
    }
}

extension FoldersViewController /* UITableViewDataSource, UITableViewDelegate */ {
    // Purely for these methods, to decide which version of the table to display.
    private var showingSearch: Bool {
        self.isSearching && (searcher?.searchBar.text?.count ?? 0) > 0
    }

    override func numberOfSections(in tableView: UITableView) -> Int {
        guard !showingSearch else {
            return 1
        }
        return self.dataModel.indexNames.count
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard !showingSearch else {
            return Int(self.dataModel.searchCount)
        }
        if let counts = self.dataModel.indexCounts as? [Int], counts.count > section {
            return counts[section]
        }
        return 0
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(
            withIdentifier: UniversalTableViewCell.reuseId, for: indexPath
        ) as? UniversalTableViewCell else { fatalError("no cell") }
        cell.hideNumberLabel = true
        cell.hideCoverArt = true
        cell.hideSecondaryLabel = true
        cell.hideDurationLabel = true
        cell.update(withModel: self.artist(atIndexPath: indexPath))
        return cell
    }
    
    func artist(atIndexPath indexPath: IndexPath) -> Artist? {
        guard !showingSearch else {
            return self.dataModel.artistForPosition(inSearch: UInt(indexPath.row) + 1)
        }
        if let indexPositions = self.dataModel.indexPositions as? [Int] {
            if indexPositions.count > indexPath.section {
                let sectionStartIndex = indexPositions[indexPath.section]
                return self.dataModel.artist(forPosition: UInt(sectionStartIndex + indexPath.row))
            }
        }
        return nil
    }

    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard !showingSearch else {
            return nil
        }
        guard self.dataModel.indexNames.count > 0 else {
            return nil
        }

        let sectionHeader = tableView.dequeueReusableHeaderFooterView(
            withIdentifier: BlurredSectionHeader.reuseId
        ) as? BlurredSectionHeader
        sectionHeader?.text = self.dataModel.indexNames[section] as? String
        return sectionHeader
    }

    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        guard !showingSearch else {
            return 0
        }
        guard self.dataModel.indexNames.count > 0 else {
            return 0
        }

        return Defines.rowHeight - 5
    }

    override func sectionIndexTitles(for tableView: UITableView) -> [String]? {
        guard !showingSearch else {
            return nil
        }
        guard let names = self.dataModel.indexNames as? [String] else {
            return nil
        }
        // return ["{search}"] + names
        return names.map { $0 == "[Unknown]" ? "[?]" : $0 }
    }

    override func tableView(_ tableView: UITableView, sectionForSectionIndexTitle title: String, at index: Int) -> Int {
        guard !showingSearch else {
            return -1
        }
        return index
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        pushCustom(AlbumViewController(withArtist: artist(atIndexPath: indexPath), orAlbum: nil))
    }

    override func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        if let model = artist(atIndexPath: indexPath) {
            return SwipeAction.downloadAndQueueConfig(model: model)
        }
        return nil
    }
}

extension FoldersViewController: UISearchResultsUpdating, UISearchControllerDelegate {
    func updateSearchResults(for searchController: UISearchController) {
        if let update = searchController.searchBar.text, !update.isEmpty {
            self.dataModel.search(forFolderName: update)
        } else {
            self.dataModel.clearSearchTable()
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
        let top = self.tableView.adjustedContentInset.top
        self.tableView.setContentOffset(CGPoint(x: 0, y: -top), animated: true)
    }
}
