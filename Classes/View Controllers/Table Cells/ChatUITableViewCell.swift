import UIKit

final class ChatUITableViewCell: UITableViewCell {
    @objc let userNameLabel: UILabel

    @objc let messageLabel: UILabel

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        let userNameLabel = UILabel()
        userNameLabel.frame = .init(x: 0, y: 0, width: 320, height: 20)
        userNameLabel.autoresizingMask = .flexibleWidth
        userNameLabel.textAlignment = .center
        userNameLabel.backgroundColor = .systemGray
        userNameLabel.font = .boldSystemFont(ofSize: 10)
        userNameLabel.textColor = .white
        self.userNameLabel = userNameLabel

        let messageLabel = UILabel()
        messageLabel.frame = .init(x: 5, y: 20, width: 310, height: 55)
        messageLabel.autoresizingMask = .flexibleWidth
        messageLabel.textAlignment = .left
        messageLabel.textColor = .label
        messageLabel.font = .systemFont(ofSize: 20)
        messageLabel.lineBreakMode = .byWordWrapping
        messageLabel.numberOfLines = 0
        self.messageLabel = messageLabel

        super.init(style: style, reuseIdentifier: reuseIdentifier)

        self.contentView.addSubview(userNameLabel)
        self.contentView.addSubview(messageLabel)

        self.backgroundColor = UIColor(named: "isubBackgroundColor")
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        var expectedLabelSize: CGSize = (messageLabel.text ?? "").boundingRect(
            with: .init(width: 310, height: .max),
            options: .usesLineFragmentOrigin,
            attributes: [.font : messageLabel.font ?? .systemFont(ofSize: 20)],
            context: nil
        ).size
        expectedLabelSize.height = max(expectedLabelSize.height, 40)
        messageLabel.frame.size.height = expectedLabelSize.height
    }

}
