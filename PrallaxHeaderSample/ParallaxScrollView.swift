//
//  ParallaxScrollView.swift
//  PrallaxHeaderSample
//
//  Created by Yuichirou Takahashi on 2020/05/24.
//  Copyright © 2020 chanuapp. All rights reserved.
//

import UIKit

protocol ParallaxScrollViewDelegate: UIScrollViewDelegate {
    func scrollView(_ scrollView: ParallaxScrollView, shouldScrollWith subview: UIView) -> Bool
}

class ParallaxScrollViewDelegateForwarder: NSObject {
    weak var delegate: ParallaxScrollViewDelegate?
}

extension ParallaxScrollViewDelegateForwarder: ParallaxScrollViewDelegate {
    func scrollView(_ scrollView: ParallaxScrollView, shouldScrollWith subview: UIView) -> Bool {
        return false
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        if let parallaxScrollView = scrollView as? ParallaxScrollView {
            parallaxScrollView.scrollViewDidEndDecelerating(scrollView)
        }

        delegate?.scrollViewDidEndDecelerating?(scrollView)
    }
    
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if let parallaxScrollView = scrollView as? ParallaxScrollView {
            parallaxScrollView.scrollViewDidEndDragging(scrollView, willDecelerate: decelerate)
        }
        
        delegate?.scrollViewDidEndDragging?(scrollView, willDecelerate: decelerate)
    }
}

class ParallaxScrollView: UIScrollView {
    // MARK: - Properties
    var parallaxScrollViewDelegate: ParallaxScrollViewDelegate? {
        set {
            forwarder.delegate = newValue
            super.delegate = nil
            super.delegate = forwarder
        }
        get {
            forwarder.delegate
        }
    }
    var forwarder = ParallaxScrollViewDelegateForwarder()
    var observedViews = [UIScrollView]()
    var observers = [Int: NSKeyValueObservation]()

    private var observer: NSKeyValueObservation?
    private var isObserving = false
    private var isLock = false

    // MARK: - Life cycle
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        initialize()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        
        initialize()
    }

    deinit {
        removeObservedViews()
    }

    private func initialize() {
        super.delegate = forwarder
        
        showsVerticalScrollIndicator = false
        isDirectionalLockEnabled = true
        bounces = true
        
        panGestureRecognizer.cancelsTouchesInView = false
        
        observer = observe(\.contentOffset, options: [.new, .old]) { [weak self] view, change in
            self?.contentOffsetDidChange(view, change: change)
        }
        
        isObserving = true
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        isLock = false
        removeObservedViews()
    }
    
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if !decelerate {
            isLock = false
            removeObservedViews()
        }
    }
}

// MARK: - Scroll View
private extension ParallaxScrollView {
    func scrollView(_ scrollView: UIScrollView, contentOffset offset: CGPoint) {
        isObserving = false
        scrollView.contentOffset = offset
        isObserving = true
    }
    
    func contentOffsetDidChange(_ scrollView: UIScrollView, change: NSKeyValueObservedChange<CGPoint>) {
        let newPoint = change.newValue ?? .zero
        let oldPoint = change.oldValue ?? .zero
        let diff = oldPoint.y - newPoint.y
        
        guard diff != 0, isObserving else { return }
        
        if diff > 0 && isLock {
            self.scrollView(self, contentOffset: oldPoint)
        } else if (contentOffset.y < -contentInset.top) && !bounces {
            self.scrollView(self, contentOffset: CGPoint(x: contentOffset.x, y: -contentInset.top))
        } else if contentOffset.y > -parallaxHeaderView.minimumHeight {
            self.scrollView(self, contentOffset: CGPoint(x: contentOffset.x, y: -parallaxHeaderView.minimumHeight))
        }
    }
}

// MARK: - KVO
private extension ParallaxScrollView {
    func addObserver(to scrollView: UIScrollView) {
        isLock = scrollView.contentOffset.y > -scrollView.contentInset.top

        observers[scrollView.hash] = scrollView.observe(\.contentOffset, options: [.new, .old]) { [weak self] view, change in
            self?.contentOffsetDidChange(view, change: change)
        }
    }
    
    func removeObserver(from scrollView: UIScrollView) {
        if let observer = observers[scrollView.hash] {
            observer.invalidate()
            observers[scrollView.hash] = nil
        }
    }
    
    func addObservedView(scrollView: UIScrollView) {
        if !observedViews.contains(scrollView) {
            observedViews.append(scrollView)
            addObserver(to: scrollView)
        }
    }
    
    func removeObservedViews() {
        for scrollView in observedViews {
            removeObserver(from: scrollView)
        }

        observedViews.removeAll()
    }
}

// MARK: - Gesture Recoginzer Delegate
extension ParallaxScrollView: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        if otherGestureRecognizer.view == self {
            return false
        }
        
        // Pan Gesture 以外の Gesture は許容しない
        guard let panGesture = gestureRecognizer as? UIPanGestureRecognizer else { return false }
        
        // 横方向の Pan Gesture は使えないようにする
        let velocity = panGesture.velocity(in: self)
        if abs(velocity.x) > abs(velocity.y) {
            return false
        }
        
        var otherView = otherGestureRecognizer.view
        
        if otherView?.isKind(of: NSClassFromString("WKContentView")!) == true {
            otherView = otherView?.superview
        }
        
        guard let scrollView = otherView as? UIScrollView else { return false }
        
        if scrollView.superview is UITableView {
            return false
        }
        
        if scrollView.superview?.isKind(of: NSClassFromString("UITableViewCellContentView")!) == true {
            return false
        }
        
        var shouldScroll = true
        shouldScroll = parallaxScrollViewDelegate?.scrollView(self, shouldScrollWith: scrollView) ?? true
        
        if shouldScroll {
            addObservedView(scrollView: scrollView)
        }

        return shouldScroll
    }
}
