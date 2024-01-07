import UIKit

final class FoldersViewController: UIViewController {
    @IBOutlet var tableView: UITableView!

    private var isSearching = false

    private var isCountShowing = false

    private var headerView = UIView()

    private var searchBar = UISearchBar()

    private var searchOverlay: UIVisualEffectView?

    private var countLabel = UILabel()

    private var reloadTimeLabel = UILabel()

    private var dropdown = FolderDropdownControl()

    private lazy var dataModel: SUSRootFoldersDAO = createModel()

    private func createModel() -> SUSRootFoldersDAO {
        let model = SUSRootFoldersDAO(delegate: self)!
        model.selectedFolderId = Settings.shared().rootFoldersSelectedFolderId
        return model
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        self.title = "Folders"
        self.view.backgroundColor = UIColor(named: "isubBackgroundColor")

        NotificationCenter.default.addObserver(self, selector: #selector(serverSwitched), name: .init(ISMSNotification_ServerSwitched), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(updateFolders), name: .init(ISMSNotification_ServerCheckPassed), object: nil)

        tableView.refreshControl = RefreshControl { [weak self] in
            if let self, let id = Settings.shared().rootFoldersSelectedFolderId {
                self.loadData(id)
            }
        }

        tableView.register(BlurredSectionHeader.self, forHeaderFooterViewReuseIdentifier: BlurredSectionHeader.reuseId)
        tableView.register(UniversalTableViewCell.self, forCellReuseIdentifier: UniversalTableViewCell.reuseId)
        tableView.rowHeight = Defines.rowHeight

        if self.dataModel.isRootFolderIdCached {
            self.addCount()
            self.tableView.contentOffset = .zero
        }

        NotificationCenter.default.addObserver(self, selector: #selector(addURLRefBackButton), name: .init(UIApplication.didBecomeActiveNotification), object: nil)
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
            if !dataModel.isRootFolderIdCached, let id = Settings.shared().rootFoldersSelectedFolderId {
                loadData(id)
            }
        }
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
        self.dataModel.delegate = nil
        self.dropdown.delegate = nil
    }

    func loadData(_ folderId: NSNumber) {
        self.dropdown.updateFolders()
        ViewObjects.shared().isArtistsLoading = true
        ViewObjects.shared().showAlbumLoadingScreen(AppDelegate.shared().window, sender: self)
        self.dataModel.selectedFolderId = folderId
        self.dataModel.startLoad()
    }

    @objc func serverSwitched() {
        self.dataModel = createModel()
        if !self.dataModel.isRootFolderIdCached {
            self.tableView.reloadData()
            self.removeCount()
        }
        self.folderDropdownSelectFolder(-1)
    }

    @objc func updateFolders() {}
    @objc func nowPlayingAction() {
        let player = PlayerViewController()
        player.hidesBottomBarWhenPushed = true
        navigationController?.pushViewController(player, animated: true)
    }

    @objc func addURLRefBackButton() {
        let appDelegate = AppDelegate.shared()
        if appDelegate.referringAppUrl != nil && appDelegate.mainTabBarController.selectedIndex != 4 {
            self.navigationItem.leftBarButtonItem = UIBarButtonItem(
                title: "Back", style: .plain, target: appDelegate,
                action: #selector(AppDelegate.backToReferringApp)
            )
        }
    }
    @objc func reloadAction() {
        if !SUSAllSongsLoader.isLoading(), let id = Settings.shared().rootFoldersSelectedFolderId {
            self.loadData(id)
        } else if Settings.shared().isPopupsEnabled {
            let message = "You cannot reload the Artists tab while the Albums or Songs tabs are loading"
            let alert = UIAlertController(title: "Please Wait", message: message, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .cancel))
            self.present(alert, animated: true)
        }
    }

    func updateCount() {
        let folder = " Folder" + (dataModel.count > 1 ? "s" : "")
        countLabel.text = String(dataModel.count) + folder

        if let date = Settings.shared().rootFoldersReloadTime {
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            formatter.timeStyle = .short
            reloadTimeLabel.text = "last reload: \(formatter.string(from: date))"
        }
    }

    func removeCount() {
        tableView.tableHeaderView = nil
        isCountShowing = false
    }

