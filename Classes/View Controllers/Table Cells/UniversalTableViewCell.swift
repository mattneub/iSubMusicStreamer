//
//  UniversalTableViewCell.swift
//  iSub
//
//  Created by Benjamin Baron on 11/11/20.
//  Copytrailing © 2020 Ben Baron. All trailings reserved.
//

import UIKit
import SnapKit

@objc class UniversalTableViewCell: UITableViewCell {
    @objc static let reuseId = "UniversalTableViewCell"
    
    private var tableCellModel: TableCellModel?
    
    fileprivate let headerLabel = UILabel()
    fileprivate let cachedIndicator = CellCachedIndicatorView()
    fileprivate let numberLabel = UILabel()
    fileprivate let coverArtView = AsyncImageView()
    // made these public so that we can override what the `update(withModel:)` method does; the
    // problem is that the "model" is not e.g. a model struct but a full-fledged class that might
    // be used for other purposes — I'll deal with that later
    let primaryLabel = UILabel()
    let secondaryLabel = UILabel()
    fileprivate let durationLabel = UILabel()

//    @objc var autoScroll: Bool {
//        get { return primaryLabel.autoScroll }
//        set {
//            primaryLabel.autoScroll = newValue
//            secondaryLabel.autoScroll = newValue
//        }
//    }
//    
//    @objc var repeatScroll: Bool {
//        get { return primaryLabel.repeatScroll }
//        set {
//            primaryLabel.repeatScroll = newValue
//            secondaryLabel.repeatScroll = newValue
//        }
//    }
    
    @objc var number: Int = 0 {
        didSet { numberLabel.text = "\(number)" }
    }
    
    @objc var headerText: String = "" {
        didSet { headerLabel.text = headerText }
    }
    
    @objc var hideCacheIndicator: Bool = false {
        didSet { cachedIndicator.isHidden = (hideCacheIndicator || !(tableCellModel?.isCached ?? false)) }
    }
    
    @objc var hideHeaderLabel: Bool = true {
        didSet { if oldValue != hideHeaderLabel { makeHeaderLabelConstraints() } }
    }
    
    @objc var hideNumberLabel: Bool = false {
        didSet { if oldValue != hideNumberLabel { makeNumberLabelConstraints() } }
    }
    
    @objc var hideCoverArt: Bool = false {
        didSet { if oldValue != hideCoverArt { makeCoverArtConstraints(); makePrimaryLabelConstraints() } }
    }
    
    @objc var hideSecondaryLabel: Bool = false {
        didSet { if oldValue != hideSecondaryLabel { makeSecondaryLabelConstraints() } }
    }
    
    @objc var hideDurationLabel: Bool = false {
        didSet { if oldValue != hideDurationLabel { makeDurationLabelConstraints() } }
    }
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        backgroundColor = .systemBackground

        headerLabel.textColor = .label
        headerLabel.backgroundColor = .systemGray
        headerLabel.font = .systemFont(ofSize: 12)
        headerLabel.adjustsFontSizeToFitWidth = true;
        headerLabel.minimumScaleFactor = 0.5
        headerLabel.textAlignment = .center;
        contentView.addSubview(headerLabel)

        numberLabel.textColor = .label
        numberLabel.font = .boldSystemFont(ofSize: 20)
        numberLabel.adjustsFontSizeToFitWidth = true
        numberLabel.minimumScaleFactor = 0.25
        numberLabel.textAlignment = .center
        contentView.addSubview(numberLabel)

        coverArtView.isLarge = false
        coverArtView.backgroundColor = .systemGray
        contentView.addSubview(coverArtView)

        primaryLabel.textColor = .label
        primaryLabel.font = .boldSystemFont(ofSize: UIDevice.isSmall() ? 16 : 17)
        contentView.addSubview(primaryLabel)

        secondaryLabel.textColor = .secondaryLabel
        secondaryLabel.font = .systemFont(ofSize: UIDevice.isSmall() ? 13 : 14)
        contentView.addSubview(secondaryLabel)

        durationLabel.textColor = .secondaryLabel
        durationLabel.font = .systemFont(ofSize: 14)
        durationLabel.adjustsFontSizeToFitWidth = true
        durationLabel.minimumScaleFactor = 0.25
        durationLabel.textAlignment = .center
        contentView.addSubview(durationLabel)

