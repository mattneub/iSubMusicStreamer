final class HomeAlbumViewController: UITableViewController {
    private var isMoreAlbums: Bool = true

    private var isLoading: Bool = false

    var loader: SUSQuickAlbumsLoader?

    var listOfAlbums = Array<Album>()

    var modifier: String = ""

    private var offset: UInt = 0

    override func viewDidLoad() {
        super.viewDidLoad()

        if Music.shared().showPlayerIcon {
            let image = UIImage(systemName: Defines.musicNoteImageSystemName)
            navigationItem.rightBarButtonItem = .init(image: image, style: .plain, target: self, action: #selector(nowPlayingAction))
        } else {
            navigationItem.rightBarButtonItem = nil
        }

        self.tableView.rowHeight = Defines.rowHeight
        self.tableView.register(UniversalTableViewCell.self, forCellReuseIdentifier: UniversalTableViewCell.reuseId)
        self.tableView.register(UITableViewCell.self, forCellReuseIdentifier: "HomeAlbumLoadCell")
    }

    @objc private func nowPlayingAction() {
        let playerViewController = PlayerViewController()
        playerViewController.hidesBottomBarWhenPushed = true
        self.navigationController?.pushViewController(playerViewController, animated: true)
    }

    // TODO: the entire paginated loading approach used here appears broken

    private func loadMoreResults() {
        if self.isLoading {
            return
        }

        self.isLoading = true
        self.offset += 20

        let loader = SUSQuickAlbumsLoader(delegate: self)
        loader.modifier = self.modifier
        loader.offset = self.offset
        loader.startLoad()
        self.loader = loader
    }
}

extension HomeAlbumViewController: SUSLoaderDelegate {
    func loadingFailed(_ loader: SUSLoader!, withError error: Error!) {
        self.loader = nil
        self.isLoading = false

        if Settings.shared().isPopupsEnabled {
            let message = "There was an error performing the search.\n\nError: \(error.localizedDescription)"
            let alert = UIAlertController(title: "Error",  message: message, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
            self.present(alert, animated: true)
        }
    }

    func loadingFinished(_ loader: SUSLoader!) {
        if let loader = self.loader, let loaderList = loader.listOfAlbums as? [Album] {
            if loaderList.count == 0 || true {
                self.isMoreAlbums = false
            } else {
                self.listOfAlbums.append(contentsOf: loaderList)
            }
        }
        self.tableView.reloadData()
        self.isLoading = false
        self.loader = nil
    }
}

extension HomeAlbumViewController /* UITableViewDataSource, UITableViewDelegate */ {
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.listOfAlbums.count + 1
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.row < self.listOfAlbums.count {
            if let cell = tableView.dequeueReusableCell(
                withIdentifier: UniversalTableViewCell.reuseId, for: indexPath
            ) as? UniversalTableViewCell {
                cell.hideNumberLabel = true
                cell.hideCoverArt = false
                cell.hideDurationLabel = true
                cell.update(withModel: self.listOfAlbums[indexPath.row])
                return cell
            }
        } else {
            // last cell is a "loader" cell
            let cell = tableView.dequeueReusableCell(
                withIdentifier: "HomeAlbumLoadCell", for: indexPath
            )
            cell.backgroundColor = UIColor(named: "isubBackgroundColor")
            if self.isMoreAlbums {
                cell.textLabel?.text = "Loading more results..."
                let indicator = UIActivityIndicatorView(style: .medium)
                indicator.center = .init(x: 300, y: 30)
                cell.contentView.addSubview(indicator)
                indicator.startAnimating()
                self.loadMoreResults()
            } else {
                cell.textLabel?.text = "No more results"
                // TODO: this code is completely wrong, need to remove indicator etc.
            }
            return cell
        }
        fatalError("no cell")
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.row != self.listOfAlbums.count {
            let album = self.listOfAlbums[indexPath.row]
            let albumViewController = AlbumViewController(withArtist: nil, orAlbum: album)
            pushCustom(albumViewController)
        } else {
            tableView.deselectRow(at: indexPath, animated: false)
        }
    }

    override func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        if indexPath.row != self.listOfAlbums.count {
            return SwipeAction.downloadAndQueueConfig(model: self.listOfAlbums[indexPath.row])
        } else {
            return nil
        }
    }
}
