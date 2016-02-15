//
//  EventProducer.swift
//  ConfigurationKit
//
//  Created by Kevin DELANNOY on 10/02/16.
//  Copyright © 2016 Kevin Delannoy. All rights reserved.
//

import Foundation

/**
 *  An `EventListener` listens to events and reacts to them.
 */
public protocol EventListener: class {
    /**
     Called when an event occurs.
     */
    func onEvent()
}

/**
 *  An `EventProducer` serves the purpose of producing events that
 *  will generate a new download cycle of the configuration.
 */
public protocol EventProducer: class {
    /// The listener that will be alerted a new event occured.
    weak var eventListener: EventListener? { get set }

    /**
     Tells the producer to start producing events.
     */
    func startProducingEvents()

    /**
     Tells the producer to stop producing events.
     */
    func stopProducingEvents()
}
