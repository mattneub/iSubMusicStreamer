//
//  AutoScrollingLabel.swift
//  iSub
//
//  Created by Benjamin Baron on 11/11/20.
//  Copyright © 2020 Ben Baron. All rights reserved.
//

import UIKit
import SnapKit

private let labelGap = 25.0

@objc final class AutoScrollingLabel: UIView {
    private let scrollView = UIScrollView()
    private let label1 = UILabel()
    private let label2 = UILabel()
    private var animator: UIViewPropertyAnimator?
    
    @objc var autoScroll = true
    @objc var repeatScroll = true
    
    @objc var font: UIFont? {
        get {
            label1.font
        }
        set {
            label1.font = newValue
            label2.font = newValue
            if self.window != nil {
                stopScrolling()
                if autoScroll {
                    startScrolling()
                }
            }
        }
    }
    
    @objc var textColor: UIColor? {
        get {
            label1.textColor
        }
        set {
            label1.textColor = newValue
            label2.textColor = newValue
        }
    }
    
    @objc var text: String? {
        get {
            label1.text
        }
        set {
            label1.text = newValue
            label2.text = newValue
            invalidateIntrinsicContentSize()
            if self.window != nil {
                stopScrolling()
                if autoScroll {
                    startScrolling()
                }
            }
        }
    }
    
    override var intrinsicContentSize: CGSize {
        return label1.intrinsicContentSize
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        scrollView.showsVerticalScrollIndicator = false
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.isUserInteractionEnabled = false
        scrollView.decelerationRate = .fast
        addSubview(scrollView)
        scrollView.snp.makeConstraints { make in
            make.width.equalToSuperview().priority(.required)
            make.leading.top.bottom.equalToSuperview().priority(.required)
        }
        
        // Must use an intermediary content view for autolayout to work correctly inside a scroll view
        let contentView = UIView()
        scrollView.addSubview(contentView)
        contentView.snp.makeConstraints { make in
            make.leading.trailing.top.bottom.equalTo(scrollView.contentLayoutGuide).priority(.required)
        }

        contentView.addSubview(label1)
        label1.snp.makeConstraints { make in
            make.leading.top.bottom.equalToSuperview()
        }

        label2.isHidden = true
        contentView.addSubview(label2)
        label2.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.leading.equalTo(label1.snp.trailing).offset(labelGap)
            make.trailing.equalToSuperview().offset(labelGap)
        }

        NotificationCenter.addObserverOnMainThread(self, selector: #selector(didEnterBackground), name: UIApplication.didEnterBackgroundNotification.rawValue)
        NotificationCenter.addObserverOnMainThread(self, selector: #selector(willEnterForeground), name: UIApplication.willEnterForegroundNotification.rawValue)
    }
    
    required init?(coder: NSCoder) {
        fatalError("unsupported")
    }
    
    deinit {
        stopScrolling()
        NotificationCenter.removeObserverOnMainThread(self)
    }
    
    @objc private func didEnterBackground() {
        stopScrolling()
    }
    
    @objc private func willEnterForeground() {
        if autoScroll {
            startScrolling()
        }
    }
    
    override func willMove(toWindow: UIWindow?) {
        super.willMove(toWindow: window)
        if window == nil {
            // If the view leaves the window, stop and reset all scrolling
            stopScrolling()
        }
    }
    
    override func layoutSubviews() {
        stopScrolling()
        super.layoutSubviews()
        if autoScroll {
            Task {
                try await Task.sleep(nanoseconds: 200_000_000)
                startScrolling()
            }
        }
    }
    
    private func createAnimator(delay: TimeInterval) {
        guard scrollView.frame.width > 0, label1.frame.width > 0, scrollView.frame.width < label1.frame.width else { return }
        
        // Stop any existing animation
        stopScrolling()
        
        // Unhide label2 for the animation
        label2.isHidden = false
        
        // Create the new animation
        let startTime = Date()
        let minDuration = 1.0
        var duration = TimeInterval((label1.frame.width * 2) - scrollView.frame.width) * 0.03
        duration = duration < minDuration ? minDuration : duration
        animator = UIViewPropertyAnimator(duration: duration, curve: .linear) { [unowned self] in
            // Animate to show the second label
            self.scrollView.contentOffset.x = self.label1.frame.width + CGFloat(labelGap)
        }
        animator?.addCompletion { [unowned self] position in
            // Hack due to UIKit bug that causes the completion block to fire instantly
            // if animation starts before the view is fully displayed like in a table cell
            // which means we need to reschedule with the same delay instead of the longer repeat delay
            let didAnimate = Date().timeIntervalSince(startTime) > (delay + duration) * 0.9
            let repeatDelay = didAnimate ? delay * 2.5 : delay
            
            // Reset scroll view before the next run
            resetScrollView()
            self.animator = nil;
            if self.repeatScroll {
                self.startScrolling(delay: repeatDelay)
            }
        }
        animator?.isInterruptible = true
    }
    
    private func resetScrollView() {
        label2.isHidden = true
        scrollView.contentOffset = .zero
    }
    
    @objc func startScrolling(delay: TimeInterval = 2) {
        // Prevent iOS from killing the app for overusing the CPU in the background
        // NOTE: While the notification listeners stop the animation when the app enters
        //       the backgorund, whenever the song would change, it would kick off the
        //       animations again which would short-circuit and eat up CPU.
        //       This check prevents any animation while in the background.
        guard UIApplication.shared.applicationState != .background else { return }
        
        createAnimator(delay: delay)
        animator?.startAnimation(afterDelay: delay)
    }
    
    @objc func stopScrolling() {
        animator?.stopAnimation(true)
        animator = nil
        resetScrollView()
    }
}
