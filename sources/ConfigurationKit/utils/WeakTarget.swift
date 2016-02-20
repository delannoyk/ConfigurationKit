//
//  WeakTarget.swift
//  ConfigurationKit
//
//  Created by Kevin DELANNOY on 20/02/16.
//  Copyright © 2016 Kevin Delannoy. All rights reserved.
//

import UIKit

/// The protocol to conform to in order to use a weak target.
protocol WeakTargetDelegate: class {
    /**
     Alerts the implementation that the selector was called on the weak target.

     - parameter target: The target.
     */
    func selectorCalledOnWeakTarget(target: WeakTarget)
}

/**
 *  A `WeakTarget` is used so that a NSTimer doesn't retain the real target
 *  and the real target can invalidate the timer in its deinit.
 */
class WeakTarget: NSObject {
    /// The real target.
    weak var target: WeakTargetDelegate?

    /**
     Initializes a `WeakTarget` from a real target.

     - parameter target: The real target.

     - returns: An initialzed `WeakTarget`.
     */
    init(_ target: WeakTargetDelegate) {
        self.target = target
    }

    /**
     The selector that will cause the delegate to be called.

     - parameter _: Anything.
     */
    @objc func selector(_: AnyObject) {
        target?.selectorCalledOnWeakTarget(self)
    }
}