    func addCount() {
        self.isCountShowing = true

        self.headerView = UIView(frame: CGRect(x: 0, y: 0, width: 320, height: 157))
        self.headerView.autoresizingMask = .flexibleWidth
        self.headerView.backgroundColor = self.view.backgroundColor

        self.countLabel = UILabel(frame: CGRect(x: 0, y: 9, width: 320, height: 30))
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

        self.dropdown = FolderDropdownControl(frame: CGRect(x: 50, y: 61, width: 220, height: 40))
        self.dropdown.delegate = self
        if let dropdownFolders = SUSRootFoldersDAO.folderDropdownFolders() {
            self.dropdown.folders = dropdownFolders
        } else {
            self.dropdown.folders = [-1: "All Folders"]
        }
        self.dropdown.selectFolder(withId: self.dataModel.selectedFolderId)
        self.headerView.addSubview(self.dropdown)

        self.searchBar = UISearchBar(frame: CGRect(x: 0, y: 111, width: 320, height: 40))
        self.searchBar.autoresizingMask = .flexibleWidth
        self.searchBar.searchBarStyle = .minimal
        self.searchBar.delegate = self
        self.searchBar.autocorrectionType = .no
        self.searchBar.placeholder = "Folder name"
        self.headerView.addSubview(self.searchBar)

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

    func cancelLoad() {
        dataModel.cancelLoad()
        ViewObjects.shared().hideLoadingScreen()
        tableView.refreshControl?.endRefreshing()
    }

}

extension FoldersViewController: FolderDropdownDelegate {
    func folderDropdownMoveViewsY(_ y: Float) {
        self.tableView.performBatchUpdates {
            self.tableView.tableHeaderView?.frame.size.height += CGFloat(y)
            self.searchBar.frame.origin.y += CGFloat(y)
            self.tableView.tableHeaderView = self.tableView.tableHeaderView

            let visibleSections = Set(self.tableView.indexPathsForVisibleRows?.map { $0.section } ?? [])
            for section in visibleSections {
                let sectionHeader = self.tableView.headerView(forSection: section)
                sectionHeader?.frame.origin.y += CGFloat(y)
            }
        }
    }

    func folderDropdownViewsFinishedMoving() {}

    func folderDropdownSelectFolder(_ folderId: NSNumber!) {
        // let folderId = folderId.intValue // well, that's aspirational
        self.dropdown.selectFolder(withId: folderId)

        // Save the default
        Settings.shared().rootFoldersSelectedFolderId = folderId

        // Reload the data
        self.dataModel.selectedFolderId = folderId
        self.isSearching = false
        if self.dataModel.isRootFolderIdCached {
            self.tableView.reloadData()
            self.updateCount()
        } else {
            self.loadData(folderId)
        }
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
        self.tableView.refreshControl?.endRefreshing()
    }
}

extension FoldersViewController: UISearchBarDelegate {
    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        guard !self.isSearching else { return }
        self.isSearching = true

        self.dataModel.clearSearchTable()
        self.dropdown.closeDropdownFast()
        self.tableView.setContentOffset(CGPoint(x: 0, y: 104), animated: true)

        if searchBar.text.isEmpty {
            self.createSearchOverlay()
        }

