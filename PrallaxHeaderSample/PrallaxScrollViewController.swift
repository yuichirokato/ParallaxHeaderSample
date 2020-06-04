//
//  PrallaxScrollViewController.swift
//  PrallaxHeaderSample
//
//  Created by Yuichirou Takahashi on 2020/06/04.
//  Copyright © 2020 chanuapp. All rights reserved.
//

import UIKit

class PrallaxScrollViewController: UIViewController {
    @IBOutlet private var headerView: UIView?
    
    var scrollView = ParallaxScrollView() {
        didSet {
            observer = scrollView.parallaxHeader.observe(\.minimumHeight, options: [.new]) { [weak self] header, value in
                guard let self = self else { return }

                self.childHeightConstraint?.constant = -self.scrollView.parallaxHeader.minimumHeight
            }
        }
    }
    var headerViewController: UIViewController? {
        didSet {
            if headerViewController?.parent == self {
                headerViewController?.willMove(toParent: nil)
                headerViewController?.view.removeFromSuperview()
                headerViewController?.removeFromParent()
                headerViewController?.didMove(toParent: nil)
            }
            
            if let viewController = headerViewController {
                viewController.willMove(toParent: self)
                addChild(viewController)
                
                objc_setAssociatedObject(viewController, &viewControllerParallaxHeaderAssociatedKey, scrollView.parallaxHeader, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
                
                scrollView.parallaxHeader.view = viewController.view
                viewController.didMove(toParent: self)
            }
        }
    }
    var childViewController: UIViewController? {
        didSet {
            if childViewController?.parent == self {
                childViewController?.willMove(toParent: nil)
                childViewController?.view.removeFromSuperview()
                childViewController?.removeFromParent()
                childViewController?.didMove(toParent: nil)
            }
            
            if let viewController = childViewController {
                viewController.willMove(toParent: self)
                addChild(viewController)
                
                objc_setAssociatedObject(viewController, &viewControllerParallaxHeaderAssociatedKey, scrollView.parallaxHeader, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
                
                scrollView.addSubview(viewController.view)
                
                viewController.view.translatesAutoresizingMaskIntoConstraints = false
                
                childHeightConstraint = viewController.view.heightAnchor.constraint(equalTo: scrollView.heightAnchor)
                NSLayoutConstraint.activate([
                    viewController.view.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
                    viewController.view.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
                    viewController.view.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
                    viewController.view.topAnchor.constraint(equalTo: scrollView.topAnchor),
                    viewController.view.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
                    childHeightConstraint!
                ])

                viewController.didMove(toParent: self)
            }
        }
    }

    @IBInspectable
    private var headerHeight: CGFloat {
        set { scrollView.parallaxHeader.height = newValue }
        get { scrollView.parallaxHeader.height }
    }
    @IBInspectable
    private var headerMinimumHeight: CGFloat {
        set { scrollView.parallaxHeader.minimumHeight = newValue }
        get { scrollView.parallaxHeader.minimumHeight }
    }

    private var childHeightConstraint: NSLayoutConstraint?
    private var observer: NSKeyValueObservation?

    override func viewDidLoad() {
        super.viewDidLoad()

        scrollView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView)
        
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.topAnchor),
            scrollView.rightAnchor.constraint(equalTo: view.rightAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            scrollView.leftAnchor.constraint(equalTo: view.leftAnchor),
        ])
        
        scrollView.parallaxHeader.view = headerView
        scrollView.parallaxHeader.height = headerHeight
        scrollView.parallaxHeader.minimumHeight = headerMinimumHeight
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if #available(iOS 11.0, *) {
            return
        }

        // iOS 10 以下の対応
//        if self.automaticallyAdjustsScrollViewInsets {
//            self.headerMinimumHeight = topLayoutGuide.length
//        }
    }
    
    // デバイスを回転させた時に　SafeArea に content がめり込まないようにしている
    override func viewSafeAreaInsetsDidChange() {
        super.viewSafeAreaInsetsDidChange()
        
        if scrollView.contentInsetAdjustmentBehavior != .never {
            self.headerMinimumHeight = view.safeAreaInsets.top
            
            var safeAreaInsets = UIEdgeInsets.zero
            safeAreaInsets.bottom = view.safeAreaInsets.bottom
            childViewController?.additionalSafeAreaInsets = safeAreaInsets
        }
    }
    
    deinit {
        observer?.invalidate()
        observer = nil
    }
}

fileprivate var viewControllerParallaxHeaderAssociatedKey: UInt8 = 0

extension UIViewController {
    var parallaxHeader: ParallaxHeader {
        set {
            objc_setAssociatedObject(self, &viewControllerParallaxHeaderAssociatedKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
        get {
            if let header = objc_getAssociatedObject(self, &viewControllerParallaxHeaderAssociatedKey) as? ParallaxHeader {
                return header
            }

            let header = ParallaxHeader()
            self.parallaxHeader = header

            return header
        }
    }
}
