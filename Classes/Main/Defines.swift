//
//  Defines.swift
//  iSub
//
//  Created by Benjamin Baron on 11/24/20.
//  Copyright © 2020 Ben Baron. All rights reserved.
//

import Foundation

// Set up this way to be accessible in both Swift and Obj-C
@objc final class Defines: NSObject {
    @objc static var rowHeight: CGFloat { return UIDevice.isSmall() ? 50 : 65 }
    @objc static var tallRowHeight: CGFloat { return UIDevice.isSmall() ? 70 : 85 }
    @objc static var headerRowHeight: CGFloat { return UIDevice.isSmall() ? 45 : 60 }
    
    @objc static var musicNoteImageSystemName: String {
        if #available(iOS 14.0, *) {
            return "music.quarternote.3"
        } else {
            return "music.note"
        }
    }
    @objc static var equalizerSliderImageSystemName: String {
        if #available(iOS 14.0, *) {
            return "slider.vertical.3"
        } else {
            return "slider.horizontal.3"
        }
    }
}