        // TODO: Flip for RTL
        cachedIndicator.isHidden = true
        contentView.addSubview(cachedIndicator)
        cachedIndicator.snp.makeConstraints { make in
            make.leading.equalToSuperview()
            make.top.equalTo(headerLabel.snp.bottom)
        }
        
        remakeConstraints()
    }

    private func remakeConstraints() {
        makeHeaderLabelConstraints()
        makeNumberLabelConstraints()
        makeCoverArtConstraints()
        makePrimaryLabelConstraints()
        makeSecondaryLabelConstraints()
        makeDurationLabelConstraints()
    }

    required init?(coder: NSCoder) {
        fatalError("unimplemented")
    }

    @objc func update(withModel model: TableCellModel?) {
        tableCellModel = model;
        if let model = model {
            if !hideCoverArt { coverArtView.coverArtId = model.coverArtId }
            primaryLabel.text = model.primaryLabelText
            if !hideSecondaryLabel { secondaryLabel.text = model.secondaryLabelText }
            if !hideDurationLabel { durationLabel.text = model.durationLabelText }
            cachedIndicator.isHidden = hideCacheIndicator || !model.isCached
            remakeConstraints()
        }
    }
    
    @objc func update(withPrimaryText primaryText: String, secondaryText: String?) {
        tableCellModel = nil;
        hideNumberLabel = true
        hideCoverArt = true
        hideSecondaryLabel = (secondaryText == nil)
        hideDurationLabel = true
        primaryLabel.text = primaryText
        secondaryLabel.text = secondaryText;
        cachedIndicator.isHidden = true;
    }
    
    @objc func update(withPrimaryText primaryText: String, secondaryText: String?, coverArtId: String?) {
        tableCellModel = nil;
        hideNumberLabel = true
        hideSecondaryLabel = (secondaryText == nil)
        hideDurationLabel = true
        primaryLabel.text = primaryText
        secondaryLabel.text = secondaryText;
        coverArtView.coverArtId = coverArtId;
        cachedIndicator.isHidden = true;
    }
    
//    @objc func startScrollingLabels() {
//        primaryLabel.startScrolling()
//        if !hideSecondaryLabel {
//            secondaryLabel.startScrolling()
//        }
//    }
//
//    @objc func stopScrollingLabels() {
//        primaryLabel.stopScrolling()
//        if !hideSecondaryLabel {
//            secondaryLabel.stopScrolling()
//        }
//    }
    
    // MARK: AutoLayout

    fileprivate func makeHeaderLabelConstraints() {
        headerLabel.snp.remakeConstraints { make in
            if hideHeaderLabel { make.height.equalTo(0) }
            else { make.height.equalTo(20)}
            make.leading.trailing.top.equalToSuperview()
        }
    }
    
    fileprivate func makeNumberLabelConstraints() {
        numberLabel.snp.remakeConstraints { make in
            if hideNumberLabel { make.width.equalTo(0) }
            else { make.width.equalTo(30) }
            make.leading.bottom.equalToSuperview()
            make.top.equalTo(headerLabel.snp.bottom)
        }
    }
    
    fileprivate func makeCoverArtConstraints() {
        coverArtView.snp.remakeConstraints { make in
            if hideCoverArt { make.width.equalTo(0) }
            else { make.width.equalTo(coverArtView.snp.height) }
            make.leading.equalTo(numberLabel.snp.trailing).offset(hideCoverArt ? 0 : 5)
            make.top.equalTo(headerLabel.snp.bottom).offset(5)
            make.bottom.equalToSuperview().offset(-5)
        }
    }
    
    fileprivate func makePrimaryLabelConstraints() {
        primaryLabel.snp.remakeConstraints { make in
            if hideSecondaryLabel {
                make.height.equalTo(coverArtView).multipliedBy(0.66)
            } else {
                make.bottom.equalTo(secondaryLabel.snp.top)
            }
            make.leading.equalTo(coverArtView.snp.trailing).offset(hideCoverArt ? 5 : 10)
            make.trailing.equalTo(durationLabel.snp.leading).offset(-10)
            make.top.equalTo(headerLabel.snp.bottom).offset(UIDevice.isSmall() ? 5 : 10)
        }
    }
    
    fileprivate func makeSecondaryLabelConstraints() {
        secondaryLabel.snp.remakeConstraints { make in
            if hideSecondaryLabel { make.height.equalTo(0) }
            else { make.height.equalTo(coverArtView).multipliedBy(0.33) }
            make.leading.equalTo(primaryLabel)
            make.trailing.equalTo(primaryLabel)
            make.bottom.equalToSuperview().offset(UIDevice.isSmall() ? -5 : -10)
        }
    }
    
    fileprivate func makeDurationLabelConstraints() {
        durationLabel.snp.remakeConstraints { make in
            if hideDurationLabel { make.width.equalTo(0) }
            else { make.width.equalTo(30) }
            make.trailing.equalToSuperview().offset(hideDurationLabel ? 0 : -10)
            make.top.equalTo(headerLabel.snp.bottom)
            make.bottom.equalToSuperview()
        }
    }
}