        // Add the done button.
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(searchBarSearchButtonClicked))
    }

    func searchBarTextDidEndEditing(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
    }

    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        if !searchText.isEmpty {
            self.hideSearchOverlay()
            self.dataModel.search(forFolderName: self.searchBar.text)
        } else {
            self.createSearchOverlay()
            self.dataModel.clearSearchTable()
            self.tableView.setContentOffset(CGPoint(x: 0, y: 104), animated: false)
        }
        self.tableView.reloadData()
    }

    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        self.updateCount()

        self.searchBar.text = ""
        self.searchBar.resignFirstResponder()
        self.hideSearchOverlay()
        self.isSearching = false

        self.navigationItem.leftBarButtonItem = nil
        self.dataModel.clearSearchTable()
        self.tableView.reloadData()
        self.tableView.setContentOffset(CGPoint(x: 0, y: 104), animated: true)
    }

    private func createSearchOverlay() {
        let effectStyle: UIBlurEffect.Style = self.traitCollection.userInterfaceStyle == .dark ? .systemUltraThinMaterialLight : .systemUltraThinMaterialDark
        let searchOverlay = UIVisualEffectView(effect: UIBlurEffect(style: effectStyle))
        searchOverlay.translatesAutoresizingMaskIntoConstraints = false

        let dismissButton = UIButton(type: .custom)
        dismissButton.translatesAutoresizingMaskIntoConstraints = false
        dismissButton.addTarget(self, action: #selector(searchBarSearchButtonClicked), for: .touchUpInside)
        searchOverlay.contentView.addSubview(dismissButton)

        self.view.addSubview(searchOverlay)

        NSLayoutConstraint.activate([
            searchOverlay.leadingAnchor.constraint(equalTo: self.view.leadingAnchor),
            searchOverlay.trailingAnchor.constraint(equalTo: self.view.trailingAnchor),
            searchOverlay.topAnchor.constraint(equalTo: self.view.topAnchor, constant:50),
            searchOverlay.bottomAnchor.constraint(equalTo: self.view.bottomAnchor),

            dismissButton.leadingAnchor.constraint(equalTo: searchOverlay.leadingAnchor),
            dismissButton.trailingAnchor.constraint(equalTo: searchOverlay.trailingAnchor),
            dismissButton.topAnchor.constraint(equalTo: searchOverlay.topAnchor),
            dismissButton.bottomAnchor.constraint(equalTo: searchOverlay.bottomAnchor),
        ])

        // Animate the search overlay on screen
        searchOverlay.alpha = 0.0
        UIView.animate(withDuration: 0.2, delay: 0, options: .curveEaseOut) {
            searchOverlay.alpha = 1
        }
        self.searchOverlay = searchOverlay
    }

    private func hideSearchOverlay() {
        if self.searchOverlay != nil {
            // Animate the search overlay off screen
            UIView.animate(withDuration: 0.2, delay: 0, options: .curveEaseOut) {
                self.searchOverlay?.alpha = 0
            } completion: { _ in
                self.searchOverlay?.removeFromSuperview()
                self.searchOverlay = nil
            }
        }
    }
}

extension FoldersViewController: UITableViewDataSource, UITableViewDelegate {
    var searchIsActive: Bool {
        self.isSearching && (self.dataModel.searchCount > 0 || !self.searchBar.text.isEmpty)
    }

    func numberOfSections(in tableView: UITableView) -> Int {
        guard !searchIsActive else {
            return 1
        }
        return self.dataModel.indexNames.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard !searchIsActive else {
            return Int(self.dataModel.searchCount)
        }
        if let counts = self.dataModel.indexCounts as? [Int], counts.count > section {
            return counts[section]
        }
        return 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(
            withIdentifier: UniversalTableViewCell.reuseId, for: indexPath
        ) as? UniversalTableViewCell else { fatalError("no cell") }
        cell.hideNumberLabel = true
        cell.hideCoverArt = true
        cell.hideSecondaryLabel = true
        cell.hideDurationLabel = true
        cell .update(model: self.artist(atIndexPath: indexPath))
        return cell
    }
    
    func artist(atIndexPath indexPath: IndexPath) -> Artist? {
        guard !searchIsActive else {
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

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard !searchIsActive else {
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

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        guard !searchIsActive else {
            return 0
        }
        guard self.dataModel.indexNames.count > 0 else {
            return 0
        }

        return Defines.rowHeight - 5
    }

    func sectionIndexTitles(for tableView: UITableView) -> [String]? {
        guard !searchIsActive else {
            return nil
        }
        guard let names = self.dataModel.indexNames as? [String] else {
            return nil
        }
        return ["{search}"] + names
    }

    func tableView(_ tableView: UITableView, sectionForSectionIndexTitle title: String, at index: Int) -> Int {
        guard !searchIsActive else {
            return -1
        }
        if index == 0 {
            if self.dropdown.folders == nil || self.dropdown.folders.count == 2 {
                self.tableView.setContentOffset(CGPoint(x: 0, y: 104), animated: false)
            } else {
                self.tableView.setContentOffset(CGPoint(x: 0, y: 54), animated: false)
            }
            return -1
        }
        return index - 1
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        pushCustom(AlbumViewController(artist: artist(atIndexPath: indexPath), orAlbum: nil))
    }

    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        if let model = artist(atIndexPath: indexPath) {
            return SwipeAction.downloadAndQueueConfig(model: model)
        }
        return nil
    }
}
