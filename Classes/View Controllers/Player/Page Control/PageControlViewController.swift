import UIKit

final class PageControlViewController: UIPageViewController {
    private var coverArtViewController: CoverArtViewController?
    var coverArtId: String? {
        get { return coverArtViewController?.coverArtId }
        set { coverArtViewController?.coverArtId = newValue }
    }
    var coverArtImage: UIImage? {
        get { return coverArtViewController?.image }
        set { coverArtViewController?.image = newValue }
    }

    convenience init() {
        self.init(transitionStyle: .scroll, navigationOrientation: .horizontal)
        coverArtViewController = CoverArtViewController()
        setViewControllers([coverArtViewController!], direction: .forward, animated: false)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.dataSource = self
    }
    /*
        pageControl.numberOfPages = numberOfPages
        pageControl.currentPage = 0
        pageControl.addTarget(self, action: #selector(changePage), for: .valueChanged)
        view.addSubview(pageControl)
        pageControl.snp.makeConstraints { make in
            make.height.equalTo(20)
            make.top.equalTo(scrollView.snp.bottom)
            make.centerX.equalToSuperview()
        }
        
        var prevController: UIViewController? = nil
        for index in 0..<numberOfPages {
            var controller: UIViewController? = nil
            switch index {
            case 0:
                coverArtViewController = CoverArtViewController()
                controller = coverArtViewController
            case 1:
                controller = LyricsViewController()
            case 2:
                controller = SongInfoViewController()
            case 3:
                controller = CacheStatusViewController()
            default: break
            }
            
            if let controller = controller {
                viewControllers.append(controller)
    
                addChild(controller)
                scrollView.addSubview(controller.view)
                controller.didMove(toParent: self)
                controller.view.snp.makeConstraints { make in
                    make.width.height.equalTo(view.snp.width)
                    if let prevController = prevController {
                        make.leading.equalTo(prevController.view.snp.trailing)
                    } else {
                        make.leading.equalToSuperview()
                    }
                    if index == numberOfPages - 1 {
                        make.trailing.equalToSuperview()
                    }
                }
                prevController = controller
            }
        }
    }
    */
}

extension PageControlViewController: UIPageViewControllerDataSource {
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
        return switch viewController {
        case is CoverArtViewController: LyricsViewController()
        case is LyricsViewController: SongInfoViewController()
        case is SongInfoViewController: CacheStatusViewController()
        default: nil
        }
    }

    func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
        return switch viewController {
        case is LyricsViewController: coverArtViewController
        case is SongInfoViewController: LyricsViewController()
        case is CacheStatusViewController: SongInfoViewController()
        default: nil
        }
    }

    func presentationCount(for pageViewController: UIPageViewController) -> Int {
        return 4
    }

    func presentationIndex(for pageViewController: UIPageViewController) -> Int {
        return switch pageViewController.viewControllers?.first ?? UIViewController() {
        case is CoverArtViewController: 0
        case is LyricsViewController: 1
        case is SongInfoViewController: 2
        case is CacheStatusViewController: 3
        default: 0
        }
    }
}
