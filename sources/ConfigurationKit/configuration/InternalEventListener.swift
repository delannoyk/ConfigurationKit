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
internal protocol InternalEventListener {
    /**
     Called when an event occurs.
     */
    func onEvent()
}

/*internal class InternalEventListener: EventListener {


    /**
     Called when an event occurs.
     */
    func onEvent() {

    }
}*/
