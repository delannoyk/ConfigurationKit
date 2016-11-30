//
//  WeakTarget.swift
//  ConfigurationKit
//
//  Created by Kevin DELANNOY on 20/02/16.
//  Copyright © 2016 Kevin Delannoy. All rights reserved.
//

import Foundation

/// The protocol to conform to in order to use a weak target.
protocol WeakTargetDelegate: class {
    /**
     Alerts the implementation that the selector was called on the weak target.

     - parameter target: The target.
     */
    func selectorCalled(on target: WeakTarget)
}

extension Selector {
    /// The selector that `WeakTarget` will answer and call the delegate.
    static let weakTargetSelector = #selector(WeakTarget.selector(_:))
}


/**
 *  A `WeakTarget` is used so that a NSTimer doesn't retain the real target and the real target can
 *  invalidate the timer in its deinit.
 */
class WeakTarget: NSObject {
    /// The real target.
    weak var target: WeakTargetDelegate?

    /**
     Initializes a `WeakTarget` from a real target.

     - parameter target: The real target.
     */
    init(_ target: WeakTargetDelegate) {
        self.target = target
    }

    /**
     The selector that will cause the delegate to be called.

     - parameter sender: Anything.
     */
    @objc fileprivate func selector(_ sender: Any) {
        target?.selectorCalled(on: self)
    }
}
