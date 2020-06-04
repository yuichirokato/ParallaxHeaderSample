//
//  ParallaxHeaderView.swift
//  PrallaxHeaderSample
//
//  Created by Yuichirou Takahashi on 2020/05/24.
//  Copyright © 2020 chanuapp. All rights reserved.
//

import ObjectiveC
import UIKit

protocol ParallaxHeaderViewDelegate: AnyObject {
    func parallaxHeaderDidScroll(header: ParallaxHeader)
}

enum ParallaxHeaderMode {
    case fill
    case topFill
    case top
    case center
    case bottom
}

class ParallaxHeader: NSObject {
    weak var delegate: ParallaxHeaderViewDelegate?
    weak var scrollView: UIScrollView? {
        didSet {
            if scrollView != oldValue {
                isObserving = true
            }
        }
    }
    var observer: NSKeyValueObservation?
    var height: CGFloat = 0 {
        didSet {
            if height != oldValue {
                adjustScrollViewTopInset(height)
                
                heightConstraint?.constant = height
                heightConstraint?.isActive = true
                layoutContentView()
            }
        }
    }
    var minimumHeight: CGFloat = 0 {
        didSet {
            layoutContentView()
        }
    }
    var mode = ParallaxHeaderMode.fill {
        didSet {
            if mode != oldValue {
                updateConstraints()
            }
        }
    }
    var progress: CGFloat = 0 {
        didSet {
            if progress != oldValue {
                delegate?.parallaxHeaderDidScroll(header: self)
            }
        }
    }
    var view: UIView? {
        didSet {
            if view != oldValue {
                oldValue?.removeFromSuperview()
                updateConstraints()
                contentView.layoutIfNeeded()

                height = contentView.frame.height

                heightConstraint?.constant = height
                heightConstraint?.isActive = true
            }
        }
    }

    private var isObserving = false
    private var heightConstraint: NSLayoutConstraint?
    private var positionConstraint: NSLayoutConstraint?
    private lazy var contentView: ParallaxView = {
        let view = ParallaxView()
        view.parent = self
        view.clipsToBounds = true
        view.translatesAutoresizingMaskIntoConstraints = false
        view.contentOffsetDidChange = { [weak self] _, _ in
            self?.layoutContentView()
        }

        self.heightConstraint = view.heightAnchor.constraint(equalToConstant: 0)
        
        return view
    }()
    
    func updateConstraints() {
        guard let view = self.view else { return }
        
        contentView.removeFromSuperview()
        scrollView?.addSubview(contentView)
        
        view.removeFromSuperview()
        contentView.addSubview(view)
        
        view.translatesAutoresizingMaskIntoConstraints = false
        
        switch mode {
            case .fill:
                setFillModeConstraints()

            case .topFill:
                setTopFillModeConstraints()
            
            case .top:
                setTopModeConstraints()
            
            case .center:
                setCenterModeConstraints()
            
            case .bottom:
                setBottomModeConstraints()
        }
    }
    
    // MARK: - Constraints
    private func setCenterModeConstraints() {
        guard let view = self.view else { return }

        NSLayoutConstraint.activate([
            view.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            view.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            view.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            view.heightAnchor.constraint(equalToConstant: height)
        ])
    }
    
    private func setFillModeConstraints() {
        guard let view = self.view else { return }

        NSLayoutConstraint.activate([
            view.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            view.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            view.topAnchor.constraint(equalTo: contentView.topAnchor),
            view.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
        ])
    }
    
    private func setTopFillModeConstraints() {
        guard let view = self.view else { return }

        let constraint = view.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
        constraint.priority = .defaultHigh

        NSLayoutConstraint.activate([
            view.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            view.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            view.topAnchor.constraint(equalTo: contentView.topAnchor),
            view.heightAnchor.constraint(equalToConstant: height),
            constraint
        ])
    }
    
    private func setTopModeConstraints() {
        guard let view = self.view else { return }

        NSLayoutConstraint.activate([
            view.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            view.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            view.topAnchor.constraint(equalTo: contentView.topAnchor),
            view.heightAnchor.constraint(equalToConstant: height),
        ])
    }
    
    private func setBottomModeConstraints() {
        guard let view = self.view else { return }

        NSLayoutConstraint.activate([
            view.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            view.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            view.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            view.heightAnchor.constraint(equalToConstant: height),
        ])
    }
    
    private func setContentViewConstraints() {
        guard let view = self.view else { return }
        guard let scrollView = self.scrollView else { return }
        
        positionConstraint = contentView.topAnchor.constraint(equalTo: scrollView.topAnchor)

        NSLayoutConstraint.activate([
            view.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            view.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            positionConstraint!
        ])
    }
    
    private func layoutContentView() {
        guard let scrollView = self.scrollView else { return }
        let minHeight = min(minimumHeight, height)
        let relativeYOffset = scrollView.contentOffset.y + scrollView.contentInset.top - height
        let relativeHeight = -relativeYOffset
        
        positionConstraint?.constant = relativeYOffset
        heightConstraint?.constant = max(relativeHeight, minHeight)

        let div = height - minimumHeight
        progress = (contentView.frame.height - minimumHeight) / (div > 0 ? div : height)
    }
    
    private func adjustScrollViewTopInset(_ top: CGFloat) {
        guard let scrollView = self.scrollView else { return }
        var inset = scrollView.contentInset
        var offset = scrollView.contentOffset
        
        offset.y += inset.top - top
        scrollView.contentOffset = offset
        
        inset.top = top
        scrollView.contentInset = inset
    }
}

fileprivate var parallaxHeaderAssociatedKey: UInt8 = 0

extension UIScrollView {
    var parallaxHeader: ParallaxHeader {
        set {
            newValue.scrollView = self
            objc_setAssociatedObject(self, &parallaxHeaderAssociatedKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
        get {
            if let header = objc_getAssociatedObject(self, &parallaxHeaderAssociatedKey) as? ParallaxHeader {
                return header
            }

            let header = ParallaxHeader()
            self.parallaxHeader = header

            return header
        }
    }
}
