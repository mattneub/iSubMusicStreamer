//
//  PlayAllAndShuffleHeader.swift
//  iSub
//
//  Created by Benjamin Baron on 11/13/20.
//  Copyright © 2020 Ben Baron. All rights reserved.
//

import UIKit
import SnapKit

@objc class PlayAllAndShuffleHeader: UIView {
    private let playAllButton = UIButton(type: .custom)
    private let shuffleButton = UIButton(type: .custom)
    
    @objc init(playAllHandler: @escaping () -> (), shuffleHandler: @escaping () -> ()) {
        super.init(frame: CGRect.zero)
        
        backgroundColor = .systemBackground
        snp.makeConstraints { make in
            make.height.equalTo(50)
        }
        
        playAllButton.setTitle("Play All", for: .normal)
        playAllButton.setTitleColor(.systemBlue, for: .normal)
        playAllButton.titleLabel?.font = .systemFont(ofSize: 24)
        playAllButton.addClosure(for: .touchUpInside, closure: playAllHandler)
        addSubview(playAllButton)
        playAllButton.snp.makeConstraints { make in
            make.width.equalTo(self).dividedBy(2)
            make.leading.equalTo(self)
            make.top.equalTo(self)
            make.bottom.equalTo(self)
        }
        
        shuffleButton.setTitle("Shuffle", for: .normal)
        shuffleButton.setTitleColor(.systemBlue, for: .normal)
        shuffleButton.titleLabel?.font = .systemFont(ofSize: 24)
        shuffleButton.addClosure(for: .touchUpInside, closure: shuffleHandler)
        addSubview(shuffleButton)
        shuffleButton.snp.makeConstraints { make in
            make.width.equalTo(self).dividedBy(2)
            make.trailing.equalTo(self)
            make.top.equalTo(self)
            make.bottom.equalTo(self)
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("unimplemented")
    }
}
