//
//  ConfigurationEventListener.swift
//  ConfigurationKit
//
//  Created by Kevin DELANNOY on 15/02/16.
//  Copyright © 2016 Kevin Delannoy. All rights reserved.
//

import Foundation

/**
 *  This protocol is a copy of `EventListener` except that
 *  it isn't public. It allows `Configuration` to implement it
 *  internally and doesn't show publicly the implementation.
 */
internal protocol InternalEventListener: class {
    /**
     Called when an event occurs.
     */
    func onEvent()
}

/**
 *  `ConfigurationEventListener` is an internal implementation
 *  of `EventListener` so that we don't have to make the implementation
 *  public.
 */
internal class ConfigurationEventListener: EventListener {
    /// The real event listener
    weak var realEventListener: InternalEventListener?

    /**
     Called when an event occurs.
     */
    func onEvent() {
        realEventListener?.onEvent()
    }
}
