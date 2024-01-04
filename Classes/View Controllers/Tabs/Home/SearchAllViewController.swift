import UIKit

final class SearchAllViewController: UITableViewController {
    var listOfArtists = [Artist]()
    var listOfAlbums = [Album]()
    var listOfSongs = [Song]()

    enum Category: String {
        case artists = "Artists"
        case albums = "Albums"
        case songs = "Songs"
    }

    var query = ""

    private var cellNames = [Category]()

    override func viewDidLoad() {
        super.viewDidLoad()

        if !self.listOfArtists.isEmpty {
            cellNames.append(.artists)
        }
        if !self.listOfAlbums.isEmpty {
            cellNames.append(.albums)
        }
        if !self.listOfSongs.isEmpty {
            cellNames.append(.songs)
        }

        self.tableView.rowHeight = Defines.rowHeight
        self.tableView.register(UniversalTableViewCell.self, forCellReuseIdentifier:UniversalTableViewCell.reuseId)
    }
}

extension SearchAllViewController /* UITableViewDataSource, UITableViewDelegate */ {
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        cellNames.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(
            withIdentifier: UniversalTableViewCell.reuseId, for: indexPath
        ) as? UniversalTableViewCell else { fatalError("no cell") }
        cell.update(primaryText: cellNames[indexPath.row].rawValue, secondaryText: nil)
        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let searchView = SearchSongsViewController()
        let type = cellNames[indexPath.row]
        switch type {
        case .artists:
            searchView.listOfArtists = self.listOfArtists
            searchView.searchType = .artists
        case .albums:
            searchView.listOfAlbums = self.listOfAlbums
            searchView.searchType = .albums
        case .songs:
            searchView.listOfSongs = self.listOfSongs
            searchView.searchType = .songs
        }
        searchView.query = self.query
        pushCustom(searchView)
    }
}
