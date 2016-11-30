//
//  StopWatchEventProducer.swift
//  ConfigurationKit
//
//  Created by Kevin DELANNOY on 11/02/16.
//  Copyright © 2016 Kevin Delannoy. All rights reserved.
//

import Foundation

/**
 *  A `StopWatchEventProducer` generates events at regular interval.
 */
public class StopWatchEventProducer: NSObject, EventProducer {
    /// The timer.
    private var timer: Timer?

    /// The time interval used to generate events.
    public var timeInterval: TimeInterval {
        didSet {
            if let _ = timer {
                stopProducingEvents()
                startProducingEvents()
            }
        }
    }

    /// The event listener.
    public weak var eventListener: EventListener?


    /**
     Initializes a `StopWatchEventProducer`.

     - parameter timeInterval: The time interval to wait before generating new events.
     */
    public init(timeInterval: TimeInterval) {
        self.timeInterval = timeInterval
        super.init()
    }

    /**
     Stops producing events.
     */
    deinit {
        stopProducingEvents()
    }


    /**
     Creates a timer that will generate events at regular interval.
     */
    public func startProducingEvents() {
        guard timer == nil else {
            return
        }

        timer = Timer.scheduledTimer(timeInterval: timeInterval,
            target: WeakTarget(self),
            selector: .weakTargetSelector,
            userInfo: nil,
            repeats: true)
    }

    /**
     Stops the timer.
     */
    public func stopProducingEvents() {
        guard let timer = timer else {
            return
        }

        timer.invalidate()
        self.timer = nil
    }
}

extension StopWatchEventProducer: WeakTargetDelegate {
    /**
     Method that gets called when the timer ticks.

     - parameter target: The weak target.
     */
    func selectorCalled(on weakTarget: WeakTarget) {
        eventListener?.onEvent()
    }
}
