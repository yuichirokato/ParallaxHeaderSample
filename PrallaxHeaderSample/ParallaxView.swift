//
//  ParallaxView.swift
//  PrallaxHeaderSample
//
//  Created by Yuichirou Takahashi on 2020/05/24.
//  Copyright © 2020 chanuapp. All rights reserved.
//

import UIKit

class ParallaxView: UIView {
    weak var parent: ParallaxHeader?
    
    var contentOffsetDidChange: (UIView, CGPoint?) -> Void = { _, _ in }

    override func willMove(toSuperview newSuperview: UIView?) {
        if self.superview?.isKind(of: UIScrollView.self) == true {
            parent?.observer?.invalidate()
            parent?.observer = nil
        }
    }
    
    override func didMoveToSuperview() {
        if let scrollView = self.superview as? UIScrollView {
            parent?.observer = scrollView.observe(\.contentOffset) { [weak self] view, change in
                self?.contentOffsetDidChange(view, change.newValue)
            }
        }
    }
}
