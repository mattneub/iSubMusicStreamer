import UIKit

final class CustomUITabBarControllerHelper: NSObject {
    @objc func fixTabBar(_ controller: UITabBarController) {
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = .black
        let itemAppearance = UITabBarItemAppearance()
        itemAppearance.normal.iconColor = .white
        itemAppearance.normal.titleTextAttributes = [
            .foregroundColor: UIColor.white
        ]
        let yellow = UIColor.systemYellow.resolvedColor(with: .init(userInterfaceStyle: .dark))
        itemAppearance.selected.iconColor = yellow
        itemAppearance.selected.titleTextAttributes = [
            .foregroundColor: yellow
        ]
        appearance.inlineLayoutAppearance = itemAppearance
        appearance.stackedLayoutAppearance = itemAppearance
        appearance.compactInlineLayoutAppearance = itemAppearance
        controller.tabBar.standardAppearance = appearance
        controller.tabBar.scrollEdgeAppearance = appearance
    }

    @objc class func createMainTabBarController() -> CustomUITabBarController {
        let home = CustomUINavigationController(rootViewController: HomeViewController())
        home.tabBarItem = UITabBarItem(title: "Home", image: UIImage(named: "tabbaricon-home"), tag: 9)

        let folders = CustomUINavigationController(rootViewController: FoldersViewController())
        folders.tabBarItem = UITabBarItem(title: "Folders", image: UIImage(named: "tabbaricon-folders"), tag: 0)

        let playlists = CustomUINavigationController(rootViewController: PlaylistsViewController())
        playlists.tabBarItem = UITabBarItem(title: "Playlists", image: UIImage(named: "tabbaricon-playlists"), tag: 3)

        let cache = CustomUINavigationController(rootViewController: CacheViewController())
        cache.tabBarItem = UITabBarItem(title: "Cache", image: UIImage(named: "tabbaricon-cache"), tag: 7)

        let albums = CustomUINavigationController(rootViewController: AllAlbumsViewController())
        albums.tabBarItem = UITabBarItem(title: "Albums", image: UIImage(named: "tabbaricon-albums"), tag: 1)

        let songs = CustomUINavigationController(rootViewController: AllSongsViewController())
        songs.tabBarItem = UITabBarItem(title: "Songs", image: UIImage(named: "tabbaricon-songs"), tag: 2)

        let bookmarks = CustomUINavigationController(rootViewController: BookmarksViewController())
        bookmarks.tabBarItem = UITabBarItem(title: "Bookmarks", image: UIImage(named: "tabbaricon-bookmarks"), tag: 4)

        let playing = CustomUINavigationController(rootViewController: PlayingViewController())
        playing.tabBarItem = UITabBarItem(title: "Playing", image: UIImage(named: "tabbaricon-playing"), tag: 5)

        let genres = CustomUINavigationController(rootViewController: GenresViewController())
        genres.tabBarItem = UITabBarItem(title: "Genres", image: UIImage(named: "tabbaricon-genres"), tag: 6)

        let chat = CustomUINavigationController(rootViewController: ChatViewController())
        chat.tabBarItem = UITabBarItem(title: "Chat", image: UIImage(named: "tabbaricon-chat"), tag: 8)

        let tbc = CustomUITabBarController()
        tbc.setViewControllers([
            home,
            folders,
            playlists,
            cache,
            albums,
            songs,
            bookmarks,
            playing,
            genres,
            chat
        ], animated: false)
        return tbc
    }

    @objc class func createOfflineTabBarController() -> CustomUITabBarController {
        let folders = CustomUINavigationController(rootViewController: FoldersViewController())
        folders.tabBarItem = UITabBarItem(title: "Folders", image: UIImage(named: "tabbaricon-folders"), tag: 0)

        let genres = CustomUINavigationController(rootViewController: GenresViewController())
        genres.tabBarItem = UITabBarItem(title: "Genres", image: UIImage(named: "tabbaricon-genres"), tag: 0)

        let playlists = CustomUINavigationController(rootViewController: PlaylistsViewController())
        playlists.tabBarItem = UITabBarItem(title: "Playlists", image: UIImage(named: "tabbaricon-playlists"), tag: 0)

        let bookmarks = CustomUINavigationController(rootViewController: BookmarksViewController())
        bookmarks.tabBarItem = UITabBarItem(title: "Bookmarks", image: UIImage(named: "tabbaricon-bookmarks"), tag: 0)

        let tbc = CustomUITabBarController()
        tbc.setViewControllers([
            folders,
            genres,
            playlists,
            bookmarks,
        ], animated: false)
        return tbc
    }
}