@objc final class TrackTableViewCell: UniversalTableViewCell {
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        primaryLabel.numberOfLines = 0
//        primaryLabel.setContentCompressionResistancePriority(.required, for: .vertical)
//        primaryLabel.setContentHuggingPriority(.required, for: .vertical)
//        primaryLabel.setContentCompressionResistancePriority(.required, for: .horizontal)
//        primaryLabel.setContentHuggingPriority(.required, for: .horizontal)
        primaryLabel.lineBreakStrategy = .init()

        secondaryLabel.numberOfLines = 0
//        secondaryLabel.setContentCompressionResistancePriority(.required, for: .vertical)
//        secondaryLabel.setContentHuggingPriority(.required, for: .vertical)
//        secondaryLabel.setContentCompressionResistancePriority(.required, for: .horizontal)
//        secondaryLabel.setContentHuggingPriority(.required, for: .horizontal)
        secondaryLabel.lineBreakStrategy = .init()
    }
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    var oldHideSecondaryLabel: Bool?

    /// Try to work around layout bug when entering edit mode, I don't understand it — it's as if
    /// this just never worked properly or something
//    override func setEditing(_ editing: Bool, animated: Bool) {
//        super.setEditing(editing, animated: animated) // and why doesn't it obey the animation when stopping editing?
//        if editing {
//            oldHideSecondaryLabel = hideSecondaryLabel
//            hideSecondaryLabel = true
//        } else {
//            if let oldHideSecondaryLabel {
//                hideSecondaryLabel = oldHideSecondaryLabel
//            }
//        }
//    }

//    override func willTransition(to state: UITableViewCell.StateMask) {
//
//    }
//
//    override func didTransition(to state: UITableViewCell.StateMask) {
//
//    }

    fileprivate override func makePrimaryLabelConstraints() {
        primaryLabel.snp.remakeConstraints { make in
            if hideSecondaryLabel {
                make.bottom.equalToSuperview().offset(UIDevice.isSmall() ? -5 : -10)
            } else {
                make.bottom.equalTo(secondaryLabel.snp.top)
            }
            make.leading.equalTo(coverArtView.snp.trailing).offset(hideCoverArt ? 5 : 10)
            make.trailing.equalTo(durationLabel.snp.leading).offset(-10)
            make.top.equalTo(headerLabel.snp.bottom).offset(UIDevice.isSmall() ? 5 : 10)
        }
    }

    fileprivate override func makeSecondaryLabelConstraints() {
        secondaryLabel.snp.remakeConstraints { make in
            if hideSecondaryLabel {
                make.height.equalTo(0)
            } else {
                make.height.equalTo(1).priority(10) // resolve potential "ambiguity"
            }
            make.leading.equalTo(primaryLabel)
            make.trailing.equalTo(primaryLabel)
            make.bottom.equalToSuperview().offset(UIDevice.isSmall() ? -5 : -10)
        }
    }

    fileprivate override func makeCoverArtConstraints() {
        coverArtView.snp.remakeConstraints { make in
            if hideCoverArt {
                make.width.equalTo(0)
            }
            else {
                make.width.equalTo(coverArtView.snp.height)
            }
            make.leading.equalTo(numberLabel.snp.trailing).offset(hideCoverArt ? 0 : 5)
            make.centerY.equalToSuperview()
            make.height.lessThanOrEqualTo(40)
            make.height.lessThanOrEqualToSuperview().offset(-10)
            make.height.equalTo(40).priority(10)
        }
    }
}
