import UIKit

final class CustomUINavigationControllerHelper: NSObject {
    @objc func fixNavBar(_ controller: UINavigationController) {
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = .black
        appearance.titleTextAttributes = [
            .foregroundColor: UIColor.white
        ]
        controller.navigationBar.standardAppearance = appearance
        controller.navigationBar.compactAppearance = appearance
        controller.navigationBar.scrollEdgeAppearance = appearance
        controller.navigationBar.compactScrollEdgeAppearance = appearance

        let yellow = UIColor.systemYellow.resolvedColor(with: .init(userInterfaceStyle: .dark))
        controller.navigationBar.tintColor = yellow
    }
}
