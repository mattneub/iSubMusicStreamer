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
        if #available(iOS 15.0, *) {
            controller.tabBar.scrollEdgeAppearance = appearance
        }
    }
}
