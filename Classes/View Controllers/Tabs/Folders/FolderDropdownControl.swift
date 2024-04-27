import UIKit

protocol FolderDropdownDelegate: AnyObject {

    func folderDropdownMoveViews(y: CGFloat)
    func folderDropdownViewsFinishedMoving()
    func folderDropdownSelect(folderId: Int)

}

final class FolderDropdownControl: UIView {
    private let HEIGHT: CGFloat = 40

    weak var delegate: FolderDropdownDelegate?

    private var selectedFolderId = -1
    var folders: [Int: String] = SUSRootFoldersDAO.folderDropdownFolders() as? [Int: String] ?? [-1: "All Folders"] {
        didSet {
            didSetFolders()
        }
    }
    private var labels = [UILabel]()
    private var isOpen = false
    private var borderColor = UIColor.systemGray
    private var textColor   = UIColor.label
    private var lightColor  = UIColor(named: "isubBackgroundColor")
    private var darkColor   = UIColor(named: "isubBackgroundColor")
    private lazy var selectedFolderLabel: UILabel = {
        let selectedFolderLabel = UILabel(frame: CGRect(x: 5, y: 0, width: self.frame.size.width - 10, height: HEIGHT))
        selectedFolderLabel.autoresizingMask = .flexibleWidth
        selectedFolderLabel.isUserInteractionEnabled = true
        selectedFolderLabel.backgroundColor = .clear
        selectedFolderLabel.textColor = textColor;
        selectedFolderLabel.textAlignment = .center
        selectedFolderLabel.font = .boldSystemFont(ofSize: 20)
        selectedFolderLabel.text = "All Folders"
        return selectedFolderLabel
    }()
    private lazy var arrowImage: CALayer = {
        let arrowImage = CALayer()
        arrowImage.frame = CGRect(x: 0, y: 0, width: 18, height: 18);
        arrowImage.contentsGravity = .resizeAspect
        arrowImage.contents = UIImage(named: "folder-dropdown-arrow")!.cgImage
        return arrowImage
    }()
    private lazy var dropdownButton: UIButton = {
        let dropdownButton = UIButton(frame: CGRect(x: 0, y: 0, width: 220, height: HEIGHT))
        dropdownButton.autoresizingMask = .flexibleWidth
        dropdownButton.addTarget(self, action: #selector(toggleDropdown), for: .touchUpInside)
        dropdownButton.accessibilityLabel = selectedFolderLabel.text
        dropdownButton.accessibilityHint = "Switches folders"
        return dropdownButton
    }()
    private var sizeIncrease: CGFloat = 0


    override init(frame: CGRect) {
        super.init(frame: frame)

        self.autoresizingMask = .flexibleWidth
        self.isUserInteractionEnabled = true
        self.backgroundColor = UIColor.systemGray5
        self.layer.borderColor = borderColor.cgColor
        self.layer.borderWidth = 2.0
        self.layer.cornerRadius = 8
        self.layer.masksToBounds = true

        self.addSubview(selectedFolderLabel)

        let arrowImageView = UIView(frame: CGRect(x: 193, y: 12, width: 18, height: 18))
        arrowImageView.autoresizingMask = .flexibleLeftMargin
        self.addSubview(arrowImageView)

        arrowImageView.layer.addSublayer(arrowImage)

        self.addSubview(dropdownButton)

        updateFolders()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func didSetFolders() {
        // Remove old labels
        for label in self.labels {
            label.removeFromSuperview()
        }
        self.labels.removeAll()

        self.sizeIncrease = CGFloat(folders.count) * HEIGHT

        var sortedValues = folders.filter { $0.key != -1 }.map {($0.key, $0.value)}

        // Sort by folder name
        sortedValues.sort(by: { $0.1.lowercased() < $1.1.lowercased() })

        // Add All Folders again
        sortedValues.insert((-1, "All Folders"), at: 0)

        // Process the names and create the labels/buttons
        for (ix, pair) in sortedValues.enumerated() {
            let folder = pair.1
            let tag = pair.0
            let labelFrame = CGRect(x: 0, y: CGFloat(ix + 1) * HEIGHT, width: self.frame.size.width, height: HEIGHT)
            let buttonFrame = CGRect(x: 0, y: 0, width: labelFrame.size.width, height: labelFrame.size.height)

            let folderLabel = UILabel(frame: labelFrame)
            folderLabel.autoresizingMask = .flexibleWidth
            folderLabel.isUserInteractionEnabled = true
            //folderLabel.alpha = 0.0;
            if ix % 2 == 0 {
                folderLabel.backgroundColor = self.lightColor
            } else {
                folderLabel.backgroundColor = self.darkColor
            }
            folderLabel.textColor = self.textColor
            folderLabel.textAlignment = .center
            folderLabel.font = .boldSystemFont(ofSize: 20)
            folderLabel.text = folder
            folderLabel.tag = tag
            folderLabel.isAccessibilityElement = false
            self.addSubview(folderLabel)
            self.labels.append(folderLabel)

            let folderButton = UIButton(type: .custom)
            folderButton.frame = buttonFrame
            folderButton.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            folderButton.accessibilityLabel = folderLabel.text
            folderButton.addTarget(self, action: #selector(selectFolderr), for: .touchUpInside)
            folderLabel.addSubview(folderButton)
            folderButton.isAccessibilityElement = self.isOpen
        }

        self.selectedFolderLabel.text = self.folders[self.selectedFolderId]

    }

    func updateFolders() {
        guard Settings.shared().urlString != nil else {
            return
        }
        let loader = SUSDropdownFolderLoader { success, error, loader in
            guard let loader = loader as? SUSDropdownFolderLoader else { return }
            if success, let folders = loader.updatedfolders as? [Int: String] {
                self.folders = folders
            } else {
                NSLog("[FolderDropdownControl] failed to update folders: %@", error?.localizedDescription ?? "")
            }
        }
        loader.startLoad()

        // Save the default
        SUSRootFoldersDAO.setFolderDropdownFolders(self.folders)
    }

    func selectFolder(withId folderId: Int) {
        // guard let folderId else { return }
        self.selectedFolderId = folderId
        self.selectedFolderLabel.text = self.folders[self.selectedFolderId]
        self.dropdownButton.accessibilityLabel = self.selectedFolderLabel.text
    }

//    func closeDropdown() {
//        if self.isOpen {
//            self.toggleDropdown()
//        }
//    }

    func closeDropdownFast() {
        if self.isOpen {
            self.isOpen.toggle()

            self.frame.size.height -= self.sizeIncrease
            self.delegate?.folderDropdownMoveViews(y: -self.sizeIncrease)

            self.arrowImage.transform = CATransform3DMakeRotation((.pi / 180.0) * 0.0, 0.0, 0.0, 1.0)

            self.delegate?.folderDropdownViewsFinishedMoving()
        }
    }

    @objc private func toggleDropdown() {
        if self.isOpen {
            // Close it
            UIView.animate(withDuration: 0.25) {
                self.frame.size.height -= self.sizeIncrease
                self.delegate?.folderDropdownMoveViews(y: -self.sizeIncrease)
            } completion: { _ in
                self.delegate?.folderDropdownViewsFinishedMoving()
            }
            CATransaction.begin()
            CATransaction.setAnimationDuration(0.25)
            self.arrowImage.transform = CATransform3DMakeRotation((.pi / 180.0) * 0.0, 0.0, 0.0, 1.0)
            CATransaction.commit()
        } else {
            // Open it
            UIView.animate(withDuration: 0.25) {
                self.frame.size.height += self.sizeIncrease
                self.delegate?.folderDropdownMoveViews(y: self.sizeIncrease)
            } completion: { _ in
                self.delegate?.folderDropdownViewsFinishedMoving()
            }

            CATransaction.begin()
            CATransaction.setAnimationDuration(0.25)
            self.arrowImage.transform = CATransform3DMakeRotation((.pi / 180.0) * -60.0, 0.0, 0.0, 1.0)
            CATransaction.commit()
        }

        self.isOpen.toggle()

        // Remove accessibility when not visible
        for label in self.labels {
            for subview in label.subviews where subview is UIButton {
                subview.isAccessibilityElement = self.isOpen
            }
        }

        UIAccessibility.post(notification: .layoutChanged, argument: nil)

    }

    @objc private func selectFolderr(_ button: UIButton) {
        guard let label = button.superview as? UILabel else { return }

        //DLog(@"Folder selected: %@ -- %i", label.text, label.tag);

        self.selectedFolderId = label.tag
        self.selectedFolderLabel.text = self.folders[self.selectedFolderId]
        self.dropdownButton.accessibilityLabel = self.selectedFolderLabel.text
        //[self toggleDropdown:nil];
        self.closeDropdownFast()

        // Call the delegate method
        self.delegate?.folderDropdownSelect(folderId: self.selectedFolderId)

    }
}
